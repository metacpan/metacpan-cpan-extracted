package Pod::Elemental::Element::Generic::Blank;
# ABSTRACT: a series of blank lines
$Pod::Elemental::Element::Generic::Blank::VERSION = '0.103004';
use Moose;
with 'Pod::Elemental::Flat';

#pod =head1 OVERVIEW
#pod
#pod Generic::Blank elements represent vertical whitespace in a Pod document.  For
#pod the most part, these are meant to be placeholders until made unnecessary by the
#pod Pod5 transformer.  Most end-users will never need to worry about these
#pod elements.
#pod
#pod =cut

use namespace::autoclean;

sub as_debug_string { '|' }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Element::Generic::Blank - a series of blank lines

=head1 VERSION

version 0.103004

=head1 OVERVIEW

Generic::Blank elements represent vertical whitespace in a Pod document.  For
the most part, these are meant to be placeholders until made unnecessary by the
Pod5 transformer.  Most end-users will never need to worry about these
elements.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
