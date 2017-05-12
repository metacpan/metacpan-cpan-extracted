use strict;
use warnings;
use v5.10.1;
use Test::More;
use Test::Warn;
use Plack::Test;
use HTTP::Request::Common;

use Plack::App::DAIA;

sub test_client (@) {
    my ($config, @tests) = @_;
    my $app = Plack::App::DAIA->new( %$config );

    test_psgi $app, sub {
        my $cb  = shift;

        foreach my $t (@tests) {
            my $path   = shift @$t;
            my $like   = \&like;
            if ($t->[0] eq '!') { $like = \&unlike; shift @$t; }
            my $regexp = shift @$t;
            my $name   = shift @$t;

            my $res = $cb->(GET $path);
            $like->($res->content, $regexp, $name);
        }
    };
}

test_client { } => [
    '/',
    qr{<\?xml-stylesheet type="text/xsl" href="daia\.xsl"\?>}m,
    "default client"
];

test_client { xslt => 0 } => [
    '/',
    '!' => qr{<\?xml-stylesheet type="text/xsl" href="daia\.xsl"\?>}m,
    "disabled client"
];

test_client { xslt => 1 } => [
    '',
    qr{<\?xml-stylesheet type="text/xsl" href="daia\.xsl"\?>}m,
    "default client"
], [
    '/daia.xsl',
   qr{xsl:stylesheet}m, 
   "client provided"
];

test_client { xslt => 'foo.xsl' } => [
    "/",
    qr{<\?xml-stylesheet type="text/xsl" href="foo\.xsl"\?>}m,
    "custom client"
], [
    '/foo.xsl',
    qr{<daia}m, 
    "no client provided" # TODO: return 404 instead?
];

done_testing;
