package Sort::Sub::changes_group_ala_perlancar;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-08'; # DATE
our $DIST = 'Sort-SubBundle-PERLANCAR'; # DIST
our $VERSION = '0.093'; # VERSION

sub meta {
    return {
        v => 1,
        summary => 'Sort changes group heading PERLANCAR-style',
    };
}

sub gen_sorter {
    require Sort::BySpec;

    my ($is_reverse, $is_ci) = @_;

    Sort::BySpec::cmp_by_spec(
        spec => [
            '',
            qr/break|incompatible/i,
            qr/remove|delete/i,
            qr/new|feature/i,
            qr/enhance/i,
            qr/bug|fix/i,
        ],
        reverse => $is_reverse,
    );
}

1;
# ABSTRACT: Sort changes group heading PERLANCAR-style

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::changes_group_ala_perlancar - Sort changes group heading PERLANCAR-style

=head1 VERSION

This document describes version 0.093 of Sort::Sub::changes_group_ala_perlancar (from Perl distribution Sort-SubBundle-PERLANCAR), released on 2024-01-08.

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$changes_group_ala_perlancar'; # use '$changes_group_ala_perlancar<i>' for case-insensitive sorting, '$changes_group_ala_perlancar<r>' for reverse sorting
 my @sorted = sort $changes_group_ala_perlancar ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'changes_group_ala_perlancar<ir>';
 my @sorted = sort {changes_group_ala_perlancar} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::changes_group_ala_perlancar;
 my $sorter = Sort::Sub::changes_group_ala_perlancar::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub changes_group_ala_perlancar
 % some-cmd | sortsub changes_group_ala_perlancar --ignore-case -r

=head1 DESCRIPTION

A Changes file can group its changes entries into groups with headings, e.g.:

 [ENHANCEMENTS]

 - blah blah

 - blah

 [BUG FIXES]

 - blah blah blah

I sort these group headings according to this principle: prioritize the items
that:

=over

=item * are more important;

=item * affect users the most;

=item * users would want to know first.

=back

Thus breaking or backward-incompatible changes are put first because they affect
existing users and in a significant way. Removed features are next, they are
also basically backward-incompatible changes.

Then come new features. After that, enhancements. Bug fixes currently come last
(actually bug fixes vary in importance but we currently do not categorize them
further into subgroups).

=for Pod::Coverage ^(gen_sorter|meta)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sort-SubBundle-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sort-SubBundle-PERLANCAR>.

=head1 SEE ALSO

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-SubBundle-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
