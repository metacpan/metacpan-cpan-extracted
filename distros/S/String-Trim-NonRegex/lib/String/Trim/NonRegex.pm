package String::Trim::NonRegex;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-23'; # DATE
our $DIST = 'String-Trim-NonRegex'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       ltrim
                       rtrim
                       trim
                       ltrim_lines
                       rtrim_lines
                       trim_lines
                       trim_blank_lines

                       ellipsis
               );

sub ltrim {
    my $str = shift;
    my $len = length $str;
    my $i = 0;
    while (1) {
        my $c = substr($str, $i, 1);
        last unless $c eq ' ' || $c eq "\t" || $c eq "\n";
        $i++;
        last if $i >= $len;
    }
    substr($str, $i);
}

sub rtrim {
    my $str = shift;
    my $i = length($str)-1;
    while (1) {
        my $c = substr($str, $i, 1);
        last unless $c eq ' ' || $c eq "\t" || $c eq "\n";
        $i--;
        last if $i < 0;
    }
    substr($str, 0, $i+1);
}

sub trim {
    my $str = shift;
    my $len = length $str;

    my $i = $len-1;
    while (1) {
        my $c = substr($str, $i, 1);
        last unless $c eq ' ' || $c eq "\t" || $c eq "\n";
        $i--;
        last if $i < 0;
    }

    my $j = 0;
    while (1) {
        my $c = substr($str, $j, 1);
        last unless $c eq ' ' || $c eq "\t" || $c eq "\n";
        $j++;
        last if $j >= $i;
    }
    substr($str, $j, $i-$j+1);
}

#sub ltrim_lines {
#    my $str = shift;
#    $str =~ s/^[ \t]+//mg; # XXX other unicode non-newline spaces
#    $str;
#}

#sub rtrim_lines {
#    my $str = shift;
#    $str =~ s/[ \t]+$//mg;
#    $str;
#}

#sub trim_lines {
#    my $str = shift;
#    $str =~ s/^[ \t]+//mg;
#    $str =~ s/[ \t]+$//mg;
#    $str;
#}

#sub trim_blank_lines {
#    local $_ = shift;
#    return $_ unless defined;
#    s/\A(?:\n\s*)+//;
#    s/(?:\n\s*){2,}\z/\n/;
#    $_;
#}

#sub ellipsis {
#    my ($str, $maxlen, $ellipsis) = @_;
#    $maxlen   //= 80;
#    $ellipsis //= "...";
#
#    if (length($str) <= $maxlen) {
#        return $str;
#    } else {
#        return substr($str, 0, $maxlen-length($ellipsis)) . $ellipsis;
#    }
#}

1;
# ABSTRACT: String trimming functions that do not use regex

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Trim::NonRegex - String trimming functions that do not use regex

=head1 VERSION

This document describes version 0.002 of String::Trim::NonRegex (from Perl distribution String-Trim-NonRegex), released on 2021-06-23.

=head1 DESCRIPTION

For testing/benchmarking purpose only. In general, regex is faster in this case
(see benchmark in L</SEE ALSO>).

=head1 FUNCTIONS

=head2 ltrim

Usage:

 my $trimmed = ltrim($str);

Trim whitespaces (including newlines) at the beginning of string.

=head2 rtrim

Usage:

 my $trimmed = rtrim($str);

Trim whitespaces (including newlines) at the end of string.

=head2 trim

Usage:

 my $trimmed = trim($str);

ltrim + rtrim.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-Trim-NonRegex>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-Trim-NonRegex>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-Trim-NonRegex>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<String::Trim>, L<Text::Trim>, L<String::Strip>, L<String::Util>,
L<String::Trim::More>, L<Text::Minify::XS>.

Benchmark: L<Bencher::Scenario::StringFunctions::Trim>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
