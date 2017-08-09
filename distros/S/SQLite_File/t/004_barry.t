# -*-perl-*-
use lib '../lib';
use Test::More;
use File::Spec;
use SQLite_File qw/O_RDWR/;

my $dir = -d 't' ? 't' : '.';
my $testdb = File::Spec->catfile($dir,'my.db');
my ($key, $value);
my %db;
my $flags = O_RDWR;
diag 'Read the hash in 004';
ok tie( %db, 'SQLite_File', $testdb, $flags, 0666, $DB_HASH, 0), "tie";

is $db{'butcher'}, 1, "butcher correct";
is $db{'baker'}, 2, "baker correct";
ok $db{'candlestick maker'} = 4, "set candlestick maker";
is $db{'candlestick maker'}, 4, "candlesitck maker correct";
ok $db{'add this key'} = 5, "add this key";
is $db{'add this key'}, 5, "key added";

done_testing();
1;
