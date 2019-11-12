[![MetaCPAN Release](https://badge.fury.io/pl/Mojolicious-Plugin-Text-Caml.svg)](https://metacpan.org/release/Mojolicious-Plugin-Text-Caml) [![Build Status](https://travis-ci.org/cynovg/p5-Mojolicious-Plugin-Text-Caml.svg?branch=master)](https://travis-ci.org/cynovg/p5-Mojolicious-Plugin-Text-Caml) [![Coverage Status](https://img.shields.io/coveralls/cynovg/p5-Mojolicious-Plugin-Text-Caml/master.svg?style=flat)](https://coveralls.io/r/cynovg/p5-Mojolicious-Plugin-Text-Caml?branch=master)
# NAME

Mojolicious::Plugin::Text::Caml - Mojolicious Plugin

# SYNOPSIS

    plugin 'Text::Caml';

    get '/inline' => sub {
      my $c = shift;
      $c->render(handler => 'caml', inline  => 'Hello, {{message}}!', message => 'Mustache');
    };

# DESCRIPTION

[Mojolicious::Plugin::Text::Caml](https://metacpan.org/pod/Mojolicious::Plugin::Text::Caml) is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin.

# METHODS

[Mojolicious::Plugin::Text::Caml](https://metacpan.org/pod/Mojolicious::Plugin::Text::Caml) inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin) and implements the following new ones.

## register

    # Mojolicious
    $self->plugin('Text::Caml');

    # Mojolicious::Lite
    plugin 'Text::Caml';

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# SEE ALSO

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojolicious::Guides](https://metacpan.org/pod/Mojolicious::Guides), [http://mojolicious.org](http://mojolicious.org), [http://mustache.github.io](http://mustache.github.io), [Text::Caml](https://metacpan.org/pod/Text::Caml).

## AUTHOR

Cyrill Novgorodcev <cynovg@cpan.org>

## LICENSE

                    Copyright 2017 Cyrill Novgorodcev.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
