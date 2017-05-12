#!/usr/bin/perl -c

package POSIX::strftime::GNU::XS;

=head1 NAME

POSIX::strftime::GNU::XS - XS extension for POSIX::strftime::GNU

=head1 SYNOPSIS

  $ export PERL_POSIX_STRFTIME_GNU_XS=1

=head1 DESCRIPTION

This is XS extension for POSIX::strftime which implements more character
sequences compatible with GNU systems.

=cut


use 5.006;
use strict;
use warnings;

our $VERSION = '0.0305';

use Carp ();
use Config;
use POSIX ();

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);


=head1 FUNCTIONS

=head2 strftime

  $str = strftime($format, @time)

This is replacement for L<POSIX::strftime|POSIX/strftime> function.

The non-POSIX feature is that seconds can be float number.

=cut


1;


=head1 SEE ALSO

L<POSIX::strftime::GNU>.

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2012-2014 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

strftime function:

Copyright (c) 1991-2001, 2003-2007, 2009-2012 Free Software Foundation, Inc.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

See L<http://dev.perl.org/licenses/artistic.html>
