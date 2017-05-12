# $Id: 02_userstats.t,v 1.2 2003/10/10 01:58:59 vek Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 02_userstats.t'

use Test::More tests => 21;
use SETI::WebStats;

my $addr = 'webstats_test@yahoo.com'; # the test account...

my $seti = SETI::WebStats->new;
ok($seti);
ok($seti->fetchUserStats($addr));

# userinfo tests...
my $userInfo = $seti->userInfo;
ok(ref $userInfo);
ok($seti->userTime);
ok($seti->aveCpu eq '42 hr 56 min 27.6 sec');
ok($seti->numResults == 23);
ok($seti->regDate eq 'Fri Dec 27 17:04:43 2002');
ok($seti->profileURL eq 'No URL');
ok($seti->resultsPerDay);
ok($seti->lastResultTime eq 'Sun Feb  9 04:04:09 2003');
ok($seti->cpuTime eq '987 hr 38 min');
ok($seti->name eq 'webstats_test');
ok($seti->homePage eq 'No Home Page');

# rankinfo tests...
my $rankInfo = $seti->rankInfo;
ok(ref $rankInfo);
ok($seti->haveSameRank);
ok($seti->totalUsers);
ok($seti->rankPercent);
ok($seti->rank);

# groupinfo tests...
my $groupInfo = $seti->groupInfo;
ok(not $groupInfo);
ok(not $seti->groupName);
ok(not $seti->groupUrl);

