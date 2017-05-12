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

# postcard - http://www.moo.com/api/examples/0.7/xml/postcard.xml

my @postcards = (
                 {'url' => 'http://farm3.static.flickr.com/2290/2178246751_a5124fdbc7_o.jpg',
                  'text' => [{'id' => 'main', 'string' => qq(I am the main box of text

I can have all kinds of things
going on in me!)},
                             {'id' => 'bottom', 'string' => qq(And I'm the text at the bottom)},
                            ]},
                 
                 {'url' => 'http://farm3.static.flickr.com/2300/2179038972_23d2a1ff40_o.jpg',
                  'text' => [{'id' => 'main', 'string' => qq(I am blue, center aligned and
                              bold text. Don't look at me, I'm
                              shy! I'm in the main text body), 'bold' => 'true', 'align' => 'center', 'font' => 'typewriter', 'colour' => '#0000ff'},
                            ]},

                 {'url' => 'http://farm3.static.flickr.com/2266/2178246585_14139d6905_o.jpg',
                  'text' => [{'id' => 'bottom', 'string' => qq(And I'm the text at the bottom.
                              I'm green and aligned right
), 'bold' => 'true', 'align' => 'right', 'colour' => '#00ff00'},
                             ]},
                );

my $xml = $moo->builder('postcard', \@postcards);
# diag($xml);

my $digest = Digest::MD5->new();
$digest->add($xml);
my $hex = $digest->hexdigest();

cmp_ok($hex, 'eq', 'd0f4d0f47227d31072e86ed4deac168b', $hex);

#

TODO: {
        local $TODO = "network connection may not be present";

        my $valid = Net::Moo::Validate->new();
        my $report = $valid->report($xml);
        # diag(Dumper($report));

        my $ok = $valid->is_valid_xml($report);
        cmp_ok($ok, '==', 1, 'Valid XML');

        my $res = $moo->execute_request($xml);
        isa_ok($res, "HTTP::Response");

        my $rsp = $moo->parse_response($res);
        isa_ok($rsp, "XML::XPath::Node");

        my $url = $rsp->findvalue("start_url");
        ok($url, $url);
}
