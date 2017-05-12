#-*-CPerl-*-

use lib qw( ../../lib ../lib ../../Algorithm-Evolutionary/lib );

use Test::More tests => 2;
use Test::Output;

use POE::Component::Algorithm::Evolutionary;
use POE;

use Algorithm::Evolutionary qw( Individual::BitString Op::Creator 
				Op::CanonicalGA Op::Bitflip 
				Op::Crossover Op::GenerationalTerm
				Fitness::Royal_Road);

use Algorithm::Evolutionary::Utils qw(average);

my $bits = 64;
my $block_size = 4;
my $pop_size = 256; #Population size
my $numGens = 200; #Max number of generations
my $selection_rate =  0.2;


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
my $gterm = new Algorithm::Evolutionary::Op::GenerationalTerm 1;

my $poco_ae_session = POE::Component::Algorithm::Evolutionary->new( Fitness => $rr,
								    Creator => $creator,
								    Single_Step => $generation,
								    Terminator => $gterm,
								    Alias => 'Canonical' );
$poe_kernel->run();
my $this_average = average( $poco_ae_session->population );
$gterm = new Algorithm::Evolutionary::Op::GenerationalTerm 10;
#Restart session
$poco_ae_session = POE::Component::Algorithm::Evolutionary->new( Fitness => $rr,
								 Creator => $creator,
								 Single_Step => $generation,
								 Terminator => $gterm,
								 Alias => 'Canonical' );
$poe_kernel->run();
ok( $this_average < average( $poco_ae_session->population ), 'Average improves with GA' );

my $after_step = sub {  print $_[0]->[0]->asString(), "\n" }; #First argument is the population hashref

$poco_ae_session = 
  POE::Component::Algorithm::Evolutionary->new( Fitness => $rr,
						Creator => $creator,
						Single_Step => $generation,
						Terminator => Algorithm::Evolutionary::Op::GenerationalTerm->new(10),
						Alias => 'Canonical',
						After_Step => $after_step);

stdout_like( sub { $poe_kernel->run(); }, qr /[01]+ ->/, 'After step output' );
