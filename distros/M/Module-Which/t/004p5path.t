
use Test::More tests => 10;

use_ok('Module::Which::P5Path', qw(path_to_p5path path_to_p5 p5path_to_path));

use Config;

my $path = "$Config{installarchlib}/A/AA.pm";

is(path_to_p5path($path), '${installarchlib}/A/AA.pm', "path to p5-path works");

my $p5path = '${installsitearch}/X/XY.pm';
is(p5path_to_path($p5path), "$Config{installsitearch}/X/XY.pm", "and so does p5-path to path");

is(path_to_p5path(''), '', 'translation of empty path (to p5) works');
is(p5path_to_path(''), '', 'translation of empty path (from p5) works');

is(path_to_p5path('a/b/c'), 'a/b/c', 'unresolvable paths (to p5) works'); 
is(p5path_to_path('a/b/c'), 'a/b/c', 'unresolvable paths (to p5) works'); 

my ($p5_path, $p5_base) = path_to_p5($path);
is($p5_path, '${installarchlib}/A/AA.pm', "path_to_p5 (path) works");
is($p5_base, '${installarchlib}/', "path_to_p5 (base) works");

is(path_to_p5($path), '${installarchlib}/A/AA.pm', "path_to_p5 works as path_to_p5path in scalar context");


