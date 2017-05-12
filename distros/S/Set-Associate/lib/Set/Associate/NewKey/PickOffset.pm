use 5.006;
use strict;
use warnings;

package Set::Associate::NewKey::PickOffset;

# ABSTRACT: Associate a key with a value from a pool based on the keys value as a numeric offset.

our $VERSION = '0.004001';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( with );

with 'Set::Associate::Role::NewKey' => { can_get_assoc => 1, };

__PACKAGE__->meta->make_immutable;

no Moose;







sub name { 'pick_offset' }











sub get_assoc {
  use bigint;
  return $_[1]->_items_cache_get( $_[2] % $_[1]->_items_cache_count );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Set::Associate::NewKey::PickOffset - Associate a key with a value from a pool based on the keys value as a numeric offset.

=head1 VERSION

version 0.004001

=head1 METHODS

=head2 name

The name of this key assignment method ( C<pick_offset> )

=head2 get_assoc

Returns a value non-destructively by picking an item at numerical offset C<$new_key>

   my $value = $object->get_assoc( $set_assoc, $new_key );

B<Note:> C<$new_key> is automatically modulo  of the length of C<$set_assoc>, so offsets beyond end of array are safe, and wrap.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
