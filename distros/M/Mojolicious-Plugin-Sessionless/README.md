# NAME

Mojolicious::Plugin::Sessionless - disable Mojolicious sessions

# SYNOPSIS

    plugin 'Sessionless';

    app->session(key => 'value'); #noop

# DESCRIPTION

[Mojolicious::Plugin::Sessionless](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ASessionless) is an extremely simple plugin that disables
Mojolicious's session support, replacing the Session load/save handlers with
`noop`s

# METHODS

[Mojolicious::Plugin::Sessionless](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ASessionless) inherits all methods from [Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious%3A%3APlugin)
and implements the following new onees

## register

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application. Takes no parameters.

## load

Load session data. Noop.

## store

Store session data. Noop.

# AUTHOR

Mark Tyrrell `<mark@tyrrminal.dev>`

# LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
