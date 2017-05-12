#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';

use Human::Base;

my $human = new Human::Base('Joe');
   $human->height = 180;
   $human->weight = 90;

my $human1 = $human->clone();
   $human1->name = 'Mike';

say $human->name;
say $human1->name;

use Human::Movable;

my $human2 = new Human::Movable('Dick');
   $human2->moveLeft() for 1 .. 3;
   $human2->moveDown() for 1 .. 4;

print $human2->name, '\'s way length: ';
say $human2->getResultWay();
