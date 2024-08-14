package Regex::Common::SEN;
use strict;
use warnings;
no warnings 'syntax';

use Regex::Common qw /pattern clean no_defaults/;

our $VERSION = 'v1.0.0'; # VERSION

=begin does_not_exist

sub par11 {
    my $string = shift;
    my $sum    = 0;
    for my $i (0 .. length ($string) - 1) {
        my $c = substr ($string, $i, 1);
        $sum += $c * (length ($string) - $i)
    }
    !($sum % 11)
}

=end does_not_exist
=cut

# http://www.ssa.gov/history/ssn/geocard.html
pattern
  name   => [qw /SEN USA SSN -sep=-/],
  create => sub {
    my $sep = $_[1]{-sep};
    "(?k:(?k:[1-9][0-9][0-9]|0[1-9][0-9]|00[1-9])$sep"
      . "(?k:[1-9][0-9]|0[1-9])$sep"
      . "(?k:[1-9][0-9][0-9][0-9]|0[1-9][0-9][0-9]|"
      . "00[1-9][0-9]|000[1-9]))";
  },
  ;

=begin does_not_exist

It's not clear whether this is the right checksum.

# http://www.google.nl/search?q=cache:8m1zKNYrEO0J:www.enschede.nl/nieuw/projecten/aanbesteding/integratie/pve%2520Bijlage%25207.5.doc+Sofi+nummer+formaat&hl=en&start=56&lr=lang_en|lang_nl&ie=UTF-8
pattern name   => [qw /SEN Netherlands SoFi/],
        create => sub {
            # 9 digits (d1 d2 d3 d4 d5 d6 d7 d8 d9)
            # 9*d1 + 8*d2 + 7*d3 + 6*d4 + 5*d5 + 4*d6 + 3*d7 + 2*d8 + 1*d9
            # == 0 mod 11.
            qr /([0-9]{9})(?(?{par11 ($^N)})|(?!))/;
        }
        ;

=end does_not_exist
=cut

1;

__END__

=pod

=head1 NAME

Regex::Common::SEN -- provide regexes for Social-Economical Numbers.

=head1 SYNOPSIS

 use Regex::Common qw /SEN/;

 while (<>) {
     /^$RE{SEN}{USA}{SSN}$/    and  print "Social Security Number\n";
 }


=head1 DESCRIPTION

Please consult the manual of L<Regex::Common> for a general description
of the works of this interface.

Do not use this module directly, but load it via I<Regex::Common>.

=head2 C<$RE{SEN}{USA}{SSN}{-sep}>

Returns a pattern that matches an American Social Security Number (SSN).
SSNs consist of three groups of numbers, separated by a hyphen (C<->).
This pattern only checks for a valid structure, that is, it validates
whether a number is valid SSN, was a valid SSN, or maybe a valid SSN
in the future. There are almost a billion possible SSNs, and about
400 million are in use, or have been in use.

If C<-sep=I<P>> is specified, the pattern I<P> is used as the
separator between the groups of numbers.

Under C<-keep> (see L<Regex::Common>):

=over 4

=item $1

captures the entire SSN.

=item $2

captures the first group of digits (the area number).

=item $3

captures the second group of digits (the group number).

=item $4

captures the third group of digits (the serial number).

=back

=head1 SEE ALSO

L<Regex::Common> for a general description of how to use this interface.

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
