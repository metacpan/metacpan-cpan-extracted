# NAME

Sys::Sendfile::OSX - Exposing sendfile() for OS X

# SYNOPSIS

    use Sys::Sendfile::OSX qw(sendfile);

    open my $local_fh, '<', 'somefile';
    my $socket_fh = IO::Socket::INET->new(
      PeerHost => "10.0.0.1",
      PeerPort => "8080"
    );

    my $rv = sendfile($local_fh, $socket_fh);

# DESCRIPTION

The sendfile() function is a zero-copy function for transferring the
contents of a filehandle to a streaming socket.

As per the man pages, the sendfile() function was made available as of Mac
OS X 10.5.

# Sys::Sendfile

Why would you use this module over [Sys::Sendfile](https://metacpan.org/pod/Sys::Sendfile)? The answer is: you
probably wouldn't. [Sys::Sendfile](https://metacpan.org/pod/Sys::Sendfile) is more portable, and supports more
platforms.

Use [Sys::Sendfile](https://metacpan.org/pod/Sys::Sendfile).

# EXPORTED FUNCTIONS

- sendfile($from, $to\[, $count\]\[, $offset\])

    Pipes the contents of the filehandle `$from` into the socket stream `$to`.

    Optionally, only `$count` bytes will be sent across to the socket. Specifying a
    `$count` of 0 is the same as sending the entire file, as per the man page.

    Also optionally, `$offset` can be specified to set a specific-sized chunk from
    a specific offset.

# AUTHOR

Luke Triantafyllidis <ltriant@cpan.org>

# SEE ALSO

[Sys::Sendfile](https://metacpan.org/pod/Sys::Sendfile), sendfile(2)

# LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
