#!perl
BEGIN
{
    use strict;
    use warnings;
    use Test::More;
    use Cwd qw( abs_path );
    use lib abs_path( './lib' );
    use vars qw( $DEBUG );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

eval "use CBOR::XS 1.86;";
plan( skip_all => "CBOR::XS 1.86 required for testing serialisation with CBOR" ) if( $@ );

use_ok( "Module::Generic" );
use_ok( "Module::Generic::Array" );
use_ok( "Module::Generic::Boolean" );
use_ok( "Module::Generic::DateTime" );
use_ok( "Module::Generic::Dynamic" );
use_ok( "Module::Generic::Exception" );
use_ok( "Module::Generic::File::Cache" );
use_ok( "Module::Generic::File::IO" );
use_ok( "Module::Generic::File" );
use_ok( "Module::Generic::Finfo" );
use_ok( "Module::Generic::Hash" );
use_ok( "Module::Generic::HeaderValue" );
use_ok( "Module::Generic::Null" );
use_ok( "Module::Generic::Number" );
use_ok( "Module::Generic::Scalar" );
use_ok( "Module::Generic::SharedMem" );

my $gen = Module::Generic->new( debug => 4 );
my $serialised = CBOR::XS::encode_cbor( $gen );
my $gen2 = CBOR::XS::decode_cbor( $serialised );
isa_ok( $gen2 => 'Module::Generic', 'deserialised object is Module::Generic' );
is( $gen2->{debug} => $gen->{debug}, 'Module::Generic test value' );

my $a = Module::Generic::Array->new( qw( hello John ) );
$serialised = CBOR::XS::encode_cbor( $a );
my $a2 = CBOR::XS::decode_cbor( $serialised );
isa_ok( $a2 => 'Module::Generic::Array', 'deserialised object is Module::Generic::Array' );
is( "@$a2" => "@$a", 'Module::Generic::Array test value' );

my $b = Module::Generic::Boolean->new(1);
$serialised = CBOR::XS::encode_cbor( $b );
my $b2 = CBOR::XS::decode_cbor( $serialised );
isa_ok( $b2 => 'Module::Generic::Boolean', 'deserialised object is Module::Generic::Boolean' );
is( "$b2" => "$b", 'Module::Generic::Boolean test value' );

my $d = Module::Generic::DateTime->now;
isa_ok( $d => 'Module::Generic::DateTime', 'new object is Module::Generic::DateTime' );
$serialised = CBOR::XS::encode_cbor( $d );
my $d2 = CBOR::XS::decode_cbor( $serialised );
isa_ok( $d2 => 'Module::Generic::DateTime', 'deserialised object is Module::Generic::DateTime' );
is( "$d2" => "$d", 'Module::Generic::DateTime test value' );
# diag( "DateTime is: $d2" );

my $dyn = Module::Generic::Dynamic->new({
    fname => 'John',
    lname => 'Doe',
    location => 'Tokyo',
});
$serialised = CBOR::XS::encode_cbor( $dyn );
my $dyn2 = CBOR::XS::decode_cbor( $serialised );
isa_ok( $dyn2 => 'Module::Generic::Dynamic', 'deserialised object is Module::Generic::Dynamic' );
is( $dyn2->fname => $dyn->fname, 'Module::Generic::Dynamic test value #1' );
is( $dyn2->lname => $dyn->lname, 'Module::Generic::Dynamic test value #2' );
is( $dyn2->location => $dyn->location, 'Module::Generic::Dynamic test value #3' );

my $ex = Module::Generic::Exception->new( code => 400, message => 'Oops' );
$serialised = CBOR::XS::encode_cbor( $ex );
my $ex2 = CBOR::XS::decode_cbor( $serialised );
isa_ok( $ex2 => 'Module::Generic::Exception', 'deserialised object is Module::Generic::Exception' );
is( $ex2->code, $ex->code, 'Module::Generic::Exception test value #1' );
is( $ex2->message, $ex->message, 'Module::Generic::Exception test value #2' );

my $cache = Module::Generic::File::Cache->new(
    key => 'big secret',
    create => 1,
    mode => 0666,
);
$serialised = CBOR::XS::encode_cbor( $cache );
my $cache2 = CBOR::XS::decode_cbor( $serialised );
isa_ok( $cache2 => 'Module::Generic::File::Cache', 'deserialised object is Module::Generic::File::Cache' );
is( $cache2->key, $cache->key, 'Module::Generic::File::Cache test value #1' );
is( $cache2->create, $cache->create, 'Module::Generic::File::Cache test value #2' );
is( $cache2->mode, $cache->mode, 'Module::Generic::File::Cache test value #3' );

my $io = Module::Generic::File::IO->new( __FILE__, 'r' );
diag( "Module::Generic::File::IO object is '$io'" ) if( $DEBUG );
$serialised = CBOR::XS::encode_cbor( $io );
my $io2 = CBOR::XS::decode_cbor( $serialised );
diag( "deserialised Module::Generic::File::IO object is '$io2'" ) if( $DEBUG );
isa_ok( $io2 => 'Module::Generic::File::IO', 'deserialised object is Module::Generic::File::IO' );

my $f = Module::Generic::File->new( '/some/where/file.txt' );
$serialised = CBOR::XS::encode_cbor( $f );
my $f2 = CBOR::XS::decode_cbor( $serialised );
isa_ok( $f2 => 'Module::Generic::File', 'deserialised object is Module::Generic::File' );
is( $f2->filepath => $f->filepath, 'Module::Generic::File test value' );

my $finfo = Module::Generic::Finfo->new( __FILE__ );
$serialised = CBOR::XS::encode_cbor( $finfo );
my $finfo2 = CBOR::XS::decode_cbor( $serialised );
isa_ok( $finfo2 => 'Module::Generic::Finfo', 'deserialised object is Module::Generic::Finfo' );
is( $finfo2->filepath => $finfo->filepath, 'Module::Generic::Finfo test value for filepath' );
is( $finfo2->atime => $finfo->atime, 'Module::Generic::Finfo test value for atime' );
is( $finfo2->blksize => $finfo->blksize, 'Module::Generic::Finfo test value for blksize' );
is( $finfo2->blocks => $finfo->blocks, 'Module::Generic::Finfo test value for blocks' );
is( $finfo2->csize => $finfo->csize, 'Module::Generic::Finfo test value for csize' );
is( $finfo2->ctime => $finfo->ctime, 'Module::Generic::Finfo test value for ctime' );
is( $finfo2->dev => $finfo->dev, 'Module::Generic::Finfo test value for dev' );
is( $finfo2->gid => $finfo->gid, 'Module::Generic::Finfo test value for gid' );
is( $finfo2->ino => $finfo->ino, 'Module::Generic::Finfo test value for ino' );
is( $finfo2->mode => $finfo->mode, 'Module::Generic::Finfo test value for mode' );
is( $finfo2->mtime => $finfo->mtime, 'Module::Generic::Finfo test value for mtime' );
is( $finfo2->nlink => $finfo->nlink, 'Module::Generic::Finfo test value for nlink' );
is( $finfo2->size => $finfo->size, 'Module::Generic::Finfo test value for size' );
is( $finfo2->uid => $finfo->uid, 'Module::Generic::Finfo test value for uid' );

my $h = Module::Generic::Hash->new({
    fname => 'John',
    lname => 'Doe',
    location => 'Tokyo',
});
$serialised = CBOR::XS::encode_cbor( $h );
my $h2 = CBOR::XS::decode_cbor( $serialised );
isa_ok( $h2 => 'Module::Generic::Hash', 'deserialised object is Module::Generic::Hash' );
is( $h2->{fname} => $h->{fname}, 'Module::Generic::Hash test value for "fname"' );
is( $h2->{lname} => $h->{lname}, 'Module::Generic::Hash test value for "lname"' );
is( $h2->{location} => $h->{location}, 'Module::Generic::Hash test value for "location"' );

my $hv = Module::Generic::HeaderValue->new( 'foo' );
$hv->param( 'bar' => 2 );
$serialised = CBOR::XS::encode_cbor( $hv );
my $hv2 = CBOR::XS::decode_cbor( $serialised );
isa_ok( $hv2 => 'Module::Generic::HeaderValue', 'deserialised object is Module::Generic::HeaderValue' );
is( $hv2->value_name => $hv->value_name, 'Module::Generic::HeaderValue test value for value_name' );
is( $hv2->param( 'bar' ) => $hv->param( 'bar' ), 'Module::Generic::HeaderValue test value for param("bar")' );

my $null = Module::Generic::Null->new( name => 'John Doe' );
$serialised = CBOR::XS::encode_cbor( $null );
my $null2 = CBOR::XS::decode_cbor( $serialised );
isa_ok( $null2 => 'Module::Generic::Null', 'deserialised object is Module::Generic::Null' );
is( $null2->{name} => $null->{name}, 'Module::Generic::Null test value for "name"' );

my $n = Module::Generic::Number->new(12);
$serialised = CBOR::XS::encode_cbor( $n );
my $n2 = CBOR::XS::decode_cbor( $serialised );
isa_ok( $n2 => 'Module::Generic::Number', 'deserialised object is Module::Generic::Number' );
is( "$n2" => "$n", 'Module::Generic::Number test value' );

my $s = Module::Generic::Scalar->new( 'Hello world' );
$serialised = CBOR::XS::encode_cbor( $s );
my $s2 = CBOR::XS::decode_cbor( $serialised );
isa_ok( $s2 => 'Module::Generic::Scalar', 'deserialised object is Module::Generic::Scalar' );
is( "$s2" => "$s", 'Module::Generic::Scalar test value' );

my $sm = Module::Generic::SharedMem->new(
    create => 1,
    destroy => 1,
    exclusive => 1,
    key => 'testing',
    mode => 0666,
    size => 1024,
);
$serialised = CBOR::XS::encode_cbor( $sm );
my $sm2 = CBOR::XS::decode_cbor( $serialised );
isa_ok( $sm2 => 'Module::Generic::SharedMem', 'deserialised object is Module::Generic::SharedMem' );
is( $sm2->create => $sm->create, 'Module::Generic::SharedMem test value for create' );
is( $sm2->destroy => $sm->destroy, 'Module::Generic::SharedMem test value for destroy' );
is( $sm2->exclusive => $sm->exclusive, 'Module::Generic::SharedMem test value for exclusive' );
is( $sm2->key => $sm->key, 'Module::Generic::SharedMem test value for key' );
is( $sm2->mode => $sm->mode, 'Module::Generic::SharedMem test value for mode' );
is( $sm2->size => $sm->size, 'Module::Generic::SharedMem test value for size' );

done_testing();

__END__

