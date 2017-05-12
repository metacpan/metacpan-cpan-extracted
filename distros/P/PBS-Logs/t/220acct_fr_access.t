use Test::More tests => 13;
#use Test::More "no_plan";

use PBS::Logs::Acct;

my $pl = new PBS::Logs::Acct([]);
my @rfil1 = sort qw{E S Q T};
my @rfil2 = sort qw{A B D K k};

my @ret = $pl->filter_records();
cmp_ok (scalar @ret, '==', 0,			"empty set at start");

cmp_ok($pl->filter_records(\@rfil1),'==', 1,	"first set - array ref");
@ret = $pl->filter_records();
is(join(':',@ret),join(':',@rfil1),		"first look - array ref");
cmp_ok($pl->filter_records(\@rfil2),'==', 1,	"second set - array ref");
@ret = $pl->filter_records();
is(join(':',@ret),join(':',@rfil2),		"second look - array ref");
cmp_ok($pl->filter_records([]),'==', 1,		"set empty - array ref");
@ret = $pl->filter_records();
cmp_ok (scalar @ret, '==', 0,			"set empty look ");

cmp_ok($pl->filter_records(@rfil1),'==', 1,	"first set - array");
@ret = $pl->filter_records();
is(join(':',@ret),join(':',@rfil1),		"first look - array");
cmp_ok($pl->filter_records(@rfil2),'==', 1,	"second set - array");
@ret = $pl->filter_records();
is(join(':',@ret),join(':',@rfil2),		"second look - array");
cmp_ok($pl->filter_records([]),'==', 1,		"set empty - array ref");
@ret = $pl->filter_records();
cmp_ok (scalar @ret, '==', 0,			"set empty look ");
