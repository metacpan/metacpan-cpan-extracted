# NAME

Plack::App::ServiceStatus - Check and report status of various services needed by your app

# VERSION

version 0.908

# SYNOPSIS

    # using Plack::Builder with Plack::App::URLMap
    use Plack::Builder;
    use Plack::App::ServiceStatus;

    my $status_app = Plack::App::ServiceStatus->new(
        app           => 'your app',
        version       => '1.42',
        DBIC          => [ $schema, 'select 1' ],
        Elasticsearch => $es, # instance of Search::Elasticsearch
    );

    builder {
      mount "/_status" => $status_app;
      mount "/" => $your_app;
    };


    # using OX
    router as {
        mount '/_status' => 'Plack::App::ServiceStatus' => (
            app                     => literal(__PACKAGE__),
            Redis                   => 'redis',
            '+MyApp::ServiceStatus' => {
                  foo => literal("foo")
            },
        );
        route '/some/endpoint' => 'some_controller.some_action';
        # ...
    };


    # checking the status
    curl http://localhost:3000/_status | json_pp
    {
       "app" : "Your app",
       "version": "1.42",
       "started_at" : 1465823638,
       "uptime" : 42,
       "checks" : [
          {
             "status" : "ok",
             "name" : "Your app"
          },
          {
             "name" : "Elasticsearch",
             "status" : "ok"
          },
          {
             "name" : "DBIC",
             "status" : "ok"
          }
       ]
    }

# DESCRIPTION

`Plack::App::ServiceStatus` implements a small
[Plack](https://metacpan.org/pod/Plack) application that you can use
to get some status info about your application and the services needed by
it.

You can then use some monitoring software to periodically check if
your app is running and has access to all needed services.

## Options to new

- version

    Set the version of your app.

- show\_hostname

    If set to a true value, show the hostname.

## Checks

The following checks are currently available:

- [Plack::App::ServiceStatus::DBI](https://metacpan.org/pod/Plack%3A%3AApp%3A%3AServiceStatus%3A%3ADBI) - (raw DBI `$dbh`)
- [Plack::App::ServiceStatus::DBIxConnector](https://metacpan.org/pod/Plack%3A%3AApp%3A%3AServiceStatus%3A%3ADBIxConnector) - when using `DBIx::Connector` to connect to a DB
- [Plack::App::ServiceStatus::DBIC](https://metacpan.org/pod/Plack%3A%3AApp%3A%3AServiceStatus%3A%3ADBIC) - when you're using `DBIx::Class`
- [Plack::App::ServiceStatus::Redis](https://metacpan.org/pod/Plack%3A%3AApp%3A%3AServiceStatus%3A%3ARedis)
- [Plack::App::ServiceStatus::Elasticsearch](https://metacpan.org/pod/Plack%3A%3AApp%3A%3AServiceStatus%3A%3AElasticsearch)
- [Plack::App::ServiceStatus::NetStomp](https://metacpan.org/pod/Plack%3A%3AApp%3A%3AServiceStatus%3A%3ANetStomp)

Each check consists of a `name` and a `status`. The status can be
`ok` or `nok`. A check might also contain a `message`, which should
be some description of the error or problem if the status is `nok`.

Each check has to implement a method named `check` which will be
called with name of the class and the arguments you specified when
setting up `Plack::App::ServiceStatus`. `check` has to return either
the string `ok`, or the string `nok` and a string containing an
explanation.

You can add your own checks by specifying a name starting with a `+`
sign, for example `+My::App::SomeStatusCheck`. Or send me a pull
request to include your check in this distribution, or just release it
yourself!

## Weirdness

The slightly strange way `Plack::App::ServiceStatus` is initiated is caused
by the way [OX](https://metacpan.org/pod/OX) works.

`Plack::App::ServiceStatus` is **not** implemented as a middleware on
purpose. While middlewares are great for a lot of use cases, I think
that here an embedded app is the better fit.

# TODO

- tests
- make sure the app is only initiated once when running in OX

# THANKS

Thanks to

- [validad.com](http://www.validad.com/) for funding the
development of this code.
- <Manfred Stock|https://github.com/mstock> for adding
Net::Stomp and a Icinga/Nagios check script.

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2022 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
