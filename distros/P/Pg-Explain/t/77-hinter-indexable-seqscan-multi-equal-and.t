#!perl

use Test::More;
use Test::Deep;
use autodie;

use Pg::Explain;
use Pg::Explain::Hinter;

my $plan = q{
Seq Scan on piece_jointe  (cost=0.00..96.39 rows=4 width=52) (actual time=0.314..0.322 rows=9 loops=1)
  Filter: ((projet = 10317) AND (section = 29) AND (zone = 4))
  Rows Removed by Filter: 2813
};

plan 'tests' => 8;

my $explain = Pg::Explain->new( 'source' => $plan );
$explain->parse_source;

my $hinter = Pg::Explain::Hinter->new( $explain );
ok( $hinter->any_hints, "There are some hints : ${mid_line}" );

is( scalar @{ $hinter->hints }, 1, "One hint! : ${mid_line}");

my $hint = $hinter->hints->[0];
isa_ok($hint, 'Pg::Explain::Hinter::Hint');

isa_ok($hint->node, 'Pg::Explain::Node');
is( $hint->type, 'INDEXABLE_SEQSCAN_MULTI_EQUAL_AND', 'Correct hint type' );
ok( defined $hint->details, 'There are details' );
is( ref $hint->details, 'ARRAY', 'Details are an array' );
cmp_deeply(
    $hint->details,
    [
        { 'column' => 'projet', 'value' => '10317' },
        { 'column' => 'section', 'value' => '29' },
        { 'column' => 'zone', 'value' => '4' },
    ],
    'Expected details for hint'
);

exit;
