use 5.006;
use strict;
use warnings;

package Set::Associate::NewKey::LinearWrap;

# ABSTRACT: destructively empty the supply pool from the left hand end to give associations.

our $VERSION = '0.004001';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( with );

with 'Set::Associate::Role::NewKey' => { can_get_assoc => 1, };

__PACKAGE__->meta->make_immutable;

no Moose;







sub name { 'linear_wrap' }











sub get_assoc {
  return $_[1]->_items_cache_shift;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Set::Associate::NewKey::LinearWrap - destructively empty the supply pool from the left hand end to give associations.

=head1 VERSION

version 0.004001

=head1 METHODS

=head2 name

The name of this key assignment method ( C<linear_wrap> )

=head2 get_assoc

Returns a value destructively by taking the first value from C<$set_assoc>'s pool.

C<$new_key> is ignored with this method.

   my $value = $object->get_assoc( $set_assoc, $new_key );

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
