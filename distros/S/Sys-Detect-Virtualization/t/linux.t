use strict;
use warnings;
use Test::More;
use Test::Deep;

plan skip_all => 'Test only available on Linux' unless $^O eq 'linux';
plan tests => 3;

use_ok('Sys::Detect::Virtualization');

my $d = Sys::Detect::Virtualization->new();

isa_ok( $d, 'Sys::Detect::Virtualization::linux');

is_deeply(
	[ sort $d->get_detectors() ],
	[ sort qw( detect_dmesg detect_ide_devices detect_paths detect_scsi_devices detect_init_envvars detect_modules detect_mtab detect_dmidecode) ],
	'Got expected detectors on Linux');
