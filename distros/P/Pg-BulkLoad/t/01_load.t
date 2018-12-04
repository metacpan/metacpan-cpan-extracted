use 5.020;
use Test::More;
use Try::Tiny;
use Test::Exception;
use Data::Printer;
use Path::Tiny;
use Mojo::Pg;
use Test::MockObject;
use Carp;

diag( "DB_TESTING VALUE $ENV{DB_TESTING}" );

# Prepare 2 Mojo::Pg objects: one to manage the test database,
# the other to access it.
# You may need to adjust these values for your testing.
sub db_testing {
    my $dbname     = 'postgres';
    my $host       = 'localhost';
    my $port       = 5432;
    my $username   = 'postgres';
    my $password   = 'postgres';
    my $pgpostgres = Mojo::Pg->new();
    my $dsn        = "DBI:Pg:dbname=$dbname;host=$host;port=$port;";
    $pgpostgres->dsn($dsn);
    $pgpostgres->username($username);
    $pgpostgres->password($password);

    try { $pgpostgres->db->query('DROP DATABASE testbulkload') };
    try { $pgpostgres->db->query('CREATE DATABASE testbulkload') };

    $dbname = 'testbulkload';
    my $dbload = Mojo::Pg->new();
    $dsn = "DBI:Pg:dbname=$dbname;host=$host;port=$port;";
    $dbload->dsn($dsn);
    $dbload->username($username);
    $dbload->password($password);
    return $dbload; 
} 

# mockdb is always created so that seeding answers to mock
# works even when we're using a real db to have fewer
# if statements in tests. Also because Mock will always
# succeed creation does not need to be wrapped in a sub.
my $mockdb = Test::MockObject->new();
$mockdb->{answers} = [];
$mockdb->mock( 'do',
    sub { 
        my $I = shift;
        my $answer = shift $I->{answers}->@* ;
carp "mock answer to give answer $answer" ;
        if ( $answer eq 'fail' ) { die $answer }
        return $answer;
        }
    );
$mockdb->mock( 'errstr',
    sub { return shift $mockdb->{answers}->@* }
    );
$mockdb->mock( 'query',
    sub { return shift; }
    );
$mockdb->mock( 'array',
    sub { 
        my $I = shift;
        return [ shift $I->{answers}->@*  ] }
    );
$mockdb->mock( 'answers',
    sub { 
        my $I = shift @_;
        $I->{answers} = \@_; }
    );

my $db = $mockdb;
my $dbh = $mockdb;
if ( $ENV{DB_TESTING} ) {
    my $dbload = db_testing();
    $db = $dbload->db ;
    $dbh = $dbload->db->dbh ;
}

    my $createq1 = q/ CREATE TABLE public.load1
(
    string character varying COLLATE pg_catalog."default",
    adate date,
    atimestamp timestamp without time zone,
    aninteger integer
) /;
    try { $db->query($createq1) };

    path('/tmp/load1.csv')->spew(
        (   q/fickle floozy pickle,1812-11-04,2020-01-16 13:00:00,576
armistice signed,1918-11-01,1918-11-11 11:11:11,1918111
pearl harbor,1941-12-07,1941-12-07 08:00:00,1941
gladly bagrooted biscuitbox,2018-11-07,2016-12-31 04:11:59,23023
rescue vixen patriot doodles,1941-12-07,1951-12-07 08:00:00,6766
heartemoji x 3,2018-06-16,2018-06-16 12:00:00,
oops,,,
negatively varied ,,,-23023
rescue vixen patriot doodles,1948-11-07,,
RESCUE POODLES clippers needed,,,
,1961-01-11,1958-07-16 18:36:18,
/)    );
    path('/tmp/load1.csv2')->spew(
        (   q/"fickle floozy pickle",1812-11-04,2020-01-16 13:00:00,576
"armistice signed",1918-11-01,1918-11-11 11:11:11,1918111
"pearl harbor",1941-12-07,1941-12-07 08:00:00,1941
"gladly bagrooted biscuitbox",2018-11-07,2016-12-31 04:11:59,23023
"rescue vixen patriot doodles",1941-12-07,1951-12-07 08:00:00,6766
"heartemoji x 3",2018-06-16,2018-06-16 12:00:00,
"oops",,,
"negatively varied ",,,-23023
"rescue vixen patriot doodles",1948-11-07,,
"RESCUE POODLES clippers needed",,,
,1961-01-11,1958-07-16 18:36:18,
/
        )
    );
    path('/tmp/load1.tsv')->spew(
        (   q/fickle floozy pickle	1812-11-04	2020-01-16 13:00:00	576
armistice signed	1918-11-01	1918-11-11 11:11:11	1918111
pearl harbor	1941-12-07	1941-12-07 08:00:00	1941
gladly bagrooted biscuitbox	2018-11-07	2016-12-31 04:11:59	23023
rescue vixen patriot doodles	1941-12-07	1951-12-07 08:00:00	6766
heartemoji x 3	2018-06-16	2018-06-16 12:00:00	
oops			
negatively varied 			-23023
rescue vixen patriot doodles	1948-11-07		
RESCUE POODLES clippers needed			
	1961-01-11	1958-07-16 18:36:18	
/
        )
    );
