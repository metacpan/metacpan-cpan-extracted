package Sort::Sub::by_several;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-17'; # DATE
our $DIST = 'Sort-Sub-by_several'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    return {
        v => 1,
        summary => 'Sort by one or more sorters',
        args => {
            first  => {schema=>'sortsub::spec*', req=>1, pos=>0},
            second => {schema=>'sortsub::spec*', req=>0, pos=>1},
            third  => {schema=>'sortsub::spec*', req=>0, pos=>2},
            fourth => {schema=>'sortsub::spec*', req=>0, pos=>3},
            fifth  => {schema=>'sortsub::spec*', req=>0, pos=>4},
        },
        args_rels => {
            'dep_any&' => [
                [second => ['first']],
                [third  => ['second']],
                [fourth => ['third']],
                [fifth  => ['fourth']],
            ],
        },
    };
}

sub gen_sorter {
    require Sort::Sub;
    my ($is_reverse, $is_ci, $args) = @_;

    my $sorter1 = defined $args->{first}  ? Sort::Sub::get_sorter($args->{first} ) : undef;
    my $sorter2 = defined $args->{second} ? Sort::Sub::get_sorter($args->{second}) : undef;
    my $sorter3 = defined $args->{third}  ? Sort::Sub::get_sorter($args->{third} ) : undef;
    my $sorter4 = defined $args->{fourth} ? Sort::Sub::get_sorter($args->{fourth}) : undef;
    my $sorter5 = defined $args->{fifth}  ? Sort::Sub::get_sorter($args->{fifth} ) : undef;

    sub {
        no strict 'refs';

        my $caller = caller();
        my $a = @_ ? $_[0] : ${"$caller\::a"};
        my $b = @_ ? $_[1] : ${"$caller\::b"};

        my $cmp;

        {
            $cmp = $sorter1->($a, $b); last if $cmp; last unless $sorter2;
            $cmp = $sorter2->($a, $b); last if $cmp; last unless $sorter3;
            $cmp = $sorter3->($a, $b); last if $cmp; last unless $sorter4;
            $cmp = $sorter4->($a, $b); last if $cmp; last unless $sorter5;
            $cmp = $sorter5->($a, $b);
        }

        $is_reverse ? -1*$cmp : $cmp;
    };
}

1;
# ABSTRACT: Sort by one or more sorters

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::by_several - Sort by one or more sorters

=head1 VERSION

This document describes version 0.001 of Sort::Sub::by_several (from Perl distribution Sort-Sub-by_several), released on 2019-12-17.

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$by_several'; # use '$by_several<i>' for case-insensitive sorting, '$by_several<r>' for reverse sorting
 my @sorted = sort $by_several ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'by_several<ir>';
 my @sorted = sort {by_several} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::by_several;
 my $sorter = Sort::Sub::by_several::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub by_several
 % some-cmd | sortsub by_several --ignore-case -r

=head1 DESCRIPTION

=for Pod::Coverage ^(gen_sorter|meta)$

=head1 SORT ARGUMENTS

C<*> marks required arguments.

=head2 fifth

sortsub::spec.

=head2 first*

sortsub::spec.

=head2 fourth

sortsub::spec.

=head2 second

sortsub::spec.

=head2 third

sortsub::spec.

=head1 ENVIRONMENT

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sort-Sub-by_several>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sort-Sub-by_several>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-Sub-by_several>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sort::Sub>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
