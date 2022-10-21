#!perl

use Test::More;
use autodie;

use Pg::Explain;
use Pg::Explain::Hinter;

my $plan_first_line = 'Seq Scan on sc_ramfs  (cost=0.00..1772.28 rows=1309 width=82) (actual time=0.019..9.993 rows=1324 loops=1)';
my $plan_last_line  = '  Rows Removed by Filter: 65258';

my @column_names = ( 'some_id', '"SomeID"' );
my @operators    = ( '=',       '<',    '>', '>=', '<=' );
my @values       = ( 12,        "'ab'", "'ab'::text", "'abc'::timestamp without time zone" );

plan 'tests' => 9 * scalar @column_names * scalar @operators * scalar @values;

for my $column ( @column_names ) {
    for my $operator ( @operators ) {
        for my $value ( @values ) {
            my $mid_line = sprintf '  Filter: (%s %s %s)', $column, $operator, $value;

            my $plan    = join( "\n", $plan_first_line, $mid_line, $plan_last_line ) . "\n";
            my $explain = Pg::Explain->new( 'source' => $plan );
            $explain->parse_source;

            my $hinter = Pg::Explain::Hinter->new( $explain );
            ok( $hinter->any_hints, "There are some hints : ${mid_line}" );

            is( scalar @{ $hinter->hints }, 1, "One hint! : ${mid_line}" );

            my $hint = $hinter->hints->[ 0 ];
            isa_ok( $hint, 'Pg::Explain::Hinter::Hint' );

            isa_ok( $hint->node, 'Pg::Explain::Node' );
            is( $hint->type, 'INDEXABLE_SEQSCAN_SIMPLE', "Hint for disk sort : ${mid_line}" );
            ok( defined $hint->details, "There are details : ${mid_line}" );
            is( ref $hint->details,    'ARRAY',   "Details are an array : ${mid_line}" );
            is( $hint->details->[ 0 ], $column,   "Name of column matches : ${mid_line}" );
            is( $hint->details->[ 1 ], $operator, "Operator matches : ${mid_line}" );
        }
    }
}

exit;
