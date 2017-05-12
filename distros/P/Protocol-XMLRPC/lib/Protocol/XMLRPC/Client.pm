package Protocol::XMLRPC::Client;

use strict;
use warnings;

use Protocol::XMLRPC::MethodCall;
use Protocol::XMLRPC::MethodResponse;

require Carp;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    Carp::croak('http_req_cb is required') unless $self->{http_req_cb};

    return $self;
}

sub http_req_cb {
    defined $_[1] ? $_[0]->{http_req_cb} = $_[1] : $_[0]->{http_req_cb};
}

sub call {
    my $self = shift;
    my ($url, $method_name, $args, $cb, $error_cb) = @_;

    if (!defined $cb) {
        ($cb, $args) = ($args, []);
    }
    elsif (ref($args) ne 'ARRAY' && !defined $error_cb) {
        ($cb, $error_cb, $args) = ($args, $cb, []);
    }

    my $method_call = Protocol::XMLRPC::MethodCall->new(name => $method_name);
    foreach my $arg (@$args) {
        $method_call->add_param($arg);
    }

    my $host = $url;
    $host =~ s|^http(s)?://||;
    $host =~ s|/.*$||;

    my $headers = {
        'Content-Type' => 'text/xml',
        'User-Agent'   => 'Protocol-XMLRPC (Perl)',
        'Host'         => $host
    };

    $self->http_req_cb->(
        $self, $url, 'POST', $headers, "$method_call" =>
          sub {
            my ($self, $status, $headers, $body) = @_;

            unless ($status && $status == 200) {
                return $error_cb ? $error_cb->($self) : $cb->($self);
            }

            my $res = Protocol::XMLRPC::MethodResponse->parse($body);

            return $cb->($self, $res) if $res;

            return $error_cb ? $error_cb->($self) : $cb->($self);
        }
    );
}

1;
__END__

=head1 NAME

Protocol::XMLRPC::Client - Simple XML-RPC client

=head1 SYNOPSIS

    my $xmlrpc = Protocol::XMLRPC::Client->new(
        http_req_cb => sub {

            ...

            $cb->(..);
        }
    );

    $xmlrpc->call(
        'http://example.com/xmlrpc' => 'plus' => [1, 2] => sub {
            my ($self, $method_response) = @_;

            print $method_response->param->value, "\n";
        },
        sub {
            print "internal error\n";
        }
    );

=head1 DESCRIPTION

L<Protocol::XMLRPC::Client> is a simple XML-RPC client. You provide callback
subroutine for posting method requests. L<LWP>, L<AnyEvent::HTTP> etc can be used
for this purpose.

=head1 ATTRIBUTES

=head2 C<http_req_cb>

    my $xmlrpc = Protocol::XMLRPC::Client->new(
        http_req_cb => sub {
            my ($self, $url, $method, $headers, $body, $cb) = @_;

            ...

            $cb->($self, $status, $headers, $body);

A callback for sending request to the xmlrpc server. Don't forget that
User-Agent and Host headers are required by XML-RPC specification. Default
values are provided, but you are advised to change them.

Request callback is called with:

=over

=item * B<self> L<Protocol::XMLRPC::Client> instance

=item * B<url> server url (for example 'http://example.com/xmlrpc')

=item * B<method> request method

=item * B<headers> request headers hash reference

=item * B<body> request body to send. Holds L<Protocol::XMLRPC::MethodCall>
string representation.

=item * B<cb> callback that must be called after response was received

=item * B<error_cb> callback that is called on error (optional)

=back

Response callback must be called with:

=over

=item * B<self> L<Protocol::XMLRPC::Client> instance

=item * B<status> response status (200, 404 etc)

=item * B<headers> response headers hash reference

=item * B<body> response body

=back

=head1 METHODS

=head2 C<new>

    my $xmlrpc = Protocol::XMLRPC::Client->new(http_req_cb => sub { ... });

Creates L<Protocol::XMLRPC> instance. Argument B<http_req_cb> is required.

=head2 C<call>

    $xmlrpc->call(
        'http://example.com/xmlrpc' => 'plus' => [1, 2] => sub {
            my ($self, $method_response) = @_;

            ...
        }
    );

Creates L<Protocol::XMLRPC::MethodCall> object with provided parameters and
calls http_req_cb with url and body. Upon response parses and created
L<Protocol::XMLRPC::MethodResponse> object and calls provided callback.

Parameter are optional. But must be provided as an array reference. Parameters
types are guessed (more about that in L<Protocol::XMLRPC::ValueFactory>).

=cut
