# NAME

Net::Z3950::FOLIO - Z39.50 server for FOLIO bibliographic data

# SYNOPSIS

    use Net::Z3950::FOLIO;
    $service = new Net::Z3950::FOLIO('config.json');
    $service->launch_server("someServer", @ARGV);

# DESCRIPTION

The `Net::Z3950::FOLIO` module provides all the application logic of
a Z39.50 server that allows searching in and retrieval from the
inventory module of FOLIO.  It is used by the `z2folio` program, and
there is probably no good reason to make any other program to use it.

The library has only two public entry points: the `new()` constructor
and the `launch_server()` method.  The synopsis above shows how they
are used: a Net::Z3950::FOLIO object is created using `new()`, then
the `launch_server()` method is invoked on it to start the server.
(In fact, this synopsis is essentially the whole of the code of the
`simple2zoom` program.  All the work happens inside the library.)

# METHODS

## new($configFile)

    $s2z = new Net::Z3950::FOLIO('config.json');

Creates and returns a new Net::Z3950::FOLIO object, configured according to
the JSON file `$configFile` that is the only argument.  The format of
this file is described in `Net::Z3950::FOLIO::Config`.

## launch\_server($label, @ARGV)

    $s2z->launch_server("someServer", @ARGV);

Launches the Net::Z3950::FOLIO server: this method never returns.  The
`$label` string is used in logging, and the `@ARGV` vector of
command-line arguments is interpreted by the YAZ backend server as
described at
https://software.indexdata.com/yaz/doc/server.invocation.html

# SEE ALSO

- The `z2folio` script conveniently launches the server.
- `Net::Z3950::FOLIO::Config` describes the configuration-file format.
- The `Net::Z3950::SimpleServer` handles the Z39.50 service.

# AUTHOR

Mike Taylor, <mike@indexdata.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2018 The Open Library Foundation

This software is distributed under the terms of the Apache License,
Version 2.0. See the file "LICENSE" for more information.
