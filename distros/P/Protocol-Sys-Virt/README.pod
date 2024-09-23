
use v5.14;
use warnings;

package Protocol::Sys::Virt v10.3.8;

1;

=head1 NAME

Protocol::Sys::Virt - Abstract LibVirt protocol implementation

=head1 VERSION

v10.3.8

Based on LibVirt tag v10.3.0

=head2 Version numbering

The first two numbers follow the L<LibVirt|https://libvirt.org> release
numbering (and thus API version); the last digit indicates the sequence number
of releases of this library.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution implements the mechanics of the L<LibVirt|https://libvirt.org>
protocol. With it, client and server components can be built, although it's
unlikely anyone would want to build a LibVirt compatible server.

Rationale behind the creation of this distribution is that it allows for the
imlpementation of a truely asynchronous interface to LibVirt; a property
L<Sys::Virt> doesn't have, even when using its event loop integration.  After
having implemented L<Sys::Virt::IO::Async>, the invocations to the methods in
C<Sys::Virt> turned out to be blocking regardless.  The LibVirt
development team explained this is by design.  The solution in e.g. Python is
to use threading (the same solution as used with Python): the underlying
protocol and handling on the server is asynchronous, but the API calls are not.
Unfortunately, in Perl, threading isn't a viable option: first of all because
using Perl threads is highly discouraged, but more so because each thread
creates its own Perl interpreter with its own copies of all variables -- a
clear difference with Python, where a single interpreter is used for all
threads, sharing variables and values.

=head1 API Guarantees

The LibVirt project describes the stability guarantees of the protocol
at L<https://libvirt.org/support.html#rpc-protocol>.

=head1 TODO

=over 8

=item * Write documentation

=back

=head1 AUTHOR

=over 8

=item * Erik Huelsmann C<< <ehuels@gmail.com> >>

=back

=head1 SEE ALSO

L<Sys::Virt>, L<LibVirt|https://libvirt.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2024, Erik Huelsmann C<< <ehuels@gmail.com> >>.
All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR
THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

