[![Build Status](https://travis-ci.org/karupanerura/Plack-App-Vhost.svg?branch=master)](https://travis-ci.org/karupanerura/Plack-App-Vhost)
# NAME

Plack::App::Vhost - Simple virtual host implementation on Plack.

# SYNOPSIS

    use Plack::App::Vhost;

    Plack::App::Vhost->new(
       vhosts => [
          qr/^foo-mode\.my-app/ => $foo_app,
          qr/^bar-mode\.my-app/ => $bar_app,
       ],
       fallback => sub {
           my $env = shift;
           open my $fh, '<', 'path/to/404.html';
           return [404, ['Content-Type' => 'text/html', 'Content-Length' => -s $fh], [$fh]];
       },
    )->to_app;

# DESCRIPTION

Plack::App::Vhost is virtual host implementation on Plack.

# METHODS

- my $vhost = Plack::App::Vhost->new(\\%args)

    Creates a new Plack::App::Vhost instance.
    Arguments can be:

    - `vhosts`

        Specify regex and PSGI application pairs in order of preference.
        If `HTTP_HOST` matches to the regexp, Executes PSGI application of the pair.

    - `fallback`

        Specify fallback PSGI application.
        If `HTTP_HOST` does not match to any regexp, Executes fallback PSGI application.

- $vhost->to\_app()

    Creates as a PSGI application.

# SEE ALSO

[Plack::App::HostMap](https://metacpan.org/pod/Plack::App::HostMap)

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura <karupa@cpan.org>
