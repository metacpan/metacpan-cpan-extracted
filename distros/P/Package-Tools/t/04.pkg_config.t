BEGIN {
  use strict;
  use Test::More;
  plan tests => 13;
  use_ok('Data::Dumper');
  use_ok('Package::Configure');
}


ok(my $config = Package::Configure->new());

ok(my $s1 = $config->opt_string());
ok(my $s2 = $config->opt_integer());

ok($s1 eq 'phi');
ok($s2 == 1);

ok($config->opt_string('barbaz'));
ok($config->opt_string eq 'barbaz');
ok($config->opt_string('phi'));

ok(my $s3 = $config->opt_string());
ok($s3 eq 'phi');

ok($config->ambiguous);
