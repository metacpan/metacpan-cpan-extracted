# Name

Net::Telnet::Netgear - Generate and send Netgear Telnet-enable packets through Net::Telnet

# Synopsis

```perl
use Net::Telnet::Netgear;
my $telnet = Net::Telnet::Netgear->new (
    # Standard Net::Telnet parameters are allowed
    host             => 'example.com',
    packet_mac       => 'AA:BB:CC:DD:EE:FF', # or AABBCCDDEEFF
    packet_username  => 'admin',
    packet_password  => 'hunter2',
    netgear_defaults => 1
);
# The magic is done transparently: the packet has already been sent,
# if necessary, and the standard Net::Telnet API can now be used.
my @lines = $telnet->cmd ('whoami');

use Net::Telnet::Netgear::Packet;
# Manually create a packet.
my $packet = Net::Telnet::Netgear::Packet->new (mac => '...');
say length $packet->get_packet; # or whatever you want
$packet = Net::Telnet::Netgear::Packet->from_base64 ('...');
$packet = Net::Telnet::Netgear::Packet->from_string ('...');
```

# Description

This module allows to programmatically generate and send magic Telnet-enabling packets for
Netgear routers with a locked Telnet interface. The packet can either be user-provided or it can
be automatically generated given the username, password and MAC address of the router. Also, this
module is capable of sending packets using TCP or UDP (the latter is used on new firmwares), and
can automatically pick the right protocol to use, making it compatible with old and new firmwares
without any additional configuration.

