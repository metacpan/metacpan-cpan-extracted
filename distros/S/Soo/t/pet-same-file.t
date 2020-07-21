use strict;
use warnings;

package LocalPet;

use Soo;

has eat => { default => 'eating' };
has fly => { default => 'flying' };
has 'name';
has run => { default => 'running' };
has talk => { default => 'talking' };
has sleep => { default => 'sleeping' };


package LocalPet::Cat;

use Soo;

extends 'LocalPet';

has fly => { default => 'I cannot fly' };
has talk => { default => 'meow' };


package LocalPet::Dog;

use Soo;

extends 'LocalPet';

has fly => { default => 'I cannot fly' };
has talk => { default => 'wow' };


package LocalPet::Parrot;

use Soo;

extends 'LocalPet';

has run => { default => 'I cannot run' };
has talk => { default => 'argh' };


package main;

use Test::More 0.96;
 
subtest 'Multiple classes in a same file' => sub {
    
  my $cat = LocalPet::Cat->new({ name => 'Simba' });
  my $dog = LocalPet::Dog->new({ name => 'Buddy' });
  my $parrot = LocalPet::Parrot->new({ name => 'Petey' });

  isa_ok($cat, 'LocalPet::Cat');
  is( $cat->eat, 'eating', 'Cat is eating' );
  is( $cat->fly, 'I cannot fly', 'Cat cannot fly' );
  is( $cat->name, 'Simba', 'Cat is called Simba' );
  is( $cat->run, 'running', 'Cat is running' );
  is( $cat->talk, 'meow', 'Cat talks meow' );
  is( $cat->sleep, 'sleeping', 'Cat is sleeping' );

  isa_ok($dog, 'LocalPet::Dog');
  is( $dog->eat, 'eating', 'Dog is eating' );
  is( $dog->fly, 'I cannot fly', 'Dog cannot fly' );
  is( $dog->name, 'Buddy', 'Dog is called Buddy' );
  is( $dog->run, 'running', 'Dog is running' );
  is( $dog->talk, 'wow', 'Dog talks meow' );
  is( $dog->sleep, 'sleeping', 'Dog is sleeping' );

  isa_ok($parrot, 'LocalPet::Parrot');
  is( $parrot->eat, 'eating', 'Parrot is eating' );
  is( $parrot->fly, 'flying', 'Parrot is flying' );
  is( $parrot->name, 'Petey', 'Parrot is called Petey' );
  is( $parrot->run, 'I cannot run', 'Parrot cannot run' );
  is( $parrot->talk, 'argh', 'Parrot talks argh' );
  is( $parrot->sleep, 'sleeping', 'Parrot is sleeping' );

};

done_testing;