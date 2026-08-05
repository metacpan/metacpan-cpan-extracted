#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use OSLV::Monitor;
use OSLV::Monitor::Backends::cgroups;

if ( $^O ne 'linux' ) {
	plan skip_all => 'not linux';
}

my $base_dir = tempdir( CLEANUP => 1 );
my $obj      = OSLV::Monitor->new( base_dir => $base_dir );
my $backend  = OSLV::Monitor::Backends::cgroups->new( base_dir => $base_dir, obj => $obj );

# ID to name mappings as they would be filled in from docker/podman ps
$backend->{docker_mapping}{'0123456789abcdef'} = { name => 'web' };
$backend->{podman_mapping}{'fedcba9876543210'} = { name => 'db' };

# each entry is the cgroup to map, the name it should map to, and the dir under
# /sys/fs/cgroup that the stats for that name should be read from
my @tests = (
	[ '0::/init.scope', 'init', '/init.scope' ],

	# a plain service... the two quadrant ones share the first 27 characters, which
	# is where ps truncated the cgroup column, mapping both to s_quadrant-r
	[   '0::/system.slice/quadrant-rsync-upload.service',
		's_quadrant-rsync-upload',
		'/system.slice/quadrant-rsync-upload.service'
	],
	[   '0::/system.slice/quadrant-rsync-wrapper.service',
		's_quadrant-rsync-wrapper',
		'/system.slice/quadrant-rsync-wrapper.service'
	],
	[ '0::/system.slice/ssh.service', 's_ssh', '/system.slice/ssh.service' ],

	# a service with cgroups nested under it is named for the service and the stats
	# come from the service, as with cgroup v2 they include all descendants
	[ '0::/system.slice/systemd-udevd.service/udev', 's_systemd-udevd', '/system.slice/systemd-udevd.service' ],

	# a nested slice is skipped over as the unit of interest lives under it
	[   '0::/system.slice/system-getty.slice/getty@tty1.service',
		's_getty@tty1',
		'/system.slice/system-getty.slice/getty@tty1.service'
	],

	# a scope under system.slice
	[ '0::/system.slice/foo.scope', 's_foo', '/system.slice/foo.scope' ],

	# nothing that looks like a unit, so the last bit of the path is used
	[ '0::/system.slice/random.slice', 's_random.slice', '/system.slice/random.slice' ],

	# docker under system.slice, with and without a known ID
	[ '0::/system.slice/docker-0123456789abcdef.scope', 'd_web', '/system.slice/docker-0123456789abcdef.scope' ],
	[   '0::/system.slice/docker-0123456789abcdef.scope/init',
		'd_web',
		'/system.slice/docker-0123456789abcdef.scope'
	],
	[ '0::/system.slice/docker-deadbeef.scope', 'd_deadbeef', '/system.slice/docker-deadbeef.scope' ],

	# docker outside of system.slice
	[ '0::/docker/0123456789abcdef',     'd_0123456789abcdef', '/docker/0123456789abcdef' ],
	[ '0::/docker/0123456789abcdef/init', 'd_0123456789abcdef', '/docker/0123456789abcdef' ],

	# every cgroup for a user maps to the one name and the stats all come from the
	# slice for that user
	[ '0::/user.slice/user-1000.slice/session-5.scope',            'u_1000', '/user.slice/user-1000.slice' ],
	[ '0::/user.slice/user-1000.slice/session-6.scope',            'u_1000', '/user.slice/user-1000.slice' ],
	[ '0::/user.slice/user-1000.slice/user@1000.service/init.scope', 'u_1000', '/user.slice/user-1000.slice' ],
	[ '0::/user.slice/user_1000.slice',                            'u_1000', '/user.slice/user_1000.slice' ],

	# podman, with and without a known ID
	[ '0::/machine.slice/libpod-fedcba9876543210.scope', 'p_db', '/machine.slice/libpod-fedcba9876543210.scope' ],
	[   '0::/machine.slice/libpod-fedcba9876543210.scope/container',
		'p_db',
		'/machine.slice/libpod-fedcba9876543210.scope'
	],
	[ '0::/machine.slice/libpod-deadbeef.scope', 'libpod', '/machine.slice/libpod-deadbeef.scope' ],

	# the conmon scopes are all lumped in under the one name, so each is read
	[   '0::/machine.slice/libpod-conmon-fedcba9876543210.scope',
		'libpod-conmon',
		'/machine.slice/libpod-conmon-fedcba9876543210.scope'
	],

	# anything else is the first bit of the path
	[ '0::/lxc/foo',     'lxc', '/lxc' ],
	[ '0::/lxc/foo/ns',  'lxc', '/lxc' ],
	[ '0::/whatever',    'whatever', '/whatever' ],
);

plan tests => ( scalar(@tests) * 2 ) + 6;

foreach my $test (@tests) {
	my ( $cgroup, $expected_name, $expected_dir ) = @{$test};
	my ( $name,   $stat_dir )                     = $backend->cgroup_mapping($cgroup);
	is( $name,     $expected_name, $cgroup . ' maps to ' . $expected_name );
	is( $stat_dir, $expected_dir,  $cgroup . ' reads stats from ' . $expected_dir );
}

#
# things that should not map to anything
#

my ( $name, $stat_dir ) = $backend->cgroup_mapping('0::/');
is( $name,     undef, 'the root cgroup does not map to a name' );
is( $stat_dir, undef, 'the root cgroup does not map to a stat dir' );

( $name, $stat_dir ) = $backend->cgroup_mapping(undef);
is( $name, undef, 'a undef cgroup does not map to a name' );

#
# the truncation ps did must not be reintroduced... both of these are 27
# characters worth of identical cgroup path
#

my ($upload)  = $backend->cgroup_mapping('0::/system.slice/quadrant-rsync-upload.service');
my ($wrapper) = $backend->cgroup_mapping('0::/system.slice/quadrant-rsync-wrapper.service');
isnt( $upload, $wrapper, 'units sharing the first 27 characters get distinct names' );

#
# a numeric user maps the UID to the passwd info for it
#

my $uid = $<;
$backend->cgroup_mapping( '0::/user.slice/user-' . $uid . '.slice/session-1.scope' );
my @pw = getpwuid($uid);
if ( defined( $pw[0] ) ) {
	is( $backend->{uid_mapping}{$uid}{name}, $pw[0],  'uid_mapping has the name for the UID' );
	is( $backend->{uid_mapping}{$uid}{home}, $pw[7], 'uid_mapping has the home dir for the UID' );
} else {
	ok( !defined( $backend->{uid_mapping}{$uid} ), 'uid_mapping is not set for a UID with no passwd entry' );
	ok( 1,                                        'nothing to check for the home dir' );
}
