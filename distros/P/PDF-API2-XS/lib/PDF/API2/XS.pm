package PDF::API2::XS;

use strict;
use warnings;

our $VERSION = '1.000'; # VERSION

=head1 NAME

PDF::API2::XS - Optional PDF::API2 add-on using XS to speed up expensive operations

=head1 DESCRIPTION

L<PDF::API2> will make use of this distribution, if it's installed, to speed up
some operations that are significantly faster in C than in Perl.

There's no need to interact with this distribution directly.  PDF::API2 will use
it automatically if it detects it.

=head1 AUTHOR

Rob Scovell

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free
Software Foundation, either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.

=cut

1;
