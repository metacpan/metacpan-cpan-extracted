package Number::Pad;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-01'; # DATE
our $DIST = 'Number-Pad'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use List::Util qw(max);

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       pad_numbers
               );

sub pad_numbers {
    # note: the same logic of this function is also in
    # Perinci::Result::Format::Lite. perhaps in the future that module will be
    # refactored to use us.

    # XXX we just want to turn off 'uninitialized' and 'negative repeat
    # count does nothing' from the operator x
    no warnings;

    require String::Pad;

    my ($numbers, $width, $which, $padchar, $truncate) = @_;

    $which //= 'l';

    # determine max widths
    my ($maxw_bd, $maxw_d, $maxw_ad); # before digit, digit, after d

    my (@w_bd, @w_d, @w_ad);
    for my $i (0..$#{$numbers}) {
        my $number = $numbers->[$i];
        my $width = length($number);
        if (!defined $number) {
            push @w_bd, 0;
            push @w_bd, 0;
            push @w_ad, 0;
        } elsif ($number =~ /\A([+-]?\d+)(\.?)(\d*)[%]?\z/) {
            # decimal notation number (with optional percent sign). TODO: allow
            # arbitraty units after number, e.g. ml, mcg, etc? but should we
            # align the unit too?
            push @w_bd, length($1);
            push @w_d , length($2);
            push @w_ad, length($3);
        } elsif ($number =~ /\A([+-]?\d+\.?\d*)([eE])([+-]?\d+)\z/) {
            # scientific notation number
            push @w_bd, length($1);
            push @w_d , length($2);
            push @w_ad, length($3);
        } elsif ($number =~ /\A([+-]?(?:Inf|NaN))\z/i) {
            push @w_bd, length($1);
            push @w_d , 1;
            push @w_ad, 0;
        } else {
            # not a number
            push @w_bd, length($number);
            push @w_bd, 0;
            push @w_ad, 0;
        }
    }
    my $maxw_bd = max(@w_bd);
    my $maxw_d  = max(@w_d);
    my $maxw_ad = max(@w_ad);

    # align the decimal point/"E" in the numbers first
    my @aligned_numbers;
    for my $number (@$numbers) {
        my ($bd, $d, $ad);
        if (($bd, $d, $ad) = $number =~ /\A([+-]?\d+)(\.?)(\d*)\z/) {
            push @aligned_numbers, join(
                '',
                (' ' x ($maxw_bd - length($bd))), $bd,
                $d , (' ' x ($maxw_d  - length($d ))),
                $ad, (' ' x ($maxw_ad - length($ad))),
            );
        } elsif (($bd, $d, $ad) = $number =~ /\A([+-]?\d+\.?\d*)([eE])([+-]?\d+)\z/) {
            push @aligned_numbers, join(
                '',
                (' ' x ($maxw_bd - length($bd))), $bd,
                $d , (' ' x ($maxw_d  - length($d ))),
                $ad, (' ' x ($maxw_ad - length($ad))),
            );
        } elsif (($bd, undef, undef) = $number =~ /\A([+-]?(?:Inf|NaN))\z/i) {
            push @aligned_numbers, join(
                '',
                (' ' x ($maxw_bd - length($bd))), $bd,
                '' , (' ' x ($maxw_d  - length($d ))),
                '', (' ' x ($maxw_ad - length($ad))),
            );
        } else {
            # not a number
            push @aligned_numbers, $number;
        }
    }

    # then pad with String::Pad
    String::Pad::pad(
        \@aligned_numbers,
        $width,
        $which,
        $padchar,
        $truncate,
    );
}

1;
# ABSTRACT: Pad numbers so the decimal point (or "E" if in exponential notation) align

__END__

=pod

=encoding UTF-8

=head1 NAME

Number::Pad - Pad numbers so the decimal point (or "E" if in exponential notation) align

=head1 VERSION

This document describes version 0.001 of Number::Pad (from Perl distribution Number-Pad), released on 2021-08-01.

=head1 SYNOPSIS

 use Number::Pad qw(pad_numbers);

 my $res = pad_numbers(
       ["1",
        "-20",
        "3.1",
        "-400.56",
        "5e1",
        "6.78e02",
        "-7.8e-10",
        "Inf",
        "NaN"],         # 1st arg: (required) the numbers
       20,              # 2nd arg: (optional) number of characters; if unspecified will just pad so all numbers fit
       'right',         # 3rd arg: (optional) alignment: l/left/r/right/c/center. default is l
       undef,           # 4th arg: (optional) pad character, default is space
       0,               # 5th arg: (optional) whether we should truncate if the length of widest number exceeds specified number of characters. default is false.
 );

Result:

 [ #12345678901234567890
   "             1      ",
   "           -20      ",
   "             3.1    ",
   "          -400.56   ",
   "             5e1    ",
   "             6.78e02",
   "            -7.8e-10",
   "           Inf      ",
   "           NaN      ",
 ]

=head1 FUNCTIONS

=head2 pad_numbers

Usage:

 $res = pad_numbers($text | \@numbers, $width [, $which [, $padchar=' ' [, $truncate=0] ] ] ); # => str or arrayref

Return an arrayref of numbers padded with C<$padchar> to C<$width> columns.

C<$width> can be undef or -1, in which case the width will be determined from
the widest number.

C<$which> is either "r" or "right" for padding on the right, "l" or "left" for
padding on the right (the default if not specified), or "c" or "center" or
"centre" for left+right padding to center the text. Note that "r" will mean
"left justified", while "l" will mean "right justified".

C<$padchar> is whitespace if not specified. It should be string having the width
of 1 column.

C<$truncate> is boolean. When set to 1, then text will be truncated when it is
longer than C<$width>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Number-Pad>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Number-Pad>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Number-Pad>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<String::Pad> has the same interface, but does not have the
decimal-point-aligning logic.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
