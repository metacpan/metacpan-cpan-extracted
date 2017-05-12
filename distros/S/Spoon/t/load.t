use lib 't', 'lib';
use strict;
use warnings;
BEGIN { $^W = 1 }
use Test::More 'no_plan';

ok(eval {require Spoon; 1});
my $spoon = Spoon->new;
my $hub;
ok($hub = $spoon->load_hub);
$hub = $spoon->hub;
ok($hub);
ok($hub->config);
my %config = $hub->config->all;
my @classes = grep {
    s/_class$// and
      not /^registry$/;
} keys %config;

for my $class (@classes) {
    ok($hub->$class);
}
