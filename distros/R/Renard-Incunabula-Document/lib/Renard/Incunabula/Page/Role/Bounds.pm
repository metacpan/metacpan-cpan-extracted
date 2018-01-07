use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Page::Role::Bounds;
# ABSTRACT: Role for pages that have a height and width
$Renard::Incunabula::Page::Role::Bounds::VERSION = '0.004';
use Moo::Role;

requires 'width';

requires 'height';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Page::Role::Bounds - Role for pages that have a height and width

=head1 VERSION

version 0.004

=head1 ATTRIBUTES

=head2 width

An C<PositiveOrZeroInt> which represents the width of the page in pixels.

=head2 height

An C<PositiveOrZeroInt> which represents the height of the page in pixels.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
