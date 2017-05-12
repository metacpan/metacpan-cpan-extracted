use Test::More tests => 2;

use_ok('String::ShowHTMLDiff');
import String::ShowHTMLDiff;

my $a = 'foo bar baz';
my $b = 'fiz biz bar';

my $diff = String::ShowHTMLDiff::html_colored_diff($a, $b);

is( $diff, q|<span class='diff_unchanged'>f</span><span class='diff_minus'>o</span><span class='diff_minus'>o</span><span class='diff_plus'>i</span><span class='diff_plus'>z</span><span class='diff_unchanged'> </span><span class='diff_unchanged'>b</span><span class='diff_minus'>a</span><span class='diff_minus'>r</span><span class='diff_plus'>i</span><span class='diff_plus'>z</span><span class='diff_unchanged'> </span><span class='diff_unchanged'>b</span><span class='diff_unchanged'>a</span><span class='diff_minus'>z</span><span class='diff_plus'>r</span>|, 'html_colored_diff()' );