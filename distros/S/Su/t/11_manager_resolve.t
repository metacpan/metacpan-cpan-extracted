use Test::More tests => 15;

use lib qw(lib t/test11 . ../ ../lib);

use Su;
use Su::Model;

$Su::Template::TEMPLATE_BASE_DIR = "./t/test11";

$Su::Model::MODEL_BASE_DIR = "./t/test11";

#prepare model class

my $model_path =
    $Su::Model::MODEL_BASE_DIR . "/"
  . $Su::Model::MODEL_DIR . "/"
  . 'MenuModel.pm';

unlink $model_path if -f $model_path;

Su::Model::generate_model( 'MenuModel',
  qw(field1 string field2 number field3 date) );

##
ok( -f $model_path, "file not exist:" . $model_path );

Su::setup(
  menu => {
    proc  => 'Templates::EachFieldTmpl',
    model => [qw(Models::ModelA Models::ModelB Models::ModelC)]
  },
  book_comp => { proc => 'Templates::BookTmpl', model => 'Models::MenuModel' },
  menuWithArg =>
    { proc => 'Templates::MenuTmplWithArg', model => 'Models::MenuModel' },
);
$Su::USE_GLOBAL_SETUP = 1;

my $fgen = Su->new;

eval { my $ret = $fgen->resolve("not_exist_comp"); };
##

ok($@);
ok( !$ret );

# Template method is executed with each model class.
my @ret_arr = $fgen->resolve("menu");
##
is( $ret_arr[0], "Test11:model_a_string:model_a_number:model_a_date" );
is( $ret_arr[1], "Test11:model_b_string:model_b_number:model_b_date" );
is( $ret_arr[2], "Test11:model_c_string:model_c_number:model_c_date" );

#my @model_arr = $tmpl_module->model;
###diag(explain(@model_arr));
###diag(explain([qw(main sites about)]));
##
#ok(@model_arr);

##
#is(explain(@model_arr),explain([qw(main sites about)]), "check model field");

$ret = $fgen->resolve( "menuWithArg", "arg1" );
##
is( $ret, "Test11 arg1" );

Su::setup( {} );
##
is( scalar keys %{$Su::info_href}, 0 );

### re-execute by another usage of setup method.

Su::setup(
  {
    menu => { proc => 'Templates::MenuTmpl', model => { key1 => 'value1' } },
    book_comp =>
      { proc => 'Templates::BookTmpl', model => 'Models::MenuModel' },
    menuWithArg =>
      { proc => 'Templates::MenuTmplWithArg', model => 'Models::MenuModel' },
  }
);

$fgen = Su->new;

eval { $ret = $fgen->resolve("not_exist_comp"); };
##
ok($@);

#ok( !$ret );

$ret = $fgen->resolve("menu");
##
is( $ret, "Test11" );

$ret = $fgen->resolve( "menuWithArg", "arg1" );
##
is( $ret, "Test11 arg1" );

### check model specified as model class name.

# org place

$ret = $fgen->resolve( "menuWithArg", "arg1" );

my $tmpl_module = $fgen->{module};

##
is( $ret, "Test11 arg1" );

# Check for debug instance.
ok($tmpl_module);

my $expected_result = {
  field1 => "string",
  field2 => "number",
  field3 => "date",
};

##
is_deeply( $tmpl_module->model, $expected_result );

### utility test
my $href = {};
##
# is( Su::is_hash_empty($href), 1 );

# $href = undef;
# ##
# ok( Su::is_hash_empty($href) );

# %h = ( k => "val" );
# ##
# ok( Su::is_hash_empty(%h) );

# $aref = [ 1, 2, 3 ];
# ##
# ok( Su::is_hash_empty($aref) );

# @a = ( 1, 2, 3 );
# ##
# ok( Su::is_hash_empty(@a) );

# $href = { k => "value" };
# ##
# is( Su::is_hash_empty($href), 0 );

$ret = $fgen->resolve(
  {
    proc  => 'Templates::EachFieldTmpl',
    model => { field1 => 'f1', field2 => 'f2', field3 => 'f3', },

  }
);

is( $ret, 'Test11:f1:f2:f3' );

