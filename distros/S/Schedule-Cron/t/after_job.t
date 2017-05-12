#!/usr/bin/perl

# Test for after_job callbak

use Test::More tests => 3;
use Schedule::Cron;
use strict;

my $count = 0;
my $cron =new Schedule::Cron(\&dispatch,{nofork => 1,after_job => \&after_callback});

$cron->add_entry("* * * * * 0-59/1",{args => [ "eins", "zwei"]});
eval {
    $cron->run();
};
is($@,"e1\n","Second call must finish test");


sub dispatch {
    my @args;
    if ($count == 0) {
        $count = 1;
        return "t1";
    } elsif ($count == 1) {
        die "e1\n";
    }

}

sub after_callback {
    my ($ret,@args) = @_;
    is($ret,"t1","Return value must match");
    is_deeply(\@args,["eins","zwei" ],"Arguments must match");
}
