# -*-perl-*-
use lib '../lib';
use Test::More;
use File::Spec;
use SQLite_File;

my $dir = -d 't' ? 't' : '.';
my $testdb = File::Spec->catfile($dir,'my.db');
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
