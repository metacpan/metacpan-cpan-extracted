use Test::More tests => 153;
#use Test::More "no_plan";

use PBS::Logs::Event;

use vars qw{@data @records};
use lib 't';
require momdata;

my ($stime,$etime) = ('03/04/2005 11:27:19','03/04/2005 11:27:20');

open PL, 't/mom.20050304' or die "can not open t/mom.20050304";
my @all = <PL>;
close PL;
my $pl = new PBS::Logs::Event(\@all);

is($pl->type(), "ARRAY","passed array reference");

&try($pl,0,$#data);

$pl->start();
$pl->filter_datetime($stime,'none');
&try($pl,6,$#data);

$pl->start();
$pl->filter_datetime('none',$stime);
&try($pl,0,9);

$pl->start();
$pl->filter_datetime($stime,$stime);
&try($pl,6,9);

$pl->start();
$pl->filter_datetime('none','none');
&try($pl,0,$#data);

sub try {
	my ($pl,$start,$end) = @_;
	my ($cnt,$a) = (0,undef);
	cmp_ok($pl->line(),'==', $cnt,			"line 0 count $cnt");
	ok(! defined $pl->current(), 			"line 0 current");
	while ($a = $pl->get()) {
		cmp_ok($pl->line(),'==', $start + 1,	"line count $cnt")
			if $start < $#data;
		is(join(' | ',@$a),$data[$start],	"line data $cnt");
		is($pl->current(),$records[$start],	"record data $cnt");
		$cnt++;
		$start++;
	}
	fail("excess retrieved lines") if $start > $end+1;
	cmp_ok($pl->line(),'==', -1,			"EOF count");
	ok(! defined $pl->current(), 			"EOF current");
}
