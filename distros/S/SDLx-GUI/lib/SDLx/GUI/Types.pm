#
# This file is part of SDLx-GUI
#
# This software is copyright (c) 2013 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.016;
use warnings;

package SDLx::GUI::Types;
# ABSTRACT: Types used in the distribution
$SDLx::GUI::Types::VERSION = '0.002';
use Moose::Util::TypeConstraints;

enum 'PackSide' => [qw{ top bottom left right }];

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SDLx::GUI::Types - Types used in the distribution

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This module implements the specific types used by the distribution, and
exports them (exporting is done by L<Moose::Util::TypeConstraints>).

Current types defined:

=over 4

=item * PackSide - a simple enumeration, allowing C<top>, C<bottom>,
C<left> and C<right>.

=back

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
