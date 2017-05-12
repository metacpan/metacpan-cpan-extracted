package MouseX::Types::Common;

use 5.006_002;
use strict;
use warnings;

our $VERSION = '0.001000';

1;
__END__
=head1 NAME

MouseX::Types::Common - A set of commonly-used type constraints

=head1 SYNOPSIS

    use MouseX::Types::Common::String qw/SimpleStr/;
    has short_str => (is => 'rw', isa => SimpleStr);

    ...
    #this will fail
    $object->short_str("string\nwith\nbreaks");



    use MouseX::Types::Common::Numeric qw/PositiveInt/;
    has count => (is => 'rw', isa => PositiveInt);

    ...
    #this will fail
    $object->count(-33);

=head1 DESCRIPTION

A set of commonly-used type constraints that do not ship with Mouse by default.

This module is based on C<MooseX::Types::Common>.

=head1 SEE ALSO

=over

=item * L<MouseX::Types::Common::String>

=item * L<MouseX::Types::Common::Numeric>

=item * L<MouseX::Types>

=item * L<Mouse::Util::TypeConstraints>

=item * L<MooseX::Types::Common>

=back

=head1 ORIGINAL AUTHORS

This distribution was extracted from the L<Reaction> code base by Guillermo
Roditi (groditi).

The original authors of this library are:

=over 4

=item * Matt S. Trout

=item * K. J. Cheetham

=item * Guillermo Roditi

=back

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji@cpan.orgE<gt>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
