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
use Mojo::Role;

# test class
use People;
use Developer;
use MojoCoreMantainer;


subtest 'test for requires func' => sub {
  can_ok 'MojoCoreMantainer', 'requires';
  ok ! eval{ MojoCoreMantainer->isa('Mojo::Role') }, 'no extends Mojo::Role';
};


subtest 'test for with func' => sub {
  ok ! eval{ Developer->isa('Mojo::Role') }, 'no extends Mojo::Role';
  can_ok 'People', 'with';
};

done_testing();

