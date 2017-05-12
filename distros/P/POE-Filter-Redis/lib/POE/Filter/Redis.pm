package POE::Filter::Redis;
BEGIN {
  $POE::Filter::Redis::VERSION = '0.02';
}

#ABSTRACT: A POE Filter for the Redis protocol

use strict;
use warnings;
use Carp qw[carp croak];
use base qw[POE::Filter];

# Bit mask.
use constant {
  PARSER_IDLE         => 0x01,
  PARSER_BETWEEN_BULK => 0x02,
  PARSER_IN_BULK      => 0x04,
};

use constant {
  SELF_BUFFER   => 0,
  SELF_STATE    => 1,
  SELF_HAS      => 2,
  SELF_LENGTH   => 3,
  SELF_AWAITING => 4,
  SELF_TYPE     => 5,
};

sub new {
  my $package = shift;

  my %args = @_;

  return bless [
    '',              # SELF_BUFFER
    PARSER_IDLE,     # SELF_STATE
    [ ],             # SELF_HAS
    0,               # SELF_LENGTH
    0,               # SELF_AWAITING
    undef,           # SELF_TYPE
  ], $package;
}

sub get_one_start {
  my ($self, $stream) = @_;
  $self->[SELF_BUFFER] .= join '', @{ $stream };
}

sub get_one {
  my $self = shift;

  return [ ] unless (
    length $self->[SELF_BUFFER] and $self->[SELF_BUFFER] =~ /\x0D\x0A/
  );

  # I expect it to be here mostly.
  if ($self->[SELF_STATE] & PARSER_IDLE) {

    # Single-line responses.  Remain in PARSER_IDLE state.
    return [ [ $1, $2 ] ] if $self->[SELF_BUFFER] =~ s/^([-+:])(.*?)\x0D\x0A//s;

    if ($self->[SELF_BUFFER] =~ s/^\*(-?\d+)\x0D\x0A//) {

      # Zero-item multibulk is an empty list.
      # Remain in the PARSER_IDLE state.
      return [ [ '*', ] ] if $1 == 0;

      # Negative item multibulk is an undef list.
      return [ [ '*', undef ] ] if $1 < 0;

      @$self[SELF_STATE, SELF_AWAITING, SELF_HAS, SELF_TYPE] = (
        PARSER_BETWEEN_BULK, $1, [], '*'
      );
    }
    elsif ($self->[SELF_BUFFER] =~ s/^\$(-?\d+)\x0D\x0A//) {

      # -1 length is undef.
      # Remain in the PARSER_IDLE state.
      return [ [ '$', undef ] ] if $1 < 0;

      @$self[SELF_STATE, SELF_AWAITING, SELF_LENGTH, SELF_HAS, SELF_TYPE] = (
        PARSER_IN_BULK, 1, $1 + 2, [], '$'
      );
    }
    else {
      # TODO - Recover somehow.
      croak "illegal redis response:\n$self->[SELF_BUFFER]";
    }
  }

  while (1) {
    if ($self->[SELF_STATE] & PARSER_BETWEEN_BULK) {

      # Can't parse a bulk header?
      return [ ] unless $self->[SELF_BUFFER] =~ s/^\$(-?\d+)\x0D\x0A//;

      # -1 length is undef.
      if ($1 < 0) {
        if (push(@{$self->[SELF_HAS]}, undef) == $self->[SELF_AWAITING]) {
          $self->[SELF_STATE] = PARSER_IDLE;
          return [ [ $self->[SELF_TYPE], @{$self->[SELF_HAS]} ] ];
        }

        # Remain in PARSER_BETWEEN_BULK state.
        next;
      }

      # Got a bulk length.
      @$self[SELF_STATE, SELF_LENGTH] = (PARSER_IN_BULK, $1 + 2);

      # Fall through.
    }

    # TODO - Just for debugging..
    croak "unexpected state $self->[SELF_STATE]" unless (
      $self->[SELF_STATE] & PARSER_IN_BULK
    );

    # Not enough data?
    return [ ] if length $self->[SELF_BUFFER] < $self->[SELF_LENGTH];

    # Got a bulk value.
    if (
      push(
        @{$self->[SELF_HAS]},
        substr(
          substr($self->[SELF_BUFFER], 0, $self->[SELF_LENGTH], ''),
          0, $self->[SELF_LENGTH] - 2
        )
      ) == $self->[SELF_AWAITING]
    ) {
      $self->[SELF_STATE] = PARSER_IDLE;
      return [ [ $self->[SELF_TYPE], @{$self->[SELF_HAS]} ] ];
    }

    # But... not enough of them.
    $self->[SELF_STATE] = PARSER_BETWEEN_BULK;
  }

  croak "never gonna give you up, never gonna let you down";
}

sub get_pending {
  my $self = shift;
  return [ $self->[SELF_BUFFER] ] if length $self->[SELF_BUFFER];
  return undef;
}

sub put {
  my ($self,$cmds) = @_;

  my @raw;
  foreach my $line ( @{ $cmds } ) {
    next unless ref $line eq 'ARRAY';
    next unless scalar @{ $line };
    my $cmd = shift @{ $line };
    push @raw,
      join( "\x0D\x0A",
            '*' . ( 1 + @{ $line } ),
            map { ('$' . length $_ => $_) }
              ( uc($cmd), @{ $line } ) ) . "\x0D\x0A";
  }
  \@raw;
}

qq[Redis Filter];


# vim: ts=2 sw=2 expandtab

__END__
=pod

=head1 NAME

POE::Filter::Redis - A POE Filter for the Redis protocol

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use POE::Filter::Redis;

  my $filter = POE::Filter::Redis->new();

  my $stream = $filter->put( [ [ 'SET', 'mykey', 'myvalue' ] ] );

  my $responses = $filter->get( [ "-NOT OK THIS TIME\x0D\x0A", "$6\x0D\x0Afoobar\x0D\x0A" ] );

=head1 DESCRIPTION

POE::Filter::Redis is a L<POE::Filter> for the Redis protocol, L<http://redis.io/topics/protocol>.

It is a C<client> side implementation.

It should be L<POE::Filter::Stackable> friendly if you like that sort of thing.

=head1 CONSTRUCTOR

=over

=item C<new>

Creates a new POE::Filter::Redis object.

=back

=head1 METHODS

=over

=item C<get>

=item C<get_one_start>

=item C<get_one>

Takes an arrayref which contains lines of Redis protocol streams from a Redis server.
Returns arrayref of arrayrefs, each being a complete response from the server.

=item C<put>

Takes an arrayref of arrayrefs. Each arrayref should contain an individual Redis command and
any additional parameters.
Returns an arrayref of protocol encoded strings suitable for sending over the wire to a Redis
server.

=item C<get_pending>

Returns any data remaining in a filter's input buffer

=item C<clone>

Makes a copy of the filter, and clears the copy's buffer.

=back

=head1 SEE ALSO

Please see L<POE::Filter> for documentation regarding the base
interface.

L<http://redis.io/topics/protocol>

L<http://redis.io/>

=head1 AUTHORS

=over 4

=item *

Chris Williams <chris@bingosnet.co.uk>

=item *

Rocco Caputo <rcaputo@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams and Rocco Caputo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

