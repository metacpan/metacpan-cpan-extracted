use strict;
use warnings;
use lib 't/lib';
 
use Test::More 0.96;


require_ok('Pet::Cat');
 
subtest 'default Pet::Cat object' => sub {
    
  my $cat = Pet::Cat->new({ name => 'Simba' });

  isa_ok($cat, 'Pet::Cat');
  is( $cat->eat, 'eating', 'Cat is eating' );
  is( $cat->fly, 'I cannot fly', 'Cat cannot fly' );
  is( $cat->name, 'Simba', 'Cat is called Simba' );
  is( $cat->run, 'running', 'Cat is running' );
  is( $cat->talk, 'meow', 'Cat talks meow' );
  is( $cat->sleep, 'sleeping', 'Cat is sleeping' );

};

done_testing;