package Sort::Sub::by_example;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-01-12'; # DATE
our $DIST = 'Sort-Sub-by_example'; # DIST
our $VERSION = '0.005'; # VERSION

sub meta {
    return {
        v => 1,
        summary => 'Sort by example',
        args => {
            example => {
                summary => 'Either an arrayref or comma-separated string',
                schema => ['any' => {of=>['array*', 'str*']}],
                req => 1,
                pos => 0,
            },
        },
    };
}

sub gen_sorter {
    require Sort::ByExample;

    my ($is_reverse, $is_ci, $args) = @_;

    my $example = ref $args->{example} eq 'ARRAY' ?
        [@{$args->{example}}] : [split /\s*,\s*/, $args->{example}];
    $example = [map {lc} @$example] if $is_ci;
    $example = [reverse @$example] if $is_reverse;

    log_trace "example=%s", $example;

    my $cmp = Sort::ByExample->cmp($example);
    #use Data::Dmp; dd $cmp
}

1;
# ABSTRACT: Sort by example

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::by_example - Sort by example

=head1 VERSION

This document describes version 0.005 of Sort::Sub::by_example (from Perl distribution Sort-Sub-by_example), released on 2025-01-12.

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$by_example'; # use '$by_example<i>' for case-insensitive sorting, '$by_example<r>' for reverse sorting
 my @sorted = sort $by_example ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'by_example<ir>';
 my @sorted = sort {by_example} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::by_example;
 my $sorter = Sort::Sub::by_example::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub by_example
 % some-cmd | sortsub by_example --ignore-case -r

=head1 DESCRIPTION

=for Pod::Coverage ^(gen_sorter|meta)$

=head1 SORT ARGUMENTS

C<*> marks required arguments.

=head2 example*

any.

Either an arrayref or comma-separated string.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sort-Sub-by_example>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sort-Sub-by_example>.

=head1 SEE ALSO

L<Sort::ByExample>

L<Sort::Sub::by_sortexample>

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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-Sub-by_example>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
