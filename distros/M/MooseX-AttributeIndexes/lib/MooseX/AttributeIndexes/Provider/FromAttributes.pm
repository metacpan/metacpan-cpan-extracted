use 5.006;    # our, pragma
use strict;
use warnings;

package MooseX::AttributeIndexes::Provider::FromAttributes;

our $VERSION = '2.000001';

# ABSTRACT: A Glue-on-role that provides attribute_indexes data to a class via harvesting attribute traits

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose::Role;
use Scalar::Util qw( blessed reftype );
use namespace::clean -except => 'meta';













sub attribute_indexes {

  my $self = shift;
  my $meta = $self->meta();

  my $k = {};

  for my $attr_name ( $meta->get_attribute_list ) {
    my $attr = $meta->get_attribute($attr_name);

    if ( $attr->does('MooseX::AttributeIndexes::Meta::Attribute::Trait::Indexed') ) {
      my $indexed = $attr->primary_index;
      $indexed ||= $attr->indexed;
      my $result;
      if ($indexed) {
        $result = $attr->get_value($self);
      }
      if (  not blessed($indexed)
        and defined reftype($indexed)
        and 'CODE' eq reftype($indexed) )
      {
        local $_ = $result;
        $result = $attr->$indexed( $self, $result );
      }
      if ($result) {
        $k->{$attr_name} = $result;
      }
    }
  }
  return $k;
}

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AttributeIndexes::Provider::FromAttributes - A Glue-on-role that provides attribute_indexes data to a class via harvesting attribute traits

=head1 VERSION

version 2.000001

=head1 METHODS

=head2 C<attribute_indexes>

A very trivial scanner, which looks for the

C<indexed> and C<primary_index> keys and returns a hashref of

key->value pairs ( circumventing the getter )

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
