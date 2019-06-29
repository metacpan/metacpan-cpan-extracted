#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use JSON;
use Storable;

use Sport::Analytics::NHL;

use t::lib::Util;

plan qw(no_plan);

test_env();
$ENV{HOCKEYDB_DATA_DIR} = 't/tmp/data';
system(qw(mkdir -p t/tmp/));
system(qw(cp -a t/data t/tmp/));
system('find t/tmp -name "*.storable" -delete');
$ENV{HOCKEYDB_NODB} = 1;
my $nhl = Sport::Analytics::NHL->new();
my @storables = sort $nhl->compile({}, 201120010);

is_deeply(
	[ sort @storables ],
	[qw(
		t/tmp/data/2011/0002/0010/BH.storable
		t/tmp/data/2011/0002/0010/BS.storable
		t/tmp/data/2011/0002/0010/ES.storable
		t/tmp/data/2011/0002/0010/GS.storable
		t/tmp/data/2011/0002/0010/PL.storable
		t/tmp/data/2011/0002/0010/RO.storable
		t/tmp/data/2011/0002/0010/TH.storable
		t/tmp/data/2011/0002/0010/TV.storable
	)],
);
for my $storable (@storables) {
	ok(-f $storable, 'file exists');
}

my $r_storable = Sport::Analytics::NHL::retrieve_compiled_report({}, 201120010, 'BS', 't/tmp/data/2011/0002/0010');
is_deeply($r_storable, retrieve($storables[1]), 'retrieve correct');
unlink 't/tmp/data/2011/0002/0010/BS.storable';
$r_storable = Sport::Analytics::NHL::retrieve_compiled_report(
	{no_compile => 1}, 201120010, 'BS', 't/tmp/data/2011/0002/0010',
);
is($r_storable, undef, 'no compile detected');
$r_storable = Sport::Analytics::NHL::retrieve_compiled_report(
	{}, 201120010, 'BS', 't/tmp/data/2011/0002/0010',
);
is_deeply($r_storable, retrieve($storables[1]), 'compile on the fly correct');
unlink 't/tmp/data/2011/0002/0010/BS.storable';
unlink 't/tmp/data/2011/0002/0010/BS.json';
$r_storable = Sport::Analytics::NHL::retrieve_compiled_report(
	{}, 201120010, 'BS', 't/tmp/data/2011/0002/0010',
);
is($r_storable, undef, 'no source to compile detected');



END {
	system(qw(rm -rf t/tmp/data));
}
