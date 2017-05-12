use Mojo::Base -strict;
use Test::More;

use Mojar::Config;

my $config;

subtest q{parse} => sub {
  ok my $o = Mojar::Config->new, 'new';
  my $content = '{ abc => q{ABC} }';
  ok $config = $o->parse(\$content), 'parse';
  is $config->{abc}, q{ABC}, 'expected config value';
};

subtest q{load} => sub {
  ok $config = Mojar::Config->load('cfg/defaults.conf'), 'load';
  ok exists $config->{debug}, 'exists';
  ok ! defined($config->{debug}), 'undef';

  # scalar
  is $config->{expiration}, 36_000, 'expected config value';

  # arrayref
  is scalar(@{ $config->{secrets} }), 4, 'expected array size';

  # hashref
  is $config->{redis}{ip}, '192.168.1.1', 'expected config value';
  is $config->{redis}{port}, '6379', 'expected config value';
  is scalar(keys %{$config->{redis}}), 2, 'expected hash size';
};

SKIP: {
  skip 'set RELEASE_TESTING to enable this test (developer only!)', 1
    unless $ENV{RELEASE_TESTING};

use Mojo::Log;

subtest q{load} => sub {
  ok my $log = Mojo::Log->new, 'new log';
  ok $config = Mojar::Config->new->load('cfg/defaults.conf', log => $log),
      'log';
};

};

done_testing();
