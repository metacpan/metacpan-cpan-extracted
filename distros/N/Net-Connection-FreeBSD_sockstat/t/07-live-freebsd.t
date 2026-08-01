#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection::FreeBSD_sockstat;

if ( $^O !~ /freebsd/ ) {
	plan skip_all => 'not FreeBSD';
}

# libxo support was only added to sockstat in FreeBSD 15.0, so anything older
# exits with a usage error and there is nothing here worth testing
my $sockstat_raw = `sockstat -46s --libxo json 2>/dev/null`;
if ( $? != 0 ) {
	plan skip_all => 'sockstat does not understand --libxo, so this is older than FreeBSD 15.0';
}

subtest 'calling sockstat for real' => sub {
	my @objects;

	# ptrs and ports are off so this neither hits DNS nor depends on /etc/services
	eval { @objects = &sockstat_to_nc_objects( { ports => 0, ptrs => 0, proc_info => 0 } ); };

	is( $@, '', 'does not die' );
	ok( scalar(@objects) > 0, 'at least one socket is open on a running system' );

	foreach my $object (@objects) {
		isa_ok( $object, 'Net::Connection' );
	}

	# every socket sockstat -46 reports is one of these
	my @unexpected_protos = grep { $_ !~ /^(?:tcp|udp|div|sctp)(?:4|6|46)$/ } map { $_->proto } @objects;
	is_deeply( \@unexpected_protos, [], 'every proto looks like something sockstat -46 emits' );

	# the required Net::Connection bits are always filled in
	foreach my $object (@objects) {
		foreach my $field (qw( local_host local_port foreign_host foreign_port proto )) {
			ok( defined( $object->$field ), "$field is defined" ) or last;
		}
	}
}; ## end 'calling sockstat for real' => sub

subtest 'the parsed string matches a live call' => sub {
	my @from_string;
	eval { @from_string = &sockstat_to_nc_objects( { string => $sockstat_raw, ports => 0, ptrs => 0 } ); };

	is( $@, '', 'the raw output of a live sockstat parses' );
	ok( scalar(@from_string) > 0, 'and yields objects' );
};

subtest 'zombie_skip off against live output' => sub {
	my ( @skipped, @kept );
	eval {
		@skipped = &sockstat_to_nc_objects( { string => $sockstat_raw, ports => 0, ptrs => 0, zombie_skip => 1 } );
		@kept    = &sockstat_to_nc_objects( { string => $sockstat_raw, ports => 0, ptrs => 0, zombie_skip => 0 } );
	};

	is( $@, '', 'neither call dies' );
	ok( scalar(@kept) >= scalar(@skipped), 'keeping the orphans never yields fewer objects' );
}; ## end 'zombie_skip off against live output' => sub

subtest 'proc info from ps' => sub {
	my $proc_info;
	eval { $proc_info = Net::Connection::FreeBSD_sockstat::_ps_proc_info(); };

	is( $@,              '',     'calling ps does not die' );
	is( ref($proc_info), 'HASH', 'a hash ref keyed on pid comes back' );
	ok( scalar( keys %{$proc_info} ) > 0, 'with at least one proc in it' );

	# init is always around and always pid 1
	ok( defined( $proc_info->{1} ), 'pid 1 is present' );

	foreach my $field (qw( proc wchan pctcpu pctmem pid_start )) {
		ok( defined( $proc_info->{1}{$field} ), "pid 1 has $field" );
	}

	# ps hands these back as JSON strings, so make sure they were cast to
	# numbers rather than left as the likes of the string '0.0'
	foreach my $field (qw( pctcpu pctmem pid_start )) {
		my $value = $proc_info->{1}{$field};

		like( $value, qr/^[0-9.]+$/, "$field looks like a number" );
		is( $value, $value + 0, "$field was cast to a number rather than left a string" );
	}
	cmp_ok( $proc_info->{1}{pid_start}, '<=', time, 'pid 1 did not start in the future' );
}; ## end 'proc info from ps' => sub

subtest 'a full run with proc info' => sub {
	my @objects;
	eval { @objects = &sockstat_to_nc_objects( { ports => 0, ptrs => 0 } ); };

	is( $@, '', 'proc_info defaulting to on does not die' );
	ok( scalar(@objects) > 0, 'objects come back' );

	# a proc can exit between the sockstat and the ps calls, so this only
	# checks that the lookup worked for at least one of them
	my @with_proc = grep { defined( $_->proc ) } @objects;
	ok( scalar(@with_proc) > 0, 'at least one object got its proc filled in' );
}; ## end 'a full run with proc info' => sub

done_testing();
