# SYNOPSIS

    package My::Proxy::Server;
    use base qw(Net::EPP::MITMProxy);

    sub rewrite_command {
        my ($self, $xml) = @_;

        # do something to $xml here

        return $xml;
    }

    #
    # note: $command_xml contains the original unmodified command from the
    # client, not the rewritten command
    #
    sub rewrite_response {
        my ($self, $response_xml, $command_xml) = @_;

        # do something to $response_xml here

        return $response_xml;
    }

    __PACKAGE__->new->run(%OPTIONS);

# INTRODUCTION

This module implements an EPP proxy server that acts as a machine-in-the-middle
between client and server, and allows EPP command and response frames to be
modified in-flight.

# OPTIONS

This module inherits from [Net::Server::Prefork](https://metacpan.org/pod/Net%3A%3AServer%3A%3APrefork) and so supports all of that
module's options, in addition to the following:

- `remote_server` - the remote EPP server name.
- `remote_port` - the remote EPP server port (default 700).
- `remote_key` - (OPTIONAL) the private key to use to connect to the
remote server.
- `remote_cert` - (OPTIONAL) the certificate to use to connect to the
remote server.

Note that a limitation of the current approach is that it is not possible to
connect to the remote server using a client certificate determined by the
identity of the client.

# REWRITING COMMANDS

To rewrite EPP commands before they're sent to the remote server, you must
implement your own `rewrite_command()` method.

    sub rewrite_command {
        my ($self, $xml) = @_;

        # do something to $xml here

        return $xml;
    }

The `rewrite_command()` method is passed a scalar containing the XML received
from the client, and should return the modified command XML.

# REWRITING RESPONSES

To rewrite EPP commands before they're sent to the remote server, you must
implement your own `rewrite_response()` method.

    sub rewrite_response {
        my ($self, $response_xml, $command_xml) = @_;

        # do something to $response_xml here

        return $response_xml;
    }

The `rewrite_response()` method is passed both the original command XML from the
client, and the response XML from the remote server, and should return the
modified response XML.
