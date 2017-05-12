[![Build Status](https://travis-ci.org/JaSei/Port-Selector.svg?branch=master)](https://travis-ci.org/JaSei/Port-Selector)
# NAME

Port::Selector - pick some unused port

# SYNOPSIS

    my $port_sel = Port::Selector->new();
    $port_sel->port();

# DESCRIPTION

This module is used to find a free port,
by default in the range 49152 to 65535,
but you can change the range of ports that will be checked.

# METHODS

## new(%attributes)

### %attributes

#### min

lowest numbered port to consider

default _49152_

The range 49152-65535 is commonly used by applications that utilize a
dynamic/random/configurable port.

#### max

highest numbered port to consider

default _65535_

#### proto

socket protocol

default _tcp_

#### addr

local address

default _localhost_

## port()

Tries to find an unused port from `min`-`max` ports range,
checking each port in turn until it finds an available one.

# SEE ALSO

[Net::EmptyPort](https://metacpan.org/pod/Net::EmptyPort) (part of the `Test-TCP` distribution,
provides a function `empty_port`
which does the same thing as the `port` method in this module.

# LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jan Seidl <seidl@avast.com>
