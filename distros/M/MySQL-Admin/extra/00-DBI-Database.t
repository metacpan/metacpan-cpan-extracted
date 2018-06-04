# use strict;
# use warnings;
use lib qw(lib/);

# do('t/config.pl');
use MySQL::Admin::Settings;
use vars qw($m_hrSettings);
loadSettings("cgi-bin/settings.pl");
*m_hrSettings = \$MySQL::Admin::Settings::m_hrSettings;
use DBI::Library;
my $m_oDatabase = new DBI::Library();
my %hash = (
    name => $m_hrSettings->{database}{name},

    host => $m_hrSettings->{database}{host},

    user => $m_hrSettings->{database}{user},

    password => $m_hrSettings->{database}{password},
           );
my $m_dbh = $m_oDatabase->initDB(\%hash);
my %execute = (
               title       => 'showTables',
               description => 'description',
               sql         => "show tables",
               return      => "fetch_array",
              );
my %execute2 = (
                title       => 'truncateQuerys',
                description => 'description',
                sql         => "truncate querys",
                return      => "void",
               );
my %execute3 = (
                title       => 'querys',
                description => 'description',
                sql         => "select * from querys ",
                return      => "fetch_array",
               );
$m_oDatabase->addexecute(\%execute);
$m_oDatabase->addexecute(\%execute2);
$m_oDatabase->addexecute(\%execute3);
my @a1   = $m_oDatabase->useexecute("showTables");
my @a2   = $m_oDatabase->showTables();
my @a3   = $m_oDatabase->fetch_array('show tables');
my $hash = $m_oDatabase->fetch_hashref('select *from querys where `title` = ? && `description` = ?',
                                       'showTables', 'description');
my $hash2 = $m_oDatabase->fetch_hashref("select *from querys where `title` = 'showTables'");
my @aoh   = $m_oDatabase->fetch_AoH('select *from querys where `return` = ? && `description` = ?',
                                  'fetch_array', 'description');
my @aoa = $m_oDatabase->fetch_array('select *from querys;');
my $sth = $m_dbh->prepare("select *from querys where `title` = 'showTables'");
$sth->execute() or warn $m_dbh->errstr;
my $ref = $sth->fetchrow_hashref;
$sth->finish();
use Test::More tests => 9;
ok($#a1 > 0);
ok($#a1 eq $#a2);
ok($#a2 eq $#a3);
ok($hash->{sql} eq $hash2->{sql});
ok($#aoh > 0);
$sth->finish();
$sth = $m_dbh->prepare("select *from querys");
$sth->execute();
ok(!$@);
$sth->finish();
my %execute4 = (
                title       => 'select',
                description => 'description',
                sql         => 'select * from <TABLE> where `title` = ?',
                return      => "fetch_hashref"
               );
$m_oDatabase->addexecute(\%execute4);
$m_oDatabase->selectTable('querys');
my $showTables = $m_oDatabase->select('showTables');
ok($showTables->{sql} eq 'show tables');
my %execute5 = (
                title       => 'joins',
                description => 'description',
                sql         => 'select * from table_1 JOIN  table_2 ',
                return      => "fetch_hashref"
               );
$m_oDatabase->addexecute(\%execute5);
my $ref2 = $m_oDatabase->joins(
                               {
                                identifier => {
                                               1 => 'actions',
                                               2 => 'querys'
                                              }
                               }
                              );
ok(ref $ref2 eq 'HASH');
$m_oDatabase->truncateQuerys();
ok($m_oDatabase->tableLength('querys') == 0);
