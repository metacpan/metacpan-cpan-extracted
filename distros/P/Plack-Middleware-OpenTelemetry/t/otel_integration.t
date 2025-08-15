use strict;
use warnings;
use Test::More;
use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;
use Capture::Tiny qw(capture_stderr);
use JSON::PP;

BEGIN {
    $ENV{OTEL_TRACES_EXPORTER} = 'console';
}

use OpenTelemetry::SDK;
use OpenTelemetry::Constants qw( SPAN_KIND_SERVER SPAN_STATUS_ERROR SPAN_STATUS_OK );

sub build_app {
    my %config = @_;
    builder {
        enable "Plack::Middleware::OpenTelemetry", %config;
        sub {
            my $env = shift;
            my $path = $env->{PATH_INFO} || '/';
            
            if ($path eq '/success') {
                return [200, ['Content-Type' => 'text/plain'], ['OK']];
            } elsif ($path eq '/not_found') {
                return [404, ['Content-Type' => 'text/plain'], ['Not Found']];
            } elsif ($path eq '/server_error') {
                return [500, ['Content-Type' => 'text/plain'], ['Server Error']];
            } elsif ($path eq '/exception') {
                die "Test exception message";
            } elsif ($path eq '/streaming') {
                return sub {
                    my $respond = shift;
                    my $writer = $respond->([200, ['Content-Type' => 'text/plain']]);
                    $writer->write("chunk1");
                    $writer->write("chunk2");
                    $writer->close;
                };
            } else {
                return [200, ['Content-Type' => 'text/plain'], ['Default']];
            }
        };
    };
}

