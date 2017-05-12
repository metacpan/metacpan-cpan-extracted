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

# greetingcard - http://www.moo.com/api/examples/0.7/xml/greetingcard.xml

my @greetingcards = (
                     {'url' => 'http://farm3.static.flickr.com/2290/2178246751_a5124fdbc7_o.jpg',
                      'text' => {'main' => [
                                            {'string' => qq(Stencil in the middle (blue)), 'align' => 'center', 'font' => 'stencil', 'colour' => '#0000ff'},
                                ]},
                     },

                     {'url' => 'http://farm3.static.flickr.com/2300/2179038972_23d2a1ff40_o.jpg',
                      'text' => {'main' => [
                                            {'string' => qq(Script to the right (red)), 'align' => 'right', 'font' => 'script', 'colour' => '#ff0000'}
                                           ],
                                 'back' => [
                                            {'id' => 1, 'string' => qq(Can has cheese burger?)}
                                            ]},
                     },
                     
                     {'url' => 'http://farm3.static.flickr.com/2266/2178246585_14139d6905_o.jpg',
                      'text' => {'main' => [
                                            {'string' => qq(Rounded in the middle (light)), 'align' => 'center', 'font' => 'rounded', 'colour' => '#ddeedd'},
                                           ],
                                 'back' => [
                                            {'id' => 2, 'string' => qq(line2)},
                                            {'id' => 3, 'string' => qq(line3)},
                                            {'id' => 4, 'string' => qq(line4), 'colour' => '#ff0000'},
                                           ]},
                     },
                    );

my $xml = $moo->builder('greetingcard', \@greetingcards);
# diag($xml);

my $digest = Digest::MD5->new();
$digest->add($xml);
my $hex = $digest->hexdigest();

cmp_ok($hex, 'eq', '69453e4dd59af429ae6fa0ba08f9842c', $hex);

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
