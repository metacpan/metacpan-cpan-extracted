use Data::Dumper;

use TM::ResourceAble::MLDBM;
my $tm = new TM::ResourceAble::MLDBM (file => '/tmp/somemap');

use TM::Materialized::AsTMa;
my $update = new TM::Materialized::AsTMa (file => 'maps/mapreduce.atm');
$update->sync_in;   
warn "synced";

use TM::Literal;
$update->assert (
    map { Assertion->new (kind => TM->NAME, type => 'name', scope => 'us', roles => [ 'thing', 'value' ], players => [ "aaa$_", new TM::Literal ("AAA$_") ]) }
	   (1..10000)
	    );
warn "enriched";


$tm->clear;
$tm->add ($update);
warn "added";

my $c = {};

use Class::Trait;
Class::Trait->apply ($tm, "TM::IndexAble");
$tm->index ({ axis => 'reify', closed => 1, detached => $c });
warn "indexed";
#warn Dumper $c;

Class::Trait->apply ( $tm => 'TM::Serializable::AsTMa' );
my $content = $tm->serialize;
warn "serialized";

#warn $content;

__END__

Class::Trait->apply ( $tm => 'TM::Serializable::AsTMa' );
use TM::Index::Reified;
warn "use";
my $idx = new TM::Index::Reified ($tm, closed => 1, loose => 1);
warn "idx";
warn Dumper $tm->{rindex};

__END__


use TM::Serializable::AsTMa;

use Class::Trait;
Class::Trait->apply ( $tm => 'TM::Serializable::AsTMa' );

my $content;
{
    use TM::Index::Reified;
    my $idx = new TM::Index::Reified ($tm);
    warn "attached";
#use TM::Index::Taxonomy;
#my $idx = new TM::Index::Taxonomy ($tm, closed => 1);
    $content = $tm->serialize;
    warn "serialized";
    $idx->detach;
    warn "detached";
}

warn $content;

__END__

use TM::Materialized::MLDBM;

my $tm = new TM::Materialized::MLDBM (file => '/tmp/rumsti');

$tm->internalize ('xxx');
$tm->sync_out;
