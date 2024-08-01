package Sort::Sub::by_perl_function;

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
        summary => 'Sort by Perl function',
        args => {
            function => {
                schema => 'perl::funcname*',
                req => 1,
            },
            numeric => {
                summary => "Compare using Perl's <=> instead of cmp",
                schema => 'bool*',
                default => 0,
            },
        },
    };
}
sub gen_sorter {
    my ($is_reverse, $is_ci, $args) = @_;

    my $function = $args->{function};
    die "Please supply sorter argument 'function'"
        unless defined $function;

    if ($function =~ /(.+)::(.+)/) {
        # qualified with a package name, load associated module
        my $mod = $1;
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        require $mod_pm;
    }

    my $code_str = "sub { $function\(\$_[0]) }";
    my $code_call_func = eval $code_str; ## no critic: BuiltinFunctions::ProhibitStringyEval
    die "Can't compile $code_str: $@" if $@;

    sub {
        no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

        my $caller = caller();
        my $a = @_ ? $_[0] : ${"$caller\::a"};
        my $b = @_ ? $_[1] : ${"$caller\::b"};

        my $res_a = $code_call_func->($a);
        my $res_b = $code_call_func->($b);

        my $cmp = $args->{numeric} ? $res_a <=> $res_b :
            $is_ci ? lc($res_a) cmp lc($res_b) : $res_a cmp $res_b;
        $is_reverse ? -1*$cmp : $cmp;
    };
}

1;
# ABSTRACT: Sort by Perl function

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::by_perl_function - Sort by Perl function

=head1 VERSION

This document describes version 0.121 of Sort::Sub::by_perl_function (from Perl distribution Sort-Sub), released on 2024-07-17.

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$by_perl_function'; # use '$by_perl_function<i>' for case-insensitive sorting, '$by_perl_function<r>' for reverse sorting
 my @sorted = sort $by_perl_function ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'by_perl_function<ir>';
 my @sorted = sort {by_perl_function} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::by_perl_function;
 my $sorter = Sort::Sub::by_perl_function::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub by_perl_function
 % some-cmd | sortsub by_perl_function --ignore-case -r

=head1 DESCRIPTION

This:

 use Sort::Sub '$by_perl_function', {function=>'length'};
 my @sorted = sort $by_perl_function @data;

is equivalent to:

 my @sorted = sort { length($a) <=> length($b) } @data;

=for Pod::Coverage ^(gen_sorter|meta)$

=head1 SORT ARGUMENTS

C<*> marks required arguments.

=head2 function*

perl::funcname.

=head2 numeric

bool.

Compare using Perl's <=E<gt> instead of cmp.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sort-Sub>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sort-Sub>.

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

This software is copyright (c) 2024, 2020, 2019, 2018, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-Sub>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
