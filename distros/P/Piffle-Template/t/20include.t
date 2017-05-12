# Test include directive

use Test;
BEGIN { plan tests => 1; }
use Piffle::Template;

$tmpl = <<'__TMPL__';
outer template ok
<?include testinclude.txt?>var2: {$var2}
__TMPL__
$want = <<'__WANT__';
outer template ok
file included ok
var1: interp in included file ok
var2: interp in including template ok
__WANT__
$got = Piffle::Template->expand(source => $tmpl,
                                include_path => [qw{lib blib t}]);
ok($got, $want);
