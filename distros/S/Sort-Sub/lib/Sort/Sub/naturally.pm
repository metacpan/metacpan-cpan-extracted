package Sort::Sub::naturally;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-15'; # DATE
our $DIST = 'Sort-Sub'; # DIST
our $VERSION = '0.116'; # VERSION

use 5.010;
use strict;
use warnings;

sub meta {
    return {
        v => 1,
        summary => 'Sort naturally (by number or string parts)',
    };
}

sub gen_sorter {
    require Sort::Naturally;

    my ($is_reverse, $is_ci) = @_;

    sub {
        no strict 'refs';

        my $caller = caller();
        my $a = @_ ? $_[0] : ${"$caller\::a"};
        my $b = @_ ? $_[1] : ${"$caller\::b"};

        if ($is_reverse) {
            Sort::Naturally::ncmp($b, $a);
        } else {
            Sort::Naturally::ncmp($a, $b);
        }
    };
}

1;
# ABSTRACT: Sort naturally (by number or string parts)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::naturally - Sort naturally (by number or string parts)

=head1 VERSION

This document describes version 0.116 of Sort::Sub::naturally (from Perl distribution Sort-Sub), released on 2019-12-15.

=for Pod::Coverage ^(gen_sorter|meta)$

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$naturally'; # use '$naturally<i>' for case-insensitive sorting, '$naturally<r>' for reverse sorting
 my @sorted = sort $naturally ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'naturally<ir>';
 my @sorted = sort {naturally} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::naturally;
 my $sorter = Sort::Sub::naturally::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub naturally
 % some-cmd | sortsub naturally --ignore-case -r

=head1 DESCRIPTION

This module can generate sort subroutine. It is meant to be used via L<Sort::Sub>, although you can also use it directly via C<gen_sorter()>.

=head1 NOTES

Uses L<Sort::Naturally>'s C<ncmp> as the backend. Always sorts
case-insensitively.

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

L<Sort::Naturally>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
