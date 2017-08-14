use lib '../lib';
use Module::Build;
use Test::More;
use File::Temp;
use SQLite_File;

my $build = Module::Build->current();

my $testdb_h = File::Temp->new(UNLINK => 0, EXLOCK => 0);
my $testdb = $testdb_h->filename;
$build->notes('testdb' => $testdb);
my ($key, $value);
my %db;
my $flags = O_CREAT | O_RDWR;
diag 'Write a hash in 003';
ok tie( %db, 'SQLite_File', $testdb, $flags, 0666, $DB_HASH, 0), "tie";
(tied %db)->keep(1);
ok $db{'butcher'} = 1, "set";
ok $db{'baker'} = 2, "set";
ok $db{'candlestick maker'} = 3, "set";

done_testing();
1;
