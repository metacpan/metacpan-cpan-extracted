# NAME

Nephia::Plugin::SocketIO - Nephia plugin socketio support

# SYNOPSIS

    use Nephia plugins => [
        'SocketIO',
        ...
    ];
    

    app {
        socketio 'your_event' => sub {
            my $socket = shift; ### PocketIO::Socket object
            $socket->emit('some_event' => 'some_data');
        };
    };



# DESCRIPTION

Nephia::Plugin::SocketIO is a plugin for Nephia. It provides SocketIO messaging feature.

# DSL

## socketio

    my $coderef = sub {
        my $socket = shift; # PocketIO::Socket object
        ...
    };
    socketio $str => $coderef;

Specifier DSL for SocketIO messaging.

$str is event name, and $coderef is event logic.

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>
