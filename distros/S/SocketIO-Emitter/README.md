# NAME

SocketIO::Emitter - A Perl implementation of socket.io-emitter.

# SYNOPSIS

```perl

    use strict;
    use warnings;
    use SocketIO::Emitter;

    my $em = SocketIO::Emitter->new(
      #  key => 'another-key',
      #  redis => Redis->new(server => 'localhost:6380'),
    );

    # emit
    $em->emit('event', 'broadcast blah blah blah');

    # namespace emit
    $em->of('/nsp')->emit('event', 'nsp broadcast blah blah blah');

    # namespace room broadcast
    $em->of('/nsp')->to('roomId')->broadcast->emit('event', 'yahooooooo!!!!');

```

# DESCRIPTION

A Perl implementation of socket.io-emitter.

This project uses redis. Make sure your environment has redis.

## Installation

    git clone https://github.com/toritori0318/p5-SocketIO-Emitter.git
    cd p5-SocketIO-Emitter

    perl Makefile.PL
    make
    make test
    make install

## DEPENDENCIES

    Moo
    namespace::clean
    Redis
    Data::MessagePack(<=0.49)

# LICENSE

Copyright (C) toritori0318.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

toritori0318 <toritori0318@gmail.com>