The work on the Telnet protocol is done by [Net::Telnet](https://metacpan.org/pod/Net::Telnet), which is subclassed by this module.
In fact, it's possible to use the entire [Net::Telnet](https://metacpan.org/pod/Net::Telnet) API and configuration parameters.

# Methods

[Net::Telnet::Netgear](https://metacpan.org/pod/Net::Telnet::Netgear) inherits all methods from [Net::Telnet](https://metacpan.org/pod/Net::Telnet) and implements the following new
ones.

## new

```perl
my $instance = Net::Telnet::Netgear->new (%options);
```

Creates a new `Net::Telnet::Netgear` instance. Returns `undef` on failure.

`%options` can contain any of the options valid with the constructor of [Net::Telnet](https://metacpan.org/pod/Net::Telnet),
with the addition of:

- `packet_mac => 'AA:BB:CC:DD:EE:FF'`

    The MAC address of the router where the packet will be sent to. Each non-hexadecimal character
    (like colons) will be removed.

- `packet_username => 'admin'`

    The username that will be put in the packet. Defaults to `Gearguy` for compatibility reasons.
    With new firmwares, the username `admin` should be used.

    Has no effect if `packet_mac` is not specified.

- `packet_password => 'password'`

    The password that will be put in the packet. Defaults to `Geardog` for compatibility reasons.
    With new firmwares, the password of the router interface should be used.

    Has no effect if `packet_mac` is not specified.

- `packet_content => 'string'`

    The content of the packet to be sent, as a string.

    Only makes sense if the packet is not defined elsewhere.

- `packet_base64 => 'b64_string'`

    The content of the packet to be sent, as a Base64 encoded string.

    Only makes sense if the packet is not defined elsewhere.

- `packet_instance => ...`

    A subclass of [Net::Telnet::Netgear::Packet](https://metacpan.org/pod/Net::Telnet::Netgear::Packet) to be used as the packet.

    Only makes sense if the packet is not defined elsewhere.

    **NOTE:** Packets generated with ["new" in Net::Telnet::Netgear::Packet](https://metacpan.org/pod/Net::Telnet::Netgear::Packet#new),
    ["from\_string" in Net::Telnet::Netgear::Packet](https://metacpan.org/pod/Net::Telnet::Netgear::Packet#from_string) and ["from\_base64" in Net::Telnet::Netgear::Packet](https://metacpan.org/pod/Net::Telnet::Netgear::Packet#from_base64)
    can be used too.

- `packet_delay => .50`

    The amount of time, in seconds, to wait after sending the packet.
    In pseudo-code: `send_packet(); wait(packet_delay); connect()`

    Defaults to `.3` seconds, or 300 milliseconds. Can be `0`.

- `packet_wait_timeout => .75`

    The amount of time, in seconds, to wait for a response from the server before sending the packet.
    In pseudo-code: `connect(); if !can_read(in packet_wait_timeout seconds) then send_packet()`

    Only effective when the packet is sent using TCP. Defaults to `1` second.

- `packet_send_mode => 'auto|tcp|udp'`

    Determines how to send the packet. See ["packet\_send\_mode"](#packet_send_mode) below.

    Defaults to `auto`.

- `netgear_defaults => 0|1`

    If enabled, the default values defined in the hash `%Net::Telnet::Netgear::NETGEAR_DEFAULTS` are
    applied once the connection is established. See ["DEFAULT VALUES USING %NETGEAR\_DEFAULTS"](#default-values-using-netgear_defaults).

    Defaults to `0`.

- `exit_on_destroy => 0|1`

    If enabled, the `exit` shell command is sent before the object is destroyed. This is useful to
    avoid ghost processes when closing a Telnet connection without killing the shell first.

    Defaults to `0`.

## apply\_netgear\_defaults

```perl
$instance->apply_netgear_defaults;
$instance->apply_netgear_defaults (
    prompt => '/rxp/',
    cmd_remove_mode => 0
);
%Net::Telnet::Netgear::NETGEAR_DEFAULTS = (exit_on_destroy => 1);
$instance->apply_netgear_defaults;
```

Applies the values specified in the hash `%Net::Telnet::Netgear::NETGEAR_DEFAULTS`. If any
argument is specified, it is temporarily added to the hash.

See ["DEFAULT VALUES USING %NETGEAR\_DEFAULTS"](#default-values-using-netgear_defaults).

## exit\_on\_destroy

```perl
my $current_value = $instance->exit_on_destroy;
# Set exit_on_destroy to 1
my $old_value = $instance->exit_on_destroy (1);
```

Gets or sets the value of the boolean flag `exit_on_destroy`, which causes the module to send
the `exit` shell command before being destroyed. This is to avoid ghost processes when closing
a Telnet connection without killing the shell first.

## packet

```perl
my $current_value = $instance->packet;
# Set the content of the packet to '...'
my $old_value = $instance->packet ('...');
```

Gets or sets the value of the packet **as a string**. This is basically equivalent to the
`packet_content` constructor parameter.

Note that objects cannot be used - you have to call ["get\_packet" in Net::Telnet::Netgear::Packet](https://metacpan.org/pod/Net::Telnet::Netgear::Packet#get_packet)
before passing the value to this method.

## packet\_delay

```perl
my $current_value = $instance->packet_delay;
# Set packet_delay to .75 seconds
my $old_value = $instance->packet_delay (.75);
```

Gets or sets the amount of time, in seconds, to wait after sending the packet.

## packet\_send\_mode

```perl
my $current_value = $instance->packet_send_mode;
# Set packet_send_mode to 'udp'
my $old_value = $instance->packet_send_mode ('udp');
```

Gets or sets the protocol used to send the packet, between `tcp`, `udp` and `auto`.

If it is `auto`, then the module will try to guess the correct protocol to use. More specifically,
if the initial `open` performed on the specified `host` and `port` fails, the packet is sent
using UDP (and then the connection is reopened). Otherwise, if the `open` succeeds but it's
impossible to read within the ["packet\_wait\_timeout"](#packet_wait_timeout), the packet is sent using TCP.

If it is `tcp`, the packet is sent using TCP.

If it is `udp`, the packet is sent using UDP. Note that in this case the packet is always sent
before an `open` call.

**NOTE:** Generally, specifying the protocol instead of using `auto` is faster, especially when
the packet has to be sent using UDP (due to the additional connection that has to be made).

## packet\_wait\_timeout

```perl
my $current_value = $instance->packet_wait_timeout;
# Set packet_wait_timeout to 1.25
my $old_value = $instance->packet_wait_timeout (1.25);
```

Gets or sets the the amount of time, in seconds, to wait for a response from the server before
sending the packet.

Only effective when the packet is sent using TCP.

# Implementation details

When you open a connection with [Net::Telnet::Netgear](https://metacpan.org/pod/Net::Telnet::Netgear) (either with the `(fh)open` methods
inherited from [Net::Telnet](https://metacpan.org/pod/Net::Telnet) or by specifying the `host` constructor parameter), the following
actions are performed depending on the value of ["packet\_send\_mode"](#packet_send_mode).

**NOTE:** when `fhopen` is used, "socket" refers to the filehandle.

- "auto"

    This is the default. First, [Net::Telnet](https://metacpan.org/pod/Net::Telnet) tries to open the socket. If it succeeds,
    then it's assumed that the server may want a TCP packet. To check if the server actually needs
    it, a ["select" in perlfunc](https://metacpan.org/pod/perlfunc#select) call is performed on the socket to determine if data is available
    to read. If data is available, then nothing is done. Otherwise, the packet is sent using TCP and
    then the socket is re-opened.

    If the initial `open` didn't succeed, then the server is not listening on the port. It's assumed
    that the server wants an UDP packet, and it is immediately sent. The socket is re-opened, and if
    it fails again the error is propagated.

- "tcp"

    The actions specified in the first case apply, except that if the initial `open` goes wrong the
    error is immediately propagated.

- "udp"

    The packet is immediately sent before the `open` performed by [Net::Telnet](https://metacpan.org/pod/Net::Telnet). If it fails, the
    error is immediately propagated.

# Default values using %NETGEAR\_DEFAULTS

As an added feature, it's possible to enable a set of options suitable for Netgear routers.
This is possible with the hash `%Net::Telnet::Netgear::NETGEAR_DEFAULTS`, which contains a list
of methods to be called on the current instance along with their parameters. This is done by the
method ["apply\_netgear\_defaults"](#apply_netgear_defaults).

The current version specifies the following list of default values:

```perl
method              value
-----------------   -----------
cmd_remove_mode     1
exit_on_destroy     1
prompt              '/.* # $/'
waitfor             '/.* # $/'
```

It is possible to edit this list either by interacting directly with it:

```perl
$Net::Telnet::Netgear::NETGEAR_DEFAULTS{some_option} = 'some_value';
delete $Net::Telnet::Netgear::NETGEAR_DEFAULTS{some_option};
%Net::Telnet::Netgear::NETGEAR_DEFAULTS = (
    option1 => 'value1',
    option2 => 'value2'
);
```

Or you can supply additional parameters to ["apply\_netgear\_defaults"](#apply_netgear_defaults), which will be temporarily
added to the list. Note that user-specified values have priority over the ones in the hash, and
if you specify the value of an option as `undef`, it won't be set at all.

```perl
# cmd_remove_mode is set to 0 instead of 1, along with all the other
# default values
$instance->apply_netgear_defaults (cmd_remove_mode => 0);
# do not set cmd_remove_mode at all, but apply every other default
$instance->apply_netgear_defaults (cmd_remove_mode => undef);
# the standard list of default values is applied plus 'some_option'
$instance->apply_netgear_defaults (some_option => 'some_value');
# equivalent to:
{
    local %Net::Telnet::Netgear::NETGEAR_DEFAULTS = (
        %Net::Telnet::Netgear::NETGEAR_DEFAULTS,
        some_option => 'some_value'
    );
    $instance->apply_netgear_defaults;
}
```

# The magic behind timeouts

`Net::Telnet::Netgear` uses a timeout to determine if it should send the packet (using TCP).
But what's the magic behind this mysterious decimal number?

Timeouts, under normal conditions, are implemented using the ["select" in perlfunc](https://metacpan.org/pod/perlfunc#select) function (which
calls the [select(2)](http://man.he.net/man2/select) syscall). This magic function is awesome, and it works beautifully.

It would be great if the story ended here, but happy endings are pretty rare in real life.

`select` works basically everywhere when dealing with network sockets, but it doesn't work on
certain systems when dealing with generic filehandles (_Win32, I'm looking at you!_).
[Net::Telnet](https://metacpan.org/pod/Net::Telnet) can make Telnet work on arbitrary filehandles (thanks to ["fhopen" in Net::Telnet](https://metacpan.org/pod/Net::Telnet#fhopen)),
but that means that `select` may not be always available. This is a problem, and you can specify
what to do in this case with the boolean variable
`$Net::Telnet::Netgear::DIE_ON_SELECT_UNAVAILABLE`.

If this variable is false (the default), then if `select` is not available the module will simply
never send packets using TCP and emit a warning. This may not be always desiderable.

If this variable is true, then if `select` is unavailable the module will call
`Net::Telnet->error` which, when `errmode` is the default, stops the execution of the script.

**NOTE:** If ["packet\_send\_mode"](#packet_send_mode) is set to `udp`, then `select` is never called, thus
`$Net::Telnet::Netgear::DIE_ON_SELECT_UNAVAILABLE` won't have any effect even if `select` is
unavailable.

# Caveats

An `open` call may require serious amounts of time, depending on the ["packet\_send\_mode"](#packet_send_mode) and
["packet\_wait\_timeout"](#packet_wait_timeout).
Particularly, if no packet has to be sent, then `tcp` or `auto` are the fastest. Otherwise,
`udp` is the fastest (because there are no timeouts, and the packet is immediately sent).
`auto` is the slowest when the router requires the packet on UDP, because a connection is
attempted on the TCP port, while it has the same speed of `tcp` when the packet is expected on
TCP.

# See also

[Net::Telnet](https://metacpan.org/pod/Net::Telnet), [Net::Telnet::Netgear::Packet](https://metacpan.org/pod/Net::Telnet::Netgear::Packet),
[http://wiki.openwrt.org/toh/netgear/telnet.console](http://wiki.openwrt.org/toh/netgear/telnet.console),
[https://github.com/Robertof/perl-net-telnet-netgear](https://github.com/Robertof/perl-net-telnet-netgear)

# Author

Roberto Frenna (robertof AT cpan DOT org)

# Thanks

Thanks to [Derreck "insanid"](https://github.com/insanid) for the precious contribution to
the OpenWRT wiki page, and for helping me to discovery the mistery behind the "strange" packets
generated with long passwords.

Thanks to [the authors of Mojolicious](https://metacpan.org/pod/Mojolicious) for inspiration about the license and the
documentation.

# License

Copyright (C) 2014-2015, Roberto Frenna.

This program is free software, you can redistribute it and/or modify it under the terms of the
Artistic License version 2.0.
