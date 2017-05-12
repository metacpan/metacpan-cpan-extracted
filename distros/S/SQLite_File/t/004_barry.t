# -*-perl-*-
BEGIN {
    use lib '../lib';
    use Test::More;
    @AnyDBM_File::ISA = qw( SQLite_File );
    use_ok('DBD::SQLite');
    use_ok('AnyDBM_File');
}

use vars qw( $DB_HASH $DB_TREE $DB_RECNO &R_DUP &R_CURSOR &O_CREAT &O_RDWR &O_RDONLY);
use AnyDBM_File::Importer qw(:bdb);
my ($key, $value);
my %db;
my $flags = O_RDWR;
diag 'Read the hash in 004';
ok tie( %db, 'AnyDBM_File', 'my.db', $flags, 0666, $DB_HASH, 0), "tie";
is $db{'butcher'}, 1, "butcher correct";
is $db{'baker'}, 2, "baker correct";
ok $db{'candlestick maker'} = 4, "set candlestick maker";
is $db{'candlestick maker'}, 4, "candlesitck maker correct";
ok $db{'add this key'} = 5, "add this key";
is $db{'add this key'}, 5, "key added";

done_testing();
1;
