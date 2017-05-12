use Test::More tests => 96;
#use Test::More "no_plan";

use PBS::Logs;

use vars qw{@data @count @records};
use lib 't';
require acctdata;

my ($cnt,@a) = (0);

my $pl = new PBS::Logs('t/acct.20050201');

is($pl->type(), "FILE",	"passed acct filename");

cmp_ok($pl->line(),'==', $count[$cnt],		"line 0 count $cnt");
ok(! defined $pl->current(), 			"line 0 current");
while (@a = $pl->get()) {
	last if $#a <= 0;
	cmp_ok($pl->line(),'==', $count[$cnt+1],"line count $cnt");
	is(join(' | ',@a),$data[$cnt],		"line data $cnt");
	is($pl->current(),$records[$cnt],	"record data $cnt");
	$cnt++;
}
cmp_ok($pl->line(),'==', -1,			"EOF count");
ok(! defined $pl->current(), 			"EOF current");

# restart

$pl->start();
($cnt,@a) = (0,undef);

cmp_ok($pl->line(),'==', $count[$cnt],		"2line 0 count $cnt");
ok(! defined $pl->current(), 			"2line 0 current");
while (@a = $pl->get()) {
	cmp_ok($pl->line(),'==', $count[$cnt+1],"2line count $cnt");
	is(join(' | ',@a),$data[$cnt],		"2line data $cnt");
	is($pl->current(),$records[$cnt],	"2record data $cnt");
	$cnt++;
}
cmp_ok($pl->line(),'==', -1,			"2EOF count");
ok(! defined $pl->current(), 			"2EOF current");

$pl->end();

ok(! defined $pl->type(), 			"end type");
ok(! defined $pl->line(), 			"end line");
ok(! defined $pl->current(), 			"end current");
