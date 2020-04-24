# NAME

[Mojolicious::Plugin::ExceptionSentry](https://metacpan.org/pod/Mojolicious::Plugin::ExceptionSentry) - Sentry Plugin for Mojolicious

# SYNOPSIS

    # Mojolicious::Lite
    plugin 'ExceptionSentry' => {
        sentry_dsn => 'https://<publickey>:<secretkey>@sentry.io/<projectid>'
    };
    
    # Mojolicious
    $self->plugin('ExceptionSentry' => {
        sentry_dsn => 'https://<publickey>:<secretkey>@sentry.io/<projectid>'                          
    });
    
# DESCRIPTION

[Mojolicious::Plugin::ExceptionSentry](https://metacpan.org/pod/Mojolicious::Plugin::ExceptionSentry) is a plugin for [Mojolicious](https://metacpan.org/pod/Mojolicious), 
This module auto-send all exceptions from [Mojolicious](https://metacpan.org/pod/Mojolicious) for Sentry.

# OPTIONS

[Mojolicious::Plugin::ExceptionSentry](https://metacpan.org/pod/Mojolicious::Plugin::ExceptionSentry) supports the following options.

## sentry_dsn 

    plugin 'ExceptionSentry' => {
        sentry_dsn => 'DSN'
    };
    
The DSN for your sentry service. Get this from the client configuration page for your project.

## timeout  

    plugin 'ExceptionSentry' => {
        sentry_dsn => 'DSN',
        timeout    => 5
    };

Do not wait longer than this number of seconds when attempting to send an event.

# SEE ALSO

[Sentry::Raven](https://metacpan.org/pod/Sentry::Raven),
[Mojolicious](https://metacpan.org/pod/Mojolicious),
https://mojolicious.org.

# AUTHOR

Lucas Tiago de Moraes `lucastiagodemoraes@gmail.com`

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Lucas Tiago de Moraes.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
