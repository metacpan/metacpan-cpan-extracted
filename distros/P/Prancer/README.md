# NAME

Prancer

# SYNOPSIS

When using as part of a web application:

    ===> foobar.yml

    session:
        state:
            driver: Prancer::Session::State::Cookie
            options:
                session_key: PSESSION
        store:
            driver: Prancer::Session::Store::Storable
            options:
                dir: /tmp/prancer/sessions

    static:
        path: /static
        dir: /srv/www/resources

    ===> myapp.psgi

    #!/usr/bin/env perl

    use strict;
    use warnings;
    use Plack::Runner;

    # this just returns a PSGI application. $x can be wrapped with additional
    # middleware before sending it along to Plack::Runner.
    my $x = MyApp->new("/path/to/foobar.yml")->to_psgi_app();

    # run the psgi app through Plack and send it everything from @ARGV. this
    # way Plack::Runner will get options like what listening port to use and
    # application server to use -- Starman, Twiggy, etc.
    my $runner = Plack::Runner->new();
    $runner->parse_options(@ARGV);
    $runner->run($x);

    ===> MyApp.pm

    package MyApp;

    use strict;
    use warnings;

    use Prancer qw(config);

    sub initialize {
        my $self = shift;

        # in here we can initialize things like plugins
        # but this method is not required to be implemented

        return;
    }

    sub handler {
        my ($self, $env, $request, $response, $session) = @_;

        sub (GET + /) {
            $response->header("Content-Type" => "text/plain");
            $response->body("Hello, world!");
            return $response->finalize(200);
        }, sub (GET + /foo) {
            $response->header("Content-Type" => "text/plain");
            $response->body(sub {
                my $writer = shift;
                $writer->write("Hello, world!");
                $writer->close();
                return;
            });
        }
    }

    1;

If you save the above snippet as `myapp.psgi` and run it like this:

    plackup myapp.psgi

You will get "Hello, world!" in your browser. Or you can use Prancer as part of
a standalone command line application:

    #!/usr/bin/env perl

    use strict;
    use warnings;

    use Prancer::Core qw(config);

    # the advantage to using Prancer in a standalone application is the ability
    # to use a standard configuration and to load plugins for things like
    # loggers and database connectors and template engines.
    my $x = Prancer::Core->new("/path/to/foobar.yml");
    print "Hello, world!;

# DESCRIPTION

