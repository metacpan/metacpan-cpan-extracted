package Sort::Sub::by_count;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-28'; # DATE
our $DIST = 'Sort-Sub'; # DIST
our $VERSION = '0.118'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    return {
        v => 1,
        summary => 'Sort by number of occurrences of pattern in string',
    };
}

sub _pattern_to_re {
    my $args = shift;

    my $re;
    my $pattern = $args->{pattern}; defined $pattern or die "Please specify pattern";
    if ($args->{fixed_string}) {
        $re = $args->{ignore_case} ? qr/\Q$pattern/i : qr/\Q$pattern/;
    } else {
        eval { $re = $args->{ignore_case} ? qr/$pattern/i : qr/$pattern/ };
        die "Invalid pattern: $@" if $@;
    }

    $re;
}

sub gen_sorter {
    my ($is_reverse, $is_ci, $args) = @_;

    die __PACKAGE__.": Please specify 'pattern'" unless defined $args->{pattern};

    my $re = _pattern_to_re($args);

    sub {
        no strict 'refs';

        my $caller = caller();
        my $a = @_ ? $_[0] : ${"$caller\::a"};
        my $b = @_ ? $_[1] : ${"$caller\::b"};

        my $count_a = 0; $count_a++ while $a =~ /$re/g;
        my $count_b = 0; $count_b++ while $b =~ /$re/g;

        ($is_reverse ? -1 : 1)*(
            ($count_a <=> $count_b) ||
                ($is_ci ? lc($a) cmp lc($b) : $a cmp $b)
            );
    };
}

1;
# ABSTRACT: Sort by number of occurrences of pattern in string

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::by_count - Sort by number of occurrences of pattern in string

=head1 VERSION

This document describes version 0.118 of Sort::Sub::by_count (from Perl distribution Sort-Sub), released on 2020-02-28.

=for Pod::Coverage ^(gen_sorter|meta)$

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$by_count'; # use '$by_count<i>' for case-insensitive sorting, '$by_count<r>' for reverse sorting
 my @sorted = sort $by_count ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'by_count<ir>';
 my @sorted = sort {by_count} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::by_count;
 my $sorter = Sort::Sub::by_count::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub by_count
 % some-cmd | sortsub by_count --ignore-case -r

=head1 DESCRIPTION

This module can generate sort subroutine. It is meant to be used via L<Sort::Sub>, although you can also use it directly via C<gen_sorter()>.

=head1 ARGUMENTS

=head2 pattern

Regex pattern or string.

=head2 fixed_string

Bool. If true will assume L</pattern> is a fixed string instead of regular
expression.

=head2 ignore_case

Bool.

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

This software is copyright (c) 2020, 2019, 2018, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
