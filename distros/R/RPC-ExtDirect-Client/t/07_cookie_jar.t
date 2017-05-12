# Test cookie conversion methods

use strict;
use warnings;

use Test::More tests => 2;

use RPC::ExtDirect::Test::Util;

use RPC::ExtDirect::Client;

my $cclass = 'RPC::ExtDirect::Client';

my $expected = {
    headers => {
        Cookie => [
            'bar=baz',
            'foo=bar',
        ],
    },
};

SKIP: {
    skip "Need HTTP::Cookies", 1 unless eval "require HTTP::Cookies";

    my $cookie_jar = HTTP::Cookies->new;

    $cookie_jar->set_cookie(1, 'foo', 'bar', '/', '');
    $cookie_jar->set_cookie(1, 'bar', 'baz', '/', '');

    my $options = {};
    my $params  = { cookies => $cookie_jar };

    $cclass->_parse_cookies($options, $params);

    $options->{headers}->{Cookie}
        = [ sort @{ $options->{headers}->{Cookie} } ];

    is_deep $options, $expected, "HTTP::Cookies parsing";
}

my $options = {};
my $params  = { cookies => { foo => 'bar', bar => 'baz' } };

$cclass->_parse_cookies($options, $params);

$options->{headers}->{Cookie}
    = [ sort @{ $options->{headers}->{Cookie} } ];

is_deep $options, $expected, "Raw cookies parsing";

