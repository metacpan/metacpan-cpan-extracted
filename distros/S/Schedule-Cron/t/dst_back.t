#!perl -w

use strict;
use warnings;
use Test::More;
use Schedule::Cron;

plan tests => 3;


my %available = ();

my @refs = ( 
            [ "MET", 1256432100, 1256436000],
            [ "Europe/Berlin", 1256432100, 1256436000],
            [ "PST8PDT", 1257065700, 1257062400]
           );

# First check for timezones available:
no warnings;
$ENV{TZ} = undef;
my $tt = time;
my $local = scalar(localtime($tt));
for my $r (@refs) {
    my $tz = $r->[0];
    $ENV{TZ} = $tz;
    my $calc = scalar(localtime($tt));
    #print "C: $calc L: $local\n";
    $available{$tz} = 1 if $calc ne $local;
}


my $cron = new Schedule::Cron(sub { });

for my $r (@refs) {
    my $tz = $r->[0];
    if (!$available{$tz}) {
        ok(1,"Timezone $tz not available");
        next;
    }
    $ENV{TZ} = $tz;
    my $next = $cron->get_next_execution_time("0-59/5 * * * *",$r->[1]);
    is($next,$r->[2],"Expected time for $tz ( Ref: " . scalar(localtime($r->[1])) . ", Calc: " . scalar(localtime($next)));
}

