use Test::More tests => 88;
#use Test::More "no_plan";

use PBS::Logs::Event;

use vars qw{@data @records};
use lib 't';
require momdata;

my ($cnt,$a) = (0,undef);

open PL, 't/mom.20050304' or die "can not open t/mom.20050304";
my @all = <PL>;
close PL;
my $pl = new PBS::Logs::Event(\@all);

is($pl->type(), "ARRAY","passed array reference");

cmp_ok($pl->line(),'==', $cnt,			"line 0 count $cnt");
ok(! defined $pl->current(), 			"line 0 current");
while ($a = $pl->get()) {
	cmp_ok($pl->line(),'==', $cnt + 1,	"line count $cnt")
		if $cnt < $#data;
	is(join(' | ',@$a),$data[$cnt],		"line data $cnt");
	is($pl->current(),$records[$cnt],	"record data $cnt");
	$cnt++;
}
cmp_ok($pl->line(),'==', -1,			"EOF count");
ok(! defined $pl->current(), 			"EOF current");

# restart

$pl->start();
($cnt,$a) = (0,undef);

cmp_ok($pl->line(),'==', $cnt,			"2line 0 count $cnt");
ok(! defined $pl->current(), 			"2line 0 current");
while ($a = $pl->get()) {
	cmp_ok($pl->line(),'==', $cnt + 1,	"2line count $cnt")
		if $cnt < $#data;
	is(join(' | ',@$a),$data[$cnt],		"2line data $cnt");
	is($pl->current(),$records[$cnt],	"2record data $cnt");
	$cnt++;
}
cmp_ok($pl->line(),'==', -1,			"2EOF count");
ok(! defined $pl->current(), 			"2EOF current");

$pl->end();

ok(! defined $pl->type(), 			"end type");
ok(! defined $pl->line(), 			"end line");
ok(! defined $pl->current(), 			"end current");
