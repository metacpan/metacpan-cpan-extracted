package Mobile::Wurfl;

$VERSION = '1.09';

use strict;
use warnings;
use DBI;
use DBD::mysql;
use XML::Parser;
require LWP::UserAgent;
use HTTP::Date;
use Template;
use File::Spec;
use File::Basename;
use IO::Uncompress::Unzip qw(unzip $UnzipError);;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);

my %tables = (
    device => [ qw( id actual_device_root user_agent fall_back ) ],
    capability => [ qw( groupid name value deviceid ) ],
);

sub new
{
    my $class = shift;
    my %opts = (
        wurfl_home => "/tmp",
        db_descriptor => "DBI:mysql:database=wurfl:host=localhost", 
        db_username => 'wurfl',
        db_password => 'wurfl',
        device_table_name => 'device',
        capability_table_name => 'capability',
        wurfl_url => q{http://sourceforge.net/projects/wurfl/files/WURFL/latest/wurfl-latest.xml.gz/download},
        verbose => 0,
        @_
    );

    my $self = bless \%opts, $class;
    if ( ! $self->{verbose} )
    {
        open( STDERR, ">" . File::Spec->devnull() )
    }
    elsif ( $self->{verbose} == 1 )
    {
        open( STDERR, ">$self->{wurfl_home}/wurfl.log" );
    }
    else
    {
        warn "log to STDERR\n";
    }
    print STDERR "connecting to $self->{db_descriptor} as $self->{db_username}\n";
    $self->{dbh} ||= DBI->connect( 
        $self->{db_descriptor},
        $self->{db_username},
        $self->{db_password},
        { RaiseError => 1 }
    ) or die "Cannot connect to $self->{db_descriptor}: " . $DBI::errstr;
    die "no wurfl_url\n" unless $self->{wurfl_url};

    #get a filename from the URL and remove .zip or .gzip suffix
    my $name = (fileparse($self->{wurfl_url}, '.zip', '.gzip'))[0];
    $self->{wurfl_file} = "$self->{wurfl_home}/$name";

    $self->{ua} = LWP::UserAgent->new;
    return $self;
}


sub _tables_exist
{
    my $self = shift;
    my %db_tables = map { my $key = $_ =~ /(.*)\.(.*)/ ? $2 : $_ ; $key => 1 } $self->{dbh}->tables();
    for my $table ( keys %tables )
    {
        return 0 unless $db_tables{$self->{dbh}->quote_identifier($table)};

    }
    return 1;
}

sub _init
{
    my $self = shift;
    return if $self->{initialised};
    if ( ! $self->_tables_exist() )
    {
        die "tables don't exist on $self->{db_descriptor}: try running $self->create_tables()\n";
    }

    $self->{last_update_sth} = $self->{dbh}->prepare( 
        "SELECT ts FROM $self->{device_table_name} ORDER BY ts DESC LIMIT 1"
    );
    $self->{user_agents_sth} = $self->{dbh}->prepare( 
        "SELECT DISTINCT user_agent FROM $self->{device_table_name}" 
    );
    $self->{devices_sth} = $self->{dbh}->prepare( 
        "SELECT * FROM $self->{device_table_name}" 
    );
    $self->{device_sth} = $self->{dbh}->prepare( 
        "SELECT * FROM $self->{device_table_name} WHERE id = ?"
    );
    $self->{deviceid_sth} = $self->{dbh}->prepare( 
        "SELECT id FROM $self->{device_table_name} WHERE user_agent = ?"
    );
    $self->{lookup_sth} = $self->{dbh}->prepare(
        "SELECT * FROM $self->{capability_table_name} WHERE name = ? AND deviceid = ?"
    );
    $self->{fall_back_sth} = $self->{dbh}->prepare(
        "SELECT fall_back FROM $self->{device_table_name} WHERE id = ?"
    );
    $self->{groups_sth} = $self->{dbh}->prepare(
        "SELECT DISTINCT groupid FROM $self->{capability_table_name}"
    );
    $self->{group_capabilities_sth} = $self->{dbh}->prepare(
        "SELECT DISTINCT name FROM $self->{capability_table_name} WHERE groupid = ?"
    );
    $self->{capabilities_sth} = $self->{dbh}->prepare(
        "SELECT DISTINCT name FROM $self->{capability_table_name}"
    );
    for my $table ( keys %tables )
    {
	next if $self->{$table}{sth};
        my @fields = @{$tables{$table}};
        my $fields = join( ",", @fields );
        my $placeholders = join( ",", map "?", @fields );
        my $sql = "INSERT INTO $table ( $fields ) VALUES ( $placeholders ) ";
        $self->{$table}{sth} = $self->{dbh}->prepare( $sql );
    }
    $self->{initialised} = 1;
}

sub set
{
    my $self = shift;
    my $opt = shift;
    my $val = shift;

    die "unknown option $opt\n" unless exists $self->{$opt};
    return $self->{$opt} = $val;
}

sub get
{
    my $self = shift;
    my $opt = shift;

    die "unknown option $opt\n" unless exists $self->{$opt};
    return $self->{$opt};
}

sub create_tables
{
    my $self = shift;
    my $sql = shift;
    unless ( $sql )
    {
        my $tt = Template->new();
        my $template = join( '', <DATA> );
        $tt->process( \$template, $self, \$sql ) or die $tt->error;
    }
    for my $statement ( split( /\s*;\s*/, $sql ) )
    {
        next unless $statement =~ /\S/;
        $self->{dbh}->do( $statement ) or die "$statement failed\n";
    }
}

sub touch( $$ ) 
{ 
    my $path = shift;
    my $time = shift;
    die "no path" unless $path;
    die "no time" unless $time;
    print STDERR "touch $path ($time)\n";
    return utime( $time, $time, $path );
}

sub last_update
{
    my $self = shift;
    $self->_init();
    $self->{last_update_sth}->execute();
    my ( $ts ) = str2time($self->{last_update_sth}->fetchrow());
    $ts ||= 0;
    print STDERR "last update: $ts\n";
    return $ts;
}

sub rebuild_tables
{
    my $self = shift;

    my $local = ($self->get_local_stats())[1];
    my $last_update = $self->last_update();
    if ( $local <= $last_update )
    {
        print STDERR "$self->{wurfl_file} has not changed since the last database update\n";
        return 0;
    }
    print STDERR "$self->{wurfl_file} is newer than the last database update\n";
    print STDERR "flush dB tables ...\n";
    $self->{dbh}->begin_work;
    $self->{dbh}->do( "DELETE FROM $self->{device_table_name}" );
    $self->{dbh}->do( "DELETE FROM $self->{capability_table_name}" );
    my ( $device_id, $group_id );
    print STDERR "create XML parser ...\n";
    my $xp = new XML::Parser(
        Style => "Object",
        Handlers => {
            Start => sub { 
                my ( $expat, $element, %attrs ) = @_;
                if ( $element eq 'group' )
                {
                    my %group = %attrs;
                    $group_id = $group{id};
                }
                if ( $element eq 'device' )
                {
                    my %device = %attrs;
                    my @keys = @{$tables{device}};
                    my @values = @device{@keys};
                    $device_id = $device{id};
                    $self->{device}{sth}->execute( @values );
                }
                if ( $element eq 'capability' )
                {
                    my %capability = %attrs;
                    my @keys = @{$tables{capability}};
                    $capability{deviceid} = $device_id;
                    $capability{groupid} = $group_id;
                    my @values = @capability{@keys};
                    $self->{capability}{sth}->execute( @values );
                }
            },
        }
    );
    print STDERR "parse XML ...\n";
    $xp->parsefile( $self->{wurfl_file} );
    print STDERR "commit dB ...\n";
    $self->{dbh}->commit;
    return 1;
}

sub update
{
    my $self = shift;
    print STDERR "get wurfl\n";
    my $got_wurfl = $self->get_wurfl();
    print STDERR "got wurfl: $got_wurfl\n";
    my $rebuilt ||= $self->rebuild_tables();
    print STDERR "rebuilt: $rebuilt\n";
    return $got_wurfl || $rebuilt;
}

sub get_local_stats
{
    my $self = shift;
    return ( 0, 0 ) unless -e $self->{wurfl_file};
    print STDERR "stat $self->{wurfl_file} ...\n";
    my @stat = ( stat $self->{wurfl_file} )[ 7,9 ];
    print STDERR "@stat\n";
    return @stat;
}

sub get_remote_stats
{
    my $self = shift;
    print STDERR "HEAD $self->{wurfl_url} ...\n";
    my $response = $self->{ua}->head( $self->{wurfl_url} );
    die $response->status_line unless $response->is_success;
    die "can't get content_length\n" unless $response->content_length;
    die "can't get last_modified\n" unless $response->last_modified;
    my @stat = ( $response->content_length, $response->last_modified );
    print STDERR "@stat\n";
    return @stat;
}

sub get_wurfl
{
    my $self = shift;
    my @local = $self->get_local_stats();
    my @remote = $self->get_remote_stats();
 
    if ( $local[1] == $remote[1] )
    {
        print STDERR "@local and @remote are the same\n";
        return 0;
    }
    print STDERR "@local and @remote are different\n";
    print STDERR "GET $self->{wurfl_url} -> $self->{wurfl_file} ...\n";

    #create a temp filename
    my $tempfile = "$self->{wurfl_home}/wurfl_$$";
    
    my $response = $self->{ua}->get( 
        $self->{wurfl_url},
        ':content_file' => $tempfile
    );
    die $response->status_line unless $response->is_success;
    if ($response->{_headers}->header('content-type') eq 'application/x-gzip') {
        gunzip($tempfile => $self->{wurfl_file}) || die "gunzip failed: $GunzipError\n";
        unlink($tempfile);
    } elsif ($response->{_headers}->header('content-type') eq 'application/zip') {
        unzip($tempfile => $self->{wurfl_file}) || die "unzip failed: $UnzipError\n";
        unlink($tempfile);
    } else {
        move($tempfile, $self->{wurfl_file});
    }
    touch( $self->{wurfl_file}, $remote[1] );
    return 1;
}

sub user_agents
{
    my $self = shift;
    $self->_init();
    $self->{user_agents_sth}->execute();
    return map $_->[0], @{$self->{user_agents_sth}->fetchall_arrayref()};
}

sub devices
{
    my $self = shift;
    $self->_init();
    $self->{devices_sth}->execute();
    return @{$self->{devices_sth}->fetchall_arrayref( {} )};
}

sub groups
{
    my $self = shift;
    $self->_init();
    $self->{groups_sth}->execute();
    return map $_->[0], @{$self->{groups_sth}->fetchall_arrayref()};
}

sub capabilities
{
    my $self = shift;
    my $group = shift;
    $self->_init();
    if ( $group )
    {
        $self->{group_capabilities_sth}->execute( $group );
        return map $_->[0], @{$self->{group_capabilities_sth}->fetchall_arrayref()};
    }
    $self->{capabilities_sth}->execute();
    return map $_->[0], @{$self->{capabilities_sth}->fetchall_arrayref()};
}

sub _lookup
{
    my $self = shift;
    my $deviceid = shift;
    my $name = shift;
    $self->_init();
    $self->{lookup_sth}->execute( $name, $deviceid );
    return $self->{lookup_sth}->fetchrow_hashref;
}

sub _fallback
{
    my $self = shift;
    my $deviceid = shift;
    my $name = shift;
    $self->_init();
    my $row = $self->_lookup( $deviceid, $name );
    return $row if $row && ( $row->{value} || $row->{deviceid} eq 'generic' );
    $self->{fall_back_sth}->execute( $deviceid );
    my $fallback = $self->{fall_back_sth}->fetchrow 
        || die "no fallback for $deviceid\n"
    ;
    if ( $fallback eq 'root' )
    {
        die "fellback all the way to root: this shouldn't happen\n";
    }
    return $self->_fallback( $fallback, $name );
}

sub canonical_ua
{
    no warnings 'recursion';
    my $self = shift;
    my $ua = shift;
    $self->_init();
    $self->{deviceid_sth}->execute( $ua );
    my $deviceid = $self->{deviceid_sth}->fetchrow;
    if ( $deviceid )
    {
        print STDERR "$ua found\n";
        return $ua;
    }
    $ua = substr( $ua, 0, -1 );
    # $ua =~ s/^(.+)\/(.*)$/$1\// ;
    unless ( length $ua )
    {
        print STDERR "can't find canonical user agent\n";
        return;
    }
    return $self->canonical_ua( $ua );
}

sub device
{
    my $self = shift;
    my $deviceid = shift;
    $self->_init();
    $self->{device_sth}->execute( $deviceid );
    my $device = $self->{device_sth}->fetchrow_hashref;
    print STDERR "can't find device for user deviceid $deviceid\n" unless $device;
    return $device;
}

sub deviceid
{
    my $self = shift;
    my $ua = shift;
    $self->_init();
    $self->{deviceid_sth}->execute( $ua );
    my $deviceid = $self->{deviceid_sth}->fetchrow;
    print STDERR "can't find device id for user agent $ua\n" unless $deviceid;
    return $deviceid;
}

sub lookup
{
    my $self = shift;
    my $ua = shift;
    my $name = shift;
    $self->_init();
    my %opts = @_;
    my $deviceid = $self->deviceid( $ua );
    return unless $deviceid;
    return 
        $opts{no_fall_back} ? 
            $self->_lookup( $deviceid, $name )
        : 
            $self->_fallback( $deviceid, $name ) 
    ;
}

sub lookup_value
{
    my $self = shift;
    $self->_init();
    my $row = $self->lookup( @_ );
    return $row ? $row->{value} : undef;
}

sub cleanup
{
    my $self = shift;
    print STDERR "cleanup ...\n";
    if ( $self->{dbh} )
    {
        print STDERR "drop tables\n";
        for ( keys %tables )
        {
            print STDERR "DROP TABLE IF EXISTS $_\n";
            $self->{dbh}->do( "DROP TABLE IF EXISTS $_" );
        }
    }
    return unless $self->{wurfl_file};
    return unless -e $self->{wurfl_file};
    print STDERR "unlink $self->{wurfl_file}\n";
    unlink $self->{wurfl_file} || die "Can't remove $self->{wurfl_file}: $!\n";
}

#------------------------------------------------------------------------------
#
# Start of POD
#
#------------------------------------------------------------------------------

=head1 NAME

Mobile::Wurfl - a perl module interface to WURFL (the Wireless Universal Resource File - L<http://wurfl.sourceforge.net/>).

=head1 SYNOPSIS

    my $wurfl = Mobile::Wurfl->new(
        wurfl_home => "/path/to/wurfl/home",
        db_descriptor => "DBI:mysql:database=wurfl:host=localhost", 
        db_username => 'wurfl',
        db_password => 'wurfl',
        wurfl_url => q{http://sourceforge.net/projects/wurfl/files/WURFL/latest/wurfl-latest.xml.gz/download},
    );

    my $dbh = DBI->connect( $db_descriptor, $db_username, $db_password );
    my $wurfl = Mobile::Wurfl->new( dbh => $dbh );

    my $desc = $wurfl->get( 'db_descriptor' );
    $wurfl->set( wurfl_home => "/another/path" );

    $wurfl->create_tables( $sql );
    $wurfl->update();
    $wurfl->get_wurfl();
    $wurfl->rebuild_tables();

    my @devices = $wurfl->devices();

    for my $device ( @devices )
    {
        print "$device->{user_agent} : $device->{id}\n";
    }

    my @groups = $wurfl->groups();
    my @capabilities = $wurfl->capabilities();
    for my $group ( @groups )
    {
        @capabilities = $wurfl->capabilities( $group );
    }

    my $ua = $wurfl->canonical_ua( "SonyEricssonK750i/R1J Browser/SEMC-Browser/4.2 Profile/MIDP-2.0 Configuration/CLDC-1.1" );
    my $deviceid = $wurfl->deviceid( $ua );

    my $wml_1_3 = $wurfl->lookup( $ua, "wml_1_3" );
    print "$wml_1_3->{name} = $wml_1_3->{value} : in $wml_1_3->{group}\n";
    my $fell_back_to = wml_1_3->{deviceid};
    my $width = $wurfl->lookup_value( $ua, "max_image_height", no_fall_back => 1 );
    $wurfl->cleanup();

=head1 DESCRIPTION

Mobile::Wurfl is a perl module that provides an interface to mobile device information represented in wurfl (L<http://wurfl.sourceforge.net/>). The Mobile::Wurfl module works by saving this device information in a database (preferably mysql). 

It offers an interface to create the relevant database tables from a SQL file containing "CREATE TABLE" statements (a sample is provided with the distribution). It also provides a method for updating the data in the database from the wurfl.xml file hosted at L<http://kent.dl.sourceforge.net/sourceforge/wurfl/wurfl-latest.xml.gz>. 

It provides methods to query the database for lists of capabilities, and groups of capabilities. It also provides a method for generating a "canonical" user agent string (see L</canonical_ua>). 

Finally, it provides a method for looking up values for particular capability / user agent combinations. By default, this makes use of the hierarchical "fallback" structure of wurfl to lookup capabilities fallback devices if these capabilities are not defined for the requested device.

=head1 METHODS

=head2 new

The Mobile::Wurfl constructor takes an optional list of named options; e.g.:

    my $wurfl = Mobile::Wurfl->new(
        wurfl_home => "/path/to/wurfl/home",
        db_descriptor => "DBI:mysql:database=wurfl:host=localhost", 
        db_username => 'wurfl',
        db_password => 'wurfl',
        wurfl_url => q{http://sourceforge.net/projects/wurfl/files/WURFL/latest/wurfl-latest.xml.gz/download},,
        verbose => 1,
    );

The list of possible options are as follows:

=over 4

=item wurfl_home

Used to set the default home diretory for Mobile::Wurfl. This is where the cached copy of the wurfl.xml file is stored. It defaults to /tmp.

=item db_descriptor

A database descriptor - as used by L<DBI> to define the type, host, etc. of database to connect to. This is where the data from wurfl.xml will be stored, in two tables - device and capability. The default is "DBI:mysql:database=wurfl:host=localhost" (i.e. a mysql database called wurfl, hosted on localhost.

=item db_username

The username used to connect to the database defined by L</METHODS/new/db_descriptor>. Default is "wurfl".

=item db_password

The password used to connect to the database defined by L</METHODS/new/db_descriptor>. Default is "wurfl".

=item dbh

A DBI database handle.

=item wurfl_url

The URL from which to get the wurfl.xml file, this can be uncompressed or compressed with zip or gzip Default is L<http://sourceforge.net/projects/wurfl/files/WURFL/latest/wurfl-latest.xml.gz/download>.

=item verbose

If set to a true value, various status messages will be output. If value is 1, these messages will be written to a logfile called wurfl.log in L</METHODS/new/wurfl_home>, if > 1 to STDERR.

=back

=head2 set / get

The set and get methods can be used to set / get values for the constructor options described above. Their usage is self explanatory:

    my $desc = $wurfl->get( 'db_descriptor' );
    $wurfl->set( wurfl_home => "/another/path" );

=head2 create_tables

The create_tables method is used to create the database tables required for Mobile::Wurfl to store the wurfl.xml data in. It can be passed as an argument a string containing appropriate SQL "CREATE TABLE" statements. If this is not passed, it uses appropriate statements for a mysql database (see __DATA__ section of the module for the specifics). This should only need to be called as part of the initial configuration.

=head2 update

The update method is called to update the database tables with the latest information from wurfl.xml. It calls get_wurfl, and then rebuild_tables, each of which work out what if anything needs to be done (see below). It returns true if there has been an update, and false otherwise.

=head2 rebuild_tables

The rebuild_tables method is called by the update method. It checks the modification time of the locally cached copy of the wurfl.xml file against the last modification time on the database, and if it is greater, rebuilds the database table from the wurfl.xml file.

=head2 get_wurfl

The get_wurfl method is called by the update method. It checks to see if the locally cached version of the wurfl.xml file is up to date by doing a HEAD request on the WURFL URL, and comparing modification times. If there is a newer version of the file at the WURFL URL, or if the locally cached file does not exist, then the module will GET the wurfl.xml file from the WURFL URL.

=head2 devices

This method returns a list of all the devices in WURFL. This is returned as a list of hashrefs, each of which has keys C<user_agent>, C<actual_device_root>, C<id>, and C<fall_back>.

=head2 groups

This method returns a list of the capability groups in WURFL.

=head2 capabilities( group )

This method returns a list of the capabilities in a group in WURFL. If no group is given, it returns a list of all the capabilites.

=head2 canonical_ua( ua_string )

This method takes a user agent string as an argument, and tries to find a matching "canonical" user agent in WURFL. It does this simply by recursively doing a lookup on the string, and if this fails, chopping anything after and including the last "/" in the string. So, for example, for the user agent string:

    SonyEricssonK750i/R1J Browser/SEMC-Browser/4.2 Profile/MIDP-2.0 Configuration/CLDC-1.1

the canonical_ua method would try the following:

    SonyEricssonK750i/R1J Browser/SEMC-Browser/4.2 Profile/MIDP-2.0 Configuration/CLDC-1.1
    SonyEricssonK750i/R1J Browser/SEMC-Browser/4.2 Profile/MIDP-2.0 Configuration
    SonyEricssonK750i/R1J Browser/SEMC-Browser/4.2 Profile
    SonyEricssonK750i/R1J Browser/SEMC-Browser
    SonyEricssonK750i/R1J Browser
    SonyEricssonK750i

until it found a user agent string in WURFL, and then return it (or return undef if none were found). In the above case (for WURFL v2.0) it returns the string "SonyEricssonK750i".

=head2 deviceid( ua_string )

This method returns the deviceid for a given user agent string.

=head2 device( deviceid )

This method returns a hashref for a given deviceid. The hashref has keys C<user_agent>, C<actual_device_root>, C<id>, and C<fall_back>.

=head2 lookup( ua_string, capability, [ no_fall_back => 1 ] )

This method takes a user agent string and a capability name, and returns a hashref representing the capability matching this combination. The hashref has the keys C<name>, C<value>, C<groupid> and C<deviceid>. By default, if a capability has no value for that device, it recursively falls back to its fallback device, until it does find a value. You can discover the device "fallen back to" by accessing the C<deviceid> key of the hash. This behaviour can be controlled by using the "no_fall_back" option.

=head2 lookup_value( ua_string, capability, [ no_fall_back => 1 ] )

This method is similar to the lookup method, except that it returns a value instead if a hash.

=head2 cleanup()

This method forces the module to C<DROP> all of the database tables it has created, and remove the locally cached copy of wurfl.xml.

=head1 AUTHOR

Ave Wrigley <Ave.Wrigley@itn.co.uk>

=head1 COPYRIGHT

Copyright (c) 2004 Ave Wrigley. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

#------------------------------------------------------------------------------
#
# End of POD
#
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#
# True ...
#
#------------------------------------------------------------------------------

1;

__DATA__

DROP TABLE IF EXISTS [% capability_table_name %];
CREATE TABLE [% capability_table_name %] (
  name varchar(255) NOT NULL default '',
  value varchar(255) default '',
  groupid varchar(255) NOT NULL default '',
  deviceid varchar(255) NOT NULL default '',
  ts timestamp NOT NULL,
  KEY groupid (groupid),
  KEY name_deviceid (name,deviceid)
) TYPE=InnoDB;

DROP TABLE IF EXISTS [% device_table_name %];
CREATE TABLE [% device_table_name %] (
  user_agent varchar(255) NOT NULL default '',
  actual_device_root enum('true','false') default 'false',
  id varchar(255) NOT NULL default '',
  fall_back varchar(255) NOT NULL default '',
  ts timestamp NOT NULL,
  KEY user_agent (user_agent),
  KEY id (id)
) TYPE=InnoDB;
