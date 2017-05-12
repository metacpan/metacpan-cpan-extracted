# NAME

Prancer::Plugin::Log4perl

# SYNOPSIS

This plugin connects your [Prancer](https://metacpan.org/pod/Prancer)
application to [Log::Log4perl](https://metacpan.org/pod/Log::Log4perl) and
exports a keyword to access the configured logger. You don't _need_ this module
to log things but it certainly makes it easier.

There is very minimal configuration required to get started with this module.
To enable the logger you only need to do this:

    use Prancer::Plugin::Log4perl qw(logger);

    Prancer::Plugin::Log4perl->load();

    logger->info("hello, logger here");
    logger->fatal("something done broke");

By default, this plugin will initialize
[Log::Log4perl](https://metacpan.org/pod/Log::Log4perl) with a very basic
configuration to avoid warnings when used. You can override the configuration
by loading your own before calling `load` on this plugin. This plugin's
`load` implementation simply calls `Log::Log4perl->initialized()` to see
if it should load its own. For example, you might do this:

    use Prancer::Plugin::Log4perl qw(logger);

    Log::Log4perl::init('/etc/log4perl.conf');
    Prancer::Plugin::Log4perl->load();

The `logger` keyword gets you direct access to an instance of the logger and
you can always call static methods on
[Log::Log4perl](https://metacpan.org/pod/Log::Log4perl) and interact with the
logger that way, too.

# COPYRIGHT

Copyright 2014 Paul Lockaby. All rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

# SEE ALSO

- [Prancer](https://metacpan.org/pod/Prancer)
- [Log::Log4perl](https://metacpan.org/pod/Log::Log4perl)
- [Log::Dispatch](https://metacpan.org/pod/Log::Dispatch)
- [Log::Dispatch::Screen](https://metacpan.org/pod/Log::Dispatch::Screen)

