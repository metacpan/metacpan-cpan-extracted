package # hide from PAUSE 
    MockHTTPTiny;

# Test helper module to mock HTTP::Tiny responses
# Provides deterministic HTTP responses for testing without external dependencies

use strict;
use warnings;

sub new { 
    bless {}, shift;
}

sub request {
    my ($self, $method, $url, $options) = @_;
    
    # Mock successful response for MetaCPAN
    if ($url =~ /metacpan\.org/) {
        return {
            success => 1,
            status => 200,
            reason => 'OK',
            headers => {'content-type' => 'text/html'},
            content => '<html><body>Net::Azure search results</body></html>'
        };
    }
    
    # Mock 404 response for notification-hub (singular)
    if ($url =~ /notification-hub\/$/) {
        return {
            success => 0,
            status => 404,
            reason => 'not found',
            headers => {'content-type' => 'text/html'},
            content => '<html><body>404 Not Found</body></html>'
        };
    }
    
    # Default successful response
    return {
        success => 1,
        status => 200,
        reason => 'OK',
        headers => {'content-type' => 'text/html'},
        content => '<html><body>Default response</body></html>'
    };
}

1;
