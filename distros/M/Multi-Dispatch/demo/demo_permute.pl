use 5.038;
use warnings;
use strict;

use Multi::Dispatch;

BEGIN { package Thing; }
BEGIN { package DerThing;   our @ISA = 'Thing';    }
BEGIN { package ReDerThing; our @ISA = 'DerThing'; }
BEGIN { package Other; }

multi foo  :permute (Thing $x, DerThing $y,   Other $z )   { return 'TDO' }
multi foo  :permute (Thing $x, Thing $y,      Other $z )   { return 'TTO' }
multi foo  :permute (Thing $x, ReDerThing $y, Other $z )   { return 'TRO' }

#use Data::Dump 'ddx'; ddx $Multi::Dispatch::impl{foo}{main}; exit;

my $thing      = bless {}, 'Thing';
my $derthing   = bless {}, 'DerThing';
my $rederthing = bless {}, 'ReDerThing';
my $other      = bless {}, 'Other';

say foo($thing,      $thing,      $other), ' => foo($thing,      $thing,      $other)';
say foo($thing,      $derthing,   $other), ' => foo($thing,      $derthing,   $other)';
say foo($thing,      $rederthing, $other), ' => foo($thing,      $rederthing, $other)';
say foo($thing,      $thing,      $other), ' => foo($thing,      $thing,      $other)';
say foo($derthing,   $thing,      $other), ' => foo($derthing,   $thing,      $other)';
say foo($rederthing, $thing,      $other), ' => foo($rederthing, $thing,      $other)';

say foo($other, $thing,      $thing     ), ' => foo($other, $thing,      $thing      )';
say foo($other, $thing,      $derthing  ), ' => foo($other, $thing,      $derthing   )';
say foo($other, $thing,      $rederthing), ' => foo($other, $thing,      $rederthing )';
say foo($other, $thing,      $thing     ), ' => foo($other, $thing,      $thing      )';
say foo($other, $derthing,   $thing     ), ' => foo($other, $derthing,   $thing      )';
say foo($other, $rederthing, $thing     ), ' => foo($other, $rederthing, $thing      )';

say foo($thing,      $other, $thing     ), ' => foo($thing,      $other, $thing      )';
say foo($thing,      $other, $derthing  ), ' => foo($thing,      $other, $derthing   )';
say foo($thing,      $other, $rederthing), ' => foo($thing,      $other, $rederthing )';
say foo($thing,      $other, $thing     ), ' => foo($thing,      $other, $thing      )';
say foo($derthing,   $other, $thing     ), ' => foo($derthing,   $other, $thing      )';
say foo($rederthing, $other, $thing     ), ' => foo($rederthing, $other, $thing      )';





