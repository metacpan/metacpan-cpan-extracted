my $a1 = <<EOM;
sacklpicka (cat)
bn: Der Sacklpicka
bn: Catbert

rho (person)
oc (blog): http://kill.devc.at/

whitey (unperson)
bn: The White-Haired Man
EOM

my $a2 = <<EOM;
sacklpicka (cat)
bn: Der Sacklpicka

rho (person)
bn: The Supermodel
oc (blog): http://kill.devc.at/

sharkbert (unperson)
bn: Sharky
EOM

use TM::Materialized::AsTMa;
my $tm1 = new TM::Materialized::AsTMa (inline => $a1);
$tm1->sync_in;
my $tm2 = new TM::Materialized::AsTMa (inline => $a2);
$tm2->sync_in;


use Data::Dumper;
$Data::Dumper::Indent = 1;
#warn Dumper $tm2->diff ($tm1);

warn Dumper $tm2->diff ($tm1, { include_changes => 1 } );

