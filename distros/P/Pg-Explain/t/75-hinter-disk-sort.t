#!perl

use Test::More;
use autodie;

use Pg::Explain;
use Pg::Explain::Hinter;

my $plan = q{
Sort  (cost=1889.23..1931.55 rows=16928 width=215) (actual time=261.096..269.735 rows=16928 loops=1)
  Sort Key: sold DESC
  Sort Method: external merge  Disk: 3840kB
  ->  Seq Scan on jakarta  (cost=0.00..700.28 rows=16928 width=215) (actual time=0.007..2.255 rows=16928 loops=1)
};

plan 'tests' => 8;

my $explain = Pg::Explain->new( 'source' => $plan );
$explain->parse_source;

my $hinter = Pg::Explain::Hinter->new( $explain );
ok( $hinter->any_hints, 'There are some hints' );

is( scalar @{ $hinter->hints }, 1, 'One hint!' );

my $hint = $hinter->hints->[ 0 ];
isa_ok( $hint, 'Pg::Explain::Hinter::Hint' );

isa_ok( $hint->node, 'Pg::Explain::Node' );
is( $hint->type, 'DISK_SORT', 'Hint for disk sort' );
ok( defined $hint->details, 'There are details' );
is( ref $hint->details,    'ARRAY', 'Details are an array' );
is( $hint->details->[ 0 ], '3840',  'Disk space used for sort' );

exit;
