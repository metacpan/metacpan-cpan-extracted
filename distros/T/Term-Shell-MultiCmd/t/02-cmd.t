#!perl

use Test::More;


# plan ( skip_all => "Can't create Term::ReadLine: $@\n")
#   unless eval { use Term::ReadLine ; Term::ReadLine->new() } ;

BEGIN { plan tests => 1}

use Term::Shell::MultiCmd ;
ok( Term::Shell::MultiCmd
    -> new ()
    -> populate ('return true' => { exec => sub { 1 }} )
    -> cmd      ('return true' )
    ,
    'Execute command from object'
  )
