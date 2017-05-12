#!/usr/bin/perl

use strict;
use warnings;

use lib qw( lib ../Algorithm-Evolutionary/lib ../../lib ../lib ../../Algorithm-Evolutionary/lib );

use POE::Component::Algorithm::Evolutionary;
use POE;

use Algorithm::Evolutionary qw( Individual::BitString Op::Creator 
				Op::CanonicalGA Op::Bitflip 
				Op::Crossover Op::GenerationalTerm
				Fitness::Royal_Road);

my $bits = shift || 64;
my $block_size = shift || 4;
my $pop_size = shift || 256; #Population size
my $numGens = shift || 200; #Max number of generations
my $selection_rate = shift || 0.2;


#----------------------------------------------------------#
#Initial population
my $creator = new Algorithm::Evolutionary::Op::Creator( $pop_size, 'BitString', { length => $bits });

#----------------------------------------------------------#
# Variation operators
my $m = Algorithm::Evolutionary::Op::Bitflip->new( 1 );
my $c = Algorithm::Evolutionary::Op::Crossover->new(2, 4);

# Fitness function: create it and evaluate
my $rr = new  Algorithm::Evolutionary::Fitness::Royal_Road( $block_size );

#----------------------------------------------------------#
#Usamos estos operadores para definir una generación del algoritmo. Lo cual
# no es realmente necesario ya que este algoritmo define ambos operadores por
# defecto. Los parámetros son la función de fitness, la tasa de selección y los
# operadores de variación.
my $generation = Algorithm::Evolutionary::Op::CanonicalGA->new( $rr , $selection_rate , [$m, $c] ) ;
my $gterm = new Algorithm::Evolutionary::Op::GenerationalTerm 10;

POE::Component::Algorithm::Evolutionary->new( Fitness => $rr,
					      Creator => $creator,
					      Single_Step => $generation,
					      Terminator => $gterm,
					      Alias => 'Canonical' );


$poe_kernel->run();
