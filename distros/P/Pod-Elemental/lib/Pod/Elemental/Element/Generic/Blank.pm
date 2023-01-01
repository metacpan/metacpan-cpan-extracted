package Pod::Elemental::Element::Generic::Blank 0.103006;
# ABSTRACT: a series of blank lines

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

version 0.103006

=head1 OVERVIEW

Generic::Blank elements represent vertical whitespace in a Pod document.  For
the most part, these are meant to be placeholders until made unnecessary by the
Pod5 transformer.  Most end-users will never need to worry about these
elements.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
