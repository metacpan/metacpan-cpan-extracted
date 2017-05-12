use Test::More;

use Class::C3;
use MRO::Compat;

my @modules = (
               'Tapper::CLI',
               'Tapper::CLI::API',
               'Tapper::CLI::API::Command::download',
               'Tapper::CLI::API::Command::upload',
               'Tapper::CLI::DbDeploy',
               'Tapper::CLI::DbDeploy::Command::init',
               'Tapper::CLI::DbDeploy::Command::makeschemadiffs',
               'Tapper::CLI::DbDeploy::Command::saveschema',
               'Tapper::CLI::DbDeploy::Command::upgrade',
               'Tapper::CLI::Testrun',
               'Tapper::CLI::Testplan',
              );

plan tests => int @modules;

foreach my $module(@modules) {
        require_ok($module);
}
