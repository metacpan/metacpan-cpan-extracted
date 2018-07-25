use Test::Most 0.25;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use Test::PathClassTiny::Utils;
unload_module('Cwd');			# because it's the thing we want to test that we're loading

use Path::Class::Tiny;


loads_ok { cwd() } cwd => 'Cwd';
is cwd(), Cwd::getcwd(), 'cwd returns same as getcwd';
lives_ok { is cwd, Cwd::getcwd(), 'sanity check' } 'can call cwd without parens';


done_testing;
