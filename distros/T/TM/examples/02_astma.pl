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

use Data::Dumper;

warn Dumper [ $tm->instances  ($tm->tids ('cat')) ];
warn Dumper [ $tm->instances  ($tm->tids ('mammal')) ];
warn Dumper [ $tm->instancesT ($tm->tids ('mammal')) ];

warn "Not sure about that"
    unless $tm->is_subclass ($tm->tids ('cat', 'mammal'));

warn Dumper [ $tm->are_instances ($tm->tids ('cat', 'rho', 'sacklpicka', 'sacklpicka') ) ];

warn Dumper [ $tm->are_instances ($tm->tids ('mammal', 'rho', 'sacklpicka', 'sacklpicka') ) ];
#----------------------

use File::Slurp;
write_file( '/tmp/something.atm', "sacklpicka (cat)\n\n" ) ;

$tm = new TM::Materialized::AsTMa (file => '/tmp/something.atm');
$tm->sync_in;

$tm->internalize (rho);
$tm->assert (Assertion->new (
                             type => 'owns',
                             roles => [ 'owner', 'object' ],
                             players => [ 'rho', 'sacklpicka' ]));
#warn Dumper $tm;
$tm->sync_out;

#---------------------


$tm = new TM::Materialized::AsTMa (inline => '
%version 2.0

rho isa person and has name : "Robert Barta" .
rho has blog : http://kill.devc.at/ .

# much more is possible here

');
$tm->sync_in;

#warn Dumper $tm;
