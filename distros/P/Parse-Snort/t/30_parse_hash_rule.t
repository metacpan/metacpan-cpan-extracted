#!perl -T

use Test::More tests => 18;
use Data::Dumper;

BEGIN {
	use_ok( 'Parse::Snort' );
}

my $text_rule = 'alert tcp $EXTERNAL_NET $HTTP_PORTS -> $HOME_NET any (msg:"WEB-CLIENT Windows Scripting Host Shell ActiveX CLSID access"; flow:established,to_client; content:"F935DC22-1CF0-11D0-ADB9-00C04FD58A0B"; nocase; pcre:"/<OBJECT\s+[^>]*classid\s*=\s*[\x22\x27]?\s*clsid\s*\x3a\s*\x7B?\s*F935DC22-1CF0-11D0-ADB9-00C04FD58A0B/si"; reference:bugtraq,1399; reference:bugtraq,1754; reference:bugtraq,598; reference:bugtraq,8456; reference:cve,1999-0668; reference:cve,2000-0597; reference:cve,2000-1061; reference:cve,2003-0532; reference:url,support.microsoft.com/default.aspx?scid=kb\;en-us\;Q240308; reference:url,www.microsoft.com/technet/security/bulletin/MS00-049.mspx; reference:url,www.microsoft.com/technet/security/bulletin/MS00-075.mspx; reference:url,www.microsoft.com/technet/security/bulletin/MS03-032.mspx; reference:url,www.microsoft.com/technet/security/bulletin/MS99-032.mspx; classtype:attempted-user; sid:8066; rev:1;)';

my $rule_data = {
                     'src_port' => '$HTTP_PORTS',
                     'proto' => 'tcp',
                     'src' => '$EXTERNAL_NET',
                     'dst_port' => 'any',
                     'direction' => '->',
                     'action' => 'alert',
                     'opts' => [
                                 [ 'msg', '"WEB-CLIENT Windows Scripting Host Shell ActiveX CLSID access"' ],
                                 [ 'flow', 'established,to_client' ],
                                 [ 'content', '"F935DC22-1CF0-11D0-ADB9-00C04FD58A0B"' ],
                                 [ 'nocase' ],
                                 [ 'pcre', '"/<OBJECT\\s+[^>]*classid\\s*=\\s*[\\x22\\x27]?\\s*clsid\\s*\\x3a\\s*\\x7B?\\s*F935DC22-1CF0-11D0-ADB9-00C04FD58A0B/si"' ],
                                 [ 'reference', 'bugtraq,1399' ],
                                 [ 'reference', 'bugtraq,1754' ],
                                 [ 'reference', 'bugtraq,598' ],
                                 [ 'reference', 'bugtraq,8456' ],
                                 [ 'reference', 'cve,1999-0668' ],
                                 [ 'reference', 'cve,2000-0597' ],
                                 [ 'reference', 'cve,2000-1061' ],
                                 [ 'reference', 'cve,2003-0532' ],
                                 [ 'reference', 'url,support.microsoft.com/default.aspx?scid=kb\\;en-us\\;Q240308' ],
                                 [ 'reference', 'url,www.microsoft.com/technet/security/bulletin/MS00-049.mspx' ],
                                 [ 'reference', 'url,www.microsoft.com/technet/security/bulletin/MS00-075.mspx' ],
                                 [ 'reference', 'url,www.microsoft.com/technet/security/bulletin/MS03-032.mspx' ],
                                 [ 'reference', 'url,www.microsoft.com/technet/security/bulletin/MS99-032.mspx' ],
                                 [ 'classtype', 'attempted-user' ],
                                 [ 'sid', '8066' ],
                                 [ 'rev', '1' ]
                               ],
                     'dst' => '$HOME_NET',
};

my $references = [
                                 [ 'bugtraq', '1399' ],
                                 [ 'bugtraq', '1754' ],
                                 [ 'bugtraq', '598' ],
                                 [ 'bugtraq', '8456' ],
                                 [ 'cve', '1999-0668' ],
                                 [ 'cve', '2000-0597' ],
                                 [ 'cve', '2000-1061' ],
                                 [ 'cve', '2003-0532' ],
                                 [ 'url', 'support.microsoft.com/default.aspx?scid=kb\\;en-us\\;Q240308' ],
                                 [ 'url', 'www.microsoft.com/technet/security/bulletin/MS00-049.mspx' ],
                                 [ 'url', 'www.microsoft.com/technet/security/bulletin/MS00-075.mspx' ],
                                 [ 'url', 'www.microsoft.com/technet/security/bulletin/MS03-032.mspx' ],
                                 [ 'url', 'www.microsoft.com/technet/security/bulletin/MS99-032.mspx' ],
];

