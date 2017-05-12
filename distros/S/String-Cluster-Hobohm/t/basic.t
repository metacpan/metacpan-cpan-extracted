use Test::More;
use Test::Exception;
use_ok 'String::Cluster::Hobohm';

isa_ok my $clusterer = String::Cluster::Hobohm->new, 'String::Cluster::Hobohm';

is $clusterer->similarity, 0.62;

dies_ok  { String::Cluster::Hobohm->new( similarity =>   5 ) } 'dies on big similarity';
dies_ok  { String::Cluster::Hobohm->new( similarity =>  -5 ) } 'dies on small similarity';
lives_ok { String::Cluster::Hobohm->new( similarity => 0.5 ) } 'lives with correct similarity';

can_ok( $clusterer, 'cluster' );

dies_ok { $clusterer->cluster() } 'dies with no arguments';

my $clusters;
lives_ok { $clusters = $clusterer->cluster( [ 'foo', 'foa', 'bar' ] ) }
'lives with arguments';

is_deeply $clusters, [ [ \'foo', \'foa' ], [ \'bar' ] ], 'clustering works';

done_testing;
