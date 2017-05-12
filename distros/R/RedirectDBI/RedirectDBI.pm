#$Id: RedirectDBI.pm,v 0.02 2001/10/05 18:59:00 perler@xorgate.com Exp $
package Apache::RedirectDBI;
$VERSION='0.02';
use strict;
use Apache::Constants qw(:common OK DECLINED REDIRECT SERVER_ERROR);
my ($debug)=0;
my %Config = ('RedirectDBI_data_source'=>'',
	      'RedirectDBI_username'=>'',
	      'RedirectDBI_password'=>'',
	      'RedirectDBI_default'=>'',
	      'RedirectDBI_table2uri'=>'',
	      'RedirectDBI_location'=>'',
	      'RedirectDBI_url'=>'',
	      'RedirectDBI_field'=>'',
	      'RedirectDBI_external'=>'',
	     );

sub handler {
    my $r = shift;		     # Incoming request
    my($key, $val);		     # Configuration key/value
    
    my $config = {};		     # Configuration hash
    my @tables;			     # Map table names to URIs
#    
# Pull out the current URI
#
    my $uri=$r->uri;
# If the requested URI did not end in a trailing '/' and the URI is
# a directory then print a location redirect to the right URL. The
# user will then repeat the request with the right location, and we
# do this again.
#
# If you don't do this, the user will see the URL change when they
# get redirected to wherever based on the table they use. This exposes
# the underlying directory names, which is a bad thing.
#
    if(($uri !~ /\/$/) && (-d $r->document_root . $uri)) {
	$uri.='/';
	$r->header_out(Location=>$uri);
	return REDIRECT;
    }
# Pull out the configuration information
    while(($key, $val) = each %Config) {
	$val = $r->dir_config($key) || $val;
	$key =~ s/^RedirectDBI_//;	# Pull RedirectDBI_ off the start
	$config->{$key} = $val;
    }
#
# Connect to the database
#
    my $dbh;
    unless ($dbh = DBI->connect($config->{data_source}, $config->{username}, $config->{password})) {
	$r->log_reason(__PACKAGE__." db connect error with $config->{data_source} $uri");
	return SERVER_ERROR;
    }
#
# Get the table/uri map apart
    @tables = split /\s/, $config->{table2uri};
#
# Iterate over every other entry in @tables. Each entry will be the
# name of a table to check. For each table, count the number of users
# in the table who match the currently connected user. If there's
# at least one (there shouldn't be more than one, but you never know)
# then change the location of the current request, and fall out of the
# loop.
#    
    my $query;
    my $mode=1;
    $mode+=1 unless $config->{field};
    for(my $i=0; $i<=$#tables; $i+=$mode) {
	my $table = $tables[$i];	# Current table name
# SQL for search
	$config->{field}||='name';
	my $sql = "select ";
	if($config->{url}) {
	    $sql.="$config->{url} ";
	} else {
	    $sql.="$config->{field} ";
	}
	$sql.="from ".$table." where $config->{field}=" . $dbh->quote($r->connection->user);
    print STDERR __PACKAGE__." sql=$sql\n" if $debug;
#
# Run search, get results
#
	unless($query=$dbh->prepare($sql)) {
            $r->log_reason(__PACKAGE__." ERROR: prepare: $DBI::errstr $uri");
            $dbh->disconnect;
            return SERVER_ERROR;
        }
        unless($query->execute) {
            $r->log_reason(__PACKAGE__." ERROR: execute: $DBI::errstr $uri");
            $dbh->disconnect;
            return SERVER_ERROR;
        }
	my $matched_user = $query->fetchrow_array();
	if($matched_user) {		# User matched?
	    if($config->{url}) {
		$uri=$matched_user;
	    } else {
		my $touri = $tables[$i + 1];i # Get the location to send them to
		$uri =~ s/^$config->{'location'}/$touri/; # and store this change
	    }
	    print STDERR __PACKAGE__." uri=$uri\n" if $debug;
	    last;
	}
    }
#
# If the URI wasn't changed then send the user to the default location
#
    if ($uri eq $r->uri) {
	$uri =~ s/^$config->{'location'}/$config->{'default'}/;
	print STDERR __PACKAGE__." default_uri=$uri\n" if $debug;
    }
#
# Redirect Apache to the right location, and continue.
#
    my $retval;
    if($config->{external}) {
	print STDERR __PACKAGE__." external_REDIRECT\n" if $debug;
	$r->header_out(Location=>$uri);
	$retval=REDIRECT;
    } else {
	print STDERR __PACKAGE__." internal_redirect\n" if $debug;
	$r->internal_redirect_handler($uri);
	$retval=OK;
    }
    $query->finish;
    $dbh->disconnect;
    $retval;
}
1;

