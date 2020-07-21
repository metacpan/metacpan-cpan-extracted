use strict;
use warnings;
use lib 't/lib';
 
use Test::More 0.96;


require_ok('Pet::Dog');
 
subtest 'default Pet::Dog object' => sub {
    
  my $dog = Pet::Dog->new({ name => 'Buddy' });

  isa_ok($dog, 'Pet::Dog');
  is( $dog->eat, 'eating', 'Dog is eating' );
  is( $dog->fly, 'I cannot fly', 'Dog cannot fly' );
  is( $dog->name, 'Buddy', 'Dog is called Buddy' );
  is( $dog->run, 'running', 'Dog is running' );
  is( $dog->talk, 'wow', 'Dog talks meow' );
  is( $dog->sleep, 'sleeping', 'Dog is sleeping' );

};

done_testing;