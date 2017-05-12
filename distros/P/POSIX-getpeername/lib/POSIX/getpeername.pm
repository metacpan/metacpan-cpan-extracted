package POSIX::getpeername;

use 5.008005;
use strict;
use warnings;
use base qw/Exporter/;

our $VERSION = "0.01";
our @EXPORT_OK = qw/_getpeername/;

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=encoding utf-8

=head1 NAME

POSIX::getpeername - provides getpeername(2)

=head1 SYNOPSIS

    use POSIX::getpeername;
    use Socket;

    my $ret = POSIX::getpeername::_getpeername($fd, my $addr);
    die $! if $ret < 0;
    my ($peer_port, $peer_iaddr) = sockaddr_in($addr);
    
=head1 DESCRIPTION

POSIX::getpeername provides getpeername(2). perl's core getpeername needs a open file handle.
POSIX::getpeername allows you to get peername from sockfd.

=head1 RETURN VALUES

The _getpeername() function returns the value 0 if successful; otherwise the value -1 is returned and set errno to $!

=head1 SEE ALSO

L<POSIX::Socket>, L<Socket>

=head1 LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=cut

