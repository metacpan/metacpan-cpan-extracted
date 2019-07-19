package Sys::Sendfile::OSX;
$Sys::Sendfile::OSX::VERSION = '0.02';
# ABSTRACT: Exposing sendfile() for OS X

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(sendfile);

require XSLoader;
XSLoader::load('Sys::Sendfile::OSX');

*sendfile = \&Sys::Sendfile::OSX::handle::sendfile;

1;

=head1 NAME

Sys::Sendfile::OSX - Exposing sendfile() for OS X

=head1 SYNOPSIS

 use Sys::Sendfile::OSX qw(sendfile);

 open my $local_fh, '<', 'somefile';
 my $socket_fh = IO::Socket::INET->new(
   PeerHost => "10.0.0.1",
   PeerPort => "8080"
 );

 my $rv = sendfile($local_fh, $socket_fh);

=head1 DESCRIPTION

The sendfile() function is a zero-copy function for transferring the
contents of a filehandle to a streaming socket.

As per the man pages, the sendfile() function was made available as of Mac
OS X 10.5.

=head1 Sys::Sendfile

Why would you use this module over L<Sys::Sendfile>? The answer is: you
probably wouldn't. L<Sys::Sendfile> is more portable, and supports more
platforms.

Use L<Sys::Sendfile>.

=head1 EXPORTED FUNCTIONS

=over

=item sendfile($from, $to[, $count][, $offset])

Pipes the contents of the filehandle C<$from> into the socket stream C<$to>.

Optionally, only C<$count> bytes will be sent across to the socket. Specifying a
C<$count> of 0 is the same as sending the entire file, as per the man page.

Also optionally, C<$offset> can be specified to set a specific-sized chunk from
a specific offset.

=back

=head1 AUTHOR

Luke Triantafyllidis <ltriant@cpan.org>

=head1 SEE ALSO

L<Sys::Sendfile>, sendfile(2)

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
