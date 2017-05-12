package Search::Z3950;

use strict;
use warnings;

use Net::Z3950;

use Search::Z3950::ResultSet;

BEGIN {
    use vars qw($VERSION $have_time_hires);
    $VERSION = '0.05';
    eval "use Time::HiRes qw()";
    $have_time_hires = not $@;
}

sub new {
	my ($cls, %args) = @_;
	my %options = (
	    # Defaults - return full MARC records
	    'preferredRecordSyntax' => Net::Z3950::RecordSyntax::USMARC,
	    'elementSetName' => 'F',  # Full record
	);
	
    foreach (qw/
    
        mode
        preferredMessageSize
        maximumRecordSize
        
        user
        password
        groupid
        
        implementationId
        implementationName
        implementationVersion
        
        querytype
        databaseName
        prefetch
        
        smallSetUpperBound
        largeSetLowerBound
        mediumSetPresentNumber
        smallSetElementSetName
        mediumSetElementSetName
        
        preferredRecordSyntax
        elementSetName
        namedResultSets
        
    /) {
        $options{$_} = delete $args{$_}
            if exists $args{$_};
    }
	my $self = bless {
		# --- Default args
		'host' => $args{'host'},
		'port' => $args{'port'} || 210,
		'search_types' => {},
		'delay' => undef,  # no delays
		
		# --- Args the caller may specify
		%args,
		
		# --- Args to ignore
		'_connection' => undef,
#		'_manager' => undef,
		'_options' => \%options,
		
	}, $cls;
	return $self->_init;
}

sub search {
    my ($self, $key, $str) = @_;
    # --- Connect if necessary
    my $conn = $self->_connection
        || $self->_connect
        || die "Couldn't connect";
    my $search = $self->_make_search($key, $str);
    die "Bad search term: $key => $str"
        unless defined $search;
    # --- Pause, then perform the search
    $self->_pause;
    my $rs = $conn->search($search);
    die sprintf(
        "Search failed: %s (error code %s, add. info <%s>)",
        $conn->errmsg,
        $conn->errcode,
        $conn->addinfo,
    ) unless defined $rs;
    return Search::Z3950::ResultSet->new($rs);
}

sub disconnect {
	my ($self) = @_;
	$self->_connection->close;
	$self->_connection(undef);
}

sub DESTROY {
	my ($self) = @_;
    my $conn = $self->_connection;
    $conn->close if defined $conn;
}

sub host { scalar(@_) > 1 ? $_[0]->{'host'} = $_[1] : $_[0]->{'host'} }
sub port { scalar(@_) > 1 ? $_[0]->{'port'} = $_[1] : $_[0]->{'port'} }
sub delay { scalar(@_) > 1 ? $_[0]->{'delay'} = $_[1] : $_[0]->{'delay'} }
sub search_types { scalar(@_) > 1 ? $_[0]->{'search_types'} = $_[1] : $_[0]->{'search_types'} }
sub logic_types { scalar(@_) > 1 ? $_[0]->{'logic_types'} = $_[1] : $_[0]->{'logic_types'} }


# --- P R I V A T E   M E T H O D S --------------------------------------------

sub _init {
	my ($self) = @_;
	return $self;
}

sub _pause {
    my ($self) = @_;
    my $delay = $self->delay;
    return unless defined $delay and $delay > 0;
    if ($have_time_hires) {
        Time::HiRes::sleep($delay);
    } else {
        # --- Try to get the desired delay *on average*.
        #     For example, a delay of 3.4 means that 40%
        #     of the time we'll sleep for 4 seconds; 60%
        #     of the time we'll only sleep for 3 seconds.
        my $int_delay = int $delay;
        $int_delay++ if rand() < $delay - $int_delay;
        sleep $int_delay if $int_delay;
    }
}

sub _connect {
    my ($self) = @_;
    my $conn = Net::Z3950::Connection->new(
        $self->host,
        $self->port,
        %{ $self->_options },
    ) || die "Can't connect: $!";
    $self->_connection($conn);
}

#sub _connect {
#	my ($self) = @_;
#    my $conn = $self->_manager->connect($self->host, $self->port);
#    $self->_connection($conn);
#}

