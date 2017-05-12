#!perl 

# pragmas
use 5.10.0;
use strict;
use warnings;

# imports
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::More;
use Mojo::RoleTiny;

# test class
use People;
use Developer;
use MojoCoreMantainer;


subtest 'test for requires func' => sub {
  can_ok 'MojoCoreMantainer', 'requires';
  ok ! eval{ MojoCoreMantainer->isa('Mojo::RoleTiny') }, 'no extends Mojo::RoleTiny';
};


subtest 'test for with func' => sub {
  ok ! eval{ Developer->isa('Mojo::RoleTiny') }, 'no extends Mojo::RoleTiny';
  can_ok 'People', 'with';
};

done_testing();

