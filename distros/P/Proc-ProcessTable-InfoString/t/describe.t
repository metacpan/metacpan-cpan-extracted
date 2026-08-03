#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Proc::ProcessTable::InfoString qw(proc_infostring_describe);

# usable as a plain imported function, with out calling new first
my $described = proc_infostring_describe();
ok( defined($described) && ( $described ne '' ), 'describe returns something for the current OS' );
like( $described, qr/^Info string for \Q$^O\E,/, 'defaults to the OS perl is running on' );

# and fully qualified
is( Proc::ProcessTable::InfoString::proc_infostring_describe(),
	$described, 'same when called fully qualified' );

# pulls the symbols out of the named section, each entry being a indented
# line of '   <symbol>   <description>'
sub section_symbols {
	my ( $described, $section_name ) = @_;

	my ($section) = ( $described =~ /^\Q$section_name\E\n((?:   \S.*\n)+)/m );
	if ( !defined($section) ) {
		return [];
	}

	return [ $section =~ /^   (\S+) /mg ];
}

#
# what states and flags are described is OS specific, being limited to what
# Proc::ProcessTable reports for the OS in question
#
my %os_to_expected = (
					  'freebsd'   => {
									  'states' => [ 'S', 'R', 'I', 'W', 'L', 'T', 'Z', '?' ],
									  'flags'  => [ 'O', 'E', 's', 'L', '+', 'c', 'F', 'X' ],
									  },
					  'midnightbsd' => {
										'states' => [ 'S', 'R', 'I', 'W', 'L', 'T', 'Z', '?' ],
										'flags'  => [ 'O', 'E', 's', 'L', '+', 'c', 'F', 'X' ],
										},
					  'linux'     => {
									  'states' => [ 'S', 'R', 'I', 'W', 'D', 'T', 't', 'Z', 'X', 'K', 'P', '?' ],
									  'flags'  => [ 'O', 'E', 's', '+', 'F', 'X' ],
									  },
					  # Debian GNU/kFreeBSD, which uses the Linux implementation
					  'gnukfreebsd' => {
										'states' => [ 'S', 'R', 'I', 'W', 'D', 'T', 't', 'Z', 'X', 'K', 'P', '?' ],
										'flags'  => [ 'O', 'E', 's', '+', 'F', 'X' ],
										},
					  'openbsd'   => {
									  'states' => [ 'S', 'R', 'I', 'T', 'Z', '?' ],
									  'flags'  => [ 'O', 's', '+' ],
									  },
					  'netbsd'    => {
									  'states' => [ '?' ],
									  'flags'  => [ 's', '+' ],
									  },
					  'dragonfly' => {
									  'states' => [ '?' ],
									  'flags'  => [ 's', '+' ],
									  },
					  'solaris'   => {
									  'states' => [ 'S', 'R', 'I', 'W', 'D', 'L', 'T', 't', 'Z', 'X', 'K', 'P', '?' ],
									  'flags'  => [ 'O' ],
									  },
					  );

foreach my $os ( sort( keys(%os_to_expected) ) ) {
	my $os_described = proc_infostring_describe( os => $os );
	like( $os_described, qr/^Info string for \Q$os\E,/, "$os: os arg is honored" );

	is_deeply( section_symbols( $os_described, 'States' ), $os_to_expected{$os}{states}, "$os: states described" );
	is_deeply( section_symbols( $os_described, 'Flags' ),  $os_to_expected{$os}{flags},  "$os: flags described" );
}

#
# the wait channel section, which OpenBSD does not have as it reports none
#
foreach my $wchan_os ( 'freebsd', 'linux', 'netbsd', 'dragonfly', 'solaris' ) {
	my $wchan_described = proc_infostring_describe( os => $wchan_os );
	like( $wchan_described, qr/^Wait Channel$/m,               "$wchan_os: wait channel section" );
	like( $wchan_described, qr/^    <state>\[flags\] \[wait channel\]$/m, "$wchan_os: wait channel in the format" );
}
{
	my $openbsd_described = proc_infostring_describe( os => 'openbsd' );
	unlike( $openbsd_described, qr/Wait Channel/,         'openbsd: no wait channel section' );
	like( $openbsd_described, qr/^    <state>\[flags\]$/m, 'openbsd: no wait channel in the format' );
}

done_testing;
