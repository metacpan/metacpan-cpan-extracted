# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Net::SPOCP qw(:all);
use strict;

my $count;
ok(++$count); # If we made it this far, we're ok.

#########################

my $e1 = Net::SPOCP::SExpr->new(spocp=>
				[resource=>[file=>'etc','groups']],
				[action=>'read'],
				[subject=>[uid=>100]]);

ok(++$count);

my $e2 = Net::SPOCP->rule(resource => spocp_split_parts('/','internal','foo/index.html','-'),
			  action   => [0,1],
			  subject  => spocp_map(ip=>'130.237.95.42',
						host=>'trurl.it.su.se',
						sslver=>300,
						user=>'leifj',
						authname=>'foo',
						authtype=>'Basic'));

ok(++$count);

my $e3 = Net::SPOCP::SExpr->new('(spocp(resource(file etc groups))(action read)(subject(uid 100)))');

ok(++$count);
print $e1->toString(),"\n";
ok(++$count);
print $e2->toString(),"\n";
ok(++$count);
print $e3->toString(),"\n";
ok(++$count);
$e1->toString() eq $e3->toString() or die;
ok(++$count);
my $client = Net::SPOCP::Client->new(server=>'spocp.su.se:4751');
ok(++$count);
my $res = $client->query([test => [host => 'trurl.it.su.se'],[uid => 'leifj']]);
ok(++$count);
printf "%s\n",$res->error;
printf "%s\n",$res->code;
ok(++$count);
# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
