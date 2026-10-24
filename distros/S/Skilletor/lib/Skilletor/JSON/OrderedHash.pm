package Skilletor::JSON::OrderedHash;
# ABSTRACT: A tied hash that keeps a JavaScript object's property order

use strict;
use warnings;

our $VERSION = '0.001';

# A key is an array index – and so ordered before every other key, ascending by value –
# when it is the canonical decimal form of an integer 0 .. 2**32 - 2 (ECMA-262 §6.1.7).
sub is_index_key {
  my ( $class, $key ) = @_;
  return 0 unless defined $key && $key =~ /\A(?:0|[1-9][0-9]{0,9})\z/;
  return $key <= 4294967294 ? 1 : 0;
}

sub TIEHASH {
  my ( $class, @pairs ) = @_;
  my $self = bless { data => {}, order => [], index => {} }, $class;
  while (@pairs) {
    my ( $k, $v ) = splice @pairs, 0, 2;
    $self->STORE( $k, $v );
  }
  return $self;
}

sub FETCH { $_[0]{data}{ $_[1] } }

sub STORE {
  my ( $self, $key, $value ) = @_;
  $key = '' . $key;
  unless ( exists $self->{data}{$key} ) {
    if ( __PACKAGE__->is_index_key($key) ) {
      $self->{index}{$key} = 1;
    }
    else {
      push @{ $self->{order} }, $key;
    }
  }
  $self->{data}{$key} = $value;
}

sub EXISTS { exists $_[0]{data}{ $_[1] } }

sub DELETE {
  my ( $self, $key ) = @_;
  return unless exists $self->{data}{$key};
  if ( delete $self->{index}{$key} ) {
    # nothing else to do: index keys are ordered by value
  }
  else {
    $self->{order} = [ grep { $_ ne $key } @{ $self->{order} } ];
  }
  return delete $self->{data}{$key};
}

sub CLEAR {
  my ( $self ) = @_;
  %{ $self->{data} } = ();
  @{ $self->{order} } = ();
  %{ $self->{index} } = ();
}

sub keys_in_order {
  my ( $self ) = @_;
  return ( ( sort { $a <=> $b } keys %{ $self->{index} } ), @{ $self->{order} } );
}

sub FIRSTKEY {
  my ( $self ) = @_;
  $self->{iter} = [ $self->keys_in_order ];
  return shift @{ $self->{iter} };
}

sub NEXTKEY { shift @{ $_[0]{iter} } }

sub SCALAR { scalar %{ $_[0]{data} } }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::JSON::OrderedHash - A tied hash that keeps a JavaScript object's property order

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::JSON qw( js_ordered );

  my $h = js_ordered( b => 1, a => 2, 10 => 3 );
  print join ',', keys %$h;    # 10,b,a

=head1 DESCRIPTION

The tie class behind every object L<Skilletor::JSON/js_parse> returns and
L<Skilletor::JSON/js_ordered> builds. C<keys> gives what C<Object.keys> gives
for the same object in JavaScript: array-index keys (C<"0"> to
C<"4294967294">) first, ascending by value, then every other key in the order
it was first stored. Storing an existing key keeps its place; deleting it and
storing it again moves a non-index key to the end. So a value read, changed and
written back keeps the key order the reference implementation would keep.

=head2 is_index_key

  Skilletor::JSON::OrderedHash->is_index_key('42');   # 1

True when a key is an array index in the ECMAScript sense.

=head2 keys_in_order

  (tied %$h)->keys_in_order;

The keys in property order, without iterating the tied hash.

=head1 SUPPORT

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
