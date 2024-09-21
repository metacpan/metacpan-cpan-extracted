[![Release](https://img.shields.io/github/release/giterlizzi/perl-Mojolicious-Plugin-Badge.svg)](https://github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/releases) [![License](https://img.shields.io/github/license/giterlizzi/perl-Mojolicious-Plugin-Badge.svg)](https://github.com/giterlizzi/perl-Mojolicious-Plugin-Badge) [![Starts](https://img.shields.io/github/stars/giterlizzi/perl-Mojolicious-Plugin-Badge.svg)](https://github.com/giterlizzi/perl-Mojolicious-Plugin-Badge) [![Forks](https://img.shields.io/github/forks/giterlizzi/perl-Mojolicious-Plugin-Badge.svg)](https://github.com/giterlizzi/perl-Mojolicious-Plugin-Badge) [![Issues](https://img.shields.io/github/issues/giterlizzi/perl-Mojolicious-Plugin-Badge.svg)](https://github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/issues) [![Coverage Status](https://coveralls.io/repos/github/giterlizzi/perl-Mojolicious-Plugin-Badge/badge.svg)](https://coveralls.io/github/giterlizzi/perl-Mojolicious-Plugin-Badge)

# Mojolicious::Plugin::Badge - Badge plugin for Mojolicious

Mojolicious::Plugin::Badge is a Mojolicious plugin that generate "Shields.io"
like badge from `badge` helper or via API URL (e.g. `/badge/Hello-Mojo!-orange`).

## Usage

Create your badge ...

... in `Mojolicious` or `Mojolicious::Lite` application:

```.pl
# Mojolicious
$self->plugin('Badge');

# Mojolicious::Lite
plugin 'Badge';

get '/my-cool-badge' => sub ($c) {

  my $badge = $c->app->badge(
    label        => 'Hello',
    message      => 'Mojo!',
    color        => 'orange'
    logo         => 'https://docs.mojolicious.org/mojo/logo.png'
    badge_format => 'png',
  );

  $c->render(data => $badge, format => 'png');

};
```

... via "Shields.io"-like Badge API:

```
GET /badge/Hello-Mojo!-orange.png
```

... from CLI using "badge" command:

```console
./myapp.pl badge --label "Hello" --message "Mojo!" --color "orange" --format png --file my-cool-badge.png
```


Output:

![Hello Mojo](https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/hello-mojo.png)


## Styles

* ![flat](https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/style-flat.png)
* ![flat-square](https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/style-flat-square.png)
* ![plastic](https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/style-plastic.png)
* ![for-the-badge](https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/style-for-the-badge.png)

## Colors

![blue](https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/color-blue.png)
![brightgreen](https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/color-brightgreen.png)
![green](https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/color-green.png)
![grey](https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/color-grey.png)
![lightgrey](https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/color-lightgrey.png)
![orange](https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/color-orange.png)
![red](https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/color-red.png)
![yellow](https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/color-yellow.png)
![yellowgreen](https://raw.github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/main/examples/color-yellowgreen.png)

## Installation

To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install

Using App::cpanminus:

    cpanm Mojolicious::Plugin::Badge


## Documentation

 - `perldoc Mojolicious::Plugin::Badge`
 - https://metacpan.org/release/Mojolicious-Plugin-Badge

## Copyright

Copyright (C) 2024 by Giuseppe Di Terlizzi
