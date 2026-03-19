#!perl
use v5.36;
use Test::More;
use List::Util qw(any);
#our $verbose = grep { $_ eq '-v' or $_ eq '--verbose' } @ARGV;

do_tests();
done_testing();

#######################################################################

sub do_tests {

  my $pl_config_fn = './t/tsupport/config.pl';
  my $js_config_fn = './t/tsupport/config.json';

  {
    my $ok = eval qq|
      package My::Test::AppWithConfig {
        use PlackX::Framework qw(:Config);
        use My::Test::AppWithConfig::Config '$pl_config_fn';
      }
      1;
    |;

    ok($ok, 'Create a PXF app with auto-creation of Config module');

    ok(My::Test::AppWithConfig->can('config'), 'PXF app has a config method');

    ok(My::Test::AppWithConfig::Config->can('config'), 'PXF::Config has a config method');

    ok(ref My::Test::AppWithConfig->config eq 'HASH', 'App->config method returns hashref');

    ok(ref My::Test::AppWithConfig::Config->config eq 'HASH', '::Config->onfig method returns hashref');

    ok(ref My::Test::AppWithConfig->config eq ref My::Test::AppWithConfig::Config->config, 'App->config and ::Config->config return same hashref');

    my $conf = My::Test::AppWithConfig->config;
    is(
      $conf->{key} => 'value',
      'Config parsed correctly (key => value)',
    );

    is(
      $conf->{key2} => 'value2',
      'Config parsed correctly (key2 => value2)',
    );

    is_deeply(
      $conf->{key3} => [qw(value1 value2 value3)],
      'Config parsed correctly (key3 => arrayref)',
    );

    is_deeply(
      $conf->{key4} => {very => 'complex'},
      'Config parsed correctly (key4 => hashref)'
    );
  }

  {
    my $ok = eval qq|
      package My::Test::AppWithConfig2::Config {
        use parent 'PlackX::Framework::Config';
      }
      My::Test::AppWithConfig2::Config->import('$pl_config_fn');
      package My::Test::AppWithConfig2 {
        use PlackX::Framework; # qw(:Config); - no need to request it, we did it manually
      }
      1;
    |;

    ok(
      (
        $ok
        and My::Test::AppWithConfig2::Config->config
        and My::Test::AppWithConfig2->config
        and My::Test::AppWithConfig2::Config->config eq My::Test::AppWithConfig2->config
        and My::Test::AppWithConfig2::Config->config->{key} eq 'value'
      ),
      'Set up config module manually'
    );

    is_deeply(
      My::Test::AppWithConfig->config => My::Test::AppWithConfig2->config,
      'Different apps with same config file result in same config'
    );
  }

  unless (
    eval { require Config::Any; 1 }
    and
    any {
      eval "require $_; 1";
    } (qw/Cpanel::JSON::XS JSON::MaybeXS JSON::DWIW JSON::XS JSON::Syck JSON::PP JSON/)
  )
  {
    say 'Skipping JSON config file test (need Config::Any and supported JSON parser)';
    return;
  }

  {
    my $ok = eval qq|
      package My::Test::AppWithConfig3 {
        use PlackX::Framework qw(:Config);
        use My::Test::AppWithConfig3::Config '$js_config_fn';
      }
      1;
    |;

    ok($ok, 'Create a PXF app with auto-creation of Config module with JSON config file'.$@);

    ok(
      (
        My::Test::AppWithConfig3->config
        and ref My::Test::AppWithConfig3->config
        and ref My::Test::AppWithConfig3->config eq 'HASH'
        and My::Test::AppWithConfig3->config eq My::Test::AppWithConfig3::Config->config
      ),
      'Loaded and parsed JSON config file'
    );

    is_deeply(
      My::Test::AppWithConfig3->config => {
        key1 => 'value1',
        key2 => 'value2',
        some_array => [1, 2, 3],
        some_hash  => {
          subkey1 => 'subvalue1',
          subkey2 => 'subvalue2',
        }
      },
      'JSON config parsed correctly'
    );
  }
}
