use strict;
use warnings;
use Test::More;
use Test::Deep;

plan skip_all => 'Test only available on FreeBSD' unless $^O eq 'freebsd';
plan tests => 3;

use_ok('Sys::Detect::Virtualization');

my $d = Sys::Detect::Virtualization->new();

isa_ok( $d, 'Sys::Detect::Virtualization::freebsd');

is_deeply(
	[ sort $d->get_detectors() ],
	[ sort qw( detect_dmesg detect_ps ) ],
	'Got expected detectors on FreeBSD');