sub _make_search {
	my ($self, @args) = @_;
	my ($search_key, $search_str) = @args;
	die "Sorry, can't do explicit multiple search terms yet"
	    if scalar @args > 2;
	my ($stype) = grep { $_->{'name'} eq $search_key } @{ $self->search_types };
	my $search_syntax = $self->_options->{'querytype'};
	my $template = $stype->{'templates'}->{$search_syntax};
	if ($search_str =~ /\s/) {
	    if ($stype->{'multiple'}) {
	        die "Sorry, can't do implicit multiple search terms yet";
	        # XXX First pass at multiple-term code...
	        my @substrs = split(/\s+/, $search_str);
	        my $and = $self->logic_types->{'and'};
	        my $and_tmpl = $and->{'templates'}->{$search_syntax}
	            || die "No AND logic specified for search syntax $search_syntax";
	        $search_str = sprintf($template, shift @substrs);
	        while (@substrs) {
	            my $term = sprintf($template, shift @substrs);
    	        $search_str = sprintf($and_tmpl, $search_str, $term);
    	    };
    	    return $search_str;
	        # XXX Check this for errors
	    } else {
	        # XXX Is there anything to do here?
	    }
	}
	return sprintf($template, $search_str);
}

sub _connection { scalar(@_) > 1 ? $_[0]->{'_connection'} = $_[1] : $_[0]->{'_connection'} }
sub _manager { scalar(@_) > 1 ? $_[0]->{'_manager'} = $_[1] : $_[0]->{'_manager'} }
sub _options { scalar(@_) > 1 ? $_[0]->{'_options'} = $_[1] : $_[0]->{'_options'} }


1;


=head1 NAME

Search::Z3950 - Simple Z39.50 searching for ordinary folk

=head1 SYNOPSIS

    $z = Search::Z3950->new(
        host => $host,
        port => $port,
        user => $user,
        password => $pwd,
        databaseName => $dbname,
        delay => 0.5,  # half a second
        search_types => [
            {
                name => 'title',
                host => 'z3950.loc.gov',
                port => 7090,
                ... other Z39.50 params here ...
            },
            ...
        ],
    );
    $results = $z->search('title' => 'water method man');
    $numrecs = $results->count();
    for (1..$numrecs) {
        $rec = $results->record($_);
        ...
    }
    ...

=head1 DESCRIPTION

Search::Z3950 aims to simplify the coding of Z39.50 clients in Perl by reducing
the amount of information the programmer needs to to know about the Z39.50
protocol.  (Z39.50 is a standard for information retrieval commonly used by
libraries.)

For each Z39.50 server and database (a Z39.50 "service" or "target"), a set of
desired search types is written once by someone who knows Z39.50 search syntax
and the requirements of the particular service.  These search types are
typically stored in a configuration file (e.g., the YAML file F<services.yml>
included in the Search-Z3950 distribution).  All the Perl programmer has to know
is the search type's name (e.g., 'author') and whether it accepts multiple-word
search strings.

=head1 PUBLIC METHODS

=over 4

=item new

    $z = Search::Z3950->new(%args);

Construct a new Search::Z3950 object.  The following named arguments may be provided:

=over 4

=item host

The host name or IP address of the Z39.50 server.

=item port

(Optional.) The port on which the Z39.50 server listens.  The default is 210.

=item user

If the Z39.50 service requires authentication, you must supply a user name here.

=item password

If the Z39.50 service requires authentication, you must supply a password here.

=item databaseName

The name of the database to search.  Some Z39.50 services provide access to many
different databases, others to only one.

=item delay

See the description of the C<delay> method below.

=item search_types

See the description of the C<search_types> method below.

=item querytype

The type of query you'll be sending (i.e., the search syntax you'll be using). 
Different Z39.50 services allow for different query types; see the Library of
Congress's Z39.50 web site (URL below) for details.

The two query types most likely to be supported are C<prefix> (Prefix Query
Notation, a kind of RPN) and C<ccl> (Common Command Language).  The query type
C<ccl2rpn> may be used to write searches in CCL and have them automatically
translated into prefix notation before being sent to the Z39.50 server.

=item preferredRecordSyntax

The default value is C<Net::Z3950::RecordSyntax::USMARC()> (i.e., 19).  Using
this default, records are returned (from the results object) as instances of
the class C<MARC::Record>.

=back

A whole slew of other arguments may also be provided; these are passed on to the
L<Net::Z3950::Connection|Net::Z3950::Connection> object that's created for each
service used.