__END__
=head1 NAME

Apache::RedirectDBI - Redirect requests to different directories based on the existence of a user in one or more database tables

=head1 SYNOPSIS

PerlModule Apache::DBI Apache::RedirectDBI

<Location /path/to/virtual/directory>
    SetHandler perl-script
    PerlHandler Apache::RedirectDBI
    PerlAuthenHandler Apache::AuthenDBI

    PerlSetVar Auth_DBI_data_source     dbi:Oracle:CERT
    # :
    # and other Auth_DBI_* variables
    # :

    PerlSetVar RedirectDBI_data_source dbi:Oracle:CERT
    PerlSetVar RedirectDBI_username    nobody
    PerlSetVar RedirectDBI_password    nobody
    PerlSetVar RedirectDBI_location    /path/to/virtual/directory
    PerlSetVar RedirectDBI_default     /path/to/virtual/directory.1
    PerlSetVar RedirectDBI_table2uri   "t1 /directory.2 t2 /directory.3"
    PerlSetVar RedirectDBI_field       DB_field_name_containing_username
    PerlSetVar RedirectDBI_url         DB_field_name_containing_redirect_url
    PerlSetVar RedirectDBI_external    External_REDIRECT_is_issued

    AuthName "Realm"
    AuthType Basic
    Require  valid-user
</Location>

=head1 DESCRIPTION

C<Apache::RedirectDBI> allows you to create a virtual path in your document 
hierarchy.

All requests for access to this virtual path should require a username and
password
to access. When the user attempts to access this virtual path their username is
looked up in one or more database tables. The table in which the username is
found
in determines the physical path from which files are served.

For internal redirects the files are served to the user without the URL
changing,
so they never know that they have been redirected.  For external redirects the
web browser is sent a redirected to the desired URL.

The user is redirected to a default location if they are not in any of the
database
tables.
 
=head1 CONFIGURATION

First, define the virtual location that a user will see. You must also create other 
directories from which files will be served.

For example, specify /dir as the virtual directory, and have $DOCROOT/dir.1,
$DOCROOT/dir.2 and $DOCROOT/dir.3 as three possible directories that files
will be served from, depending on the table that lists the user.

    <Location /dir>
        ...
    </Location>
  
The different configuration directives in httpd.conf have the following
meanings;

=over 4

=item RedirectDBI_data_source

A DBI identifier for the data source that contains the tables that will be
used to determine which directory to send the user to.

=item RedirectDBI_username

The username to use when connecting to the data source.

=item RedirectDBI_password

The password to use when connecting to the data source.

=item RedirectDBI_location

The same path as used in the <Location ...> section of this configuration.

=item RedirectDBI_default

Path (relative to the document root) from which files will be served if the
user does not exist in any of the database files.

=item PerlSetVar RedirectDBI_field

A sting that provides the field name that contains the login username.

=item PerlSetVar RedirectDBI_url

A string that provides the field name containing the URL name to use for
the user logged in.  If this directive is not provided, an URI is obtianed
from the second subparameter from the RedirectDBI_table2uri directive.

=item PerlSetVar RedirectDBI_external

If the directive is set to any value, an external REDIRECT is presented
to the client.  If it is not set, an internal redirect is issued.

=item RedirectDBI_table2uri

A string containing white space seperated elements. If the RedirectDBI_url
directive is not set, each element is forms a pair where the first element 
is the name of the user table and the second element is the redirect location.
If the RedirectDBI_url is set, the list is just the user tables to scan.
The URI directory is relative to the document root from which files will 
be redireted if the user is in this table.

=back

=head1 CREATING YOUR TABLES

The tables listed in the C<RedirectDBI_table2uri> string must contain one or
more columns. One of these columns B<must> be contain the  C<username>, 
which is specified by the RedirectDBI_field directive.

These tables do not necessarily have to be real tables. If the backend
database supports it then they could be views. This allows for a lot of
flexibility in specifying the criteria for the inclusion of a user in
the table.

=head1 BUGS AND LIMITATIONS

=over 4

=item *

If the same username exists in more than one of the listed tables, the
location for the first table they are found in is used. Tables are searched
in the same order as they are listed in the configuration file.

=item *

It is assumed that the database connection to read the tables will always
succeed.

=back

=head1 SEE ALSO

perl(1), Apache(3), Apache::DBI(3)

=head1 AUTHORS

=over 4

=item Mike Smith (mjs@iii.co.uk)
=item George Sanderson (perler@xorgate.com)

Original Apache module

=item Nik Clayton (nik@freebsd.org)

Original CGI scripts which this replaces, and this documentation.

=back