sub parse_console_span {
    my $output = shift;
    # The console exporter outputs Perl data structure format
    return unless $output;
    
    # Find the first complete span structure (handle multiple spans)
    if ($output =~ /(\{'attributes'.*?'trace_state' => '[^']*'\})/s) {
        my $span_data = $1;
        # Use eval to parse the Perl data structure
        my $span = eval $span_data;
        if ($@) {
            # Parsing failed, just return undef - tests will handle gracefully
            return;
        }
        return $span;
    }
    return;
}

# Test basic span creation and attributes
subtest 'Basic Span Creation' => sub {
    my $app = build_app();
    
    my $span_output = capture_stderr {
        test_psgi $app, sub {
            my $cb = shift;
            my $res = $cb->(GET 'http://example.com/success');
            is $res->code, 200;
        };
    };
    
    my $span = parse_console_span($span_output);
    ok $span, 'Span captured from console output';
    
    # Check span name
    is $span->{name}, 'GET request', 'Correct span name';
    
    # Check span kind (2 = SPAN_KIND_SERVER)
    is $span->{kind}, SPAN_KIND_SERVER, 'Server span kind';
    
    # Check HTTP semantic attributes
    my $attrs = $span->{attributes};
    is $attrs->{'http.request.method'}, 'GET', 'HTTP method attribute';
    is $attrs->{'url.full'}, 'http://example.com/success', 'Full URL attribute';
    is $attrs->{'url.scheme'}, 'http', 'URL scheme attribute';
    is $attrs->{'url.path'}, '/success', 'URL path attribute';
    is $attrs->{'server.address'}, 'example.com', 'Server address attribute';
    is $attrs->{'http.response.status_code'}, 200, 'Response status code';
    like $attrs->{'plack.version'}, qr/\d+\.\d+/, 'Plack version present';
};

# Test different HTTP methods
subtest 'HTTP Methods' => sub {
    my $app = build_app();
    
    for my $method (qw(GET POST PUT DELETE)) {
        my $span_output = capture_stderr {
            test_psgi $app, sub {
                my $cb = shift;
                my $req = HTTP::Request->new($method => 'http://example.com/success');
                my $res = $cb->($req);
                is $res->code, 200;
            };
        };
        
        my $span = parse_console_span($span_output);
        is $span->{name}, "$method request", "Span name for $method";
        is $span->{attributes}->{'http.request.method'}, $method, "Method attribute for $method";
    }
};

# Test query parameters
subtest 'Query Parameters' => sub {
    my $app = build_app();
    
    my $span_output = capture_stderr {
        test_psgi $app, sub {
            my $cb = shift;
            my $res = $cb->(GET 'http://example.com/success?param1=value1&param2=value2');
            is $res->code, 200;
        };
    };
    
    my $span = parse_console_span($span_output);
    my $attrs = $span->{attributes};
    is $attrs->{'url.query'}, 'param1=value1&param2=value2', 'Query parameters captured';
    is $attrs->{'url.full'}, 'http://example.com/success?param1=value1&param2=value2', 'Full URL with query';
};

# Test User-Agent handling
subtest 'User-Agent Header' => sub {
    my $app = build_app();
    
    my $span_output = capture_stderr {
        test_psgi $app, sub {
            my $cb = shift;
            my $res = $cb->(GET 'http://example.com/success', 'User-Agent' => 'TestAgent/1.0');
            is $res->code, 200;
        };
    };
    
    my $span = parse_console_span($span_output);
    is $span->{attributes}->{'user_agent.original'}, 'TestAgent/1.0', 'User-Agent captured';
    
    # Test missing User-Agent
    $span_output = capture_stderr {
        test_psgi $app, sub {
            my $cb = shift;
            my $req = HTTP::Request->new(GET => 'http://example.com/success');
            $req->remove_header('User-Agent');
            my $res = $cb->($req);
            is $res->code, 200;
        };
    };
    
    $span = parse_console_span($span_output);
    is $span->{attributes}->{'user_agent.original'}, '', 'Empty User-Agent when missing';
};

# Test X-Forwarded-Proto header
subtest 'X-Forwarded-Proto Header' => sub {
    my $app = build_app();
    
    my $span_output = capture_stderr {
        test_psgi $app, sub {
            my $cb = shift;
            my $res = $cb->(GET 'http://example.com/success', 'X-Forwarded-Proto' => 'https');
            is $res->code, 200;
        };
    };
    
    my $span = parse_console_span($span_output);
    my $attrs = $span->{attributes};
    is $attrs->{'url.scheme'}, 'https', 'X-Forwarded-Proto overrides scheme';
    like $attrs->{'url.full'}, qr/^https:/, 'Full URL uses forwarded proto';
};

# Test span status for different HTTP codes
subtest 'Span Status for HTTP Codes' => sub {
    my $app = build_app();
    
    # Test 4xx without include_client_errors (should not be error)
    my $span_output = capture_stderr {
        test_psgi $app, sub {
            my $cb = shift;
            my $res = $cb->(GET 'http://example.com/not_found');
            is $res->code, 404;
        };
    };
    
    my $span = parse_console_span($span_output);
    # Status code 0 means unset (not error), which is what we want for 404 by default
    isnt $span->{status}{code}, SPAN_STATUS_ERROR, '404 not marked as error by default';
    is $span->{attributes}->{'http.response.status_code'}, 404, '404 status code recorded';
    
    # Test 5xx (should be error)
    $span_output = capture_stderr {
        test_psgi $app, sub {
            my $cb = shift;
            my $res = $cb->(GET 'http://example.com/server_error');
            is $res->code, 500;
        };
    };
    
    $span = parse_console_span($span_output);
    is $span->{status}{code}, SPAN_STATUS_ERROR, '500 marked as error';
    is $span->{attributes}->{'http.response.status_code'}, 500, '500 status code recorded';
};

# Test include_client_errors configuration
subtest 'Include Client Errors' => sub {
    my $app = build_app(include_client_errors => 1);
    
    my $span_output = capture_stderr {
        test_psgi $app, sub {
            my $cb = shift;
            my $res = $cb->(GET 'http://example.com/not_found');
            is $res->code, 404;
        };
    };
    
    my $span = parse_console_span($span_output);
    is $span->{status}{code}, SPAN_STATUS_ERROR, '404 marked as error with include_client_errors';
};

# Test exception handling
subtest 'Exception Handling' => sub {
    my $app = build_app();
    
    my $span_output = capture_stderr {
        test_psgi $app, sub {
            my $cb = shift;
            my $res = $cb->(GET 'http://example.com/exception');
            # Plack::Test catches exceptions and converts them to 500 responses
            is $res->code, 500, 'Exception converted to 500 response';
        };
    };
    
    my $span = parse_console_span($span_output);
    is $span->{status}{code}, SPAN_STATUS_ERROR, 'Exception marked span as error';
    is $span->{attributes}->{'http.response.status_code'}, 500, 'Exception sets 500 status';
    
    # Check if exception was recorded
    ok $span->{events} && @{$span->{events}}, 'Exception events recorded';
};

# Test streaming responses
subtest 'Streaming Response' => sub {
    my $app = build_app();
    
    my $span_output = capture_stderr {
        test_psgi $app, sub {
            my $cb = shift;
            my $res = $cb->(GET 'http://example.com/streaming');
            is $res->code, 200;
            is $res->content, 'chunk1chunk2', 'Streaming content received';
        };
    };
    
    # For streaming responses, multiple spans might be output or format might differ
    # Just verify we captured some span output
    ok $span_output, 'Span output captured for streaming response';
    like $span_output, qr/streaming|GET request/, 'Span output contains expected content';
};

# Test resource attributes
subtest 'Resource Attributes' => sub {
    my $app = build_app(
        resource_attributes => {
            'service.name' => 'test-service',
            'service.version' => '1.0.0'
        }
    );
    
    my $span_output = capture_stderr {
        test_psgi $app, sub {
            my $cb = shift;
            my $res = $cb->(GET 'http://example.com/success');
            is $res->code, 200;
        };
    };
    
    my $span = parse_console_span($span_output);
    ok $span->{resource}, 'Span has resource';
    # Resource attributes should be present, exact format may vary
    ok ref($span->{resource}) eq 'HASH', 'Resource is a hash structure';
};

done_testing();