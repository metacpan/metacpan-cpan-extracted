package POE::Filter::DNS::TCP;
$POE::Filter::DNS::TCP::VERSION = '0.06';
#ABSTRACT: A POE Filter to handle DNS over TCP connections

use strict;
use warnings;
use Net::DNS;
use Net::DNS::Packet;

use base 'POE::Filter';

use bytes;

sub FRAMING_BUFFER () { 0 }
sub EXPECTED_SIZE  () { 1 }
sub INT16SZ        () { 2 }

sub new {
  my $class = shift;
  my $self = bless [
    '',           # FRAMING_BUFFER
    undef,        # EXPECTED_SIZE
  ], $class;
  return $self;
}

sub get_one_start {
  my ($self, $stream) = @_;
  $self->[FRAMING_BUFFER] .= join '', @$stream;
}

sub get_one {
  my $self = shift;

  if (
    defined($self->[EXPECTED_SIZE]) ||
    defined(
      $self->[EXPECTED_SIZE] = _decoder(\$self->[FRAMING_BUFFER])
    )
  ) {
    return [ ] if length($self->[FRAMING_BUFFER]) < $self->[EXPECTED_SIZE];

    # Four-arg substr() would be better here, but it's not compatible
    # with Perl as far back as we support.
    my $block = substr($self->[FRAMING_BUFFER], 0, $self->[EXPECTED_SIZE]);
    substr($self->[FRAMING_BUFFER], 0, $self->[EXPECTED_SIZE]) = '';
    $self->[EXPECTED_SIZE] = undef;

    if ( my $packet = Net::DNS::Packet->new( \$block ) ) {
      return [ $packet ];
    }
    warn "Could not parse DNS packet\n";
  }

  return [];
}

sub _decoder {
  my $data = shift;
  my $buf = substr $$data, 0, INT16SZ;
  return unless length $buf;
  my ($len) = unpack 'n', $buf;
  return unless $len;
  substr $$data, 0, INT16SZ, '';
  return $len;
}

sub get_pending {
  my $self = shift;
  return $self->[FRAMING_BUFFER];
}

sub put {
  my $self = shift;
  my $packets = shift;
  my @blocks;
  foreach my $packet (@$packets) {
    next unless eval { $packet->isa('Net::DNS::Packet'); };
    $packet->{buffer} = '';
    my $packet_data = $packet->data;
    my $lenmsg = pack( 'n', length $packet_data );
    push @blocks, $lenmsg . $packet_data;
  }
  return \@blocks;
}

q[You know like, in'it];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Filter::DNS::TCP - A POE Filter to handle DNS over TCP connections

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use POE::Filter::DNS::TCP;

  my $filter = POE::Filter::DNS::TCP->new();
  my $arrayref_of_net_dns_objects = $filter->get( [ $dns_stream ] );
  my $arrayref_of_streamed_dns_pckts = $filter->put( $arrayref_of_net_dns_objects );

=head1 DESCRIPTION

POE::Filter::DNS::TCP is a L<POE::Filter> for parsing and generating DNS messages
received from or transmitted (respectively) over TCP as per RFC 1035.

=for Pod::Coverage  FRAMING_BUFFER
 EXPECTED_SIZE
 INT16SZ

=head1 CONSTRUCTOR

=over

=item C<new>

Creates a new POE::Filter::DNS::TCP object.

=back

=head1 METHODS

=over

=item C<get>

=item C<get_one_start>

=item C<get_one>

Takes an arrayref which is contains streams of raw TCP DNS packets.
Returns an arrayref of L<Net::DNS::Packet> objects.

=item C<put>

Takes an arrayref of L<Net::DNS::Packet> objects.
Returns an arrayref of raw TCP DNS packets.

=item C<clone>

Makes a copy of the filter, and clears the copy's buffer.

=back

=head1 AUTHORS

=over 4

=item *

Chris Williams <chris@bingosnet.co.uk>

=item *

Hans Dieter Pearcey <hdp@cpan.org>

=item *

Rocco Caputo <rcaputo@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Chris Williams, Hans Dieter Pearcey and Rocco Caputo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
