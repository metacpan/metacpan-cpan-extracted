use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;

BEGIN { use_ok('Sys::Detect::Virtualization') }

{
	local $^O;
	throws_ok { Sys::Detect::Virtualization->new() }
		qr/Perl doesn't know what OS you're on!/,
		'Empty $^O throws error';
}

{
	local $^O = 'MSWin32';
	throws_ok { Sys::Detect::Virtualization->new() }
		qr/Virtualization detection not supported for 'MSWin32' platform/,
		'Unsupported $^O throws error';
}

{
	local $^O = 'linux';
	my $d;
	lives_ok { $d = Sys::Detect::Virtualization->new() }
		'Linux is a valid OS for detection';
	isa_ok($d, 'Sys::Detect::Virtualization::linux');
}
