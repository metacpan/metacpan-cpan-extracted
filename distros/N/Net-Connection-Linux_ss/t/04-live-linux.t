#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection::Linux_ss;

if ( $^O !~ /linux/ ) {
	plan skip_all => 'not Linux';
}

my $ipv4_raw = `ss -p4an 2> /dev/null`;
if ( $? != 0 ) {
	plan skip_all => 'calling "ss -p4an" failed, so there is nothing here worth testing';
}

subtest 'calling ss for real' => sub {
	my @objects;

	# ptrs and ports are off so this neither hits DNS nor depends on /etc/services
	eval { @objects = &ss_to_nc_objects( { ports => 0, ptrs => 0, proc_info => 0 } ); };

	is( $@, '', 'does not die' );
	ok( scalar(@objects) > 0, 'at least one socket is open on a running system' );

	foreach my $object (@objects) {
		isa_ok( $object, 'Net::Connection' );
	}

	# the required Net::Connection bits are always filled in
	foreach my $object (@objects) {
		foreach my $field (qw( local_host local_port foreign_host foreign_port proto state )) {
			ok( defined( $object->$field ), "$field is defined" ) or last;
		}
	}

	# every proto is the netid with the address family on the end of it
	my @unexpected_protos = grep { $_ !~ /^[a-z_]+[46]$/ } map { $_->proto } @objects;
	is_deeply( \@unexpected_protos, [], 'every proto looks like something ss -4/-6 emits' );

	# the UID comes from /proc rather than ss, so at least the sockets of
	# this very process should have one
	my @with_uid = grep { defined( $_->uid ) } @objects;
	ok( scalar(@with_uid) > 0, 'at least one object got its uid looked up from /proc' );
}; ## end 'calling ss for real' => sub

subtest 'the address families can be asked for on their own' => sub {
	my @ipv4_only;
	eval { @ipv4_only = &ss_to_nc_objects( { ports => 0, ptrs => 0, proc_info => 0, ipv6 => 0 } ); };
	is( $@,                                              '', 'turning ipv6 off does not die' );
	is( scalar( grep { $_->proto =~ /6$/ } @ipv4_only ), 0,  'and no IPv6 sockets come back' );

	my @ipv6_only;
	eval { @ipv6_only = &ss_to_nc_objects( { ports => 0, ptrs => 0, proc_info => 0, ipv4 => 0 } ); };
	is( $@,                                              '', 'turning ipv4 off does not die' );
	is( scalar( grep { $_->proto =~ /4$/ } @ipv6_only ), 0,  'and no IPv4 sockets come back' );
}; ## end 'the address families can be asked for on their own' => sub

subtest 'zombie_skip against live output' => sub {
	my ( @skipped, @kept );
	eval {
		@skipped = &ss_to_nc_objects( { ipv4_string => $ipv4_raw, ports => 0, ptrs => 0, zombie_skip => 1 } );
		@kept    = &ss_to_nc_objects( { ipv4_string => $ipv4_raw, ports => 0, ptrs => 0, zombie_skip => 0 } );
	};

	is( $@, '', 'neither call dies' );
	ok( scalar(@kept) >= scalar(@skipped), 'keeping the orphans never yields fewer objects' );
}; ## end 'zombie_skip against live output' => sub

subtest 'proc info from the process table' => sub {
	my $proc_info;
	eval { $proc_info = Net::Connection::Linux_ss::_proc_table_info(); };

	is( $@,              '',     'walking the process table does not die' );
	is( ref($proc_info), 'HASH', 'a hash ref keyed on pid comes back' );
	ok( scalar( keys %{$proc_info} ) > 0, 'with at least one proc in it' );

	# init is always around and always pid 1
	ok( defined( $proc_info->{1} ), 'pid 1 is present' );

	foreach my $field (qw( proc uid pctcpu pctmem pid_start )) {
		ok( defined( $proc_info->{1}{$field} ), "pid 1 has $field" );
	}

	is( $proc_info->{1}{uid}, 0, 'pid 1 belongs to root' );
	cmp_ok( $proc_info->{1}{pid_start}, '<=', time, 'pid 1 did not start in the future' );
}; ## end 'proc info from the process table' => sub

subtest 'a full run with proc info' => sub {
	my @objects;
	eval { @objects = &ss_to_nc_objects( { ports => 0, ptrs => 0 } ); };

	is( $@, '', 'proc_info defaulting to on does not die' );
	ok( scalar(@objects) > 0, 'objects come back' );

	# a proc can exit between the ss and the process table calls, so this
	# only checks that the lookup worked for at least one of them
	my @with_pctcpu = grep { defined( $_->pctcpu ) } @objects;
	ok( scalar(@with_pctcpu) > 0, 'at least one object got its proc info filled in' );

	# ss truncates the process name to fifteen characters, so anything longer
	# than that only comes from the process table
	my @with_username = grep { defined( $_->username ) } @objects;
	ok( scalar(@with_username) > 0, 'and at least one had its uid resolved to a username' );
}; ## end 'a full run with proc info' => sub

done_testing();
