#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use autodie;
plan 'tests' => 6;

use Pg::Explain;

my $plan_source = q{                                                     QUERY PLAN                                                      
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
 Hash Left Join  (cost=11.83..13.98 rows=11 width=268) (actual time=0.264..0.360 rows=42 loops=1)
   Hash Cond: (p.gid = g.gid)
   InitPlan 1 (returns $0)
     ->  Aggregate  (cost=9.92..9.93 rows=1 width=0) (actual time=0.088..0.088 rows=1 loops=1)
           ->  Foreign Scan on passwd  (cost=0.00..9.70 rows=87 width=0) (actual time=0.010..0.079 rows=42 loops=1)
                 Foreign File: /etc/passwd
                 Foreign File Size: 2079
   ->  Foreign Scan on passwd p  (cost=0.00..2.10 rows=11 width=168) (actual time=0.019..0.090 rows=42 loops=1)
         Foreign File: /etc/passwd
         Foreign File Size: 2079
   ->  Hash  (cost=1.80..1.80 rows=8 width=100) (actual time=0.112..0.112 rows=71 loops=1)
         Buckets: 1024  Batches: 1  Memory Usage: 4kB
         ->  Foreign Scan on groups g  (cost=0.00..1.80 rows=8 width=100) (actual time=0.013..0.080 rows=71 loops=1)
               Foreign File: /etc/group
               Foreign File Size: 987
 Total runtime: 0.511 ms
};

my $explain = Pg::Explain->new( 'source' => $plan_source );
isa_ok( $explain,           'Pg::Explain' );
isa_ok( $explain->top_node, 'Pg::Explain::Node' );
lives_ok(
    sub {
        $explain->anonymize();
    },
    'Anonymization works',
);

my $textual = $explain->as_text();

ok( $textual !~ /passwd/, 'anonymize() hides foreign file names (passwd)' );
ok( $textual !~ /group/, 'anonymize() hides foreign file names (group)' );

my @files = $textual =~ m{^\s*Foreign File: (.*?)\s*$}mg;
my %counts = ();
for my $f ( @files ) {
    $counts{$f}++;
}

my @just_counts = sort { $a <=> $b } values %counts;
my $counts_string = join ',', @just_counts;
ok( $counts_string eq '1,2', 'Same file anonymized to the same string' );

exit;

