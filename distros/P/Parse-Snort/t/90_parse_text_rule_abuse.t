#!perl -T

use Test::More qw(no_plan);
use Data::Dumper;

BEGIN {
	use_ok( 'Parse::Snort' );
}

my $text_rule_abuse = '    alert    tcp     $EXTERNAL_NET   $HTTP_PORTS    ->   $HOME_NET    any   ( msg : "WEB-CLIENT Windows Scripting Host Shell ActiveX CLSID access"  ;     flow : established,to_client;   content:"F935DC22-1CF0-11D0-ADB9-00C04FD58A0B";  nocase ;pcre:"/<OBJECT\s+[^>]*classid\s*=\s*[\x22\x27]?\s*clsid\s*\x3a\s*\x7B?\s*F935DC22-1CF0-11D0-ADB9-00C04FD58A0B/si";reference:bugtraq,1399 ; )  ';

my $text_rule_data = {
                  'src_port' => '$HTTP_PORTS',
                  'proto' => 'tcp',
                  'src' => '$EXTERNAL_NET',
                  'dst_port' => 'any',
                  'direction' => '->',
                  'action' => 'alert',
                  'opts' => [
                              [
                                'msg',
                                '"WEB-CLIENT Windows Scripting Host Shell ActiveX CLSID access"'
                              ],
                              [
                                'flow',
                                'established,to_client'
                              ],
                              [
                                'content',
                                '"F935DC22-1CF0-11D0-ADB9-00C04FD58A0B"'
                              ],
                              [
                                'nocase'
                              ],
                              [
                                'pcre',
                                '"/<OBJECT\\s+[^>]*classid\\s*=\\s*[\\x22\\x27]?\\s*clsid\\s*\\x3a\\s*\\x7B?\\s*F935DC22-1CF0-11D0-ADB9-00C04FD58A0B/si"'
                              ],
                              [
                                'reference',
                                'bugtraq,1399'
                              ]
                            ],
                  'dst' => '$HOME_NET'
                };

my $obj_1 = Parse::Snort->new($text_rule_abuse);

is_deeply($obj_1,$text_rule_data,"parse whitespace abusive text rule");
