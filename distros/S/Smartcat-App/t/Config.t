
=begin comment

Smartcat::App::Config tests

=end comment

=cut

use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;
use Test::Fatal;
use Test::MockModule;

use Cwd qw(abs_path);
use File::Basename;
use File::Copy;
use File::Spec::Functions qw(catfile);

use lib 'lib';

use_ok('Smartcat::App::Config');

my $test_config_path =
  catfile( dirname( abs_path(__FILE__) ), 'data', 'test.config' );

my $config_module = Test::MockModule->new('Smartcat::App::Config');
$config_module->mock( get_config_file => sub { return $test_config_path; } );

my $config = Smartcat::App::Config->load;
copy( $test_config_path, $test_config_path . ".bak" );

is( $config->username, '__token_id__',
    "'username' attribute set as 'token_id' value" );
is( $config->password, '__token__',
    "'password' attribute set as 'token' value" );
ok( $config->log eq '__log__', "'log' attribute set properly" );

$config->{username} = '__token_id__changed__';
$config->{password} = '__token__changed__';
$config->{log}      = '__log__changed__';
$config->save;

$config = Smartcat::App::Config->load;

ok(
    $config->username eq '__token_id__changed__',
    "'username' attribute saved properly"
);
ok(
    $config->password eq '__token__changed__',
    "'password' attribute saved properly"
);
ok( $config->log eq '__log__changed__', "'log' attribute saved properly" );

move( $test_config_path . ".bak", $test_config_path );

$test_config_path =
  catfile( dirname( abs_path(__FILE__) ), 'data', 'test_validate_log.config' );
like(
    exception {
        Smartcat::App::Config->load;
    },
    qr'ConfigError',
    "not valid 'log' value in config file raised an error"
);

$test_config_path =
  catfile( dirname( abs_path(__FILE__) ), 'data', 'non_existing.config' );
is( ref Smartcat::App::Config->load->{instance},
    'Config::Tiny',
    "init empty Config::Tiny instance for non existing config file" );

1;
