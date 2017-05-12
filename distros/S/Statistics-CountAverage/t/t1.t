use Test::More tests => 2;
BEGIN { use_ok('Statistics::CountAverage') };

ok my $avg = new Statistics::CountAverage, "create object";
