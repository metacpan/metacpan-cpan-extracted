#!perl -T

use Test::More tests => 16;
use Data::Dumper;

BEGIN {
	use_ok( 'Parse::Snort' );
}

my $text_rule = 'alert tcp $EXTERNAL_NET $HTTP_PORTS -> $HOME_NET any (msg:"WEB-CLIENT Windows Scripting Host Shell ActiveX CLSID access"; flow:established,to_client; content:"F935DC22-1CF0-11D0-ADB9-00C04FD58A0B"; nocase; pcre:"/<OBJECT\s+[^>]*classid\s*=\s*[\x22\x27]?\s*clsid\s*\x3a\s*\x7B?\s*F935DC22-1CF0-11D0-ADB9-00C04FD58A0B/si"; reference:bugtraq,1399; reference:bugtraq,1754; reference:bugtraq,598; reference:bugtraq,8456; reference:cve,1999-0668; reference:cve,2000-0597; reference:cve,2000-1061; reference:cve,2003-0532; reference:url,support.microsoft.com/default.aspx?scid=kb\;en-us\;Q240308; reference:url,www.microsoft.com/technet/security/bulletin/MS00-049.mspx; reference:url,www.microsoft.com/technet/security/bulletin/MS00-075.mspx; reference:url,www.microsoft.com/technet/security/bulletin/MS03-032.mspx; reference:url,www.microsoft.com/technet/security/bulletin/MS99-032.mspx; classtype:attempted-user; sid:8066; rev:1; metadata:policy balanced-ips drop, policy security-ips drop; gid:1; priority:10;)';


my $rule = Parse::Snort->new($text_rule);

# XXX

note("Rule header testing");
$rule->action("pass"); is($rule->action(),'pass','action modified to pass');
$rule->proto("udp"); is($rule->proto(),'udp','proto modified to udp');
$rule->src("192.168.1.1"); is($rule->src(),'192.168.1.1','src ip modified to 192.168.2.1');
$rule->src_port("80"); is($rule->src_port(),'80','src_port modified to 80');
$rule->direction('<>'); is($rule->direction(),'<>','direction modified to  <>');
$rule->dst("any");is($rule->dst(),'any','dst modified to any');
$rule->dst_port("31337"); is($rule->dst_port(),'31337','dst_port modified to 31330');

note("Rule option testing, not intended to be exhaustive...");
$rule->sid("8675309"); is($rule->sid(),'8675309','sid modified to 8675309');
$rule->gid("37"); is($rule->gid(),'37','gid = 1');
is($rule->rev(),'1','rev = 1');
is($rule->msg(),'"WEB-CLIENT Windows Scripting Host Shell ActiveX CLSID access"','msg = "WEB-CLIENT Windows Scripting Host Shell ActiveX CLSID access"');
is($rule->classtype(),'attempted-user','classtype = attempted-user');
is($rule->metadata(),'policy balanced-ips drop, policy security-ips drop','metadata = policy balanced-ips drop, policy security-ips drop');
is($rule->priority(),'10','priority = 10');
is($rule->flow(),'established,to_client','flow = established,to_client');

# XXX

