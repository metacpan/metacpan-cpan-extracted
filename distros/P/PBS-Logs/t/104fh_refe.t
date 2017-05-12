use Test::More tests => 43;
#use Test::More "no_plan";

use PBS::Logs::Event;

use vars qw{@data @records};
use lib 't';
require momdata;

my ($cnt,$a) = (0,undef);

open PL, 't/mom.20050304' or die "can not open t/mom.20050304";
my $pl = new PBS::Logs::Event(\*PL);

is($pl->type(), "FILTER","passed FILEHANDLE");

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
