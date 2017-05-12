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

# minicard - http://www.moo.com/api/examples/0.7/xml/minicard.xml

my @minicards = (
                 {'url' => 'http://farm3.static.flickr.com/2290/2178246751_a5124fdbc7_o.jpg',
                  'text' => [{'id' => 1, 'string' => 'This is line 1'},
                             {'id' => 2, 'string' => 'This is line 2'},
                             {'id' => 3, 'string' => 'This is line 3'},
                             {'id' => 4, 'string' => 'This is line 4'},
                             {'id' => 5, 'string' => 'This is line 5'},
                             {'id' => 6, 'string' => 'This is line 6'},
                            ]},
                 
                 {'url' => 'http://farm3.static.flickr.com/2300/2179038972_23d2a1ff40_o.jpg',
                  'text' => [{'id' => 1, 'string' => 'Bold / left / modern / red', 'bold' => 'true', 'align' => 'left', 'font' => 'modern', 'colour' => '#ff0000'},
                             {'id' => 2, 'string' => 'normal / center / traditional / green', 'bold' => 'false', 'align' => 'center', 'font' => 'traditional', 'colour' => '#00ff00'},
                             {'id' => 3, 'string' => 'bold / right / typewriter / blue', 'bold' => 'true', 'align' => 'right', 'font' => 'typewriter', 'colour' => '#0000ff'},
                             {'id' => 4, 'string' => 'normal / left / modern / yellow', 'bold' => 'false', 'align' => 'left', 'font' => 'modern', 'colour' => '#fff000'},
                             {'id' => 5, 'string' => 'bold / center / traditional / purple', 'bold' => 'true', 'align' => 'center', 'font' => 'traditional', 'colour' => '#ff00ff'},
                             {'id' => 6, 'string' => 'normal / right / typewriter / cyan', 'bold' => 'false', 'align' => 'right', 'font' => 'typewriter', 'colour' => '#00ffff'},
                            ]},

                 {'url' => 'http://farm3.static.flickr.com/2266/2178246585_14139d6905_o.jpg'},
                );

my $xml = $moo->builder('minicard', \@minicards);

my $digest = Digest::MD5->new();
$digest->add($xml);
my $hex = $digest->hexdigest();

cmp_ok($hex, 'eq', 'e86e3034372cbdd51455df376204fed9', $hex);

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
