package Number::Phone::Formatter::EPP;
$Number::Phone::Formatter::EPP::VERSION = '0.06';
# ABSTRACT: An EPP formatter for Number::Phone

use strict;
use warnings;


sub format {
    my ($class, $number) = @_;

    my ($code, $subscriber) = split /\s+/, $number, 2;

    $code =~ s/\D+//g;
    $subscriber =~ s/\D+//g;

    return "+${code}.${subscriber}";
}

1;

__END__

=pod

=head1 NAME

Number::Phone::Formatter::EPP - An EPP formatter for Number::Phone

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This is a formatter that will format an L<E.123|http://www.itu.int/rec/T-REC-E.123> formatted number (from
L<Number::Phone>) as an EPP phone number.

=head1 METHODS

=head2 format

This is the only method.  It takes an L<E.123|http://www.itu.int/rec/T-REC-E.123> international format string as its
only argument and reformats it in EPP (L<RFC 5733|https://tools.ietf.org/html/rfc5733>) format.  For example:

 +44 20 8771 2924 -> +44.2087712924
 +1 212 334 0611  -> +1.2123340611

=head1 SEE ALSO

L<RFC 5733|https://tools.ietf.org/html/rfc5733>

=head1 SOURCE

The development version is on github at L<https://github.com/mschout/perl-number-phone-formatter-epp>
and may be cloned from L<git://github.com/mschout/perl-number-phone-formatter-epp.git>

=head1 BUGS

Please report any bugs or feature requests to bug-number-phone-formatter-epp@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Number-Phone-Formatter-EPP

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
