use strict;
use warnings;
use Test::More;

use SQL::Abstract::FromQuery;


my %data = ( 
             gt      => ">",
             between => 'BETWEEN',
             neg     => '!',
            );
my $expected_error_EN = q{INCORRECT INPUT
between : Expected min and max after "BETWEEN"
gt : Expected a value after comparison operator
neg : Expected a value after negation};

my $expected_error_FR = q{SAISIE INCORRECTE
between : Pas de valeurs min/max après "ENTRE/BETWEEN"
gt : Aucune valeur après l'opérateur de comparaison
neg : Aucune valeur après la négation};

plan tests => 2;

my $parser_EN = SQL::Abstract::FromQuery->new;
my $where_EN  = eval {$parser_EN->parse(\%data);};
my $errors_EN = $@;
is($errors_EN, $expected_error_EN);

my $parser_FR = SQL::Abstract::FromQuery->new(-components => [qw/FR/]);
my $where_FR  = eval {$parser_FR->parse(\%data);};
my $errors_FR = $@;
is($errors_FR, $expected_error_FR);