path( '/tmp/loadbad1.csv')->spew(
(q/fickle floozy pickle,1812-11-04,2020-01-16 13:00:00,576
armistice signed,1918-11-01,1918-11-11 11:11:11,1918111
pearl harbor,1941-12-07,1941-12-07 08:00:00,1941
this is a bad line
gladly bagrooted biscuitbox,2018-11-07,2016-12-31 04:11:59,23023
rescue vixen patriot doodles,1941-12-07,1951-12-07 08:00:00,6766
heartemoji x 3,2018-06-16,2018-06-16 12:00:00,
oops,,,
we're really very sorry about another bad line,1904-04-04
negatively varied ,,,-23023
rescue vixen patriot doodles,1948-11-07,,
RESCUE POODLES clippers needed,,,
,1961-01-11,1958-07-16 18:36:18,
/) );
path( '/tmp/loadbad2.csv')->spew(
(q/fickle floozy pickle,1812-11-04,2020-01-16 13:00:00,576
armistice signed,1918-11-01,1918-11-11 11:11:11,1918111
pearl harbor,1941-12-07,1941-12-07 08:00:00,1941
this is a bad line
gladly bagrooted biscuitbox,2018-11-07,2016-12-31 04:11:59,23023
rescue vixen patriot doodles,1941-12-07,1951-12-07 08:00:00,6766, gadfly
heartemoji x 3,2018-06-16,2018-06-16 12:00:00,
oops,,,
oops,,,
,sd0-cat-got,on,my
keyboard
willy goolily gadfly blond hero
kuzuntite
aaaah choo
we're really very sorry about another bad line,1904-04-04
negatively varied ,,,-23023
rescue vixen patriot doodles,1948-11-07,,
RESCUE POODLES clippers needed,,,
,1961-01-11,1958-07-16 18:36:18,
/) );

# }

# plan skip_all => 'Not set up for db tests' unless $ENV{DB_TESTING};

use_ok('Pg::BulkLoad');

use feature qw/signatures postderef/;
no warnings qw/experimental uninitialized/;

my %args = (
    pg        => $dbh,
    errorfile => '/tmp/pgbulk.error',
);

my $pgc = Pg::BulkLoad->new(%args);

sub test_some_data ( $file, $format, $insert_count ) {
    $db->query('truncate load1');
    is( $pgc->load( $file, 'load1', $format ),
        $insert_count, "$file inserted $insert_count rows." );
    is( $db->query('select count(*) from load1')->array->[0],
        $insert_count, "confirm insert $insert_count rows" );
}

$mockdb->answers( 11, 11, 11, 11, 11, 11 );
test_some_data( '/tmp/load1.csv',  'csv',  11 );
test_some_data( '/tmp/load1.csv2', 'csv',  11 );
test_some_data( '/tmp/load1.tsv',  'text', 11 );

SKIP: {
      skip 'Not running all tests with MOCKED DataBase', 
      undef unless $ENV{DB_TESTING};

note('testing a file with some bad lines');
# this was somehow passing with mock, but since it shouldn't have 
# I'm still skipping it when testing with mockdb.
$mockdb->answers( 'fail', 'failed, line 4', 3, 'fail', 'failed, line 8', 13, 12, 11 );
test_some_data( '/tmp/loadbad1.csv', 'csv', 11 );

undef $pgc;    # force close of error file.

my $err1 = path('/tmp/pgbulk.error')->slurp;
like( $err1, qr/this is a bad line/, "Evicted: this is a bad line " );
like( $err1, qr/another bad line/,   "Evicted: another bad line " );

note('testing a file with too many errors');
$args{errorlimit} = 5;
my $pgc2 = Pg::BulkLoad->new(%args);

$db->query('truncate load1');
dies_ok(
    sub { $pgc2->load( '/tmp/loadbad2.csv', 'load1', 'csv' ) },
    'Set badrow errorlimit and file with too many, died!'
);
undef $pgc2;
my $err2 = path('/tmp/pgbulk.error')->slurp;
like( $err2, qr/gadfly/, "Evicted: bad line with word gadfly " );
like(
    $err2,
    qr/Exceeded Error limit with 5 Errors/,
    "error file says it Exceeded Error limit with 5 Errors"
);

}; # skip

# $pgc->process( 't/loadbad1.csv', 'load1', 'csv');

# my $r = $pgc->{db}->query('select count(*) from load1')->array->[0];
# p $r;

done_testing();

# cleanup
# try { $pgpostgres->db->query('DROP DATABASE testbulkload') };

=pod 

loopmax 12
loadq copy load1 from '/tmp/pgbulkcopywork.csv' with ( format 'csv' )
line 1 DBD::Pg::st execute failed: ERROR:  missing data for column "adate"
CONTEXT:  COPY load1, line 4: "this is a bad line" at /home/brainbuz/projects/Pg-BulkLoad/lib/Pg/BulkLoad.pm line 68.
