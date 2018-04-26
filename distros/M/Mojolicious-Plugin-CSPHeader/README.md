# NAME

Mojolicious::Plugin::CSPHeader - Mojolicious Plugin to add Content-Security-Policy header to every HTTP response.

# SYNOPSIS

    # Mojolicious
    $self->plugin('CSPHeader', csp => "default-src 'none'; font-src 'self'; img-src 'self' data:; style-src 'self'");

    # Mojolicious::Lite
    plugin 'CSPHeader', csp => "default-src 'none'; font-src 'self'; img-src 'self' data:; style-src 'self'";

# DESCRIPTION

[Mojolicious::Plugin::CSPHeader](https://metacpan.org/pod/Mojolicious::Plugin::CSPHeader) is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin which adds Content-Security-Policy header to every HTTP response.

To know what should be the CSP header to add to your site, you can use this Firefox addon: [https://addons.mozilla.org/fr/firefox/addon/laboratory-by-mozilla/](https://addons.mozilla.org/fr/firefox/addon/laboratory-by-mozilla/).

[https://content-security-policy.com/](https://content-security-policy.com/) provides a good documentation about CSP.

[https://report-uri.com/home/generate](https://report-uri.com/home/generate) provides a tool to generate a CSP header.

# METHODS

[Mojolicious::Plugin::CSPHeader](https://metacpan.org/pod/Mojolicious::Plugin::CSPHeader) inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin) and implements the following new ones.

## register

    $plugin->register(Mojolicious->new);

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# BUGS and SUPPORT

The latest source code can be browsed and fetched at:

    https://framagit.org/luc/mojolicious-plugin-cspheader
    git clone https://framagit.org/luc/mojolicious-plugin-cspheader.git

Bugs and feature requests will be tracked at:

    https://framagit.org/luc/mojolicious-plugin-cspheader/issues

# AUTHOR

    Luc DIDRY
    CPAN ID: LDIDRY
    ldidry@cpan.org
    https://fiat-tux.fr/

# COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

# SEE ALSO

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojolicious::Guides](https://metacpan.org/pod/Mojolicious::Guides), [http://mojolicious.org](http://mojolicious.org), [https://www.w3.org/TR/CSP/](https://www.w3.org/TR/CSP/)
