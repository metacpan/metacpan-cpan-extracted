use Modern::Perl;
use Test::More;


my $module = 'MooX::CalcTime';

BEGIN {
  $module = 'MooX::CalcTime';
  use_ok($module);
}

can_ok($module, "_time_start");

my @methods = qw/get_run_second get_runtime print_runtime/;

for my $method (@methods) {
  can_ok($module, $method);
}

done_testing;

