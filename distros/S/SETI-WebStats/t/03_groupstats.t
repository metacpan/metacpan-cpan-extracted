# $Id: 03_groupstats.t,v 1.3 2003/10/10 01:59:06 vek Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 02_groupstats.t'

use Test::More tests => 9;
use SETI::WebStats;

my $group = 'perlmonks';

my $seti = SETI::WebStats->new;
ok($seti);
ok($seti->fetchGroupStats($group));

# group tests...
ok($seti->groupURL eq 'www.perlmonks.org');
ok($seti->numGroupResults);
ok($seti->numGroupMembers);
ok($seti->totalGroupCPU);
ok($seti->nameOfGroup eq 'Perlmonks');
ok($seti->groupFounderName eq 'Ovid');
ok($seti->groupFounderURL);

