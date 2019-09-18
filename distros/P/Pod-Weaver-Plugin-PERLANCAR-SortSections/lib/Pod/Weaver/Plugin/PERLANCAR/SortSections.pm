package Pod::Weaver::Plugin::PERLANCAR::SortSections;

our $DATE = '2019-09-17'; # DATE
our $VERSION = '0.07'; # VERSION

use 5.010001;
use Moose;

with 'Pod::Weaver::Role::Finalizer';
with 'Pod::Weaver::Role::SortSections';

use namespace::autoclean;

sub finalize_document {
    my ($self, $document, $input) = @_;

    $self->sort_sections(
        $document,
        [
            # preamble
            'NAME',
            'SPECIFICATION VERSION',
            'VERSION',
            'SYNOPSIS',

            # main content
            'DESCRIPTION',

            # Bencher::Scenario::*
            'BENCHMARKED MODULES',
            'BENCHMARK PARTICIPANTS',
            'BENCHMARK DATASETS',
            'SAMPLE BENCHMARK RESULTS',

            # everything else that are uncategorized go here
            sub { 1 },

            # reference section
            'FUNCTIONS',
            'ATTRIBUTES',
            'METHODS',

            # reference section (CLI)
            'SUBCOMMANDS',
            'OPTIONS',

            # other content (CLI)
            'COMPLETION',

            # FAQ (after all content & references)
            'FAQ',
            'FAQS',

            # links/pointers (CLI)
            'CONFIGURATION FILE',
            'CONFIGURATION FILES',
            'ENVIRONMENT',
            'ENVIRONMENT VARIABLES',
            'FILES',

            # todos
            'TODO',
            'TODOS',

            # links/pointers/extra information
            'HISTORY',
            'HOMEPAGE',
            'SOURCE',
            qr/^.+'S BUGS$/i, # in a forked module, i put the original module's BUGS in ORIGMODULE'S BUGS
            'BUGS',
            'SEE ALSO',

            # author & copyright
            qr/^.+'S AUTHORS?$/i, # in a forked module, i put the original module's AUTHOR in ORIGMODULE'S AUTHOR
            qr/^AUTHORS?/,
            qr/^.+'S COPYRIGHT( AND LICENSE)?$/i, # in a forked module, i put the original module's COPYRIGHT in ORIGMODULE'S COPYRIGHT
            'COPYRIGHT AND LICENSE',
            'COPYRIGHT',
        ],
    );
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Sort POD sections like PERLANCAR

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::PERLANCAR::SortSections - Sort POD sections like PERLANCAR

=head1 VERSION

This document describes version 0.07 of Pod::Weaver::Plugin::PERLANCAR::SortSections (from Perl distribution Pod-Weaver-Plugin-PERLANCAR-SortSections), released on 2019-09-17.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-PERLANCAR::SortSections]

=for Pod::Coverage ^(finalize_document)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-PERLANCAR-SortSections>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-PERLANCAR-SortSections>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-PERLANCAR-SortSections>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Pod::Weaver::Plugin::SortSections>, the generic/configurable version

L<Pod::Weaver::Role::SortSections>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
