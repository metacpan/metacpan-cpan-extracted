#!/usr/bin/perl

use warnings;
use strict;

use PortageXS::UI::Spinner::Rainbow;
use Time::HiRes qw(sleep);

print "Spinner demonstration..  ";
my $spinner=PortageXS::UI::Spinner::Rainbow->new();
for (my $i=0;$i<500;$i++) {
	$spinner->spin();
	sleep(0.05);
}
$spinner->reset();
print "done! :)\n";
