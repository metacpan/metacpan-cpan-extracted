use strict;

use Test::More tests => 15;

BEGIN {
    use_ok('Plack::Middleware::XSLT');
}

use File::Touch;
use HTTP::Request::Common;
use Plack::Test;

# Simple static file server serving XML files in t/xml

my $app = sub {
    my $env = shift;

    my $xml_filename = "t/xml$env->{PATH_INFO}";
    open(my $xml_file, '<', $xml_filename) or die("$xml_filename: $!");

    local $/ = undef;
    my $xml = <$xml_file>;

    close($xml_file);

    my @headers = (
        'Content-Type'   => 'text/xml',
        'Content-Length' => length($xml),
    );

    $env->{'xslt.style'} = 'master.xsl';

    return [ 200, \@headers, [ $xml ] ];
};

# Wrap with Plack::Middleware::XSLT

my $xslt = Plack::Middleware::XSLT->new(
    cache => 1,
    path  => 't/xsl',
);
ok($xslt, 'new');

$app = $xslt->wrap($app);
ok($app, 'middleware wrap');

# Test XSLT cache

my $expected_content = <<'EOF';
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<title>Test</title>
<body>
<h1>Test</h1>
</body>
</html>
EOF

test_psgi $app, sub {
    my $cb = shift;

    my ($res, $content);

    $res = $cb->(GET "/doc.xml");
    $content = $res->decoded_content;
    # It seems that some Windows setups don't indent the result.
    $content =~ s/^\s+//gm;
    is($content, $expected_content, 'response content');
    is($res->code, 200, 'response code');
    is($res->content_type, 'text/html', 'response content type');
    is($res->content_length, length($res->content), 'response content length');
    is(lc($res->content_type_charset), 'utf-8', 'response charset');
    is($xslt->_cache_hits, 0, 'cache hits before');

    $res = $cb->(GET "/doc.xml");
    $content = $res->decoded_content;
    $content =~ s/^\s+//gm;
    is($content, $expected_content, 'response content');
    is($res->code, 200, 'response code');
    is($xslt->_cache_hits, 1, 'cache hits after');

    my $time = time() - 5;
    my $touch = File::Touch->new(
        no_create => 1,
        atime     => $time,
        mtime     => $time,
    );
    $touch->touch('t/xsl/import_import.xsl');

    $res = $cb->(GET "/doc.xml");
    $content = $res->decoded_content;
    $content =~ s/^\s+//gm;
    is($content, $expected_content, 'response content');
    is($res->code, 200, 'response code');
    is($xslt->_cache_hits, 1, 'cache hits after');
};

