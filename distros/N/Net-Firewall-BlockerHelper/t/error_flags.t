#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# Asserts the exact error codes / flags raised, not just that something died.
# All errors are fatal, so the codes are read back from the Error::Helper
# package globals after catching the die.

sub new_error {
	my (%opts) = @_;
	eval { Net::Firewall::BlockerHelper->new(%opts); };
	ok( $@, ( $opts{_desc} || 'new' ) . ' dies' );
	return ( $Error::Helper::error, $Error::Helper::errorFlag );
}

my %base = ( backend => 'dummy', name => 'ssh' );

# --- new: each validation failure raises its documented code/flag ------------
{
	my ( $error, $flag ) = new_error( %base, backend => undef, _desc => 'undef backend' );
	is( $error, 1,                    'undef backend raises error 1' );
	is( $flag,  'noBackendSpecified', 'undef backend raises noBackendSpecified' );
}
{
	my ( $error, $flag ) = new_error( %base, backend => 'no/pe', _desc => 'invalid backend' );
	is( $error, 11,               'invalid backend raises error 11' );
	is( $flag,  'invalidBackend', 'invalid backend raises invalidBackend, not noBackendSpecified' );
}
{
	my ( $error, $flag ) = new_error( %base, ports => {}, _desc => 'ports not array' );
	is( $error, 3,               'non-array ports raises error 3' );
	is( $flag,  'portsNotArray', 'non-array ports raises portsNotArray' );
}
{
	my ( $error, $flag ) = new_error( %base, ports => ['0'], _desc => 'port 0' );
	is( $error, 2,                      'port 0 raises error 2' );
	is( $flag,  'invalidPortSpecified', 'port 0 raises invalidPortSpecified' );
}
{
	my ( $error, $flag ) = new_error( %base, ports => ['65536'], _desc => 'port 65536' );
	is( $error, 2,                      'port above 65535 raises error 2' );
	is( $flag,  'invalidPortSpecified', 'port above 65535 raises invalidPortSpecified' );
}
{
	my ( $error, $flag ) = new_error( %base, ports => ['not-a-service-name-derp'], _desc => 'bad service name' );
	is( $error, 2, 'unresolvable service name raises error 2' );
}
{
	my $fw = Net::Firewall::BlockerHelper->new( %base, ports => ['65535'] );
	is_deeply( $fw->{ports}, [65535], 'port 65535 is accepted as the upper bound' );
}
{
	my ( $error, $flag ) = new_error( %base, protocols => {}, _desc => 'protocols not array' );
	is( $error, 4,                   'non-array protocols raises error 4' );
	is( $flag,  'protocolsNotArray', 'non-array protocols raises protocolsNotArray' );
}
{
	my ( $error, $flag ) = new_error( %base, protocols => ['thisisinvalid-derp'], _desc => 'invalid protocol' );
	is( $error, 5, 'unresolvable protocol raises error 5' );
}
{
	my ( $error, $flag ) = new_error( %base, prefix => ' derp', _desc => 'invalid prefix' );
	is( $error, 6,                        'invalid prefix raises error 6' );
	is( $flag,  'invalidPrefixSpecified', 'invalid prefix raises invalidPrefixSpecified' );
}
{
	my ( $error, $flag ) = new_error( %base, name => undef, _desc => 'undef name' );
	is( $error, 7,             'undef name raises error 7' );
	is( $flag,  'invalidName', 'undef name raises invalidName' );
}
{
	my ( $error, $flag ) = new_error( %base, options => [], _desc => 'options not hash' );
	is( $error, 8,               'non-hash options raises error 8' );
	is( $flag,  'optionsNotHash', 'non-hash options raises optionsNotHash' );
}

# --- ban/unban input validation ----------------------------------------------
{
	my $fw = Net::Firewall::BlockerHelper->new( %base, testing => 1 );
	$fw->init_backend;

	eval { $fw->ban; };
	is( $fw->error, 9, 'ban with nothing to ban raises error 9' );

	eval { $fw->ban( ban => 'not.an.ip' ); };
	is( $fw->error,     10,             'ban of a non-IP raises error 10' );
	is( $fw->errorFlag, 'banItemNotIP', 'ban of a non-IP raises banItemNotIP' );

	eval { $fw->ban( ban => ['1.2.3.4'] ); };
	is( $fw->error, 10, 'ban of a ref raises error 10' );

	eval { $fw->unban( ban => 'not.an.ip' ); };
	is( $fw->error, 10, 'unban of a non-IP raises error 10' );
}

# --- methods called before init_backend give a clear error --------------------
{
	my $fw = Net::Firewall::BlockerHelper->new( %base, testing => 1 );

	my %method_error = (
		ban      => 13,
		unban    => 14,
		list     => 15,
		re_init  => 16,
		teardown => 17,
		check    => 24,
		flush    => 25,
	);

	foreach my $method ( sort( keys(%method_error) ) ) {
		eval { $fw->$method( ban => '1.2.3.4' ); };
		ok( $@, $method . ' before init_backend dies' );
		is( $fw->error, $method_error{$method}, $method . ' before init_backend raises error ' . $method_error{$method} );
		like(
			$fw->errorString,
			qr/init_backend/,
			$method . ' before init_backend mentions init_backend in the error string'
		);
	}
}

done_testing();
