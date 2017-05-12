# Mojolicious::Plugin::SizeLimit [![Build Status](https://api.travis-ci.org/augensalat/mojolicious-plugin-sizelimit.svg?branch=master)](https://travis-ci.org/augensalat/mojolicious-plugin-sizelimit)

This module allows you to terminate
[Hypnotoad](http://mojolicio.us/perldoc/Mojo/Server/Hypnotoad) worker
processes if they grow too large. You can make the decision to end
a process based on its overall size, by setting a minimum limit on shared
memory, or a maximum on unshared memory.

This module is highly platform dependent, it is possible that this module
simply does not support your platform.

## Features

* Limits for Hypnotoad worker overall size, minimum limit on shared
  memory, or a maximum on unshared memory. Terminate the worker process
  if any limit is exceeded.
* Check frequency limit, meaning that this module only checks every N
  requests.

## Installation

Stable releases are available from the
[CPAN](https://metacpan.org/release/Mojolicious-Plugin-SizeLimit).

You can use [cpanm](https://metacpan.org/pod/App::cpanminus) to install from
the command line:

    $ cpanm Mojolicious::Plugin::SizeLimit

## Usage

```perl
use Mojolicious::Lite;

plugin 'SizeLimit',
    max_unshared_size => 262_144,   # 256 M
    check_interval => 100;

...

app->start;
```

## More Information

Please look at the
[manpage](https://metacpan.org/pod/Mojolicious::Plugin::SizeLimit).

