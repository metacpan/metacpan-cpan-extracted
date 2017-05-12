use Mojo::Base -strict;
use Test::More;

use Mojar::Config::Ini;

my $config;

subtest q{parse} => sub {
  ok my $o = Mojar::Config::Ini->new, 'new';
  my $content = "abc = ABC";
  ok $config = $o->parse(\$content), 'parse';
  is $config->{_}{abc}, q{ABC}, 'expected config value';

  $content = qq{[mysql]\nlang = "en"};
  ok $config = $o->parse(\$content), 'parse';
  is $config->{mysql}{lang}, q{"en"}, 'expected config value';

  $content = "[apache]\nlog = '/var/log/apache/error.log'";
  ok $config = $o->parse(\$content), 'parse';
  is $config->{apache}{log}, q{'/var/log/apache/error.log'},
      'expected config value';
};

subtest q{parse_with_ignore} => sub {
  ok my $o = Mojar::Config::Ini->new, 'new';
  my $content = "abc = ABC";
  ok $config = $o->parse(\$content, sections => ':ignore'), 'parse';
  is $config->{abc}, q{ABC}, 'expected config value';

  $content = qq{[mysql]\nlang = "en"\n[mysqldump]\nlang = "fr"};
  ok $config = $o->parse(\$content, sections => ':ignore'), 'parse';
  is $config->{lang}, q{"fr"}, 'expected config value';

  $content = "[apache]\nlog = '/var/log/apache/error.log'";
  ok $config = $o->parse(\$content, sections => ':ignore'), 'parse';
  is $config->{log}, q{'/var/log/apache/error.log'}, 'expected config value';
};

subtest q{parse_with_filter} => sub {
  ok my $o = Mojar::Config::Ini->new, 'new';
  my $content = "abc = ABC";
  ok $config = $o->parse(\$content, sections => ['mysql']), 'parse';
  ok ! defined $config->{abc}, 'expected config value';

  $content = qq{[mysql]\nlang = "en"\n[mysqldump]\nlang = "fr"};
  ok $config = $o->parse(\$content, sections => ['mysql']), 'parse';
  is $config->{lang}, q{"en"}, 'expected config value';

  $content = "[apache]\nlog = '/var/log/apache/error.log'";
  ok $config = $o->parse(\$content, sections => ['apache']), 'parse';
  is $config->{log}, q{'/var/log/apache/error.log'}, 'expected config value';
};

subtest q{load} => sub {
  ok $config = Mojar::Config::Ini->load('cfg/defaults.cnf'), 'load';
  ok ! defined($config->{_}{debug}), 'undef';

  # scalar
  is $config->{_}{expiration}, 36_000, 'expected config value';

  # arrayref
  is scalar(split q{,}, $config->{_}{secrets}), 4, 'expected array size';

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
  ok $config = Mojar::Config::Ini->new->load('cfg/defaults.cnf', log => $log),
      'log';
};

};

done_testing();
