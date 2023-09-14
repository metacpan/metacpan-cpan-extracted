package Sort::Sub::by_spec;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-06'; # DATE
our $DIST = 'Sort-Sub-by_spec'; # DIST
our $VERSION = '0.002'; # VERSION

sub meta {
    return {
        v => 1,
        summary => 'Sort by spec',
        description => <<'MARKDOWN',

This sorter allows you to sort "by spec". Sorting by spec is an advanced form of
sorting by example. In addition to specifying strings of examples, you can also
specify regexes or Perl sorter codes. Thus the spec is an arrayref of
strings|regexes|coderefs. For more details, see the sorting backend module
<pm:Sort::BySpec>.

On the command-line, you can specify a coderef in the form of:

    sub { ... }

which returns the spec. For example:

    sub { [qr/[13579]\z/, 4, 2, 42, sub {$_[1] <=> $_[0]}] }

MARKDOWN
        args => {
            spec => {
                summary => "Either an array of str|re|code's or a code that returns the former",
                schema => ['any' => {of=>[
                    ['array*', of=>'str_or_re_or_code*'],
                    ['code*'],
                ],}],
                req => 1,
                pos => 0,
            },
        },
    };
}

sub gen_sorter {
    require Sort::BySpec;

    my ($is_reverse, $is_ci, $args) = @_;

    die "Sorting case-insensitively not supported yet" if $is_ci;

    my $spec = $args->{spec};
    ## no critic: BuiltinFunctions::ProhibitStringyEval
    if (!ref $spec) { $spec = eval $spec; die if $@ }
    $spec = $spec->() if ref $spec eq 'CODE';

    Sort::BySpec::cmp_by_spec(spec=>$spec, reverse=>$is_reverse);
}

1;
# ABSTRACT: Sort by spec

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::by_spec - Sort by spec

=head1 VERSION

This document describes version 0.002 of Sort::Sub::by_spec (from Perl distribution Sort-Sub-by_spec), released on 2023-09-06.

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$by_spec'; # use '$by_spec<i>' for case-insensitive sorting, '$by_spec<r>' for reverse sorting
 my @sorted = sort $by_spec ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'by_spec<ir>';
 my @sorted = sort {by_spec} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::by_spec;
 my $sorter = Sort::Sub::by_spec::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub by_spec
 % some-cmd | sortsub by_spec --ignore-case -r

=head1 DESCRIPTION

=for Pod::Coverage ^(gen_sorter|meta)$

=head1 SORT ARGUMENTS

C<*> marks required arguments.

=head2 spec*

any.

Either an array of strE<verbar>reE<verbar>code's or a code that returns the former.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sort-Sub-by_spec>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sort-Sub-by_spec>.

=head1 SEE ALSO

L<Sort::BySpec>

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-Sub-by_spec>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
