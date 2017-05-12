# -*-perl-*-

# lib.pl is the file where database specific things should live,
# whereever possible. For example, you define certain constants
# here and the like.

use strict;
use warnings;

use vars qw($test_dsn $test_user $test_pass $test_pass $test_attr $dbh $short_dsn $PK $dir);

use Carp;
use Cwd;
use File::Path;
use File::Spec;

my %v;
my @req = qw(DBI Template Template::Plugin::DBI);
my @eval = map { qq{require $_;\n\$v{"$_"} = $_->VERSION ()} } @req;
$@ = undef;
eval $_ for @eval;

if ($@)
{
    my @missing = grep { !exists $v{$_} } qw( DBI Template );
    print STDERR "\n\nYOU ARE MISSING REQUIRED MODULES: [ @missing ]\n\n";
    exit 0;
}

# Start each test clean
$dir = File::Spec->catdir( getcwd(), 'test_output' );
rmtree $dir;
END { rmtree $dir }
mkpath $dir;

$test_dsn  = $ENV{DBI_DSN}  || "dbi:DBM(RaiseError=0,PrintError=1,ChopBlanks=1):f_dir=$dir;dbm_mldbm=Storable";
$test_user = $ENV{DBI_USER} || "";
$test_pass = $ENV{DBI_PASS} || "";
$test_attr = {};

# new feature in DBI plugin v2.30+ is to allow user to drop initial 'dbi:'
( $short_dsn = $test_dsn ) =~ s/^dbi://i;

# another hack: if we want to test Tie::DBI updates then we have to build
# database with primary keys to force uniqueness.  However, different database
# have different ways of defining primary keys, so we're only going to test
# it on mysql
$PK = ( $short_dsn =~ /^mysql/i ) ? 'PRIMARY KEY' : '';

eval "use Tie::DBI";
my $tiedbi = $@ ? 0 : 1;

sub BAIL_OUT($)
{
    carp $_[0];
    ntests(1);
    ok(0);
    exit(0);
}

sub get_tt_test_vars
{
    my $vars = {
                 dbh    => $dbh,
                 dsn    => $test_dsn,
                 user   => $test_user,
                 pass   => $test_pass,
                 attr   => $test_attr,
                 short  => $short_dsn,
                 mysql  => $PK ? 1 : 0,
                 tiedbi => $tiedbi,
               };
    return $vars;
}

sub connect_database
{
    $dbh = DBI->connect( $test_dsn, $test_user, $test_pass );
}

#------------------------------------------------------------------------
# init_database
#------------------------------------------------------------------------

sub init_database
{
    my $dbh = shift;

    # ensure tables don't already exist (in case previous test run failed).
    sql_query( $dbh, 'DROP TABLE IF EXISTS usr', 1 );
    sql_query( $dbh, 'DROP TABLE IF EXISTS grp', 1 );

    # create some tables
    sql_query(
        $dbh, "CREATE TABLE grp ( 
                         id Char(16) $PK, 
                         name Char(32) 
                     )"
             );

    sql_query(
        $dbh, "CREATE TABLE usr  ( 
                         id Char(16) $PK, 
                         name Char(32),
                         grp Char(16)
                     )"
             );

    # add some records to the 'grp' table
    sql_query(
        $dbh, "INSERT INTO grp 
                     VALUES ('foo', 'The Foo Group')" );
    sql_query(
        $dbh, "INSERT INTO grp 
                     VALUES ('bar', 'The Bar Group')" );
    sql_query(
        $dbh, "INSERT INTO grp 
                     VALUES ('baz', 'The Baz Group')" );

    # add some records to the 'usr' table
    sql_query(
        $dbh, "INSERT INTO usr 
		     VALUES ('abw', 'Andy Wardley', 'foo')" );
    sql_query(
        $dbh, "INSERT INTO usr 
		     VALUES ('sam', 'Simon Matthews', 'foo')" );

    sql_query(
        $dbh, "INSERT INTO usr 
		     VALUES ('hans', 'Hans von Lengerke', 'bar')" );
    sql_query(
        $dbh, "INSERT INTO usr 
		     VALUES ('mrp', 'Martin Portman', 'bar')" );

    sql_query(
        $dbh, "INSERT INTO usr 
		     VALUES ('craig', 'Craig Barratt', 'baz')" );

}

#------------------------------------------------------------------------
# sql_query($dbh, $sql, $quiet)
#------------------------------------------------------------------------

sub sql_query
{
    my ( $dbh, $sql, $quiet ) = @_;

    my $sth = $dbh->prepare($sql)
      || warn "prepare() failed: $DBI::errstr\n";

    $sth->execute()
      || $quiet
      || warn "execute() failed: $DBI::errstr\n";

    $sth->finish();
}

#------------------------------------------------------------------------
# cleanup_database($dsn, $user, $pass)
#------------------------------------------------------------------------

sub cleanup_database
{
    my $dbh = shift;

    sql_query( $dbh, 'DROP TABLE usr' );
    sql_query( $dbh, 'DROP TABLE grp' );
}

1;
