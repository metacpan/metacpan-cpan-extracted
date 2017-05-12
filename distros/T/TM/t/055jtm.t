use strict;
use warnings;

use Test::More qw(no_plan);
use TM::Materialized::AsTMa;

require_ok ('TM::Materialized::JTM');
require_ok ('TM::Serializable::JTM');

{
    my $tm = new TM::Materialized::JTM;
    ok ($tm->isa('TM::Materialized::JTM'),'correct class 1');
    ok ($tm->isa('TM::Materialized::Stream'),'correct class 2');
    ok ($tm->isa('TM'),'correct class 3');
}

# prime testdata
my $tm = new TM::Materialized::AsTMa (baseuri=>"tm://", inline=>'
nackertes_topic 

atop
bn: just a topic

btop (ctop)
bn: something
bn@ascope: some other thing

ctop
bn: over the top!
in: something
in: somemore
oc: http://somewhere
in@ascope: scoped
in@ascope (sometype): also typed
oc (sometype): http://typedoc
oc @ascope (sometype): http://typedandscopedoc

(sucks-more-than)
sucker: ctop
winner: atop
winner: others

(sucks-more-than) @ascope
sucker: nobody
winner: nobody

thistop reifies http://rumsti
bn: reification
in: reification
sin: http://nowhere.never.ever
sin: http://nowhere.ever.never

sometopic 
bn: some topic that reifies an internal other topic

othertopic is-reified-by sometopic 
bn: the reified target

# is-reified-by sometopic

(sucks-more-than) is-reified-by atop
winner: nobody
sucker: nobody

')->sync_in;

Class::Trait->apply($tm,"TM::Serializable::JTM");
{
    my ($d,$tm2);
    ok($d=$tm->serialize,"serialize to json works");
    
    ok($tm2 = new TM::Materialized::JTM(baseuri=>"tm://",inline => $d)->sync_in,"deserialize from json works");

    is_deeply( $tm2->{mid2iid},    $tm->{mid2iid},    'toplet structure survived unchanged' );
    is_deeply( $tm2->{assertions}, $tm->{assertions}, 'asserts structure survived unchanged' );
}

{
    my ($d,$tm2);
    ok($d=$tm->serialize(format=>"yaml"),"serialize to yaml works");
    ok($d=~/^---[^{}\[\]]+$/s,"the result is indeed yaml, not just json");
    
    ok($tm2 = new TM::Materialized::JTM(baseuri=>"tm://",format=>"yaml", inline => $d)->sync_in,"deserialize from yaml works");

    is_deeply( $tm2->{mid2iid},    $tm->{mid2iid},    'toplet structure survived unchanged' );
    is_deeply( $tm2->{assertions}, $tm->{assertions}, 'asserts structure survived unchanged' );
}
   



