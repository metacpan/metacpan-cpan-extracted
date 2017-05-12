use TM::Materialized::AsTMa;
my $tm = new TM::Materialized::AsTMa (file => 'examples/old_testament.atm');
$tm->sync_in;

Class::Trait->apply ( $tm => 'TM::Graph' );

use Data::Dumper;
print Dumper $tm->clusters;


my ($adam, $begets) = $tm->tids ('adam', 'begets');
warn Dumper [
	$tm->frontier ([ $adam ],
		       [
			 [ $begets ]
			])
	];

warn Dumper [
	$tm->frontier ([ $adam ],
		       bless [
			  [ $begets ]
			], '*')
	];

my ($apple, $eats) = $tm->tids ('apple_1', 'eats');

warn Dumper [
	$tm->frontier ([ $apple ],
		       [
			[ $eats ],
			[ bless [ [ $begets ] ], '*' ]
			]
		       )
	];


