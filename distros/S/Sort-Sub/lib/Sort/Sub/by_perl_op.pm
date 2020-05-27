package Sort::Sub::by_perl_op;

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
        summary => 'Sort by Perl operator',
        args => {
            op => {
                schema => ['str*', in=>['cmp', '<=>']],
                req => 1,
            },
        },
    };
}
sub gen_sorter {
    my ($is_reverse, $is_ci, $args) = @_;

    my $op = $args->{op};
    die "Please supply sorter argument 'op'"
        unless defined $op;

    my $code_str = "sub { \$_[0] $op \$_[1] }";
    my $code_cmp = eval $code_str;
    die "Can't compile $code_str: $@" if $@;

    sub {
        no strict 'refs';

        my $caller = caller();
        my $a = @_ ? $_[0] : ${"$caller\::a"};
        my $b = @_ ? $_[1] : ${"$caller\::b"};

        my $cmp = $code_cmp->($a, $b);
        $is_reverse ? -1*$cmp : $cmp;
    };
}

1;
# ABSTRACT: Sort by Perl operator

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::by_perl_op - Sort by Perl operator

=head1 VERSION

This document describes version 0.120 of Sort::Sub::by_perl_op (from Perl distribution Sort-Sub), released on 2020-05-25.

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$by_perl_op'; # use '$by_perl_op<i>' for case-insensitive sorting, '$by_perl_op<r>' for reverse sorting
 my @sorted = sort $by_perl_op ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'by_perl_op<ir>';
 my @sorted = sort {by_perl_op} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::by_perl_op;
 my $sorter = Sort::Sub::by_perl_op::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub by_perl_op
 % some-cmd | sortsub by_perl_op --ignore-case -r

=head1 DESCRIPTION

This:

 use Sort::Sub '$by_perl_op', {op=>'<=>'};
 my @sorted = sort $by_perl_op @data;

is equivalent to:

 my @sorted = sort { $a <=> $b } @data;

Case-sensitivity flag C<i> is not relevant.

=for Pod::Coverage ^(gen_sorter|meta)$

=head1 SORT ARGUMENTS

C<*> marks required arguments.

=head2 op*

str.

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
