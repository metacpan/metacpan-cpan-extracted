use TM::Materialized::AsTMa;

my $tm = new TM::Materialized::AsTMa (inline => '
sacklpicka (cat)
bn: Der Sacklpicka

rho (person)
oc (blog): http://kill.devc.at/

(owns)
owner: rho
owned: sacklpicka

(is-subclass-of)
subclass: person
superclass: mammal

(is-subclass-of)
subclass: cat
superclass: mammal

');

$tm->sync_in;

use TM::QL;
my $q = new TM::QL ('for $a in %_ // owns return $a');
use Data::Dumper;
warn Dumper $q->eval ({ '%_' => $tm });
