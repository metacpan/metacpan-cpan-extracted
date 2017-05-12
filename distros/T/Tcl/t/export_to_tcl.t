# tests convenience sub export_to_tcl

use Test;
BEGIN {plan tests=>4}
use Tcl;

my $int = Tcl->new;

$tcl::foo = $tcl::foo = 'qwerty';
my $x = "some perl scalar var";

$int->export_to_tcl(subs_from=>'tcl',vars_from=>'tcl');
$int->export_to_tcl(subs=>{lala=>sub{"ok"}}, namespace=>'');
$int->export_to_tcl(vars=>{foo1=>\$x}, namespace=>'');

# this should croak:
#$int->export_to_tcl(vars=>{foo=>$x}, namespace=>'');

$int->export_to_tcl(subs_from=>''); # this will bind sub named sub1 below
sub sub1 {"sub1 its me"}
sub tcl::sub2 {"sub2 its me"}

ok($int->call('perl::sub1'),"sub1 its me");
ok($int->call('lala'),"ok");

ok($int->Eval('set perl::foo'),'qwerty');
ok($int->call('set','foo1'),'some perl scalar var');

