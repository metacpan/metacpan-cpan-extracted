use strict;
use warnings;
use lib 't/lib';
 
use Test::More 0.96;


require_ok('Pet');
 
subtest 'default Pet object' => sub {
    
  my $pet = Pet->new({ name => 'Ghost' });

  isa_ok($pet, 'Pet');
  is( $pet->eat, 'eating', 'Pet is eating' );
  is( $pet->fly, 'flying', 'Pet is flying' );
  is( $pet->name, 'Ghost', 'Pet is called Ghost' );
  is( $pet->run, 'running', 'Pet is running' );
  is( $pet->talk, 'talking', 'Pet is talking' );
  is( $pet->sleep, 'sleeping', 'Pet is sleeping' );

};

done_testing;