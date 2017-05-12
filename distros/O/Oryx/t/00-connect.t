use lib 't', 'lib';
use Test::More tests => 1;
use Oryx;
use YAML;

my $conn = YAML::LoadFile('t/dsn.yml');
my $storage = Oryx->connect($conn);

#my $storage = Oryx->connect([ "dbi:Pg:dbname=test", 'test', 'test' ]);
#my $storage = Oryx->connect([ "dbm:Deep:datapath=/tmp" ]);

ok($storage->ping);
