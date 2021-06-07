package Sort::Sub::pod_section_ala_perlancar;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-04'; # DATE
our $DIST = 'Sort-SubBundle-PERLANCAR'; # DIST
our $VERSION = '0.088'; # VERSION

use 5.010001;
use strict;
use warnings;

our $SORT_SPEC = [
    # ORIGINAL XXX are for forked modules, where the ORIGINAL XXX sections are
    # the sections from the original (forked) module, and the XXX sections are
    # for the new module (the fork).

    # preamble
    'NAME',
    'SPECIFICATION VERSION',
    'VERSION',
    'DEPRECATION NOTICE',
    'SYNOPSIS', 'ORIGINAL SYNOPSIS',

    # main content
    'DESCRIPTION', 'ORIGINAL DESCRIPTION',

    # Acme::CPANModules::*
    "ACME::CPANMODULES ENTRIES",
    "ACME::CPANMODULES FEATURE COMPARISON MATRIX",

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
    'FAQ', 'ORIGINAL FAQ',
    'FAQS', 'ORIGINAL FAQS',

    # links/pointers (CLI)
    'CONFIGURATION FILE',
    'CONFIGURATION FILES',
    'ENVIRONMENT',
    'ENVIRONMENT VARIABLES',
    'FILES',

    # todos
    'TODO', 'ORIGINAL TODO',
    'TODOS', 'ORIGINAL TODOS',

    # links/pointers/extra information
    'HISTORY', 'ORIGINAL HISTORY',
    'HOMEPAGE', 'ORIGINAL HOMEPAGE',
    'SOURCE', 'ORIGINAL SOURCE',
    'BUGS', 'ORIGINAL BUGS',
    'GOTCHAS',
    'CAVEATS',
    'SEE ALSO', 'ORIGINAL SEE ALSO',

    # credits
    'CREDITS', 'ORIGINAL CREDITS',
    'THANKS', 'ORIGINAL THANKS',

    # author, contributors, & copyright
    qr/^AUTHORS?/,
    qr/^ORIGINAL AUTHORS?/,

    'CONTRIBUTORS',

    'COPYRIGHT AND LICENSE', 'ORIGINAL COPYRIGHT AND LICENSE',
    'COPYRIGHT', 'ORIGINAL COPYRIGHT',
    'LICENSE', 'ORIGINAL LICENSE',
];

sub meta {
    return {
        v => 1,
        summary => 'Sort POD sections (headings) PERLANCAR-style',
    };
}

sub gen_sorter {
    require Sort::BySpec;

    my ($is_reverse, $is_ci) = @_;

    Sort::BySpec::cmp_by_spec(
        spec => $SORT_SPEC,
        reverse => $is_reverse,
    );
}

1;
# ABSTRACT: Sort POD sections (headings) PERLANCAR-style

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::pod_section_ala_perlancar - Sort POD sections (headings) PERLANCAR-style

=head1 VERSION

This document describes version 0.088 of Sort::Sub::pod_section_ala_perlancar (from Perl distribution Sort-SubBundle-PERLANCAR), released on 2021-06-04.

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$pod_section_ala_perlancar'; # use '$pod_section_ala_perlancar<i>' for case-insensitive sorting, '$pod_section_ala_perlancar<r>' for reverse sorting
 my @sorted = sort $pod_section_ala_perlancar ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'pod_section_ala_perlancar<ir>';
 my @sorted = sort {pod_section_ala_perlancar} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::pod_section_ala_perlancar;
 my $sorter = Sort::Sub::pod_section_ala_perlancar::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub pod_section_ala_perlancar
 % some-cmd | sortsub pod_section_ala_perlancar --ignore-case -r

=head1 DESCRIPTION

POD sections in a Perl documentation are usually ordered according to a certain
convention, e.g.:

 NAME
 VERSION
 SYNOPSIS
 DESCRIPTION
 ...

I include this convention plus some more for my specific POD sections.

=for Pod::Coverage ^(gen_sorter|meta)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sort-SubBundle-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sort-SubBundle-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-SubBundle-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Pod::Weaver::Plugin::PERLANCAR::SortSections>, which uses the sort
specification in this module, to actually sort POD sections in POD documents
during dzil build.

L<Sort::Sub>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
