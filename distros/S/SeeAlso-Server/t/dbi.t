#!perl -Tw

use strict;

use Test::More;
use SeeAlso::DBI;
use SeeAlso::Identifier;
use SeeAlso::Response;
use SeeAlso::Source;
use Data::Dumper;
use File::Temp qw(tempfile);
use DBI;

my @res = (
    SeeAlso::Response->new("x",["a"],["b"],["x:c"]),
    SeeAlso::Response->new("1",["l1"],["hello"],["uri:1"]),
);
my ($source,$r);
my (undef,$file) = tempfile;

my $dbh = eval { DBI->connect("dbi:SQLite:dbname=$file","",""); };

if ( $dbh ) {
    plan( 'no_plan' );
} else {
    plan( skip_all => 'DBD::SQLite required to test SeeAlso::DBI' );
    exit;
}

$source = SeeAlso::DBI->new( dbh => $dbh, build => 1 );
isa_ok( $source, 'SeeAlso::DBI' );

$r = $res[0];
$source->insert($r);
my $r2 = $source->query("x");
is_deeply( $r2, $r , 'insert and query' );

my $src2 = SeeAlso::Source->new( $source );
is_deeply( $src2->query("x"), $r, 'wrapped source' );

#### Read from config file
eval "require Config::IniFiles";
if (! $@ ) {
    my ($fh, $filename) = tempfile( SUFFIX => ".ini" );
    print $fh "[DBI]\ndbi=SQLite:dbname=$file\n";
    close $fh;
    $source = SeeAlso::DBI->new( config => $filename );
    is_deeply( $source->query("x"), $r, 'from config file (INI)' );
}

eval "require YAML::Any";
if (! $@ ) {
    my ($fh, $filename) = tempfile( SUFFIX => ".yml" );
    print $fh "DBI:\n  dbi: SQLite:dbname=$file\n";
    close $fh;
    $source = SeeAlso::DBI->new( config => $filename );
    is_deeply( $source->query("x"), $r, 'from config file (YAML)' );
}

eval "require JSON";
if (! $@ ) {
    my ($fh, $filename) = tempfile( SUFFIX => ".json" );
    print $fh '{ "DBI" : { "dbi" : "SQLite:dbname=' . $file . '"}}';
    close $fh;
    $source = SeeAlso::DBI->new( config => $filename );
    is_deeply( $source->query("x"), $r, 'from config file (JSON)' );
}

#### SeeAlso::DBI as cache
my $s2 = SeeAlso::DBI->new( dbh => $dbh );
my $s1 = SeeAlso::Source->new( 
    sub { SeeAlso::Response->new( $_[0], ['x'], [''], [''] ); },
    cache => $s2
);

$r = $s2->query('foo');
ok( ! $r->size, 'empty response' );
$r = $s1->query('foo');
ok( $r->size, 'not empty response' );
is_deeply( $s2->query('foo'), $r, 'result stored back in the cache' );


### import
# t/isbn.csv
$source->clear;
$source->bulk_import( file => 't/isbn-dump.csv', uri => 'http://de.wikipedia.org/wiki/#2' );

# SeeAlso::Identifier::ISBN->new(...)->hash

$r = $source->query( '377760736' );
is_deeply( [ sort $r->labels ], ["Actinium","Aluminium","Antimon","Argon","Arsen","Astat"], "bulk_import" );



#### omit some of label/description/uri

$source = SeeAlso::DBI->new( dbh => $dbh, table => 'foo', description => "hello", build => 1 );

$r = $res[1];
$source->insert( $r );
$r2 = $source->query( '1' );
#print Dumper($r2) . "\n";
is_deeply( $r2, $r, "omitted description" );

# TODO: test 'key' parameter

