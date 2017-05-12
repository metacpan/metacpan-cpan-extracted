use Test::More tests => 181;
#use Test::More "no_plan";

use PBS::Logs::Acct;

use vars qw{@data @count @records};
use lib 't';
require acctdata;

my ($stime,$etime) = ('02/01/2005 11:06:18','02/01/2005 11:56:10');

open PL, 't/acct.20050201' or die "can not open t/acct.20050201";
my @all = <PL>;
close PL;
my $pl = new PBS::Logs::Acct(\@all);

is($pl->type(), "ARRAY","passed array reference");

&try($pl,0 .. $#data);

# filter on both records and datetime

$pl->filter_datetime($stime,'none');

$pl->start();
$pl->filter_records('E');
&try($pl,@E_cnt[1 .. $#E_cnt]);

$pl->start();
$pl->filter_records('S');
&try($pl,@S_cnt[1 .. $#S_cnt]);

$pl->start();
$pl->filter_records('S','E');
&try($pl,@SE_cnt[2 .. $#SE_cnt]);

$pl->filter_datetime('none',$etime);

$pl->start();
$pl->filter_records('E');
&try($pl,@E_cnt[0 .. 2]);

$pl->start();
$pl->filter_records('S');
&try($pl,@S_cnt[0 .. 2]);

$pl->start();
$pl->filter_records('S','E');
&try($pl,@SE_cnt[0 .. 5]);

$pl->filter_datetime($stime,$etime);

$pl->start();
$pl->filter_records('E');
&try($pl,@E_cnt[1,2]);

$pl->start();
$pl->filter_records('S');
&try($pl,@S_cnt[1,2]);

$pl->start();
$pl->filter_records('S','E');
&try($pl,@SE_cnt[2 .. 5]);

sub try {
	my $pl = shift;
	my ($cnt,$a) = (0,undef);
	cmp_ok($pl->line(),'==', $cnt,			"line 0 count $cnt");
	ok(! defined $pl->current(), 			"line 0 current");
	while ($a = $pl->get_hash()) {
		cmp_ok($pl->line(),'==', $count[$_[$cnt]+1],"line count $cnt")
			if $cnt < $#_;
		my @a = @{$a}{
	@PBS::Logs::Acct::num2keys{sort keys %PBS::Logs::Acct::num2keys}};
		is(join(' | ',@a),$data[$_[$cnt]],	"line data $cnt");
		is($pl->current(),$records[$_[$cnt]],	"record data $cnt");
		$cnt++;
	}
	cmp_ok($pl->line(),'==', -1,			"EOF count");
	ok(! defined $pl->current(), 			"EOF current");
}
