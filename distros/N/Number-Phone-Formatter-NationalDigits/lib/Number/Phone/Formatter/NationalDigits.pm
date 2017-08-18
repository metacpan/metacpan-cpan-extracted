#
# This file is part of Number-Phone-Formatter-NationalDigits
#
# This software is copyright (c) 2017 by Michael Schout.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

package Number::Phone::Formatter::NationalDigits;
$Number::Phone::Formatter::NationalDigits::VERSION = '0.01';
# ABSTRACT: A L<Number::Phone> formatter for the national digits only.

use strict;
use warnings;


sub format {
    my ($self, $number) = @_;

    $number =~ s/^.*?\s//;
    $number =~ s/[^0-9]+//g;

    return $number;
}

1;

__END__

=pod

=head1 NAME

Number::Phone::Formatter::NationalDigits - A L<Number::Phone> formatter for the national digits only.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 # option 1: use with Number::Phone
 #
 # prints 2087712924
 my $number = Number::Phone->new('+44 20 8771 2924');
 print $number->format_using('NationalDigits');

 # Option 2: use standaline, without Number::Phone
 #
 # prints: 2087712924
 #
 print Number::Phone::Formatter::NationalDigits->format('+44 20 8771 2924');

=head1 DESCRIPTION

This is a formatter that will format an
L<E.123|http://www.itu.int/rec/T-REC-E.123> formatted number (e.g. from
L<Number::Phone>) as the National portion of the number, with all non-digits
removed.  This is the same thing that L<Number::Phone::Formatter::Raw> does,
except you can install this module without installing the entire
L<Number::Phone> package, which is quite large.  If you merely need to format 
L<E.123|http://www.itu.int/rec/T-REC-E.123> phone numbers as raw national
digits, and you don't want to install the entirety of L<Number::Phone>, then
this is the module for you.  Otherwise you should probably just stick with
L<Number::Phone::Formatter::Raw>.

This module can be used with L<Number::Phone>, or, as a standalone module.

=head1 METHODS

=head2 format($number)

This is the only method.  It takes an
L<E.123|http://www.itu.int/rec/T-REC-E.123> international format string as its
only argument and reformats it as the national portion of the number with all
non-digits removed.  For example:

 +44 20 8771 2924 -> 2087712924
 +1 212 334 0611  -> 2123340611

=head1 SOURCE

The development version is on github at L<https://github.com/mschout/perl-number-phone-formatter-nationaldigits>
and may be cloned from L<git://github.com/mschout/perl-number-phone-formatter-nationaldigits.git>

=head1 BUGS

Please report any bugs or feature requests to bug-number-phone-formatter-nationaldigits@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Number-Phone-Formatter-NationalDigits

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
