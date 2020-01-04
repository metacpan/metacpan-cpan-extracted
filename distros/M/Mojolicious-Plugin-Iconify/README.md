[![Release](https://img.shields.io/github/release/giterlizzi/perl-Mojolicious-Plugin-Iconify.svg)](https://github.com/giterlizzi/perl-Mojolicious-Plugin-Iconify/releases) [![Build Status](https://travis-ci.org/giterlizzi/perl-Mojolicious-Plugin-Iconify.svg)](https://travis-ci.org/giterlizzi/perl-Mojolicious-Plugin-Iconify) [![License](https://img.shields.io/github/license/giterlizzi/perl-Mojolicious-Plugin-Iconify.svg)](https://github.com/giterlizzi/perl-Mojolicious-Plugin-Iconify) [![Starts](https://img.shields.io/github/stars/giterlizzi/perl-Mojolicious-Plugin-Iconify.svg)](https://github.com/giterlizzi/perl-Mojolicious-Plugin-Iconify) [![Forks](https://img.shields.io/github/forks/giterlizzi/perl-Mojolicious-Plugin-Iconify.svg)](https://github.com/giterlizzi/perl-Mojolicious-Plugin-Iconify) [![Issues](https://img.shields.io/github/issues/giterlizzi/perl-Mojolicious-Plugin-Iconify.svg)](https://github.com/giterlizzi/perl-Mojolicious-Plugin-Iconify/issues)

# Mojolicious::Plugin::Iconify

## Usage

```.pl
# Mojolicious
$self->plugin('Iconify');

# Mojolicious::Lite
plugin 'Iconify';
```

```.html
@@ template.html.ep

<html>
<head>
    <%= iconify_js %>
</head>
<body>
    <h1>
        Mojolicious::Plugin::Iconify
    <h1>
    <p>
        Made with <%= icon 'mdi:heart', style => 'color:red' %> by <em>Giterlizzi</em>
    </p>
</body>
</html>
```

## Installation

To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install

## Copyright

Copyright (C) 2019-2020 by Giuseppe Di Terlizzi
