#!perl -T

use Test::More qw(no_plan);

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


my $obj_1 = Parse::Snort->new();
$obj_1->parse($text_rule);
is_deeply($obj_1,$rule_data,"parse text rule");

