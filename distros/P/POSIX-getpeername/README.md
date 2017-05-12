# NAME

POSIX::getpeername - provides getpeername(2)

# SYNOPSIS

    use POSIX::getpeername;
    use Socket;

    my $ret = POSIX::getpeername::_getpeername($fd, my $addr);
    die $! if $ret < 0;
    my ($peer_port, $peer_iaddr) = sockaddr_in($addr);
    

# DESCRIPTION

POSIX::getpeername provides getpeername(2). perl's core getpeername needs a open file handle.
POSIX::getpeername allows you to get peername from sockfd.

# RETURN VALUES

The \_getpeername() function returns the value 0 if successful; otherwise the value -1 is returned and set errno to $!

# SEE ALSO

[POSIX::Socket](http://search.cpan.org/perldoc?POSIX::Socket), [Socket](http://search.cpan.org/perldoc?Socket)

# LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masahiro Nagano <kazeburo@gmail.com>
