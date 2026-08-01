#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection::FreeBSD_sockstat;

# sockstat prints the raw UID when it can not resolve one to a name, so a
# numeric username is expected to be used as the UID as is. The UID picked here
# is one that should not exist anywhere.
my $unresolvable_uid  = '4294967290';
my $unresolvable_name = 'no-such-user-for-testing';

sub parse_user {
	my $user = $_[0];

	my $sockstat_json
		= '{"__version": "1", "sockstat": {"socket": ['
		. '{"user":"'
		. $user
		. '","command":"foo","pid":1234,"fd":4,"proto":"tcp4",'
		. ' "local": {"address":"*","port":22}, "foreign": {"address":"*","port":0},"conn-state":"LISTEN"}' . ']}}';

	my @objects = &sockstat_to_nc_objects(
		{
			string => $sockstat_json,
			ports  => 0,
			ptrs   => 0,
		}
	);

	return $objects[0];
} ## end sub parse_user

subtest 'a username that resolves' => sub {
	my $root_uid = getpwnam('root');

	plan skip_all => 'root does not resolve on this system' if !defined($root_uid);

	my $object = parse_user('root');

	is( $object->username, 'root',    'the username is carried over' );
	is( $object->uid,      $root_uid, 'the uid comes from getpwnam' );
}; ## end 'a username that resolves' => sub

subtest 'a uid of zero is not mistaken for a failed lookup' => sub {
	my $root_name = getpwuid(0);

	plan skip_all => 'uid 0 does not resolve on this system' if !defined($root_name);

	my $object = parse_user($root_name);

	is( $object->uid, 0, 'a uid of zero is kept rather than falling through' );
};

subtest 'a numeric username sockstat could not resolve' => sub {
	plan skip_all => "uid $unresolvable_uid unexpectedly resolves on this system"
		if defined( getpwnam($unresolvable_uid) );

	my $object = parse_user($unresolvable_uid);

	is( $object->username, $unresolvable_uid, 'the numeric username is carried over' );
	is( $object->uid,      $unresolvable_uid, 'and is reused as the uid' );
};

subtest 'a non numeric username that does not resolve' => sub {
	plan skip_all => "$unresolvable_name unexpectedly resolves on this system"
		if defined( getpwnam($unresolvable_name) );

	my $object = parse_user($unresolvable_name);

	is( $object->username, $unresolvable_name, 'the username is still carried over' );
	is( $object->uid,      undef,              'but the uid is left undefined rather than dying' );
};

done_testing();
