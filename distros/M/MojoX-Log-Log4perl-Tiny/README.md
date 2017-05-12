[![Build Status](https://travis-ci.org/yowcow/p5-MojoX-Log-Log4perl-Tiny.svg?branch=master)](https://travis-ci.org/yowcow/p5-MojoX-Log-Log4perl-Tiny)
# NAME

MojoX::Log::Log4perl::Tiny - Minimalistic Log4perl adapter for Mojolicious

# SYNOPSIS

    use MojoX::Log::Log4perl::Tiny;

    # In your $app->setup...

    $app->log(
        MojoX::Log::Log4perl::Tiny->new(
            logger => Log::Log4perl->get_logger('MyLogger')
        )
    );

# DESCRIPTION

MojoX::Log::Log4perl::Tiny allows you to replace default Mojolicious logging `Mojo::Log` with
your existing `Log::Log4perl::Logger` instance.

# METHODS

## new(Hash %args) returns MojoX::Log::Log4perl::Tiny

Creates and returns an instance to replace `Mojolicious-&gt;log`.

- logger

    A `Log::Log4perl::Logger` instance. **Required**.

- level

    Minimum log level for logging.  Default: "debug"

- max\_history\_size

    Max history size for logs to be shown on "exception.html.ep".  Default: 5

# LICENSE

Copyright (C) yowcow.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

yowcow <yowcow@cpan.org>
