use Test2::V0 -no_srand => 1;
use NewFangle;
use YAML qw( Dump );

$ENV{NEWRELIC_LICENSE_KEY} = 'a' x 40;

my $config = NewFangle::Config->new;
isa_ok $config, 'NewFangle::Config';
note Dump($config->to_perl);

done_testing;
