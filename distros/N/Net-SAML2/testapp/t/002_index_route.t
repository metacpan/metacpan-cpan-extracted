use Test::More;
use strict;
use warnings;

# the order is important
use Saml2Test;
use Dancer::Test;

route_exists [GET => '/'], 'a route handler is defined for /';
response_status_is ['GET' => '/'], 200, 'response status is 200 for /';
response_content_like [GET => '/'], qr/Log In/s,
    'content looks OK for /';

done_testing;
