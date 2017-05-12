#!/usr/bin/perl

use warnings;
use strict;

use PortageXS::UI::Spinner;
use Time::HiRes qw(sleep);

print "Spinner demonstration..  ";
my $spinner=PortageXS::UI::Spinner->new();
for (my $i=0;$i<50;$i++) {
	$spinner->spin();
	sleep(0.05);
}
$spinner->reset();
print "done! :)\n";
