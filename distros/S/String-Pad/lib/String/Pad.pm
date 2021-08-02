package String::Pad;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-01'; # DATE
our $DIST = 'String-Pad'; # DIST
our $VERSION = '0.021'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       pad
               );

sub pad {
    my ($text0, $width, $which, $padchar, $is_trunc) = @_;
    if ($which) {
        $which = substr($which, 0, 1);
    } else {
        $which = "r";
    }
    $padchar //= " ";

    my $texts = ref $text0 eq 'ARRAY' ? [@$text0] : [$text0];

    if (!defined($width) || $width < 0) {
        my $longest = 0;
        for (@$texts) {
            my $len = length($_);
            $longest = $len if $longest < $len;
        }
        $width = $longest;
    }

    for my $text (@$texts) {
        my $w = length($text);
        if ($is_trunc && $w > $width) {
            $text = substr($text, 0, $width, 1);
            $w = $width;
        } else {
            if ($which eq 'l') {
                no warnings; # negative repeat count
                $text = ($padchar x ($width-$w)) . $text;
            } elsif ($which eq 'c') {
                my $n = int(($width-$w)/2);
                $text = ($padchar x $n) . $text . ($padchar x ($width-$w-$n));
            } else {
                no warnings; # negative repeat count
                $text .= ($padchar x ($width-$w));
            }
        }
    } # for $text

    ref $text0 eq 'ARRAY' ? $texts : $texts->[0];
}

1;
# ABSTRACT: String padding routines

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Pad - String padding routines

=head1 VERSION

This document describes version 0.021 of String::Pad (from Perl distribution String-Pad), released on 2021-08-01.

=head1 SYNOPSIS

 use String::Pad qw(pad);

 my $res;

 # pad a single string
 $res = pad("foo", 5);           # => "foo  "  # default $which is 'right' or 'r'
 $res = pad("foo", 5, "left");   # => "  foo"  # left padding, which means to be 'right-justified'
 $res = pad("foo", 5, "l");      # => "  foo"  # 'l' is same thing as 'left'
 $res = pad("foo", 5, "c");      # => " foo "  # 'center' ('c') padding
 $res = pad("foo", 5, "c", "x"); # => "xfoox"  # pad with a custom character
 $res = pad("foo", 5, "c", "x"); # => "xfoox"  # pad with a custom character

 $res = pad("foobar", 5, 'r', undef, 'truncate'); # => "fooba"

 # pad multiple strings

=head1 FUNCTIONS

=head2 pad

Usage:

 $res = pad($text | \@texts, $width [, $which [, $padchar=' ' [, $truncate=0] ] ] ); # => str or arrayref

Return C<$text> padded with C<$padchar> to C<$width> columns. Can accept
multiple texts (C<\@texts>); in which case will return a new arrayref of padded
texts.

C<$width> can be undef or -1 if you supply multiple texts, in which case the
width will be determined from the longest text.

C<$which> is either "r" or "right" for padding on the right (the default if not
specified), "l" or "left" for padding on the right, or "c" or "center" or
"centre" for left+right padding to center the text. Note that "r" will mean
"left justified", while "l" will mean "right justified".

C<$padchar> is whitespace if not specified. It should be string having the width
of 1 column.

C<$truncate> is boolean. When set to 1, then text will be truncated when it is
longer than C<$width>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-Pad>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-Pad>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-Pad>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Other string padding modules: L<Text::Padding>, L<Text::WideChar::Util> (for
strings that contain wide Unicode characters), L<Text::ANSI::Util> (for strings
that contain ANSI color codes), L<Text::ANSIWide::Util> (for strings that
contain both ANSI color codes and wide Unicode characters).

Other alignment modules: L<Number::Pad> (for padding numbers so that the decimal
points align).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2018, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
