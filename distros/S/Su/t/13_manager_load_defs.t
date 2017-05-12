use Test::More tests => 2;

use lib qw(t/test13 lib ../lib);

use Su;
use Su::Template;
use Su::Model;

## Template and Model are already prepared. Read these files and generate it using the method 'resolve'.

$Su::BASE_DIR                    = "./t/test13";
$Su::Template::TEMPLATE_BASE_DIR = "./t/test13";
$Su::Model::MODEL_BASE_DIR       = "./t/test13";

# execute once.
#Su::Template::gen_tmpl('MenuTmpl');

my $fgen = Su->new;

my $ret = $fgen->resolve('site');

#diag($ret);

my $expected = <<'__HERE__';
each fields of the model.
  key:field1 value:string
  key:field2 value:number
  key:field3 value:date
__HERE__

is( $ret, $expected );

$Su::BASE_DIR                    = "./t/test13/dmy_not_exist_dir";
$Su::Template::TEMPLATE_BASE_DIR = "./t/test13/dmy_not_exist_dir";
$Su::Model::MODEL_BASE_DIR       = "./t/test13/dmy_not_exist_dir";

# Specify integrated base directory at once. This setting effects template and model base directory.
$fgen = Su->new( base => "./t/test13" );

$ret = $fgen->resolve('site');

$expected = <<'__HERE__';
each fields of the model.
  key:field1 value:string
  key:field2 value:number
  key:field3 value:date
__HERE__

# re-execute same test.
is( $ret, $expected );

