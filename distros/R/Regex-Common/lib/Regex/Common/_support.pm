package Regex::Common::_support;
use strict;
use warnings;
no warnings 'syntax';

our $VERSION = 'v1.0.0'; # VERSION

# Returns true/false, depending whether the given the argument
# satisfies the LUHN checksum.
# See http://www.webopedia.com/TERM/L/Luhn_formula.html.
#
# Note that this function is intended to be called from regular
# expression, so it should NOT use a regular expression in any way.
#
sub luhn {
    my $arg  = shift;
    my $even = 0;
    my $sum  = 0;
    while ( length $arg ) {
        my $num = chop $arg;
        return if $num lt '0' || $num gt '9';
        if ( $even && ( ( $num *= 2 ) > 9 ) ) { $num = 1 + ( $num % 10 ) }
        $even = 1 - $even;
        $sum += $num;
    }
    !( $sum % 10 );
}

sub import {
    my $pack   = shift;
    my $caller = caller;
    no strict 'refs';
    *{ $caller . "::" . $_ } = \&{ $pack . "::" . $_ } for @_;
}

1;

__END__

=pod

=head1 NAME

Regex::Common::support -- Support functions for Regex::Common.

=head1 SYNOPSIS

    use Regex::Common::_support qw /luhn/;

    luhn ($number)    # Returns true/false.


=head1 DESCRIPTION

This module contains some subroutines to be used by other C<Regex::Common>
modules. It's not intended to be used directly. Subroutines from the
module may disappear without any notice, or their meaning or interface
may change without notice.

=over

=item luhn

This subroutine returns true if its argument passes the luhn checksum test.

=back

=head1 SEE ALSO

L<http://www.webopedia.com/TERM/L/Luhn_formula.html>.

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
