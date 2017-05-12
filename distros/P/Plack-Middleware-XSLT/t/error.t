use strict;

use Test::More tests => 7;

BEGIN {
    use_ok('Plack::Middleware::XSLT');
}

use HTTP::Request::Common;
use Plack::Test;

my $app = sub {
    my $env = shift;

    my $xml = '<doc/>';

    my @headers = (
        'Content-Type' => 'text/xml',
    );

    $env->{'xslt.style'} = 'error.xsl';

    return [ 200, \@headers, [ $xml ] ];
};

# Wrap with Plack::Middleware::XSLT

my $xslt = Plack::Middleware::XSLT->new(
    path  => 't/xsl',
);
ok($xslt, 'new');

$app = $xslt->wrap($app);
ok($app, 'middleware wrap');

# Test HTTP errors from xsl:message

test_psgi $app, sub {
    my $cb = shift;

    my ($res, $content);

    $res = $cb->(GET "/doc.xml");
    is($res->decoded_content, 'Not found', 'response content');
    is($res->code, 404, 'response code');
    is($res->content_type, 'text/plain', 'response content type');
    is($res->content_length, length($res->content), 'response content length');
};

