# vim: set ft=perl:
use lib 't', 'lib';

use Oryx;
use YAML;

use Test::More qw(no_plan);
use Oryx::Class(auto_deploy => 1);
use CMS::Schema;

my $storage = Oryx->connect(['dbi:SQLite:dbname=test'], CMS::Schema);

# this class is defined in XML (in t/XMLSchema.pm) and is here at
# compile time, neat eh?
use CMS::Page( auto_deploy => 1 );

my $page = CMS::Page->create({ title => "my page" });
my $auth = CMS::Author->create({ first_name => "Richard Hundt" });

$page->author($auth);
$page->update;
$page->commit;

ok(1);