my $opts_text = '(msg:"WEB-CLIENT Windows Scripting Host Shell ActiveX CLSID access"; flow:established,to_client; content:"F935DC22-1CF0-11D0-ADB9-00C04FD58A0B"; nocase; pcre:"/<OBJECT\s+[^>]*classid\s*=\s*[\x22\x27]?\s*clsid\s*\x3a\s*\x7B?\s*F935DC22-1CF0-11D0-ADB9-00C04FD58A0B/si"; reference:bugtraq,1399; reference:bugtraq,1754; reference:bugtraq,598; reference:bugtraq,8456; reference:cve,1999-0668; reference:cve,2000-0597; reference:cve,2000-1061; reference:cve,2003-0532; reference:url,support.microsoft.com/default.aspx?scid=kb\;en-us\;Q240308; reference:url,www.microsoft.com/technet/security/bulletin/MS00-049.mspx; reference:url,www.microsoft.com/technet/security/bulletin/MS00-075.mspx; reference:url,www.microsoft.com/technet/security/bulletin/MS03-032.mspx; reference:url,www.microsoft.com/technet/security/bulletin/MS99-032.mspx; classtype:attempted-user; sid:8066; rev:1;)';

my $opts = [
                                 [ 'msg', '"WEB-CLIENT Windows Scripting Host Shell ActiveX CLSID access"' ],
                                 [ 'flow', 'established,to_client' ],
                                 [ 'content', '"F935DC22-1CF0-11D0-ADB9-00C04FD58A0B"' ],
                                 [ 'nocase' ],
                                 [ 'pcre', '"/<OBJECT\\s+[^>]*classid\\s*=\\s*[\\x22\\x27]?\\s*clsid\\s*\\x3a\\s*\\x7B?\\s*F935DC22-1CF0-11D0-ADB9-00C04FD58A0B/si"' ],
                                 [ 'reference', 'bugtraq,1399' ],
                                 [ 'reference', 'bugtraq,1754' ],
                                 [ 'reference', 'bugtraq,598' ],
                                 [ 'reference', 'bugtraq,8456' ],
                                 [ 'reference', 'cve,1999-0668' ],
                                 [ 'reference', 'cve,2000-0597' ],
                                 [ 'reference', 'cve,2000-1061' ],
                                 [ 'reference', 'cve,2003-0532' ],
                                 [ 'reference', 'url,support.microsoft.com/default.aspx?scid=kb\\;en-us\\;Q240308' ],
                                 [ 'reference', 'url,www.microsoft.com/technet/security/bulletin/MS00-049.mspx' ], 
                                 [ 'reference', 'url,www.microsoft.com/technet/security/bulletin/MS00-075.mspx' ],
                                 [ 'reference', 'url,www.microsoft.com/technet/security/bulletin/MS03-032.mspx' ],
                                 [ 'reference', 'url,www.microsoft.com/technet/security/bulletin/MS99-032.mspx' ],
                                 [ 'classtype', 'attempted-user' ],
                                 [ 'sid', '8066' ],
                                 [ 'rev', '1' ]
                               ];


my $obj_1 = Parse::Snort->new($rule_data);
is_deeply($obj_1,$rule_data,"parse hashref rule");
is($obj_1->src_port(),'$HTTP_PORTS','src_port = $HTTP_PORTS');
is($obj_1->sid(),8066,'sid = 8066');
is_deeply($obj_1->references,$references,"references");

$obj_1->sid(2);
is($obj_1->sid(),2,'sid changed to 2');
$obj_1->sid(1);
$obj_1->sid(8066);
is_deeply($obj_1,$rule_data,"modifying sid twice then reverting back is the same structure");

is($obj_1->as_string,$text_rule,"as_string matches original rule");

is_deeply($obj_1->opts(),$opts,"options parsing");

$opts_text =~ s/^\(//;
$opts_text =~ s/\)$//;

$obj_1->opts($opts_text);
is_deeply($obj_1->opts(),$opts,"options text parsing");

$obj_1->opts($opts);
is_deeply($obj_1->opts(),$opts,"options array parsing");

$obj_1->opts([]);

$rule_data->{opts} = [];
is_deeply($obj_1,$rule_data,"opts removed");

my $obj_2 = new Parse::Snort;
is($obj_2->sid(),undef,"blank rule sid");
is($obj_2->opts(),undef,"blank rule opts");
is($obj_2->as_string,undef,"blank rule as_string returns undef");
$obj_2->sid(1);
$obj_2->msg("message");
$obj_2->rev(3);
is($obj_2->as_string,undef,"mostly blank rule as_string returns undef");
$obj_2->classtype("attack");
is($obj_2->sid(1),1,"blank rule sid set to 1");

my $obj_3 = Parse::Snort::new('Parse::Snort');
isa_ok($obj_3,'Parse::Snort');


