# NAME

MojoX::Log::Any - Use the current Log::Any adapter from Mojolicious

# SYNOPSIS

    use Mojolicious::Lite;

    # Use Mojo::Log by default when importing
    use MojoX::Log::Any;

    # Or you can specify a different default adapter
    use MojoX::Log::Any default_adapter => 'Stderr';

    get '/' => sub {
      my $c = shift;

      app->log->debug('Using Log::Any::Adapter::MojoLog');

      # They can be redefined
      use Log::Any::Adapter;
      Log::Any::Adapter->set('Stderr');
      app->log->warning('Using Log::Any::Adapter::Stderr')
        if app->log->is_warning;

      # Or use whatever adapter you've set
      use Log::Log4perl qw(:easy);
      Log::Log4perl->easy_init($ERROR);

      Log::Any::Adapter->set('Log4perl');
      app->log->fatalf('Formatting with %s', 'Log::Any::Adapter::Log4perl');

      $c->render(text => 'OK!');
    };

    app->start;

# DESCRIPTION

[MojoX::Log::Any](https://metacpan.org/pod/MojoX::Log::Any) makes it easy to use a [Log::Any::Adapter](https://metacpan.org/pod/Log::Any::Adapter) from within
[Mojolicious](https://metacpan.org/pod/Mojolicious) without getting in the way of the user.

When imported from within a Mojolicious application (of from within a
package into which Mojolicious' app function has been exported), it sets
that application's log attribute to a [Log::Any::Proxy](https://metacpan.org/pod/Log::Any::Proxy) connected to
whatever adapter is currently available.

When imported, the logger defaults to using [Log::Any::Adapter::MojoLog](https://metacpan.org/pod/Log::Any::Adapter::MojoLog),
which seems to be the currently maintained adapter for [Mojo::Log](https://metacpan.org/pod/Mojo::Log). Any
parameters passed to the module's `import` function are passed _as is_
to the `get_logger` function from [Log::Any](https://metacpan.org/pod/Log::Any), to allow for user
customisation and to maintain a coherent interface with that package.

# MOTIVATION

There are numerous packages in the "MojoX::Log" namespace providing an
interface with the various different logging mechanisms on CPAN; except
Log::Any.

There is also a Log::Any adapter for Mojo::Log, which makes it
possible to use that logger from any application using Log::Any; but
not Mojolicious apps.

This package attempts to fill that void by offering Mojolicious
applications an easy way to plug into the current Log::Any::Adapter
(whatever it may be).

# INTERNALS AND CAVEATS

This module does a fair amount of meddling in the namespace of the caller and
that of the currently available [Log::Any::Adapter](https://metacpan.org/pod/Log::Any::Adapter), so use at your own risk.

The module detects [Mojolicious](https://metacpan.org/pod/Mojolicious) apps by checking the inheritance tree of the
caller; while [Mojolicious::Lite](https://metacpan.org/pod/Mojolicious::Lite) apps are detected by checking whether that
module is loaded.

With Mojolicious::Lite apps, the application's `log` attribute is simply set
to the current adapter. With Mojolicious apps, this overrides the `log`
function in that module to set or get a reference to the Log::Any::Proxy object.

In order to more closely mimic the behaviour of [Mojo::Log](https://metacpan.org/pod/Mojo::Log), this module also
installs the [Format](https://metacpan.org/pod/Log::Any::Plugin::Format) and
[History](https://metacpan.org/pod/Log::Any::Plugin::History) plugins from [Log::Any::Plugin](https://metacpan.org/pod/Log::Any::Plugin), which
will make the adapter usable with the default Mojolicious HTML templates.

Since the message formatting in most adapters is hard coded (or configured
through external configuration files), the starting set by this module is a
no-op. This means that the formatting won't perfectly mimic that of Mojo::Log,
but avoids clashes with other logging mechanisms.

# CONTRIBUTIONS AND BUG REPORTS

The main repository for this distribution is on
[GitLab](https://gitlab.com/jjatria/MojoX-Log-Any), which is where patches
and bug reports are mainly tracked. Bug reports can also be sent through the
CPAN RT system, or by mail directly to the developers at the address below,
although these will not be as closely tracked.

# SEE ALSO

- [Log::Any](https://metacpan.org/pod/Log::Any)
- [Log::Any::Plugin](https://metacpan.org/pod/Log::Any::Plugin)
- [Log::Any::Adapter::MojoLog](https://metacpan.org/pod/Log::Any::Adapter::MojoLog)
- [Log::Any::Adapter::Mojo](https://metacpan.org/pod/Log::Any::Adapter::Mojo)

# AUTHOR

- José Joaquín Atria <jjatria@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016-2017 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
