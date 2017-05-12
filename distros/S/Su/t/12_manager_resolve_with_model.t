use Test::More tests => 3;

use lib qw(lib t/test12 ../lib);

use Su;
use Su::Template;
use Su::Model;

## Template and Model are already prepared. Read these files and generate by the method resolve.

$Su::Template::TEMPLATE_BASE_DIR = "./t/test12";

$Su::Model::MODEL_BASE_DIR = "./t/test12";

Su::setup(
  site => { proc => 'Templates::MenuTmpl', model => [qw(main sites about)] },
  menu => { proc => 'Templates::MenuTmpl', model => 'Models::MenuModel' },
);

# my $fgen = Su->new;

# For the first generation.
#Su::Model::gen_model('MenuModel', qw(field1 value1 field2 value2 field3 value3));
#Su::Template::gen_tmpl('MenuTmpl');

# my $ret = $fgen->resolve("menu");

my $ret = Su::resolve('menu');

#diag($ret);

my $expected = <<'__HERE__';
field and values.
  field1:value1
  field2:value2
  field3:value3

__HERE__

is( $ret, $expected );

# The process 'main' increments it's instance variable 0 to 1. Call twice and both return 1 not 1, 2;
my $su = Su->new();
$ret = $su->resolve('main');
is( $ret, 1 );
$ret = $su->resolve('main');
is( $ret, 1, 'Instance variable is illegally incremented.' );

