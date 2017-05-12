package Net::MythTV;
use Moose;
use MooseX::StrictConstructor;
use DateTime;
use IO::File;
use IO::Socket::INET;
use Net::MythTV::Connection;
use Net::MythTV::Recording;
use Sys::Hostname qw();
use URI;

our $VERSION = '0.33';

has 'hostname' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'localhost',
);

has 'port' => (
    is      => 'rw',
    isa     => 'Int',
    default => 6543,
);

has 'connection' => (
    is  => 'rw',
    isa => 'Net::MythTV::Connection',
);

__PACKAGE__->meta->make_immutable;

sub BUILD {
    my $self = shift;

    my $connection = Net::MythTV::Connection->new(
        hostname => $self->hostname,
        port     => $self->port,
    );
    my ($ann_status)
        = $connection->send_command(
        'ANN Playback ' . Sys::Hostname::hostname . ' 0' );
    confess("Unable to announce") unless $ann_status eq 'OK';
    $self->connection($connection);
}

sub recordings {
    my $self = shift;
    my @bits = $self->connection->send_command('QUERY_RECORDINGS Play');
    my $nrecordings = shift @bits;
    my @recordings;
    foreach my $i ( 1 .. $nrecordings ) {
        my @parts = splice( @bits, 0, 46 );

        # use YAML; die Dump \@parts;
        my $title   = $parts[0];
        my $channel = $parts[6];
        my $url     = $parts[8];
        my $size    = $parts[10];

        # work around unsigned/signed bug for files bigger than 2GB
        if ( $size < 0 ) {
            $size = unpack( 'L', pack( 'l', $size ) );
        }

        my $start = DateTime->from_epoch( epoch => $parts[11] );
        my $stop  = DateTime->from_epoch( epoch => $parts[12] );

        # warn "$channel, $title $url $start - $stop ($size)\n";
        push @recordings,
            Net::MythTV::Recording->new(
            title   => $title,
            channel => $channel,
            url     => $url,
            size    => $size,
            start   => $start,
            stop    => $stop,
            );

        #use YAML; die Dump \@parts;
    }

    #die $nrecordings;
    return @recordings;
}

sub download_recording {
    my ( $self, $recording, $destination ) = @_;
    my $command_connection = $self->connection;

    my $uri      = URI->new( $recording->url );
    my $filename = $uri->path;

    my $fh = IO::File->new("> $destination") || die $!;

    my $data_connection = Net::MythTV::Connection->new(
        hostname => $self->hostname,
        port     => $self->port,
    );

    my ( $ann_status, $socket_id, $zero, $total )
        = $data_connection->send_command(
        'ANN FileTransfer ' . Sys::Hostname::hostname . '[]:[]' . $filename );
    confess("Unable to announce") unless $ann_status eq 'OK';

    # work around unsigned/signed bug for files bigger than 2GB
    if ( $total < 0 ) {
        $total = unpack( 'L', pack( 'l', $total ) );
    }

    # warn "$ann_status / $socket_id / $zero / $total";

    my ( $seek_status1, $seek_status2 )
        = $command_connection->send_command( 'QUERY_FILETRANSFER '
            . $socket_id . '[]:[]' . 'SEEK' . '[]:[]' . '0' . '[]:[]'
            . '0' );
    confess("Unable to announce")
        unless $seek_status1 == 0 && $seek_status2 == 0;

    while ($total) {
        my ($request_length)
            = $command_connection->send_command( 'QUERY_FILETRANSFER '
                . $socket_id . '[]:[]'
                . 'REQUEST_BLOCK' . '[]:[]'
                . 65535 );

        # warn "$total ($request_length)";
        last unless $request_length;
        my $read = 0;
        while ( $read < $request_length ) {
            my $bytes
                = $data_connection->socket->read( my $buffer,
                $request_length )
                || die $!;
            $fh->print($buffer) || die $!;
            $read += $bytes;

            # warn "read $bytes";
        }
        $total -= $read;
    }
}

__END__

=head1 NAME

Net::MythTV - Interface to MythTV

=head1 SYNOPSIS

  use Net::MythTV;

  my $mythtv = Net::MythTV->new();
  my @recordings = $mythtv->recordings;
  foreach my $recording (@recordings) {
    my $filename = $recording->title . ' ' . $recording->start . '.mpg';
    $filename =~ s{[^a-zA-Z0-9]}{_}g;
    print $recording->channel . ', '
      . $recording->title . ' '
      . $recording->start . ' - '
      . $recording->stop . ' ('
      . $recording->size . ') -> '
      . $filename
      . "\n";
    $mythtv->download_recording( $recording, $filename );
  }

  # prints out something like:
  # BBC TWO, Springwatch 2009-06-11T19:00:00 - 2009-06-11T20:00:00
  #   (3184986020) -> Springwatch_2009_06_11T19_00_00_mpg
  # Channel 4, Derren Brown 2009-06-11T22:40:00 - 2009-06-11T23:10:00
  #   (1734615088) -> Derren_Brown_2009_06_11T22_40_00_mpg

=head1 DESCRIPTION

This module provides a simple interface to MythTV using the
MythTV protocol. MythTV is a free open source digital video recorder.
Find out more at L<http://www.mythtv.org/>.

This module allows you to query the recordings and to download
them to a local file. By default the MythTV protocol is only
allowed on the local machine running MythTV.

=head1 METHODS

=head2 new

The constructor takes a hostname and port, but defaults to:

  my $mythtv = Net::MythTV->new();
  my $mythtv = Net::MythTV->new( hostname => 'localhost', port => 6543 );

=head2 recordings

List the recordings and return them as L<Net::MythTV::Recording> objects:

  my @recordings = $mythtv->recordings;
  foreach my $recording (@recordings) {
    print $recording->channel . ', '
      . $recording->title . ' '
      . $recording->start . ' - '
      . $recording->stop . ' ('
      . $recording->size . ') -> '
      . $filename
      . "\n";
  }

=head2 download_recording

Downloads a recording to a local file:

  $mythtv->download_recording( $recording, $filename );

=head1 SEE ALSO

L<Net::MythTV::Connection>, L<Net::MythTV::Recording>.

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2009, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
