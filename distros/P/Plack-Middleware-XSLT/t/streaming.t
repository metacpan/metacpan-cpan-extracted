use strict;

use Test::More tests => 6;

BEGIN {
    use_ok('Plack::Middleware::XSLT');
}

use HTTP::Request::Common;
use Plack::Test;

my $app = sub {
    my $env = shift;

    $env->{'xslt.style'} = 'identity.xsl';

    return sub {
        my $responder = shift;

        my @headers = (
            'Content-Type' => 'text/xml',
        );
        my $writer = $responder->([ 200, \@headers ]);
        $writer->write('<doc>');
        $writer->write('<elem/>');
        $writer->write('</doc>');
        $writer->close;
    };
};

# Wrap with Plack::Middleware::XSLT

my $xslt = Plack::Middleware::XSLT->new(
    path  => 't/xsl',
);
ok($xslt, 'new');

$app = $xslt->wrap($app);
ok($app, 'middleware wrap');

# Test PSGI streaming

test_psgi $app, sub {
    my $cb = shift;

    my ($res, $content);

    $res = $cb->(GET "/doc.xml");
    is($res->decoded_content, qq{<?xml version="1.0"?>\n<doc><elem/></doc>\n},
       'response content');
    is($res->code, 200, 'response code');
    is($res->content_type, 'text/xml', 'response content type');
};

