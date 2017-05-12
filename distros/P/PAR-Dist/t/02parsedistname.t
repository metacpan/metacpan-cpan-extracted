use strict;
use warnings;
our @tests;

BEGIN {
    @tests = (
    	'Math-Symbolic-0.502-x86_64-linux-gnu-thread-multi-5.8.7.par'
	    => ['Math-Symbolic', '0.502', 'x86_64-linux-gnu-thread-multi', '5.8.7'],
    	'Math-Symbolic-0.502.tar.gz'
	    => ['Math-Symbolic', '0.502', undef, undef],
        'Foo-0.5.3_1-x86-win32-thread-multi-any_version'
    	=> ['Foo', '0.5.3_1', 'x86-win32-thread-multi', 'any_version'],
	    'Foo-v0.5.3_1-MSWin32-x86-thread-multi-5.005_03'
    	=> ['Foo', 'v0.5.3_1', 'MSWin32-x86-thread-multi', '5.005_03'],
	    'Foo-Bar-5-0.5.3_1-MSWin32-x86-thread-multi-5.005_03'
    	=> ['Foo-Bar-5', '0.5.3_1', 'MSWin32-x86-thread-multi', '5.005_03'],
    );
}

use Test::More tests => int(scalar(@tests)/2) + 1;

use_ok('PAR::Dist');

while (@tests) {
	my $str = shift @tests;
	my $res = shift @tests;
	my @res = PAR::Dist::parse_dist_name($str);
	is_deeply($res, \@res, "Parsing '$str'");
}
