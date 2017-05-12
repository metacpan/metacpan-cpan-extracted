#!perl -T

use warnings ;
use strict ;
use Test::More ;


# plan ( skip_all => "Can't create Term::ReadLine: $@\n")
#   unless eval { use Term::ReadLine ; Term::ReadLine->new() } ;

use Term::Shell::MultiCmd ;

BEGIN{ plan tests => 1 }

ok( Term::Shell::MultiCmd
    -> new ()
    -> populate( 'return true' => { exec => sub {1}},
                 'return'      => 'dummy help',
               )
    ,
    'Populate commands tree in object'
  ) ;


