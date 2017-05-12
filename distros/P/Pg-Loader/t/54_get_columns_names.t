BEGIN { push @ARGV, "--dbitest=42"; }
use Pg::Loader::Query;
use Test::More qw( no_plan );
use Test::MockDBI;

*get_columns_names = \&Pg::Loader::Query::get_columns_names;

my $dh = DBI->connect( '$dsn', '','');
ok $dh;

my $mock = get_instance Test::MockDBI;
my $fake = [ [ 'classid', '1'    ], [ 'objid','2'   ], ['objsubid','3'],
             [ 'refclassid', '4' ], [ 'refobjid','5'], 
             [ 'refobjsubid', '6'], [ 'deptype','7' ]
];
my @fake = qw( classid objid objsubid refclassid refobjid refobjsubid deptype);

$mock->set_retval_scalar( 42, '.*select column_name, ordi.*', $fake);

is_deeply [ get_columns_names( $dh, 'pg_catalog','pg_depend') ] , [@fake];

