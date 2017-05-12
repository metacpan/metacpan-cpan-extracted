use Test::More tests => 28;

use lib qw(lib t t/test09 . ../lib);
use File::Path;
use Cwd;
use Su::Model;

##
is( $Su::Model::MODEL_DIR, "Models" );

##
is( $Su::Model::MODEL_BASE_DIR, "./" );

$Su::Model::MODEL_DIR = "test09/Models";

$Su::Model::MODEL_BASE_DIR = "./t";

##
is( $Su::Model::MODEL_DIR, "test09/Models" );
##
is( $Su::Model::MODEL_BASE_DIR, "./t" );

my $model_path =
    $Su::Model::MODEL_BASE_DIR . "/"
  . $Su::Model::MODEL_DIR . "/"
  . "NewModel" . ".pm";
if ( -f $model_path ) {
  unlink $model_path
    or die "[ERROR]Can't clean up generated file by previous  test. " . $!;
}
### Generate model file.
generate_model('NewModel');

##
ok( -f $model_path );

$model_path =
    $Su::Model::MODEL_BASE_DIR . "/"
  . $Su::Model::MODEL_DIR . "/"
  . "NewModelWithArg" . ".pm";

if ( -f $model_path ) {
  unlink $model_path
    or die "[ERROR]Can't clean up generated file by previous  test. " . $!;
}

### Generate model file.
generate_model( 'NewModelWithArg',
  qw(field1 string field2 number field3 date) );

##
ok( -f $model_path );

# $MODEL_DIR is defined, so this value used as a part of package name.
my $model_href = Su::Model::load_model('test09::Models::NewModelWithArg');

##
ok($model_href);

my $expected_result = {
  'field1' => 'string',
  'field2' => 'number',
  'field3' => 'date',
};

##
is_deeply( $model_href, $expected_result,
  "Check the field of Generated Model class." );

### todo test in usage of oo.

rmtree "./t/test09/NestModels" if -d "./t/test09/NestModels";

$mdl = Su::Model->new( base => "./t/test09", dir => 'NestModels' );

$mdl->generate_model('Mdl');

ok( -f "./t/test09/NestModels/" . "Mdl.pm", "Test for OO like usage." );

if ( -f "t/test09/Nest/Mdl2.pm" ) {
  unlink "t/test09/Nest/Mdl2.pm";
}

$mdl->generate_model( 'Nest/Mdl2', "field1", "value1" );

ok( -f "./t/test09/" . "Nest/Mdl2.pm",
  "Generate Nested package Model with separator '/'." );

$model_href = $mdl->load_model('Nest/Mdl2');
is( $model_href->{field1}, "value1",
  "Load Model which has nested package name." );

if ( -f "t/test09/Nest/Mdl3.pm" ) {
  unlink "t/test09/Nest/Mdl3.pm";
}

# Note that if the class name has package,then previouslyl specified model directory 'NestModels' is ignored.
$mdl->generate_model( 'Nest::Mdl3', "field2", "value2" );

ok( -f "./t/test09/" . "Nest/Mdl3.pm",
  "Generate Nested package Model with separator '::'." );

$model_href = $mdl->load_model('Nest::Mdl3');
ok($model_href);
is( $model_href->{field2}, "value2",
  "Load Model which has nested package name." );

if ( -f "t/test09/Nest/Mdl4.pm" ) {
  unlink "t/test09/Nest/Mdl4.pm";
}

$mdl->generate_model( 'Nest::Mdl4', "field1",
  { "key1" => "value1", "key2" => "value2" },
  "field2", "value3" );
$model_href = $mdl->load_model('Nest::Mdl4');
ok($model_href);

is( $model_href->{field1}->{key1},
  "value1", "Load Model which has hash field." );
is( $model_href->{field1}->{key2},
  "value2", "Load Model which has hash field." );
is( $model_href->{field2}, "value3", "Load Model which has hash field." );

# Test for application scope attribute.

Su::Model->attr( 'key1', 'value1' );

is( Su::Model->attr('key1'), 'value1' );

Su::Model->attr( 'key2', [ 'value2_1', 'value2_2' ] );

is_deeply( Su::Model->attr('key2'), [ 'value2_1', 'value2_2' ] );

Su::Model->attr( 'key1', 'value1' );

is( Su::Model->attr('key1'), 'value1' );

Su::Model->attr( 'key3', { key31 => 'value3_1', key32 => 'value3_2' } );

is_deeply( Su::Model->attr('key3'),
  { key31 => 'value3_1', key32 => 'value3_2' } );

Su::Model->attr->{key4} = 'value4';

is( Su::Model->attr->{key4}, 'value4' );

# Test for suppress error.
my $ret = 0;
eval { $model_href = $mdl->load_model('dmy data'); };
if ($@) {
  $ret = 1;
}
ok($ret);

$model_href = $mdl->load_model( 'dmy data', { suppress_error => 1 } );

ok( !defined $model_href );

# Test for not accept destructive operation.

ok( Su::Model::load_model('Nest::Mdl4')->{field2} eq 'value3' );

Su::Model::load_model('Nest::Mdl4')->{field2} = 'new value';

ok( Su::Model::load_model('Nest::Mdl4')->{field2} eq 'value3',
  'The value changed.' );

# Test for destructive operation.

Su::Model::load_model( 'Nest::Mdl4', { share => 1 } )->{field2} = 'new value';

is( Su::Model::load_model( 'Nest::Mdl4', { share => 1 } )->{field2},
  'new value', 'The value not changed.' );

