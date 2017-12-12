package Number::Format::BigFloat;

our $DATE = '2017-12-09'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Math::BigFloat;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       format_number
               );

sub format_number {
    my ($num, $opts) = @_;
    $opts //= {};

    $opts->{thousands_sep}  //= ',';
    $opts->{decimal_point}  //= '.';
    $opts->{decimal_digits} //= 2;

    my $str = Math::BigFloat->new($num)->round(0, -$opts->{decimal_digits});
    my ($sign, $int, $decpoint, $frac) =
        $str =~ /\A(-?)([0-9]+)(\.?)([0-9]*)\z/
        or return $num;

    $int =~ s/(?<=[0-9])(?=([0-9]{3})+(?![0-9]))/$opts->{thousands_sep}/g
        if length $opts->{thousands_sep};

    $decpoint = $opts->{decimal_point}
        if length $decpoint;

    "$sign$int$decpoint$frac";
}

1;
# ABSTRACT: Format Math::BigFloat number

__END__

=pod

=encoding UTF-8

=head1 NAME

Number::Format::BigFloat - Format Math::BigFloat number

=head1 VERSION

This document describes version 0.001 of Number::Format::BigFloat (from Perl distribution Number-Format-BigFloat), released on 2017-12-09.

=head1 SYNOPSIS

 use Number::Format::BigFloat qw(format_number);

 format_number(1.1);                                             # => "1.10"
 format_number(1.1, {decimal_digits=>20});                       # => "1.10000000000000000000"
 format_number("1.123456789012345678901", {decimal_digits=>20}); # => "1.12345678901234567890"

=head1 FUNCTIONS

None exported by default but all of them exportable.

=head2 format_number($num, \%opts) => STR

Format C<$num>. C<$num> will be converted to L<Math::BigFloat> instance first.
Will return C<$num> as-is if C<$num> is not expressable as decimal notation
number.

Known options:

=over

=item * thousands_sep => str (default: ",")

=item * decimal_point => str (default: ".")

=item * decimal_digits => int (default: 2)

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Number-Format-BigFloat>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Number-Format-BigFloat>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Number-Format-BigFloat>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Other number formatting modules: L<Number::Format>.

L<Math::BigFloat>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
