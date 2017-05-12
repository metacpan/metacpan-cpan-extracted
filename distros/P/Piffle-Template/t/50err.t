# Errors should be reported from the right line
use Test;
BEGIN { plan tests => 5 }
use Piffle::Template;

my $tmpl = <<'__TMPL__';
gfdgfdg
gfdg   <?perl #nothing ?>
gfdgd
<?perl

# nothing,
# over more than one line.

?>
AAA<?perl print __LINE__ ?>
gfd
fdsfdfsf
<?perl

 for (1..10)
 {


?>none of these interps should emit code longer than one line
{$_}
BBB<?perl print __LINE__ ?>
{$_,raw}
CCC<?perl print __LINE__ ?>
{$_,uri}
DDD<?perl print __LINE__ ?>
<?perl

 }

?>
okay, so where where we?
ZZZ<?perl print __LINE__ ?>
__TMPL__
$_ = Piffle::Template->expand(source => $tmpl);

ok(/AAA10/);
s/BBB21//g;
s/CCC23//g;
s/DDD25//g;
ok(!/BBB/);
ok(!/CCC/);
ok(!/DDD/);
ok(/ZZZ32/);

