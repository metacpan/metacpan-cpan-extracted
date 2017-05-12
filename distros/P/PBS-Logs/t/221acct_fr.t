use Test::More tests => 160;
#use Test::More "no_plan";

use PBS::Logs::Acct;

use vars qw{@data @count @records};
use lib 't';
require acctdata;

open PL, 't/acct.20050201' or die "can not open t/acct.20050201";
my @all = <PL>;
close PL;
my $pl = new PBS::Logs::Acct(\@all);

is($pl->type(), "ARRAY","passed array reference");

&try($pl,0 .. $#data);

$pl->start();
$pl->filter_records('E');
&try($pl,@E_cnt);

$pl->start();
$pl->filter_records('S');
&try($pl,@S_cnt);

$pl->start();
$pl->filter_records('S','E');
&try($pl,sort {$a <=> $b;} (@S_cnt,@E_cnt));

$pl->start();
$pl->filter_records([]);
&try($pl,0 .. $#data);

sub try {
	my $pl = shift;
	my ($cnt,$a) = (0,undef);
	cmp_ok($pl->line(),'==', $cnt,			"line 0 count $cnt");
	ok(! defined $pl->current(), 			"line 0 current");
	while ($a = $pl->get()) {
		cmp_ok($pl->line(),'==', $count[$_[$cnt]+1],"line count $cnt")
			if $cnt < $#_;
		is(join(' | ',@$a),$data[$_[$cnt]],	"line data $cnt");
		is($pl->current(),$records[$_[$cnt]],	"record data $cnt");
		$cnt++;
	}
	cmp_ok($pl->line(),'==', -1,			"EOF count");
	ok(! defined $pl->current(), 			"EOF current");
}
