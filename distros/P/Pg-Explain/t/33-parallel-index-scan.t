#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use autodie;

use Pg::Explain;

plan 'tests' => 8;

my $explain = Pg::Explain->new(
    'source' => q{
GroupAggregate  (cost=1002.57..31309179.09 rows=115381975 width=154)
  Group Key: mac, freq, (ceil((heading / '60'::double precision))), (ceil((st_x(geom) / '60'::double precision))), (ceil((st_y(geom) / '60'::double precision)))
  ->  Incremental Sort  (cost=1002.57..21790166.15 rows=115381975 width=98)
        Sort Key: mac, freq, (ceil((heading / '60'::double precision))), (ceil((st_x(geom) / '60'::double precision))), (ceil((st_y(geom) / '60'::double precision)))
        Presorted Key: mac, freq
        ->  Gather Merge  (cost=1000.74..17575025.65 rows=115381975 width=98)
              Workers Planned: 9
              ->  Parallel Index Scan using wifi_seen_mac_freq_idx on wifi_seen  (cost=0.57..11849967.18 rows=12820219 width=74)
                    Filter: ((accuracy < '30'::double precision) AND ((speed * abs((ts - pos_ts))) < '30'::double precision))
    }
);
isa_ok( $explain,           'Pg::Explain' );
isa_ok( $explain->top_node, 'Pg::Explain::Node' );

is( $explain->top_node->type,                                     'GroupAggregate',   'Properly extracted top node type' );
is( $explain->top_node->sub_nodes->[ 0 ]->type,                   'Incremental Sort', 'Properly extracted subnode-1' );
is( $explain->top_node->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->type, 'Gather Merge',     'Properly extracted subnode-2' );

my $parallel = $explain->top_node->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->sub_nodes->[ 0 ];

is( $parallel->type,                      'Parallel Index Scan',    'Properly parallel node' );
is( $parallel->scan_on->{ 'index_name' }, 'wifi_seen_mac_freq_idx', 'Properly extracted index used for parallel node' );
is( $parallel->scan_on->{ 'table_name' }, 'wifi_seen',              'Properly extracted table used for parallel node' );

exit;
