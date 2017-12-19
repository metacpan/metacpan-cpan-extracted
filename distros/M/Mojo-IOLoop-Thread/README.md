[![Build Status](https://img.shields.io/appveyor/ci/tomk3003/mojo-ioloop-thread/master.svg)](https://ci.appveyor.com/project/tomk3003/mojo-ioloop-thread/branch/master)
# NAME

Mojo::IOLoop::Thread - Threaded Replacement for Mojo::IOLoop::Subprocess

# SYNOPSIS

    use Mojo::IOLoop::Thread;

    # Operation that would block the event loop for 5 seconds
    my $subprocess = Mojo::IOLoop::Thread->new;
    $subprocess->run(
      sub {
        my $subprocess = shift;
        sleep 5;
        return '♥', 'Mojolicious';
      },
      sub {
        my ($subprocess, $err, @results) = @_;
        say "Subprocess error: $err" and return if $err;
        say "I $results[0] $results[1]!";
      }
    );

    # Start event loop if necessary
    $subprocess->ioloop->start unless $subprocess->ioloop->is_running;

or

    use Mojo::IOLoop;
    use Mojo::IOLoop::Thread;

    my $iol = Mojo::IOLoop->new;
    $iol->subprocess(
      sub {'♥'},
      sub {
        my ($subprocess, $err, @results) = @_;
        say "Subprocess error: $err" and return if $err;
        say @results;
      }
    );
    $loop->start;

# DESCRIPTION

[Mojo::IOLoop::Thread](https://metacpan.org/pod/Mojo::IOLoop::Thread) is a multithreaded alternative for
[Mojo::IOLoop::Subprocess](https://metacpan.org/pod/Mojo::IOLoop::Subprocess) which is not available under Win32.
It is a dropin replacement, takes the same parameters and works
analoguous by just using threads instead of forked processes.

[Mojo::IOLoop::Thread](https://metacpan.org/pod/Mojo::IOLoop::Thread) replaces ["subprocess" in Mojo::IOLoop](https://metacpan.org/pod/Mojo::IOLoop#subprocess) with a threaded
version on module load. Please make sure that you load [Mojo::IOLoop](https://metacpan.org/pod/Mojo::IOLoop) first.

# AUTHOR

Thomas Kratz <tomk@cpan.org>

# REPOSITORY

[https://github.com/tomk3003/mojo-ioloop-thread](https://github.com/tomk3003/mojo-ioloop-thread)

# COPYRIGHT

Copyright 2017 Thomas Kratz.

# LICENSE

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.
