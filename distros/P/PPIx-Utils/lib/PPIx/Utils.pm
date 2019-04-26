package PPIx::Utils;

use strict;
use warnings;
use Exporter 'import';

use PPIx::Utils::Classification ':all';
use PPIx::Utils::Language ':all';
use PPIx::Utils::Traversal ':all';

our $VERSION = '0.003';

our @EXPORT_OK = (
    @PPIx::Utils::Classification::EXPORT_OK,
    @PPIx::Utils::Language::EXPORT_OK,
    @PPIx::Utils::Traversal::EXPORT_OK,
);

our %EXPORT_TAGS = (
    all            => [@EXPORT_OK],
    classification => [@PPIx::Utils::Classification::EXPORT_OK],
    language       => [@PPIx::Utils::Language::EXPORT_OK],
    traversal      => [@PPIx::Utils::Traversal::EXPORT_OK],
);

1;

=head1 NAME

PPIx::Utils - Utility functions for PPI

=head1 SYNOPSIS

    use PPIx::Utils qw(:classification :language :traversal);

=head1 DESCRIPTION

C<PPIx::Utils> is a collection of utility functions for working with L<PPI>
documents. The functions are organized into submodules, and may be imported
from the appropriate submodule or via this module.

These functions were originally from L<Perl::Critic::Utils> and related
modules, and have been split off to this distribution for use outside of
L<Perl::Critic>.

=head1 MODULES

The import tag C<:all> will import the functions from all modules listed below.

=head2 L<PPIx::Utils::Classification>

Functions related to classification of L<PPI> elements. All functions from this
module can be imported with the import tag C<:classification>.

=head2 L<PPIx::Utils::Language>

Functions related to the Perl language. All functions from this module can be
imported with the import tag C<:language>.

=head2 L<PPIx::Utils::Traversal>

Functions related to traversal of L<PPI> documents. All functions from this
module can be imported with the import tag C<:traversal>.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

Code originally from L<Perl::Critic::Utils> by Jeffrey Ryan Thalhammer
<jeff@imaginative-software.com>, L<Perl::Critic::Utils::PPI> +
L<Perl::Critic::Utils::Perl> + L<PPIx::Utilities::Node> by Elliot Shank
<perl@galumph.com>, and L<PPIx::Utilities::Statement> by
Thomas R. Wyant, III <wyant@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005-2011 Imaginative Software Systems,
2007-2011 Elliot Shank, 2009-2010 Thomas R. Wyant, III, 2017 Dan Book.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

L<PPI>, L<Perl::Critic::Utils>, L<PPIx::Utilities>
