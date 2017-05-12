package Net::Friends;

use 5.008;
use strict;
use warnings;
use Carp;
use IO::Socket::INET;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( query report ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );  # none by default

our $VERSION = '1.03';

sub Version { $VERSION }

sub new {
    my ($class, $host, $port);

    $class = shift;

    ($host = shift) || croak "Hostname must be specified in call to new.";

    $port = shift || 50123;

    my $self = {host => $host, port => $port, others => {}, name => 'Query',
        lat => '90.000000', lon => '0.000000', speed => 0, dir => 0, 
        last_update => 0, last_report => 0, max_update_freq => 60,
        id => 'queryqueryqueryqueryqu'};

    bless $self, $class;

    return $self;
}

# makes sure update isn't called more than once per max_update_freq seconds
sub _maybe_update {
    my $self = shift;

    if ($self->{last_update} + $self->{max_update_freq} > time) {
        return;  # updated too recently
    }
    $self->_update;
}

# give our position and get positions of others
sub _update {
    my $self = shift;

    $self->{last_update} = time;

    my $sock = IO::Socket::INET->new(PeerAddr => $self->{host},
        PeerPort => $self->{port}, Proto => 'udp');

    send $sock, (join ' ', ('POS:', $self->{id}, $self->{name}, $self->{lat},
        $self->{lon}, $self->{last_report}, $self->{speed}, $self->{dir})), 0;

    my %friends = ();

    my $val;

    do {
        recv $sock, $val, 1024, 0;
        chomp $val;
        if ($val =~ m/^POS:\s+(\S{22})\s+(\S+)\s+([\d\.-]+)\s+([\d\.-]+)\s+
            (\d+)\s+(\d+)\s+(\d+)/x) {
          my %entry;
          %entry = ();
          $entry{'name'} = $2;
          next if ($entry{'id'} eq 'queryqueryqueryqueryqu'); # skip lookups
          $entry{'lat'} = $3;
          $entry{'lon'} = $4;
          $entry{'time'} = $5;
          $entry{'speed'} = $6;
          $entry{'dir'} = $7;
          $friends{$2} = \%entry;
        }
    } while ($val ne '$END:$' && $val ne '');

    $self->{others} = \%friends;
}

# internally and remotely update our position information
sub report {
    my $self = shift;
    while (@_) { # push named parameters into object
        my $key = shift;
        $self->{$key} = shift;
    }
    $self->{last_report} = time;

    # set the 'id' randomly if it's still queryqueryqueryquery
    if ($self->{id} eq 'queryqueryqueryqueryqu') {
        $self->{id} = $self->_random_id;
    }

    $self->_update;
}

sub _random_id {
    my @chars = ('A' .. 'Z', 'a' .. 'z', 0, 1 .. 9);
    my @slice;
    foreach (1 .. 22) {
        push @slice, int rand @chars;
    }
    return join '', @chars[@slice];
}

# get last known position information about us and others
sub query {
    my $self = shift;
    my $who = shift;
    
    $self->_maybe_update;
    
    if (defined $who) {
        return $self->{others}->{$who}
    } else {
        return $self->{others}
    }
}

1;
__END__

=head1 NAME

Net::Friends - Perl extension for interacting with GPSDrive friendsd server

=head1 SYNOPSIS

    use Net::Friends;

    $friends = new Net::Friends $server

    $friends->report(
        name => 'Ry4an',
        lat => '44.988050',
        lon => '-93.274450',
        speed => 5,
        dir => 180
    );

    %someone = $friends->query($nick);
    
    %everyone = $friends->query;

=head1 ABSTRACT

  Net::Friends allows for the reporting to and querying of GPSDrive-style
  friendsd servers.  The friendsd server used simple UDP messages to update and
  report the most recent known position, speed, and direction of people and
  things.

=head1 DESCRIPTION

The Net::Friends module offers basic reporting and querying methods.  The
C<report> method is used to tell a remote friendsd server where an entity is,
the speed at which it's traveling, the direction in which it's traveling, and
when the provided information was last correct.  The C<query> method polls a
remote friendsd server and return results for a specific requested person or for
all people.  Each is discussed in more detail below.

Objects of type Net::Friends retain state between report() invocations.  If
multiple people/entities are being reported about either a separate Net::Friends
instance must be used for each person/entity or all the named parameters must be
provided on each call to C<report>.  See the detailed description of the
C<report> method for more information.

The friendsd program comes with GPSDrive written by Fritz Ganter.  GPSDrive can
be found on the web at http://www.gpsdrive.de

=over 4

=item C<report>

Updates the remote server's information about an entity.  Parameters include:

=over 4

=item C<name>

The name of the person/entity whose position is being reported.  Should be
provided on the first call to C<report>.

=item C<lat>

Current latitude of the person/entity whose position is being reported.  Value
is in degrees.  Locations in the Southern hemisphere should be negative values.
Values should have size decimal places of precision.

=item C<lon>

Current longitude of the person/entity whose position is being reported.  Value
is in degrees.  Locations in the Western hemisphere should be negative values.
Values should have size decimal places of precision.

=item C<speed>

Current speed in kilometers per hour of the person/entity whose position is
being reported.

=item C<dir>

Current heading in degrees of the person/entity whose position is being reported

=item C<id>

The 'id' parameter is used by friends servers to guarantee uniqueness amongst
people/entities which may have identical names.  Any report to the friendsd
server will overwrite any previous report with the same id.  A random id is
generated on the first call to report.  Subsequent calls to report will use the
same id.  Manually specifying an id can be used to allow for updating between
invocations.  Id values should be 22 character alphanumeric strings.  The
randomly selected id is available as C<$friends->{id}>.  If a single Net::Friend
instance is used to report on multiple people/entities the id corresponding to
each name should be provided with every report.  One can safely ignore id
altogether if all reports are about the same people/entity.

=back

Each call to C<report> sends an update to the remote friendsd server.  This
method need only be called when updated data is available.  All values are
recalled between calls to C<report> -- only values which have changed need be
reported.  

=item C<query>

Calls to the C<query> method return information about other persons known to the
friendsd server.  If the server has not been polled for data in over 60 seconds
new information will be fetched; otherwise cached values will be used.

A single optional parameter limits the returned data to that of a single name.
When returning data about a single person a hash is returned whose keys are
C<name>, C<lat>, C<lon>, C<speed>, C<dir> with values as explained in the
parameters for C<report>.  Also present is the key C<time> indicating the
seconds from the UNIX epoch UTC that the data was reported. 

If no parameter is provided data about all other people known by the friendsd
server are returned.  The return value is a hash whose keys are the names of
each person known to the friendsd server and whose values are hashes with the
format described in the previous paragraph.

=back

=head2 EXPORT

None by default.  Optionally the 'query' and 'report' methods which are both
covered in the export group ':all'.

=head1 SEE ALSO

C<gpsdrive>(1) as found at http://www.gpsdrive.de

=head1 AUTHOR

Ry4an Brase, E<lt>ry4an-cpan@ry4an.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Ry4an Brase

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
