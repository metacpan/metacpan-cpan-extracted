#!/usr/bin/perl -T

use strict;
use warnings;

use Sys::Utmp;
use Test::More; 

eval "use Scalar::Util qw(tainted)";

#plan skip_all => "Tainting check skipped";

if ( $@ )
{
   plan skip_all => "Need Scalar::Util to test tainting";
}
else
{
   plan tests => 2;
}

my $utmp = Sys::Utmp->new();
 
my $utent =  $utmp->getutent();

ok(tainted($utent->ut_user()),"ut_user is tainted");
ok(tainted($utent->ut_host()),"ut_host is tainted");
