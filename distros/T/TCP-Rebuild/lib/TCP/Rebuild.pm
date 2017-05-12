package TCP::Rebuild;

use warnings;
use strict;
use Net::LibNIDS 0.04;
use Socket qw(inet_ntoa);
use IO::File;
use Getopt::Long;
use Date::Format;

=head1 NAME

TCP::Rebuild - Rebuild TCP streams to files on disk.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Rebuilds TCP streams to plain text files on disk, one file per connection.

  use TCP::Rebuild;

  my $r = TCP::Rebuild->new();
  $r->rebuild('/path/to/file.pcap');

=head1 SUBROUTINES/METHODS

=head2 rebuild

  $r->rebuild('/path/to/file.pcap');

This method rebuilds a specific pcap file using the currently set options.

Will die if the file is not readable or if Net::LibNIDS cannot be initialised.

=cut

sub rebuild {
  my ($self, $filename) = @_;

  # Exception if we can't read the file
  if (!-r $filename) {
    die "File $filename is not readable";
  }

  # Net::LibNIDS is not currently object oriented, so this is the best we 
  # can do
  if ($self->{filter} ne '') {
    my $filter = $self->{filter} . ' or (ip[6:2] & 0x1fff != 0)';
    Net::LibNIDS::param::set_pcap_filter($filter);
  }
  Net::LibNIDS::param::set_filename($filename);

  if (!Net::LibNIDS::init) {
    die "libnids failed to initialise";
  }

  # Without this closure, the collector has no idea about $self
  my $callback = sub { 
    $self->_collector(@_);
  };
  Net::LibNIDS::tcp_callback($callback);
  Net::LibNIDS::run;

  $self->_cleanup;

  return 1;
}

=head2 new

  my $r = TCP::Rebuild->new;

This method constructs a new TCP::Rebuild object.  

=cut

sub new {
  my $class    = shift;
  my %defaults = (
    separator	=> 0,
    filter	=> ''
  );

  my $self = bless { %defaults, @_ } => $class;

  $self->{connections} = {};

  return $self;
}

sub _end_connection {
  my ($self, $key, $conn, $message) = @_;

  my $connections = $self->{connections};

#  _print 1, "Connection from " . $conn->client_ip . " " . $message;
#  _print 1, " (C->S: " . $connections{$key}{'client_bytes'} . " bytes, C<-S " . $connections{$key}{'server_bytes'} . " bytes)\n";

  # Close the output file, if appropriate
  undef $connections->{$key}{'fh'};

  delete $connections->{$key};
}

sub _save_data {
  my ($self, $key, $conn, $direction) = @_;

  my $connections = $self->{connections};

  # Extract the current connection object
  my $active = ($direction eq "server") ? $conn->client : $conn->server;

  my $data = substr($active->data, 0, $active->count_new);
  my $length = length $data;

  my $fh = $connections->{$key}{'fh'};

  # Print a separator delimiting packets, this could be customisable
  if ($self->{separator}) {
    print $fh "[$direction +$length] " . $conn->lastpacket_sec . "." . $conn->lastpacket_usec . "\n";
  }
  print $fh $data;

  return;
}

sub _collector {
  my ($self, $args) = @_;

  my $connections = $self->{connections};

  my $key = $args->client_ip . ":" . $args->client_port . "-" . $args->server_ip . ":" . $args->server_port;

  if($args->state == Net::LibNIDS::NIDS_JUST_EST()) {
    # Set the flags to say we want to collect this traffic
    $args->server->collect_on();
    $args->client->collect_on();

    # Create an empty buffer
    $connections->{$key}{'client_buffer'} = '';
    $connections->{$key}{'server_buffer'} = '';
    $connections->{$key}{'client_bytes'} = 0;             # Bytes FROM the client
    $connections->{$key}{'server_bytes'} = 0;             # Bytes FROM the server

    # Create a filehandle that is used subsequently to save data
    # TODO: We should probably check to see whether the file exists already
    my $fh = new IO::File $self->_generate_filename($args), O_WRONLY | O_CREAT | O_TRUNC;
    if (!defined $fh) {
      die "Could not open output file! $!";
    }
    binmode $fh;
    $connections->{$key}{'fh'} = $fh;
  
  } elsif ($args->state == Net::LibNIDS::NIDS_CLOSE()) {
    $self->_end_connection($key, $args, "was closed");
    return;

  } elsif ($args->state == Net::LibNIDS::NIDS_RESET()) {
    $self->_end_connection($key, $args, "was reset");
    return;

  } elsif ($args->state == Net::LibNIDS::NIDS_TIMED_OUT()) {
    $self->_end_connection($key, $args, "timed out");
    return;

  } elsif ($args->state == Net::LibNIDS::NIDS_DATA()) {
    # Data toward the client FROM the server
    if ($args->client->count_new) {
      $connections->{$key}{'server_bytes'} += $args->client->count_new;
      $self->_save_data($key, $args, 'server');
      return;
    }
    # Data toward the server FROM the client
    if ($args->server->count_new) {
      $connections->{$key}{'client_bytes'} += $args->server->count_new;
      $self->_save_data($key, $args, 'client');
      return;
    }

  }
  # UNREACHED, unless Net::LibNIDS changes
  return;
}

sub _generate_filename {
  my ($self, $conn) = @_;

  my $directory = time2str('%Y-%m-%d', $conn->lastpacket_sec);
  unless ( -e $directory ) { mkdir($directory); }

  my $name = $directory . '/' . $conn->client_ip . "." . $conn->client_port . "-" . $conn->server_ip . "." . $conn->server_port;
  return $name;
}

# Called when libnids finishes processing a file, to expunge old data and
# close any file handles
sub _cleanup {
  my $self = shift;

  my $connections = $self->{connections};
  foreach my $key (keys %$connections) {
    # undef automatically closes file with IO::File
    undef $connections->{$key}{'fh'};
  }
  return;
}

=head1 AUTHOR

David Cannings <david at edeca.net>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tcp-rebuild at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TCP-Rebuild>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 TODO

Things that would be nice to implement

=over 4

=item * Dump packet data to XML format

=item * Allow caller to supply a filename template

=item * Allow caller to supply a separator template

=item * Optional encoding of packet data (e.g. Base64)

=item * Introduce stream/packet statistics

=back


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TCP::Rebuild


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TCP-Rebuild>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TCP-Rebuild>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TCP-Rebuild>

=item * Search CPAN

L<http://search.cpan.org/dist/TCP-Rebuild/>

=back


=head1 ACKNOWLEDGEMENTS

Many thanks to CPAN::Mini, which provided many ideas as I packaged this code
into a module and shell script.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 David Cannings.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of TCP::Rebuild
