package Sort::Sub::pod_section_ala_perlancar;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-17'; # DATE
our $DIST = 'Sort-SubBundle-PERLANCAR'; # DIST
our $VERSION = '0.092'; # VERSION

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


    # from bsd
    'IMPLEMENTATION NOTES',


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


    # exit status, diagnostics, errors. from bsd
    'EXIT STATUS',
    'DIAGNOSTICS',
    # RETURN VALUE # for syscall
    # ERRORS # for syscall


    # examples, from bsd
    'EXAMPLES',


    # todos
    'TODO', 'ORIGINAL TODO',
    'TODOS', 'ORIGINAL TODOS',


    # links
    'HOMEPAGE', 'ORIGINAL HOMEPAGE',
    'SOURCE', 'ORIGINAL SOURCE',
    'SEE ALSO', 'ORIGINAL SEE ALSO',


    # standards, from bsd
    'STANDARDS',


    # history
    'HISTORY', 'ORIGINAL HISTORY',


    # credits, authors, contributors, & copyright
    'CREDITS', 'ORIGINAL CREDITS',
    'THANKS', 'ORIGINAL THANKS',

    qr/^AUTHORS?/,
    qr/^ORIGINAL AUTHORS?/,

    'CONTRIBUTOR', 'CONTRIBUTORS',

    'CONTRIBUTING',

    'COPYRIGHT AND LICENSE', 'ORIGINAL COPYRIGHT AND LICENSE',
    'COPYRIGHT & LICENSE', 'ORIGINAL COPYRIGHT & LICENSE',
    'COPYRIGHT', 'ORIGINAL COPYRIGHT',
    'LICENSE', 'ORIGINAL LICENSE',


    # bugs/caveats
    'BUGS', 'ORIGINAL BUGS',
    'GOTCHAS',
    'CAVEATS',
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

This document describes version 0.092 of Sort::Sub::pod_section_ala_perlancar (from Perl distribution Sort-SubBundle-PERLANCAR), released on 2021-10-17.

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

=head1 SEE ALSO

L<Pod::Weaver::Plugin::PERLANCAR::SortSections>, which uses the sort
specification in this module, to actually sort POD sections in POD documents
during dzil build.

L<Sort::Sub>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-SubBundle-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
