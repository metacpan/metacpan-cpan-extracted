use 5.006;    #our, pragmas
use strict;
use warnings;

package MooseX::AttributeIndexes::Meta::Attribute::Trait::Indexed;

our $VERSION = '2.000001';

# ABSTRACT: A Trait for attributes which permits various indexing tunables

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose::Role qw( has );
use Moose::Meta::Attribute::Custom::Trait::Indexed;
use MooseX::Types::Moose 0.19 qw( CodeRef Bool );
use namespace::clean -except => 'meta';

has 'primary_index' => (
  is       => 'ro',
  isa      => Bool | CodeRef,    ## no critic (Bangs::ProhibitBitwiseOperators)
  required => 1,
  default  => 0,
);

has 'indexed' => (
  is       => 'ro',
  isa      => Bool | CodeRef,    ## no critic (Bangs::ProhibitBitwiseOperators)
  required => 1,
  default  => 0,
);

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AttributeIndexes::Meta::Attribute::Trait::Indexed - A Trait for attributes which permits various indexing tunables

=head1 VERSION

version 2.000001

=head1 ATTRIBUTES

=head2 C<indexed>

Bool. 0 = This attribute is not/cannot indexed, 1 = This Attribute is/can-be indexed.

CodeRef.  sub{ my( $attribute_meta, $object, $attribute_value ) = @_;  .... return }

=head2 C<primary_index>

Bool. 0 = This attribute is not a primary index, 1 = This Attribute is a primary index.

CodeRef.  sub{ my( $attribute_meta, $object, $attribute_value ) = @_;  .... return }

=head1 AUTHORS

=over 4

=item *

Kent Fredric <kentnl@cpan.org>

=item *

Jesse Luehrs <doy@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
