package SimpleMock::Model::LWP_UA;
use strict;
use warnings;
use HTTP::Status qw(status_message);
use URI::QueryParam;
use URI;
use Data::Dumper;

use SimpleMock::Util qw(
    generate_args_sha
);

our $VERSION = '0.01';

sub mock_send_request {
    my ($request, $ua, $h) = @_;
    my $method = $request->method;
    my $url = $request->uri;

    # initially, only supporting 'application/x-www-form-urlencoded'
    my %request_args;
    if ($method eq 'POST') {
        my $content = $request->content;
        my $uri = URI->new("http:dummy/");  # dummy base to reuse parser
        $uri->query($content);
        %request_args = $uri->query_form;
    }
    elsif ($method eq 'GET') {
        my $uri = URI->new($request->uri);
        %request_args = $uri->query_form;
    }

    # if the request has no args, make it undef so that generate_args_sha
    # returns _default
    my $sha_arg = %request_args ? \%request_args : undef;
    my $args_sha = generate_args_sha($sha_arg);

    # remove QS from URL before lookup
    $url =~ s/\?.*//;

    for my $layer (reverse @SimpleMock::MOCK_STACK) {
        my $lwp = $layer->{LWP_UA} or next;
        my $response = $lwp->{$url}->{$method}->{$args_sha}
                    || $lwp->{$url}->{$method}->{_default};
        return $response if $response;
    }

    die "No mock is defined (nor default with no args) for url ($url), method ($method), args: " . Dumper(\%request_args);
}

sub validate_mocks {
    my $mocks_data = shift;

    my $new_mocks = {};

    URL: foreach my $url (keys %$mocks_data) {
        METHOD: foreach my $method (keys %{$mocks_data->{$url}}) {
            MOCK: foreach my $mock (@{ $mocks_data->{$url}->{$method}}) {
                my $response_arg_or_content = $mock->{response};
                my $response_arg = ref $response_arg_or_content eq 'HASH'
                                   ? $response_arg_or_content
                                   : { content => $response_arg_or_content };

                $response_arg->{code}    //= 200;
                $response_arg->{message} //= status_message($response_arg->{code});
                $response_arg->{content} //= '';
                $response_arg->{headers} //= {};

                my $response = HTTP::Response->new(
                                 $response_arg->{code},
                                 $response_arg->{message},
                                 HTTP::Headers->new( %{ $response_arg->{headers} } ),
                                 $response_arg->{content},
                               );

                my $sha = generate_args_sha($mock->{args});   
                $new_mocks->{LWP_UA}->{$url}->{$method}->{$sha} = $response;
            }
        }
    }
    return $new_mocks;
}

1;

=head1 NAME

SimpleMock::Model::LWP_UA

=head1 DESCRIPTION

This module allows you to register HTTP mocks for LWP requests, enabling you to simulate various responses for testing purposes without making actual HTTP calls.

=head1 USAGE

You probably won't use this module directly. Instead, you will use the `SimpleMock` module to register your mocks. Here's an example of how to do that:

    use SimpleMock qw(register_mocks);
    register_mocks(
        LWP_UA => {
            # URL
            'http://example.com/api' => {
                # HTTP method
                GET => [

                    # Each mock is a hashref with args and response
                    # args can be undef for default mock
                    # response can be a content string, or a hashref with code, message, content, and headers

                    { args => { foo => 'bar' },
                      response => { code => 200, content => 'Success' }
                    },

                    { args => { foo => 'bar2' },
                      response => 'Success'
                    },

                    # Default mock for GET method (no args) or for any other args not explicitly defined
                    { response => { code => 404, content => 'Not Found' } },
                ],
                POST => [
                    { args => { data => 'test' },
                      response => { code => 201, content => 'Created' }
                    },
                ],
            },
        },
    );

If args are not specified, the mock will be registered as a default mock for that URL and method.
If args are specified, they will be used to differentiate between different mocks for the same
URL and method that have different arguments.

The response can be a simple content string, or a hashref with the following keys:

=over

=item * code - HTTP status code (default: 200)
=item * message - HTTP status message (default: derived from code)
=item * content - The body of the response (default: empty string)
=item * headers - A hashref of HTTP headers to include in the response (default: empty)

=back

See the tests for more examples.

=cut
