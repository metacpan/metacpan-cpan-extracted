use Test;
BEGIN { plan tests => 5 };
ok(1);

package SLEEPY;

use Sub::Regex;

sub new { bless {}, shift }
sub /(is_|am_)?sleep(s|ing)?/ { 1 }


package main;

$I = SLEEPY->new();
$xern = SLEEPY->new();

ok(1,$I->sleep);
ok(1,$I->am_sleeping);
ok(1,$xern->sleeps);
ok(1,$xern->is_sleeping);

