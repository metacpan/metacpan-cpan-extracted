package Net::RDAP::Server;
# ABSTRACT: an RDAP server framework.
use Carp;
use DateTime;
use List::Util qw(any);
use Net::RDAP::Server::Request;
use Net::RDAP::Server::Response;
use URI;
use base qw(HTTP::Server::Simple::CGI);
use bytes;
use constant HTTP_VERSION => 'HTTP/1.1';
use strict;
use vars qw($VERSION @METHODS @OBJECTS @SEARCHES @TYPES);
use warnings;

$VERSION    = '0.06';
@METHODS    = qw(HEAD GET);
@OBJECTS    = qw(domain nameserver entity ip autnum);
@SEARCHES   = qw(domains nameservers entities);
@TYPES      = (q{help}, @OBJECTS, @SEARCHES);


sub set_handler {
    my ($self, $method, $type, $callback) = @_;

    croak("Invalid method '$method'") unless ($self->method_allowed($method));
    croak("Invalid type '$type'") unless ($self->type_allowed($type));

    $self->{_handlers}->{lc($type)}->{uc($method)} = $callback;
}

sub run {
    my $self = shift;

    $self->check_handlers;

    $self->SUPER::run(@_);
}

#
# This method implements the guts of this module, and implements the logic
# required to generate a response to an RDAP request.
#
sub handle_request {
    my ($self, $cgi) = @_;

    #
    # Initialise request and response objects.
    #
    my $request = Net::RDAP::Server::Request->from_cgi($cgi);
    my $response = Net::RDAP::Server::Response->new($request, $self);

    #
    # Set the Server: header on all responses.
    #
    $response->header('server' => sprintf('%s/%s', ref($self), $VERSION));

    #
    # Check the HTTP method.
    #
    if (!$self->method_allowed($request->method)) {
        $response->error(405, 'Bad Method');

    } else {
        #
        # Set the default status to 404, request handlers must override this
        #
        $response->code(404);
        $response->message('Not Found');

        #
        # Is a handler installed for this combination of type and method?
        #
        if (exists($self->{_handlers}->{$request->type})) {
            if (!exists($self->{_handlers}->{$request->type}->{$request->method})) {
                $response->error(405, 'Bad Method');

            } else {
                #
                # Wrap callbacks in eval to catch exceptions so we can send a
                # 500 response.
                #
                eval {
                    if (!$self->is_object($request->type)) {
                        #
                        # Help or search request.
                        #
                        $self->{_handlers}->{$request->type}->{$request->method}->($response);

                    } else {
                        #
                        # Object lookup.
                        #
                        if (!$request->object) {
                            #
                            # Request did not specify an object.
                            #
                            $response->error(400, 'Bad Request');

                        } else {
                            $self->{_handlers}->{$request->type}->{$request->method}->($response);

                        }
                    }
                };

                if ($@) {
                    #
                    # Log error message to STDERR.
                    #
                    print STDERR $@;

                    $response->error(500, 'Internal Server Error');
                }
            }
        }
    }

    #
    # Ensure Content-Length header is present for responses to GET requests.
    #
    $response->header('content-length' => length($response->content)) unless (q{HEAD} eq $request->method);

    #
    # Log to STDERR using the Combined Log Format.
    #
    print STDERR sprintf(
        "%s - - [%s] \"%s %s %s\" %03u %u \"%s\" \"%s\"\n",
        $cgi->remote_addr,
        DateTime->now->format_cldr('dd/MMM/YYYY:HH:mm:ss ZZZZZ'),
        $request->method,
        $request->uri->path_query,
        HTTP_VERSION,
        $response->code,
        $response->header('content-length'),
        $request->header('referer') || '',
        $request->header('user-agent') || '',
    );

    #
    # Send the response.
    #
    print HTTP_VERSION.' '.$response->as_string;
}

#
# This method returns a true value if the specified method is supported.
#
sub method_allowed {
    my ($self, $method) = @_;
    return any { $_ eq uc($method) } @METHODS;
}

#
# This method returns a true value if the specified query type is supported.
#
sub type_allowed {
    my ($self, $type) = @_;
    return any { $_ eq lc($type) } @TYPES;
}

#
# This method returns a true value if the specified query type is an object
# lookup.
#
sub is_object {
    my ($self, $type) = @_;
    return any { $_ eq lc($type) } @OBJECTS;
}

#
# This method is called by run() and will emit warnings if required request
# handlers have not been provided.
#
sub check_handlers {
    my $self = shift;

    if (!exists($self->{_handlers}->{help})) {
        carp("No handler(s) defined for 'help'");

    } else {
        foreach my $method (@METHODS) {
            carp("Missing handler for 'help' $method requests") unless (exists($self->{_handlers}->{help}->{$method}));
        }
    }

    foreach my $type (@OBJECTS) {
        if (exists($self->{_handlers}->{$type})) {
            foreach my $method (@METHODS) {
                carp("Missing handler for '$type' $method requests") unless (exists($self->{_handlers}->{$type}->{$method}));
            }
        }
    }

    foreach my $type (@SEARCHES) {
        if (exists($self->{_handlers}->{$type})) {
            carp("Missing handler for '$type' GET requests") unless (exists($self->{_handlers}->{$type}->{q{GET}}));
        }
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::RDAP::Server - an RDAP server framework.

=head1 VERSION

version 0.06

=head1 SYNOPSIS

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

=head1 DESCRIPTION

L<Net::RDAP::Server> implements a simple framework for creating RDAP servers.
RDAP is the Registration Data Access Protocol, which is specified in L<IETF STD
95|https://datatracker.ietf.org/doc/std95/>.

=head1 METHODS

L<Net::RDAP::Server> inherits from L<HTTP::Server::Simple::CGI> so all the
options and methods of that module are available. In addition, the following
methods are provided.

=head2 set_handler($method, $type, $callback)

This method specifies a callback to be executed when a C<$method> (either
C<GET> or C<HEAD>) request for a C<$type> RDAP resource (e.g C<domain>,
C<ip>, etc) is requested. At minimum RDAP servers should provide answer C<help>
requests plus one or more object types.

C<$type> must be one of:

=over

=item * C<help>

=item * C<domain>

=item * C<nameserver>

=item * C<entity>

=item * C<ip>

=item * C<autnum>

=item * C<domains>

=item * C<nameservers>

=item * C<entities>

=back

The callback will be passed a L<Net::RDAP::Server::Response> that it must then
manipulate in order to produce the desired response.

=head1 SEE ALSO

=over

=item * L<Net::RDAP::Server::EPPBackend> - an RDAP server that retrieves
registration data from an EPP server.

=back

=head1 AUTHOR

Gavin Brown <gavin.brown@fastmail.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gavin Brown.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
