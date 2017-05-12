# -*-cperl-*-

use strict;
use Test::More;
use Data::Dumper;

plan tests => 8;

use_ok("Net::Moo");
use_ok("Config::Simple");
use_ok("Digest::MD5");

my $cfg = Config::Simple->new("./example.cfg");
my $moo = Net::Moo->new('config' => $cfg);

# sticker - 

my @stickers = ({'url' => 'http://farm3.static.flickr.com/2290/2178246751_a5124fdbc7_o.jpg'},
                 {'url' => 'http://farm3.static.flickr.com/2300/2179038972_23d2a1ff40_o.jpg'},
                 {'url' => 'http://farm3.static.flickr.com/2266/2178246585_14139d6905_o.jpg'});

my $xml = $moo->builder('sticker', \@stickers);
# diag($xml);

my $digest = Digest::MD5->new();
$digest->add($xml);
my $hex = $digest->hexdigest();

cmp_ok($hex, 'eq', '72df76f34259f310361b5e17246d2ef7', $hex);

# 

TODO: {
        local $TODO = "network connection may not be present";

        my $valid = Net::Moo::Validate->new();
        my $report = $valid->report($xml);
        # diag(Dumper($report));

        my $ok = $valid->is_valid_xml($report);
        cmp_ok($ok, '==', 1, 'Valid order XML');

        my $res = $moo->execute_request($xml);
        isa_ok($res, "HTTP::Response");

        my $rsp = $moo->parse_response($res);
        isa_ok($rsp, "XML::XPath::Node");

        my $url = $rsp->findvalue("start_url");
        ok($url, $url);
}
