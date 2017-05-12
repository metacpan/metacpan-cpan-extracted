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
my $flags = O_CREAT | O_RDWR;
diag 'Write a hash in 003';
ok tie( %db, 'AnyDBM_File', 'my.db', $flags, 0666, $DB_HASH, 0), "tie";
(tied %db)->keep(1);
ok $db{'butcher'} = 1, "set";
ok $db{'baker'} = 2, "set";
ok $db{'candlestick maker'} = 3, "set";

done_testing();
1;
