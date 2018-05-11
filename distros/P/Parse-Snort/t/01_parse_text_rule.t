use strict;
use warnings;

use Test::More tests => 15;
use Parse::Snort;

my $text_rule = 'alert tcp $EXTERNAL_NET $HTTP_PORTS -> $HOME_NET any (msg:"WEB-CLIENT Windows Scripting Host Shell ActiveX CLSID access"; flow:established,to_client; content:"F935DC22-1CF0-11D0-ADB9-00C04FD58A0B"; nocase; pcre:"/<OBJECT\s+[^>]*classid\s*=\s*[\x22\x27]?\s*clsid\s*\x3a\s*\x7B?\s*F935DC22-1CF0-11D0-ADB9-00C04FD58A0B/si"; reference:bugtraq,1399; reference:bugtraq,1754; reference:bugtraq,598; reference:bugtraq,8456; reference:cve,1999-0668; reference:cve,2000-0597; reference:cve,2000-1061; reference:cve,2003-0532; reference:url,support.microsoft.com/default.aspx?scid=kb\;en-us\;Q240308; reference:url,www.microsoft.com/technet/security/bulletin/MS00-049.mspx; reference:url,www.microsoft.com/technet/security/bulletin/MS00-075.mspx; reference:url,www.microsoft.com/technet/security/bulletin/MS03-032.mspx; reference:url,www.microsoft.com/technet/security/bulletin/MS99-032.mspx; classtype:attempted-user; sid:8066; rev:1; metadata:policy balanced-ips drop, policy security-ips drop; gid:1; priority:10;)';

my $obj_1 = Parse::Snort->new($text_rule);
note("Rule header testing");
is($obj_1->action(),'alert','action = alert');
is($obj_1->proto(),'tcp','proto = tcp');
is($obj_1->src(),'$EXTERNAL_NET','src ip = $EXTERNAL_NET');
is($obj_1->src_port(),'$HTTP_PORTS','src_port = $HTTP_PORTS');
is($obj_1->direction(),'->','direction = ->');
is($obj_1->dst(),'$HOME_NET','dst = $HOME_NET');
is($obj_1->dst_port(),'any','dst_port = any');

note("Rule option testing, not intended to be exhaustive...");
is($obj_1->sid(),'8066','sid = 8066');
is($obj_1->gid(),'1','gid = 1');
is($obj_1->rev(),'1','rev = 1');
is($obj_1->msg(),'"WEB-CLIENT Windows Scripting Host Shell ActiveX CLSID access"','msg = "WEB-CLIENT Windows Scripting Host Shell ActiveX CLSID access"');
is($obj_1->classtype(),'attempted-user','classtype = attempted-user');
is($obj_1->metadata(),'policy balanced-ips drop, policy security-ips drop','metadata = policy balanced-ips drop, policy security-ips drop');
is($obj_1->priority(),'10','priority = 10');
is($obj_1->flow(),'established,to_client','flow = established,to_client');

done_testing;
