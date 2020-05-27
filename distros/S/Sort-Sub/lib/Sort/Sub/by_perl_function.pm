package Sort::Sub::by_perl_function;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-25'; # DATE
our $DIST = 'Sort-Sub'; # DIST
our $VERSION = '0.120'; # VERSION

use 5.010;
use strict;
use warnings;

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
    my $code_call_func = eval $code_str;
    die "Can't compile $code_str: $@" if $@;

    sub {
        no strict 'refs';

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

This document describes version 0.120 of Sort::Sub::by_perl_function (from Perl distribution Sort-Sub), released on 2020-05-25.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-Sub>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sort::Sub>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
