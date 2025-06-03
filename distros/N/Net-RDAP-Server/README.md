# NAME

Net::RDAP::Server - an RDAP server framework.

# VERSION

version 0.05

# SYNOPSIS

    use Net::RDAP::Server;

    my $server = Net::RDAP::Server->new;

    #
    # Set request handlers for the types we want to support.
    #
    $server->set_handler(GET  => 'help',   \&get_help);
    $server->set_handler(HEAD => 'help',   \&head_help);
    $server->set_handler(GET  => 'domain', \&get_domain);
    $server->set_handler(HEAD => 'domain', \&head_domain);

    #
    # Run the server (on localhost:8080 by default).
    #
    $server->run;

    #
    # Minimal HEAD handler. All responses are 404 by default so the ok() method
    # must be used to send a 200 response.
    #
    sub head_help { shift->ok }

    #
    # help request handler
    #
    sub get_help {
        my $response = shift;

        #
        # Set the HTTP status to 200.
        #
        $response->ok;

        #
        # Pass a Perl data structure to be encoded to JSON.
        #
        $response->content({
            rdapConformance => [q{rdap_level_0}],
            notices => [
                {
                    title => 'More Information',
                    description => [ 'For more information, see '.ABOUT_URL.'.'],
                    links => [
                        {
                            rel => 'related',
                            href => ABOUT_URL,
                            value => ABOUT_URL,
                        }
                    ],
                }
            ]
        });
    }

    #
    # Minimal HEAD handler as above.
    #
    sub head_domain { shift->ok }

    #
    # Generate a domain lookup response.
    #
    sub get_domain {
        my $response = shift;

        $response->ok;

        $response->content({
            objectClassName => q{domain},
            ldhName => $response->request->object,
            #
            # Add more properties here!
            #
        });
    }

# DESCRIPTION

[Net::RDAP::Server](https://metacpan.org/pod/Net%3A%3ARDAP%3A%3AServer) implements a simple framework for creating RDAP servers.
RDAP is the Registration Data Access Protocol, which is specified in [IETF STD
95](https://datatracker.ietf.org/doc/std95/).

# METHODS

[Net::RDAP::Server](https://metacpan.org/pod/Net%3A%3ARDAP%3A%3AServer) inherits from [HTTP::Server::Simple::CGI](https://metacpan.org/pod/HTTP%3A%3AServer%3A%3ASimple%3A%3ACGI) so all the
options and methods of that module are available. In addition, the following
methods are provided.

## set\_handler($method, $type, $callback)

This method specifies a callback to be executed when a `$method` (either
`GET` or `HEAD`) request for a `$type` RDAP resource (e.g `domain`,
`ip`, etc) is requested. At minimum RDAP servers should provide answer `help`
requests plus one or more object types.

`$type` must be one of:

- `help`
- `domain`
- `nameserver`
- `entity`
- `ip`
- `autnum`
- `domains`
- `nameservers`
- `entities`

The callback will be passed a [Net::RDAP::Server::Response](https://metacpan.org/pod/Net%3A%3ARDAP%3A%3AServer%3A%3AResponse) that it must then
manipulate in order to produce the desired response.

# SEE ALSO

- [Net::RDAP::Server::EPPBackend](https://metacpan.org/pod/Net%3A%3ARDAP%3A%3AServer%3A%3AEPPBackend) - an RDAP server that retrieves
registration data from an EPP server.

# AUTHOR

Gavin Brown <gavin.brown@fastmail.uk>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gavin Brown.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
