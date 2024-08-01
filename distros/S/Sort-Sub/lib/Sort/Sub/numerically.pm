package Sort::Sub::numerically;

use 5.010;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-07-17'; # DATE
our $DIST = 'Sort-Sub'; # DIST
our $VERSION = '0.121'; # VERSION

sub meta {
    return {
        v => 1,
        summary => 'Sort numerically',
    };
}

sub gen_sorter {
    my ($is_reverse, $is_ci) = @_;

    sub {
        no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

        my $caller = caller();
        my $a = @_ ? $_[0] : ${"$caller\::a"};
        my $b = @_ ? $_[1] : ${"$caller\::b"};

        my $cmp = $a <=> $b;
        $is_reverse ? -1*$cmp : $cmp;
    };
}

1;
# ABSTRACT: Sort numerically

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::numerically - Sort numerically

=head1 VERSION

This document describes version 0.121 of Sort::Sub::numerically (from Perl distribution Sort-Sub), released on 2024-07-17.

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$numerically'; # use '$numerically<i>' for case-insensitive sorting, '$numerically<r>' for reverse sorting
 my @sorted = sort $numerically ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'numerically<ir>';
 my @sorted = sort {numerically} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::numerically;
 my $sorter = Sort::Sub::numerically::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub numerically
 % some-cmd | sortsub numerically --ignore-case -r

=head1 DESCRIPTION

This is equivalent to:

 sub { $a <=> $b }

=for Pod::Coverage ^(gen_sorter|meta)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sort-Sub>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sort-Sub>.

=head1 SEE ALSO

L<Sort::Sub::numerically_no_warning>

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

This software is copyright (c) 2024, 2020, 2019, 2018, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-Sub>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
