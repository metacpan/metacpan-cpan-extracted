# NAME

Sys::Virt::IO::Async::EventImpl - Integration of libvirt into IO::Async event loop

# SYNOPSIS

    use Sys::Virt;
    use Sys::Virt::Event;
    use Sys::Virt::IO::Async::EventImpl;

    use IO::Async::Loop;

    my $loop = IO::Async::Loop;
    my $impl = Sys::Virt::IO::Async::EventImpl->new;
    Sys::Virt::Event::register( $impl );


    my $conn = Sys::Virt->new( uri => 'qemu:///system' );
    $conn->domain_event_register(
       sub {
         # ... log some event data
       });

    $loop->add( $impl );
    $loop->run;

# DESCRIPTION

This module implements an event loop integration for libvirt through
the [Sys::Virt::Event](https://metacpan.org/pod/Sys%3A%3AVirt%3A%3AEvent) libvirt event interface bindings.

`libvirt` is limited to a single registered event loop. Registration
must be done before the first libvirt connection is created.

## LOGGING

This module implements logging using [Log::Any](https://metacpan.org/pod/Log%3A%3AAny) with the module name
as the logging category.

# METHODS

## new()

Constructor.

As there can only ever be a single event loop registered at a time, this
module implements a singleton class.  The `new` method always returns the
same instance.

The returned instance is an `IO::Async::Notifier` that can be used to
register an event loop implementation through `Sys::Virt::Event::register`.

## $self->add\_handle( $fd, $events, $callback, $opaque, $opaque\_free\_cb )

Implements the event loop integration protocol `add_handle` callback.

Adds the file handle `$fd` to the event loop, calling `$callback` for
the events in the mask `$events`, returning an integer `$watch_id`
for reference with `update_handle` and `remove_handle`.

Returns a non-negative int `$watch_id` or -1 on error.

## $self->update\_handle( $watch\_id, $events )

Implements the event loop integration protocol `update_handle` callback.

Changes the events for which the callback registered through `add_handle`
will be triggered to those specified in `$events`.

## $self->remove\_handle( $watch\_id )

Implements the event loop integration protocol `remove_handle` callback.

Returns 0 on success, -1 on failure.

## $self->add\_timeout( $frequency, $callback, $opaque, $opaque\_free\_cb )

Implements the event loop integration protocol `add_timeout` callback.

Adds the file handle `$fd` to the event loop, calling `$callback` for
the events in the mask `$events`, returning an integer `$watch_id`
for reference with `update_handle` and `remove_handle`.

Returns a non-negative int `$timer_id` or -1 on error.

## $self->update\_handle( $timer\_id, $frequency )

Implements the event loop integration protocol `update_timeout` callback.

Changes the duration between callback triggers; `$frequency` is an integer
in milliseconds, with the values `0` (zero) and `-1` taking special meaning:
`0` means calling the callback on each event loop iteration and `-1` pauses
the timer.

The semantics of `0` are implemented using the `watch_idle` function
of the event loop.

Frequency changes are implemented by stopping the current IO::Async timer
and creating a new one with the desired frequency. (Where `-1` simply stops
the current IO::ASync timer.)

## $self->remove\_timeout( $timer\_id )

Implements the event loop integration protocol `remove_timeout` callback.

Returns 0 on success, -1 on failure.

# AUTHORS

- Erik Huelsmann `ehuels at gmail.com`

# SUPPORT

Please report bugs and ask your questions on [GitHub](https://github.com/ehuelsmann/Sys-Virt-IO-Async/issues).

# LICENSE AND COPYRIGHT

This software is copyright (c) 2023 by Erik Huelsmann.

This is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.
