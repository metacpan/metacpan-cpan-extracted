package Sys::Sendfile::FreeBSD;

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(sendfile);
$VERSION = 0.01;

bootstrap Sys::Sendfile::FreeBSD $VERSION;
1;
#

__END__

=head1 NAME

Sys::Sendfile::FreeBSD - Wrapper for the FreeBSD sendfile(2) function.

=head1 SYNOPSIS

use Sys::Sendfile::FreeBSD qw(sendfile);

open(F, "file.txt");
my $socket = IO::Socket::INET->new(PeerAddr => "127.0.0.1:1234");
my $offset = 0;
my $bytes_sent = 0;
my $result = sendfile(fileno(F), fileno($socket), $offset, (stat("file.txt))[7], $bytes_sent);
close(F);
close($sock);

=head1 DESCRIPTION

Uses the FreeBSD sendfile(2) function to send the contents of an open file handle
directly to an open socket.  See the sendfile(2) manual page for more details.

Note that this module does not currently support the header/trailer functionality 
of the sendfile(2) function, nor does it allow the flags argument to be set.

=head1 AUTHOR

Mark Imbriaco <mark.imbriaco@pobox.com>

=head1 COPYRIGHT

This module is Copyright (c) 2006 Mark Imbriaco.

All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.
If you need more liberal licensing terms, please contact the maintainer.

=head1 WARRANTY

This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 SEE ALSO

Sys::Syscall by Brad Fitzpatrick.

=cut


