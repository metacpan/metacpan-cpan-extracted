# ======================================================================
# $Id: PortIO.pm,v 1.3 2005/03/05 06:45:56 andrew Exp $

=head1 NAME

Sys::PortIO - perform direct port I/O from Perl

=head1 SYNOPSIS

    use Sys::PortIO;

    port_open($portnum);
    write_byte($portnum, $value);
    $value = read_byte($portnum);
    port_close($portnum);

=head1 DESCRIPTION

This module provides a Perl interface to the low-level port I/O
operations provided by Linux, FreeBSD, or OpenBSD. Among other things,
this is useful for writing Perl scripts that interface with parallel,
serial, or joystick ports.

=head1 BUGS

On some systems (for example, Linux), doing a port read or write on an
unopened port will cause a segmentation fault.

=head1 TODO

=over 4

=item Support optional range argument to C<port_open()>.

=item Set $! on errors, instead of dying (sometimes with a segfault).

=item Alternately, automatically open ports as needed.

=back

=head1 SEE ALSO

Linux I/O port mini-HOWTO:
L<http://www.faqs.org/docs/Linux-mini/IO-Port-Programming.html>

On Linux or other glibc systems, see L<ioperm(2)>, L<inb(2)>, and L<outb(2)>.
FreeBSD uses F</dev/io> for port access. On OpenBSD and NetBSD, see
L<i386_iopl(2)> and L<sysarch(2)>.

=head1 AUTHOR

Andrew Ho, E<lt>andrew@zeuscat.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Andrew Ho.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=cut


# ----------------------------------------------------------------------
# Packages declaration (the real code is in the XS interface)

package Sys::PortIO;
require 5.006;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(port_open read_byte write_byte port_close);
our @EXPORT = @EXPORT_OK;
our $VERSION = '0.1';

require XSLoader;
XSLoader::load('Sys::PortIO' => $VERSION);

1;


# ======================================================================
__END__
