
use File::Basename;
use Test::BDD::Infrastructure::Config;
use Test::BDD::Infrastructure::Config::Augeas;
use Test::BDD::Infrastructure::Config::Facter;

my $c = Test::BDD::Infrastructure::Config->new;
$c->load_config( dirname(__FILE__)."/config.yaml" );
$c->register_config(
	'a' => Test::BDD::Infrastructure::Config::Augeas->new,
	'f' => Test::BDD::Infrastructure::Config::Facter->new,
);

use Test::BDD::Infrastructure;

