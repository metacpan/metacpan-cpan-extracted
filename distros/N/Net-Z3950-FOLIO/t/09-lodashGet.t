use strict;
use warnings;

my $data = {
    val => 12368,
    foo => {
	val => 29168,
	bar => {
	    val => 18398,
	    baz => {
		val => 80100,
	    }
	}
    },
    apato => [
	undef, # 0
	31802, # 1
	undef, # 2
	undef, # 3
	undef, # 4
	undef, # 5
	undef, # 6
	undef, # 7
	undef, # 8
	undef, # 9
	undef, # 10
	'marsh', # 11
	{ # 12
	    brach => 'riggs',
	    cam => [
		undef,
		undef,
		{
		  diplo => 'hatcher',
		}
	    ]
	}
    ],
};

BEGIN {
    use vars qw(@tests);
    @tests = (
	# path, expected, val
	[ '',                       [],                               undef     ],
	[ 'val',                    ['val'],                          12368     ],
	[ 'foo.val',                ['foo', 'val'],                   29168     ],
	[ 'foo.bar.val',            ['foo', 'bar', 'val'],            18398     ],
	[ 'foo.bar.baz.val',        ['foo', 'bar', 'baz', 'val'],     80100     ],
	[ '[1]',                    [1],                              undef     ],
	[ 'apato[1]',               ['apato', 1],                     31802     ],
	[ 'apato[11]',              ['apato', 11],                    'marsh'   ],
	[ 'apato[12].brach',        ['apato', 12, 'brach'],           'riggs'   ],
	[ 'apato[12].cam[2].diplo', ['apato', 12, 'cam', 2, 'diplo'], 'hatcher' ],
	[ '1',                      [1],                              undef     ],
	[ 'apato.1',                ['apato', 1],                     31802     ],
	[ 'apato.11',               ['apato', 11],                    'marsh'   ],
	[ 'apato.12.brach',         ['apato', 12, 'brach'],           'riggs'   ],
	[ 'apato.12.cam.2.diplo',   ['apato', 12, 'cam', 2, 'diplo'], 'hatcher' ],
    );
}

use Test::More tests => 1 + 2 * scalar(@tests);

BEGIN { use_ok('Net::Z3950::FOLIO::lodashGet') };
use Net::Z3950::FOLIO::lodashGet qw(_compilePath lodashGet);

foreach my $test (@tests) {
    my($path, $expected, $val) = @$test;
    my @compiled = _compilePath($path);
    # use Data::Dumper; print Dumper(\@compiled);
    is_deeply(\@compiled, $expected, "compiled '$path'");
}

foreach my $test (@tests) {
    my($path, $expected, $val) = @$test;
    SKIP: {
	skip 'no expected value', 1 if !defined $val;
	my $res = lodashGet($data, $path);
	# use Data::Dumper; print Dumper($res);
	is($res, $val, "executed '$path'");
    }
}
