package PDF::API2::XS;

use strict;
use warnings;

our $VERSION = '1.002'; # VERSION

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

This software is copyright (c) 2020 by Steve Simms.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
