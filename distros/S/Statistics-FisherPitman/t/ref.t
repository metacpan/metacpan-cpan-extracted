
use Test::More tests => 3;
BEGIN { use_ok('Statistics::FisherPitman') };

my @dist1 = (qw/16.0 34.3 34.6 57.6 63.1 88.2 94.2 111.8 112.1 139.0 165.6 176.7 216.2 221.1 276.7 362.8 373.4 387.1 442.2 706.0/);
my @dist2 = (qw/4.7 10.8 35.7 53.1 75.6 105.5 200.4 212.8 212.9 215.2 257.6 347.4 461.9 566.0 984.0 1040.0 1306.0 1908.0 3559.0 21679.0/);

my $fishpit = Statistics::FisherPitman->new();
eval {$fishpit->load_data({dist1 => \@dist1, dist2 => \@dist2});};

ok(!$@, $@);

my $t_value = $fishpit->t_value();

ok($t_value eq '56062045.0525', 't_value');