Prancer is yet another PSGI framework that provides routing and session
management as well as plugins for logging, database access, and template
engines. It does this by wrapping
[Web::Simple](https://metacpan.org/pod/Web::Simple) to handle routing and by
wrapping other libraries to bring easy access to things that need to be done in
web applications.

There are two parts to using Prancer for a web application: a package to
contain your application and a script to call your application. Both are
necessary.

The package containing your application should contain a line like this:

    use Prancer;

This modifies your application package such that it inherits from Prancer. It
also means that your package must implement the `handler` method and
optionally implement the `initialize` method. As Prancer inherits from
Web::Simple it will also automatically enable the `strict` and `warnings`
pragmas.

As mentioned, putting `use Prancer;` at the top of your package will require
you to implement the `handler` method, like this:

    sub handler {
        my ($self, $env, $request, $response, $session) = @_;

        # routing goes in here.
        # see Web::Simple for documentation on writing routing rules.
        sub (GET + /) {
            $response->header("Content-Type" => "text/plain");
            $response->body("Hello, world!");
            return $response->finalize(200);
        }
    }

The `$request` variable is a
[Prancer::Request](https://metacpan.org/pod/Prancer::Request) object. The
`$response` variable is a
[Prancer::Response](https://metacpan.org/pod/Prancer::Response) object. The
`$session` variable is a
[Prancer::Session](https://metacpan.org/pod/Prancer::Session) object. If there
is no configuration for sessions in any of your configuration files then
`$session` will be `undef`.

You may implement your own `new` method in your application but you **MUST**
call `$class->SUPER::new(@_);` to get the configuration file loaded and
any methods exported. As an alternative to implemeting `new` and remembering
to call `SUPER::new`, Prancer will make a call to `->initialize` at the
end of its own implementation of `new` so things that you might put in `new`
can instead be put into `initialize`, like this:

    sub initialize {
        my $self = shift;

        # this is where you can initialize things when your package is created

        return;
    }

By default, Prancer does not export anything into your package's namespace.
However, that doesn't mean that there is not anything that it _could_ export
were one to ask:

    use Prancer qw(config);

Importing `config` will make the keyword `config` available which gives
access to any configuration options loaded by Prancer.

The second part of the Prancer equation is the script that creates and calls
your package. This can be a pretty small and standard little script, like this:

    my $myapp = MyApp->new("/path/to/foobar.yml")
    my $psgi = $myapp->to_psgi_app();

`$myapp` is just an instance of your package. You can pass to `new` either
one specific configuration file or a directory containing lots of configuration
files. The functionality is documented in `Prancer::Config`.

`$psgi` is just a PSGI app that you can send to
[Plack::Runner](https://metacpan.org/pod/Plack::Runner) or whatever you use to
run PSGI apps. You can also wrap middleware around `$app`.

    my $psgi = $myapp->to_psgi_app();
    $psgi = Plack::Middleware::Runtime->wrap($psgi);

# CONFIGURATION

Prancer needs a configuration file. Ok, it doesn't _need_ a configuration file
file. By default, Prancer does not require any configuration. But it is less
useful without one. You _could_ always create your application like this:

    my $app = MyApp->new->to_psgi_app();

How Prancer loads configuration files is documented in
[Prancer::Config](https://metacpan.org/pod/Prancer::Config). Anything you put
into your configuration file is available to your application.

There are two special configuration keys reserved by Prancer. The key
`session` will configure Prancer's session as documented in
[Prancer::Session](https://metacpan.org/pod/Prancer::Session). The key `static`
will configure static file loading through
[Plack::Middleware::Static](https://metacpan.org/pod/Plack::Middleware::Static).

To configure static file loading you can add this to your configuration file:

    static:
        path: /static
        dir: /path/to/my/resources

The `dir` option is required to indicate the root directory for your static
resources. The `path` option indicates the web path to link to your static
resources. If no path is not provided then static files can be accessed under
`/static` by default.

# CREDITS

This module could have been written except on the shoulders of the following
giants:

- The name "Prancer" is a riff on the popular PSGI framework [Dancer](https://metacpan.org/pod/Dancer) and [Dancer2](https://metacpan.org/pod/Dancer2). [Prancer::Config](https://metacpan.org/pod/Prancer::Config) is derived directly from [Dancer2::Core::Role::Config](https://metacpan.org/pod/Dancer2::Core::Role::Config). Thank you to the Dancer/Dancer2 teams.
- [Prancer::Database](https://metacpan.org/pod/Prancer::Database) is derived from [Dancer::Plugin::Database](https://metacpan.org/pod/Dancer::Plugin::Database). Thank you to David Precious.
- [Prancer::Request](https://metacpan.org/pod/Prancer::Request), [Prancer::Request::Upload](https://metacpan.org/pod/Prancer::Request::Upload), [Prancer::Response](https://metacpan.org/pod/Prancer::Response), [Prancer::Session](https://metacpan.org/pod/Prancer::Session) and the session packages are but thin wrappers with minor modifications to [Plack::Request](https://metacpan.org/pod/Plack::Request), [Plack::Request::Upload](https://metacpan.org/pod/Plack::Request::Upload), [Plack::Response](https://metacpan.org/pod/Plack::Response), and [Plack::Middleware::Session](https://metacpan.org/pod/Plack::Middleware::Session). Thank you to Tatsuhiko Miyagawa.
- The entire routing functionality of this module is offloaded to [Web::Simple](https://metacpan.org/pod/Web::Simple). Thank you to Matt Trout for some great code that I am able to easily leverage.

# COPYRIGHT

Copyright 2013, 2014 Paul Lockaby. All rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

# SEE ALSO

- [Plack](https://metacpan.org/pod/Plack)
- [Web::Simple](https://metacpan.org/pod/Web::Simple)
