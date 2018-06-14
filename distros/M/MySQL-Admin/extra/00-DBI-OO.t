# use strict;
# use warnings;
#use lib qw(lib);
use DBI::Library;
do('t/config.pl');

my ($m_oDatabase, $dbh) = new DBI::Library(

    {

        name => $m_hrSettings->{database}{name},

        host => $m_hrSettings->{database}{host},

        user => $m_hrSettings->{database}{user},

        password => $m_hrSettings->{database}{password},

    }

);
use Test::More tests => 2;
my %execute2 = (
                title       => 'truncateQuerys',
                description => 'description',
                sql         => "truncate querys",
                return      => "void",
               );
my %execute3 = (
                title       => 'showTables',
                description => 'description',
                sql         => "show tables",
                return      => "fetch_array",
               );
$m_oDatabase->addexecute(\%execute2);
$m_oDatabase->addexecute(\%execute3);
my %execute4 = (
                title       => 'select',
                description => 'description',
                sql         => "select *from querys where `title` = ?",
                return      => "fetch_hashref"
               );
$m_oDatabase->addexecute(\%execute4);
my $showTables = $m_oDatabase->select('showTables');
ok($showTables->{sql} eq 'show tables');
$m_oDatabase->truncateQuerys();
ok($m_oDatabase->tableLength('querys') == 0);
