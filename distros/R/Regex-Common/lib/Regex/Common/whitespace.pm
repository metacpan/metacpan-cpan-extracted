package Regex::Common::whitespace;
use strict;
use warnings;
no warnings 'syntax';

use Regex::Common qw /pattern clean no_defaults/;

our $VERSION = 'v1.0.0'; # VERSION

pattern
  name   => [qw (ws crop)],
  create => '(?:^\s+|\s+$)',
  subs   => sub { $_[1] =~ s/^\s+//; $_[1] =~ s/\s+$//; };

1;

__END__

=pod

=head1 NAME

Regex::Common::whitespace -- provides a regex for leading or
trailing whitescape

=head1 SYNOPSIS

    use Regex::Common qw /whitespace/;

    while (<>) {
        s/$RE{ws}{crop}//g;           # Delete surrounding whitespace
    }


=head1 DESCRIPTION

Please consult the manual of L<Regex::Common> for a general description
of the works of this interface.

Do not use this module directly, but load it via I<Regex::Common>.


=head2 C<$RE{ws}{crop}>

Returns a pattern that identifies leading or trailing whitespace.

For example:

        $str =~ s/$RE{ws}{crop}//g;     # Delete surrounding whitespace

The call:

        $RE{ws}{crop}->subs($str);

is optimized (but probably still slower than doing the s///g explicitly).

This pattern does not capture under C<-keep>.

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
