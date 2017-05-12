#!/usr/bin/perl -w
use strict;
use Test::More qw(no_plan);
use_ok('Sys::Lastlog');
my $ll;

ok($ll = Sys::Lastlog->new(),"Create object");

my ($llent,$lp);

my $login = getpwuid($<);
ok($lp = $ll->lastlog_path(),"lastlog_path()");
ok($llent = $ll->getlluid($<),"Get Entry by UID");
ok($llent = $ll->getllnam($login),"Get Entry by logname");
ok(my $t = $llent->ll_time(),"Get ll_time");

while(my $llent = $ll->getllent() )
{
   ok(defined($llent), "Got an entry for UID ". $llent->uid());
}

