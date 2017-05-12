use strict;
use ServiceNow::SOAP;
use Test::More;
use lib 't';
use TestUtil;

if (TestUtil::config) { plan tests => 2 } 
else { plan skip_all => "no config" };
my $username = TestUtil::getUsername();
my $sn = TestUtil::getSession();
my $tbl = $sn->table('sys_user');

my $rec = $tbl->getRecord(user_name => $username);
ok ($rec, "getRecord for single record");
eval { my $rec = $tbl->getRecord(active => 'true') };
ok ($@, "getRecord for multiple records threw exception");
1;
