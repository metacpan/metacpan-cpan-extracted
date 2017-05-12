use TM::Materialized::MLDBM;

my $tm = new TM::Materialized::MLDBM (file => '/tmp/rumsti');

$tm->internalize ('xxx');
$tm->sync_out;
