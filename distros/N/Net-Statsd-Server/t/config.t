=head1 NAME

t/config.t - Net::Statsd::Server test suite

=head1 DESCRIPTION

Test the loading of the configuration file.

=cut

use strict;
use warnings;
use Data::Dumper;
use Test::More;

use Net::Statsd::Server;

plan tests => 7;

my $s = Net::Statsd::Server->new({
  config_file => 't/config/testConfig.js',
});

my $c = $s->config();

ok ref $c eq 'HASH' && keys %{$c} > 0,
  'Config was loaded correctly';

is $c->{prefixStats}, 'statsd',
  'Defaults for missing keys are applied correctly';

is $c->{graphitePort}, 40003,
  'A random value from the config file was loaded';

is $c->{dumpMessages}, '',
  'Boolean values are converted correctly from false';

is $c->{flush_counters}, 1,
  'Boolean values are converted correctly from true';

is_deeply $c->{log}, {
  backend => 'stdout',
  level   => 'LOG_INFO'
}, 'Structures are loaded correctly (hashes)';

is_deeply $c->{backends}, [
  './backends/console', './backends/graphite'
], 'Structures are loaded correctly (arrays)';
