# NAME

Mojolicious::Plugin::CustomLog - A custom logger that can output log by date and type

# VERSION

version 0.06

# SYNOPSIS

Provides custom log utilities that can output log by date and type

    use Mojolicious::Plugin::CustomLog;

    sub startup {
        my $self = shift;

        $self->plugin('CustomLog', {
                "path" => {
                    "test"   => "log/test"   # relative to home directory of app
                    "check"  => "log/check"
                },
                "helper" => "mylog",
                "alias"  => "Global"
            });

        # using app helper
        $self->mylog->debug('test',  "this is test log");

        # using alias
        Global::CLog->error('check', "this is error log");
    }

# CONFIGURATION

## CONFIGURE YOUR OWN LOGGER

- 'path'        should contain at least a key value pair that identifies the path of the log
- 'helper'      the name of the helper to associate with the logger (default: clog)
- 'alias'       if provided, an alias of CustomLog object will be created

There should be at least one log defined. Other configs are optional.

# METHODS/HELPERS

A helper is created with a name you specified (or 'clog' by default).

# AUTHOR

Jingxuan Wang, `<lxem.wjx@gmail.com>`

# BUGS/CONTRIBUTING

Please report any bugs or feature requests to through the web interface at [https://github.com/jingxuanwang/Mojolicious-Plugin-CustomLog/issues](https://github.com/jingxuanwang/Mojolicious-Plugin-CustomLog/issues).
If you want to contribute changes or otherwise involve yourself in development, feel free to fork the Git repository from [https://github.com/jingxuanwang/Mojolicious-Plugin-CustomLog/](https://github.com/jingxuanwang/Mojolicious-Plugin-CustomLog/).

# LICENSE AND COPYRIGHT

Copyright 2016- Jingxuan Wang.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
