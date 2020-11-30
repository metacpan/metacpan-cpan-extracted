# NAME

z2folio - Z39.50 server for FOLIO bibliographic data

# SYNOPSIS

`z2folio`
\[
`-c`
_configBase_
\]
\[
`--`
_YAZ-options_
\]
\[
_listener-address_
...
\]

# DESCRIPTION

`z2folio` provides a Z39.50 server for bibliographic data in the
FOLIO ILS.  Because it relies on the `Net::Z3950::SimpleServer`
modules for the server functionality, because this module is based on
the YAZ toolkit, and because YAZ transparently handles all three
standard IR protocols (ANSI/NISO Z39.50, SRU and SRW), it can function
as a server for all three of these protocols.

The following command-line options govern how it functions:

- `-c configBase`

    Specifies that the named `configBase.json` should be used as the base configuration for the
    functionality of the server: if this option is not specified, then the
    file `config.json` in the working directory is used.  The format of
    the configuration file is described separately in
    `Net::Z3950::FOLIO::Config`, and a sample configuration file,
    `config.json`, is supplied in the `etc` directory of the
    distribution.

- `--`

    Indicates the end of `z2folio`-specific options.  This is
    required if YAZ options are to be specified, so that `z2folio`
    doesn't try to interpret them itself.

- _YAZ-options_

    Command-line arguments subsequent to the `--` option are interpreted
    by the YAZ backend server as described at
    https://software.indexdata.com/yaz/doc/server.invocation.html

    These options provide the means to control many aspects of the
    gateway's functioning: for example, whether the server forks a new
    process for each client or runs a single process using `select()`;
    how (if at all) to interpret incoming SRU requests; whether and how to
    log protocol packets for debugging.

- _listener-address_

    One or more YAZ-style listener addresses may be specified, and the
    server will accept connections on those addresses: for example,
    `@:9998`, `unix:/tmp/somesocket` or `ssl:myhost.com:210`.  If
    no explicit listener addresses are provided, the server listens on
    port 9999.

# SEE ALSO

- The `Net::Z3950::FOLIO` module provides all the functionality for this program.
- `Net::Z3950::FOLIO::Config` describes the configuration-file format.
- The `Net::Z3950::SimpleServer` handles the Z39.50 service.

# AUTHOR

Mike Taylor, <mike@indexdata.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2018 The Open Library Foundation

This software is distributed under the terms of the Apache License,
Version 2.0. See the file "LICENSE" for more information.
