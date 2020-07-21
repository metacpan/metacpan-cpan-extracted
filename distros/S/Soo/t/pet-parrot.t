use strict;
use warnings;
use lib 't/lib';
 
use Test::More 0.96;


require_ok('Pet::Parrot');
 
subtest 'default Pet::Parrot object' => sub {
    
  my $parrot = Pet::Parrot->new({ name => 'Petey' });

  isa_ok($parrot, 'Pet::Parrot');
  is( $parrot->eat, 'eating', 'Parrot is eating' );
  is( $parrot->fly, 'flying', 'Parrot is flying' );
  is( $parrot->name, 'Petey', 'Parrot is called Petey' );
  is( $parrot->run, 'I cannot run', 'Parrot cannot run' );
  is( $parrot->talk, 'argh', 'Parrot talks argh' );
  is( $parrot->sleep, 'sleeping', 'Parrot is sleeping' );

};

done_testing;