=item search

    $results = $z->search('title' => 'rutabaga tales');

Perform a search, connecting to the Z39.50 server the first time it's called.
Returns a L<Search::Z3950::ResultSet|Search::Z3950::ResultSet>.

=item disconnect

    $z->disconnect;

Disconnect from the Z39.50 server.

=item host

    $host = $z->host();
    $z->host($host);

Get or set the host.

=item port

    $port = $z->port();
    $z->port($port);

Get or set the port.

=item delay

    $delay = $z->delay;
    $z->delay($delay);

Get or set the number of seconds to delay (i.e., sleep) before sending
a request.  The delay may be specified as an integer or a floating-point
number.  The delay will be done using C<Time::HiRes::usleep> if it's
available; otherwise, C<sleep> is used and the delay is taken as an
B<average>.

For example, if the delay is specified as 1.5 seconds and Time::HiRes
isn't available, sleep(1) will be called half the time and sleep(2) the
other half.

=item search_types

    $searches = $z->search_types;
    $z->search_types($searches);

Get or set the search types available.  The search types are specified as
an array of hashes, each of which should have elements C<name>, C<multiple>,
C<templates>, and (optionally) C<description>.  (Search::Z3950 will ignore any other
elements present in the hash.)

The C<multiple> element indicates whether the search string should be broken
down into separate search terms when it consists of multiple words (separated
by whitespace).

For example, given this set of search types:

    [
        {
            'name' => 'isbn',
            'description' => 'Search by ISBN',
            'multiple' => 0,
            'templates' => ...
        }
        {
            'name' => 'authed',
            'description' => 'Search by author, editor, etc.',
            'multiple' => 1,
            'templates' => ...
        },
    ]

An ISBN search should specify only one ISBN:

    $z->search('isbn' => '0721655342');

While an author/editor search may contain several words:

    $z->search('author' => 'ulysses fishwick');

This latter example would result in a search something like this:

    au=ulysses and au=fishwick

Depending on the search syntax desired, of course.

B<WARNING:> Multiple search terms aren't allowed yet.  Trying to do
a search that would entail making multiple search terms will result
in an exception being thrown.

=back

=head1 PREREQUISITES

L<Net::Z3950|Net::Z3950> (which in turn requires the yaz toolkit).

=head1 FILES

=over 4

=item services.yml

This is a YAML file that defines a number of Z39.50 services (also known as
"targets").  The Search-Z3950 distribution uses this file only for testing
purposes, but you may copy it and adapt it for your own purposes.  See the code
in F<t/test-base.pl> for an example of how to use it.

NOTE: The fields `name', `abbrev', `location', and `searches' are used only for
testing purposes and may be deleted from the copy you make for your own purposes.

=back

=head1 BUGS

At this point, Search::Z3950 really doesn't do a very good job of insulating the
Perl programmer from Z39.50 details.

=head1 TO DO

=over 4

=item *

Allow for multiple search terms!

=item *

Better error checking when connecting.

=item *

Include a simple client as an example.

=item *

Make C<Search::Z3950::Database> and C<Search::Z3950::SearchType> modules
to simplify the specification of Z39.50 databases and
search types?

=item *

Enable asynchronous operation??

=back

=head1 SEE ALSO

L<Net::Z3950|Net::Z3950>,
L<Search::Z3950::ResultSet|Search::Z3950::ResultSet>.

=head1 VERSION

0.05

=head1 AUTHOR

Paul Hoffman (nkuitse AT cpan DOT org)

=head1 CREDITS

Many thanks to Mike Taylor (mike AT zoom DOT z3950 DOT org) for Net::Z3950,
without whom Search::Z3950 wouldn't exist.

The good folks who created the ZOOM abstract API (see
L<http://zoom.z3950.org/>), of which Net::Z3950 is a binding.

Index Data of Copenhagen for the yaz toolkit, upon which Net::Z3950 is built.

Finally, thanks to ISO, NISO, and the Library of Congress for the Z39.50
standard (see L<http://lcweb.loc.gov/z3950/agency/>).

=head1 COPYRIGHT

Copyright 2003 Paul M. Hoffman. All rights reserved.

This program is free software; you can redistribute it
and modify it under the same terms as Perl itself. 

