# Mojolicious::Plugin::AccessLog [![Build Status](https://api.travis-ci.org/augensalat/mojolicious-plugin-accesslog.svg?branch=master)](https://travis-ci.org/augensalat/mojolicious-plugin-accesslog)

You might have wondered why
[Hypnotoad](http://mojolicio.us/perldoc/Mojo/Server/Hypnotoad), the
Mojolicious application server, does not have an accesslog option.
The reason might be, that it is designed to work behing a "real" web
server like [nginx](http://nginx.org/).
In case YMMV, Mojolicious::Plugin::AccessLog is for you.

## Features

* A [Mojolicious plugin](http://mojolicio.us/perldoc/Mojolicious#plugin) with
  easy configuration.
* The log format can be specified using
  [Apache-style format strings](http://httpd.apache.org/docs/2.2/mod/mod_log_config.html).
* Logging can be directed to a file, a file handle, a subroutine or an
  object.

## Installation

Stable releases are available from the
[CPAN](https://metacpan.org/release/Mojolicious-Plugin-AccessLog).

You can use [cpanm](https://metacpan.org/pod/App::cpanminus) to install from
the command line:

    $ cpanm Mojolicious::Plugin::AccessLog

## Usage

```perl
use Mojolicious::Lite;

plugin AccessLog => log => '/var/tmp/myapp-access.log', format => 'combined';

get '/' => {text => 'I ♥ Mojolicious::Plugin::AccessLog!'};

app->start;
```

## More Information

Please look at the
[manpage](https://metacpan.org/pod/Mojolicious::Plugin::AccessLog).

