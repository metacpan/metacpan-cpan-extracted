# NAME

Sys::Pipe - `pipe2()` in Perl

# SYNOPSIS

    use Fcntl;
    use Sys::Pipe;

    Sys::Pipe::pipe( my $r, my $w, O_NONBLOCK ) or die "pipe: $!";

# DESCRIPTION

Ever wish you could create a pipe that starts out non-blocking?
Linux and a number of other OSes can do this via a proprietary `pipe2()`
system call; this little library exposes that functionality to Perl.

# WHEN IS THIS USEFUL?

As shown above, this exposes the ability to create a pipe that starts
out non-blocking. If that’s all you need, then the gain here is mostly just
tidiness. It _is_ also faster than doing:

    pipe my $r, my $w or die "pipe: $!";
    $r->blocking(0);
    $w->blocking(0);

… but the above is already quite fast, so that may not make a real-world
difference for you.

In Linux, this also exposes the ability to create a “packet mode” pipe.
Other OSes may allow similar and/or other functionality. See your
system’s [pipe2(2)](http://man.he.net/man2/pipe2) for more details.

# STATUS

This module is best considered **EXPERIMENTAL**. If you find a problem,
please file a bug report. Thank you!

# SEE ALSO

Perl’s [socket()](https://metacpan.org/pod/perlfunc#socket-SOCKET-DOMAIN-TYPE-PROTOCOL)
built-in allows similar functionality on the relevant OSes, e.g.:

    use Socket;

    socket( my $s, AF_INET, SOCK_STREAM | SOCK_NONBLOCK, 0 ) or do {
        die "socket(): $!";
    };

# FUNCTIONS

## $success\_yn = pipe( READHANDLE, WRITEHANDLE \[, FLAGS\] )

A drop-in replacement for Perl’s `pipe()` built-in that optionally
accepts a numeric _FLAGS_ argument. See your system’s [pipe2(2)](http://man.he.net/man2/pipe2)
documentation for what values you can pass in there.

Note that behavior is currently **undefined** if _FLAGS_ is nonzero on
any system (e.g., macOS) that lacks `pipe2()`. (As of this writing an
exception is thrown; that may change eventually.)

## $yn = has\_pipe2()

Returns a boolean that indicates whether the underlying system can
implement `pipe2()` mechanics.

# COPYRIGHT

Copyright 2020 Gasper Software Consulting. All rights reserved.
