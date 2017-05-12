#!/usr/bin/perl -w

=head1 Basic Checks

Check that schedule works in a basic way.. ..

=cut


$loaded = 0;

BEGIN { print "1..11\n"} ;
END { print "not ok 1\n" unless $loaded; } ;


sub ok ($) { print "ok ", shift, "\n" }
sub nogo () { print "not ", }

use Schedule::SoftTime;
$loaded = 1;
ok(1);
$sched = new Schedule::SoftTime;

#insert in sequence
$sched->schedule("123", "First");
$sched->schedule("200", "Second");
$sched->schedule("516", "Fourth");
$sched->schedule("616", "Sixth");
$sched->schedule("744", "Seventh");
$sched->schedule("744", "Eighth");
ok(2);

#insert in the middle
$sched->schedule("321", "Third");

ok(3);

$first = $sched->first_item();

nogo unless $first eq "First";

ok(4);

#insert while running
$sched->schedule("516", "Fifth");

ok(5);

$second = $sched->next_item();

nogo unless $second eq "Second";

ok(6);

$third = $sched->next_item();

nogo unless $third eq "Third";

ok(7);

$fourth = $sched->next_item();

nogo unless $fourth eq "Fourth";

ok(8);

$fifth = $sched->next_item();

nogo unless $fifth eq "Fifth";

ok(9);

$sixth = $sched->next_item();

nogo unless $sixth eq "Sixth";

ok(10);

$seventh = $sched->next_item();

nogo unless $seventh eq "Seventh";

ok(11);

$eighth = $sched->next_item();

nogo unless $eighth eq "Eighth";
