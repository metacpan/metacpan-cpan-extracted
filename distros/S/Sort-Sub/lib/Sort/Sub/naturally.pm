package Sort::Sub::naturally;

our $DATE = '2016-12-18'; # DATE
our $VERSION = '0.10'; # VERSION

use 5.010;
use strict;
use warnings;

sub gen_sorter {
    my ($is_reverse, $is_ci) = @_;

    my $re = qr/([+-]?\d+|\D+)/;

    sub {
        no strict 'refs';

        my $caller = caller();
        my $a = @_ ? $_[0] : ${"$caller\::a"};
        my $b = @_ ? $_[1] : ${"$caller\::b"};

        my @a_parts = +($is_ci ? lc($a) : $a) =~ /$re/g;
        my @b_parts = +($is_ci ? lc($b) : $b) =~ /$re/g;

        #use DD; dd \@a_parts;

        my $i = 0;
        my $cmp = 0;
        for (@a_parts) {
            last if $i >= @b_parts;
            #say "D:$a_parts[$i] <=> $b_parts[$i]";
            if ($a_parts[$i] =~ /\D/ || $b_parts[$i] =~ /\D/) {
                $cmp = $a_parts[$i] cmp $b_parts[$i];
            } else {
                $cmp = $a_parts[$i] <=> $b_parts[$i];
            }
            last if $cmp;
            $i++;
        }
        $is_reverse ? -1*$cmp : $cmp;
    };
}

1;
# ABSTRACT: Sort naturally

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::naturally - Sort naturally

=head1 VERSION

This document describes version 0.10 of Sort::Sub::naturally (from Perl distribution Sort-Sub), released on 2016-12-18.

=for Pod::Coverage ^(gen_sorter)$

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

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
