package Regex::Common::CC;
use strict;
use warnings;
no warnings 'syntax';

use Regex::Common           qw /pattern clean no_defaults/;
use Regex::Common::_support qw /luhn/;

our $VERSION = 'v1.0.0'; # VERSION

my @cards = (

    # Name           Prefix                    Length           mod 10
    [ Mastercard => '5[1-5]', 16,         1 ],
    [ Visa       => '4',      [ 13, 16 ], 1 ],
    [ Amex       => '3[47]',  15,         1 ],

    # Carte Blanche
    [ 'Diners Club' => '3(?:0[0-5]|[68])', 14, 1 ],
    [ Discover      => '6011',             16, 1 ],
    [ enRoute       => '2(?:014|149)',     15, 0 ],
    [ JCB => [ [ '3', 16, 1 ],
            [ '2131|1800', 15, 1 ] ] ],
);

foreach my $card (@cards) {
    my ( $name, $prefix, $length, $mod ) = @$card;

    # Skip the harder ones for now.
    next if ref $prefix || ref $length;
    next unless $mod;

    my $times = $length + $mod;
    pattern
      name   => [ CC => $name ],
      create => sub {
        use re 'eval';
        qr <((?=($prefix))[0-9]{$length})
                    (?(?{Regex::Common::_support::luhn $1})|(?!))>x
      };
}

1;

__END__

=pod

=head1 NAME

Regex::Common::CC -- provide patterns for credit card numbers.

=head1 SYNOPSIS

    use Regex::Common qw /CC/;

    while (<>) {
        /^$RE{CC}{Mastercard}$/   and  print "Mastercard card number\n";
    }

=head1 DESCRIPTION

Please consult the manual of L<Regex::Common> for a general description
of the works of this interface.

Do not use this module directly, but load it via I<Regex::Common>.

This module offers patterns for credit card numbers of several major
credit card types. Currently, the supported cards are: I<Mastercard>,
I<Amex>, I<Diners Club>, and I<Discover>.


=head1 SEE ALSO

L<Regex::Common> for a general description of how to use this interface.

=over 4

=item L<http://www.beachnet.com/~hstiles/cardtype.html>

Credit Card Validation - Check Digits

=item L<http://euro.ecom.cmu.edu/resources/elibrary/everycc.htm>

Everything you ever wanted to know about CC's

=item L<http://www.webopedia.com/TERM/L/Luhn_formula.html>

Luhn formula

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 LICENSE and COPYRIGHT

This software is copyright (c) 2024 of Alceu Rodrigues de Freitas Junior,
glasswalk3r at yahoo.com.br

This file is part of regex-common project.

regex-commonis free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

regex-common is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
regex-common. If not, see (http://www.gnu.org/licenses/).

The original project [Regex::Common](https://metacpan.org/pod/Regex::Common)
is licensed through the MIT License, copyright (c) Damian Conway
(damian@cs.monash.edu.au) and Abigail (regexp-common@abigail.be).

=cut
