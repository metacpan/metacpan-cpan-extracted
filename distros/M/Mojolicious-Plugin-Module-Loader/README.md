# NAME

Mojolicious::Plugin::Module::Loader - Automatically load mojolicious namespaces

# SYNOPSIS

    $app->plugin('Module::Loader' => {
      command_namespaces => ['MyApp::Command'],
      plugin_namespaces  => ['MyApp::Plugin']
    });

    # Or
    $app->plugin('Module::Loader');
    ...
    $app->add_command_namespace('Dynamically::Loaded::Module::Command');
    $app->add_plugin_namespace('Dynamically::Loaded::Module::Plugin');

# DESCRIPTION

This module simply adds two mojolicious helpers, ["add\_command\_namespace"](#add_command_namespace) and
["add\_plugin\_namespace"](#add_plugin_namespace), and calls these automatically at registration time
on the contents of the `command_namespaces` and `plugin_namespaces` configuration
parameters, respectively.

# METHODS

[Mojolicious::Plugin::Cron::Scheduler](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ACron%3A%3AScheduler) inherits all methods from 
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious%3A%3APlugin) and implements the following new ones

## register( \\%config )

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application. Accepts a HashRef of parameters
with two supprted keys:

#### command\_namespaces

ArrayRef of namespaces to automatically call ["add\_command\_namespace"](#add_command_namespace) on

#### controller\_namespaces

ArrayRef of namespaces to automatically call ["add\_controller\_namespace"](#add_controller_namespace) on

#### plugin\_namespaces

ArrayRef of namespaces to automatically call ["add\_plugin\_namespace"](#add_plugin_namespace) on

## add\_command\_namespace( $str )

Adds the given namespace to the Mojolicious Commands 
[namespaces](https://metacpan.org/pod/Mojolicious::Commands#namespaces) array. 
Packages inheriting from [Mojolicious::Command](https://metacpan.org/pod/Mojolicious%3A%3ACommand) in these namespaces are loaded
as runnable commands from the mojo entrypoint script.

## add\_controller\_namespace( $str )

Adds the given namespace to the Mojolicious routes 
[namespaces](https://metacpan.org/pod/Mojolicious::Routes#namespaces) array.

## add\_plugin\_namespace( $str )

Searches the given namespace for packages inheriting from [Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious%3A%3APlugin)
and loads them via [https://metacpan.org/pod/Mojolicious#plugin](https://metacpan.org/pod/Mojolicious#plugin)

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
