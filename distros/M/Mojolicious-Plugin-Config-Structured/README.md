# NAME

Mojolicious::Plugin::Config::Structured - provides Mojo app access to structured configuration data

# SYNOPSIS

    # For a full Mojo app
    $self->plugin('Config::Structured' => {config_file => $filename});

    ...

    if ($c->conf->feature->enabled) {
      ...
    }

    say $c->conf->email->recipient->{some_feature};

# DESCRIPTION

Mojolicious Plugin for [Config::Structured](https://metacpan.org/pod/Config%3A%3AStructured): locates and reads config and definition files and loads them into a 
Config::Structured instance, made available globally via the `conf` method.

# METHODS

[Mojolicious::Plugin::Config::Structured](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AConfig%3A%3AStructured) inherits all methods from [Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious%3A%3APlugin) and implements the following
new ones

## register

    $plugin->register(Mojolicious->new, [structure_file => $struct_fn,] [config_file => $config_file])

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application. `structure_file` is the filesystem path of the file that defines the 
configuration definition. If omitted, a sane default is used (`./{app}.conf.def`) relative to the mojo app home.

`config_file` is the filesystem path of the file that provides the active configuration. If omitted, a sane default is
used (`./{app}.{mode}.conf` or `./{app}.conf`)

## conf

This method is used to access the loaded configuration from within the Mojo 
application. Returns the root `Config::Structured::Node` instance.

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
