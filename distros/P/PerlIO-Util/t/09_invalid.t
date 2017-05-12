#!perl -w
use strict;

use Test::More;
BEGIN{
	if($] < 5.008_008){
		plan skip_all => "Version $] of PerlIO has a bug on invalid filehandle";
	}
	else{
		plan tests => 9;
	}
}

use PerlIO::Util;

# make empty IO
open my $invalid, '+<', \'';
1 while $invalid->pop_layer();

like $invalid->inspect, qr/Invalid filehandle/, 'setup invalid filehandle';

foreach my $l (qw(:flock :creat :excl :tee :dir :reverse :fse)){
	no warnings 'layer';

	ok !binmode($invalid, $l), $l;

	1 while $invalid->pop_layer();
}

ok !close($invalid), 'close';
