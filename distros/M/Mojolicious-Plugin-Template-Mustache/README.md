[![MetaCPAN Release](https://badge.fury.io/pl/Mojolicious-Plugin-Template-Mustache.svg)](https://metacpan.org/release/Mojolicious-Plugin-Template-Mustache) [![Build Status](https://travis-ci.org/cynovg/Mojolicious-Plugin-Template-Mustache.svg?branch=master)](https://travis-ci.org/cynovg/Mojolicious-Plugin-Template-Mustache)
# NAME

Mojolicious::Plugin::Template::Mustache - Mojolicious Plugin

# SYNOPSIS

    # Mojolicious
    $self->plugin('Template::Mustache');

    # Mojolicious::Lite
    plugin 'Template::Mustache';

    get '/inline' => sub {
    my $c = shift;
    $c->render(
        handler => 'mustache',
        inline  => 'Inline hello, {{message}}!',
        message => 'Mustache',
    );
  };

# DESCRIPTION

[Mojolicious::Plugin::Template::Mustache](https://metacpan.org/pod/Mojolicious::Plugin::Template::Mustache) is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin.

# METHODS

[Mojolicious::Plugin::Template::Mustache](https://metacpan.org/pod/Mojolicious::Plugin::Template::Mustache) inherits all methods from [Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin).

# SEE ALSO

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojolicious::Guides](https://metacpan.org/pod/Mojolicious::Guides), [http://mojolicious.org](http://mojolicious.org), [http://mustache.github.io](http://mustache.github.io), [Template::Mustache](https://metacpan.org/pod/Template::Mustache).

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
