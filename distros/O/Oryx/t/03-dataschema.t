# vim: set ft=perl:
use lib 't', 'lib';

use Oryx;
use YAML;

use Test::More qw(no_plan);
use DataSchema ( auto_deploy => 1 );

my $conn = YAML::LoadFile('t/dsn.yml');
my $storage = Oryx->connect($conn);

ok(DataSchema->attributes);
ok(DataSchema->attributes->{foo_attr});
