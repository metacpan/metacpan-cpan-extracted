# NAME

Mojolicious::Plugin::SessionStore - session data store plugin for Mojolicious

# SYNOPSIS

    use Mojolicious::Lite;
    use Plack::Session::Store::File;

    plugin SessionStore => Plack::Session::Store::File->new;

# DESCRIPTION

Mojolicious::Plugin::SessionStore is a session data store plugin for Mojolicious. It creates [Mojolicious::Sessions::Storable](https://metacpan.org/pod/Mojolicious::Sessions::Storable) instance with provided session data store instance.

# OPTIONS

Mojolicious::Plugin::SessionStore accepts all options of [Mojolicious::Sessions::Storable](https://metacpan.org/pod/Mojolicious::Sessions::Storable).

If a single option is provided, which is expected to be an option of [Mojolicious::Sessions::Storable](https://metacpan.org/pod/Mojolicious::Sessions::Storable)@session\_store.

If no option is provided the default <Mojolicious::Session> will be used.

# METHODS

Mojolicious::Plugin::SessionStore inherits all methods from [Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin).

# AUTHOR

hayajo <hayajo@cpan.org>

# COPYRIGHT

Copyright 2013- hayajo

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojolicious::Sessions](https://metacpan.org/pod/Mojolicious::Sessions), [Mojolicious::Sessions::Storable](https://metacpan.org/pod/Mojolicious::Sessions::Storable), [Plack::Middleware::Session](https://metacpan.org/pod/Plack::Middleware::Session)
