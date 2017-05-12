package Pod::Elemental::Element::Generic::Text;
# ABSTRACT: a Pod text or verbatim element
$Pod::Elemental::Element::Generic::Text::VERSION = '0.103004';
use Moose;
with 'Pod::Elemental::Flat';

use namespace::autoclean;

#pod =head1 OVERVIEW
#pod
#pod Generic::Text elements represent text paragraphs found in raw Pod.  They are
#pod likely to be fed to a Pod5 translator and converted to ordinary, verbatim, or
#pod data paragraphs in that dialect.  Otherwise, Generic::Text paragraphs are
#pod simple flat paragraphs.
#pod
#pod =cut

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Element::Generic::Text - a Pod text or verbatim element

=head1 VERSION

version 0.103004

=head1 OVERVIEW

Generic::Text elements represent text paragraphs found in raw Pod.  They are
likely to be fed to a Pod5 translator and converted to ordinary, verbatim, or
data paragraphs in that dialect.  Otherwise, Generic::Text paragraphs are
simple flat paragraphs.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
