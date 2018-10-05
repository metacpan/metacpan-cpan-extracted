
=begin comment

Smartcat App basic tests

=end comment

=cut

use strict;
use warnings;

use Test::More tests => 19;
use Test::Exception;
use App::Cmd::Tester;

use lib 'lib';

use_ok('Smartcat::App');

my $app = Smartcat::App->new();
isa_ok( $app,                      'Smartcat::App' );
isa_ok( $app->project_api,         'Smartcat::App::ProjectApi' );
isa_ok( $app->project_api->{api},  'Smartcat::Client::ProjectApi' );
isa_ok( $app->document_api,        'Smartcat::App::DocumentApi' );
isa_ok( $app->document_api->{api}, 'Smartcat::Client::DocumentApi' );
isa_ok( $app->document_export_api, 'Smartcat::App::DocumentExportApi' );
isa_ok( $app->document_export_api->{api},
    'Smartcat::Client::DocumentExportApi' );

is_deeply(
    [ sort $app->command_names ],
    [
        sort
          qw(--help --version -? -h account commands config document help project pull push version)
    ],
    "got correct list of registered command names",
);

is_deeply(
    [ sort $app->command_plugins ],
    [
        sort qw(
          Smartcat::App::Command::document
          Smartcat::App::Command::config
          Smartcat::App::Command::pull
          App::Cmd::Command::version
          App::Cmd::Command::commands
          App::Cmd::Command::help
          Smartcat::App::Command::push
          Smartcat::App::Command::project
          Smartcat::App::Command::account
          )
    ],
    "got correct list of registered command plugins",
);

my $return = test_app( 'Smartcat::App', [qw(commands)] );

for my $name (qw(account commands config document help project pull push)) {
    like( $return->stdout, qr/^\s+\Q$name\E/sm, "$name plugin in listing" );
}
unlike( $return->stdout, qr/--version/, "version plugin not in listing" );

1;
