use 5.006;
use strict;
use warnings;

package Set::Associate::RefillItems::Shuffle;

# ABSTRACT: a refill method that replenishes the cache with a shuffled list

our $VERSION = '0.004001';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( with has );

with 'Set::Associate::Role::RefillItems' => { can_get_all => 1, };









has items => ( isa => 'ArrayRef', is => 'rw', required => 1 );

__PACKAGE__->meta->make_immutable;

no Moose;







sub name { 'shuffle' }

use List::Util qw( shuffle );







sub get_all { return shuffle( @{ $_[0]->items } ) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Set::Associate::RefillItems::Shuffle - a refill method that replenishes the cache with a shuffled list

=head1 VERSION

version 0.004001

=head1 CONSTRUCTOR ARGUMENTS

=head2 items

    required ArrayRef

=head1 METHODS

=head2 name

The name of this refill method ( C<shuffle> )

=head2 get_all

Get a new copy of C<items> in shuffled form.

=head1 ATTRIBUTES

=head2 items

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
