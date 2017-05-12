# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Synapse-Object.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib ('../lib', './lib');
use Test::More;

for (qw /Synapse::CLI::Config Synapse::CLI::Config::Type Synapse::CLI::Config::Object/) {
    eval "use $_";
    my $ok = $@ ? 0 : 1;
    ok ($ok, "use $_");
}

$Synapse::CLI::Config::BASE_DIR = "/etc/myapp";
$Synapse::CLI::Config::BASE_DIR = "./t/config";
$Synapse::CLI::Config::ALIAS->{type}   = 'Synapse::CLI::Config::Type';
$Synapse::CLI::Config::ALIAS->{object} = 'Synapse::CLI::Config::Object';
#Synapse::CLI::Config::execute (@ARGV);
#Synapse::CLI::Config::flush();


Test::More::done_testing();
