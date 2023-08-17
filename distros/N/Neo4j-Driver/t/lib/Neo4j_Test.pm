package Neo4j_Test;
use strict;
use warnings;

use URI;
use Neo4j::Driver;
use Neo4j_Test::NetModulePlugin;
use Neo4j_Test::Sim;


our $user = $ENV{TEST_NEO4J_USERNAME} // 'neo4j';
our $pass = $ENV{TEST_NEO4J_PASSWORD} // '';
our $server = $ENV{TEST_NEO4J_SERVER} // '';
our $error = '';

# may be used for conditional testing
our $bolt;
our $sim;


# returns a driver that might or might not work
sub driver_maybe {
	
	my $driver;
	eval {
		# a default URI (localhost) is built into the driver
		$driver = Neo4j::Driver->new( $server );
	};
	return unless $driver;
	
	$driver->basic_auth($user, $pass);
	$driver->config(timeout => 2);  # 2 seconds timeout may speed up testing
	$driver->config(cypher_params => v2);
	
	$bolt = $driver->config('uri') && $driver->config('uri')->scheme eq 'bolt';
	if ($ENV{TEST_NEO4J_NETMODULE}) {
		eval "require $ENV{TEST_NEO4J_NETMODULE} unless $ENV{TEST_NEO4J_NETMODULE}->can('new'); 1" or die;
		$driver->plugin(Neo4j_Test::NetModulePlugin->new($ENV{TEST_NEO4J_NETMODULE}));
	}
	elsif (! $ENV{TEST_NEO4J_PASSWORD} && ! $bolt) {
		# without a password, we use the REST simulator instead
		$driver->plugin(Neo4j_Test::NetModulePlugin->new('Neo4j_Test::Sim'));
		$sim = 1;
	}
	
	return $driver;
}


# returns a driver that is known to work
sub driver {
	my $driver = driver_maybe;
	
	# verify that the supplied credentials actually work
	eval {
		# the Neo4j HTTP API allows running empty statements
		$driver->session->run('');
	};
	if ($@) {
		$error = $@;
		return;
	}
	
	return $driver;
}


# returns a driver that is expected to fail (no connection)
sub driver_no_connect {
	# Port 14 is unassigned and should be closed. The IP address is the
	# multicast address that belongs to TEST-NET-1 and should fail.
	driver_maybe;  # init $bolt
	my $driver = Neo4j::Driver->new(($bolt ? 'bolt' : 'http') . '://234.192.0.2:14');
	return $driver;
}


# returns a driver that is expected to fail (unauthorized)
sub driver_no_auth {
	my $driver = driver_maybe;
	if ($sim) {
		delete $driver->{plugins}->{handlers}->{http_adapter_factory};
		$driver->plugin(Neo4j_Test::NetModulePlugin->new( Neo4j_Test::Sim->new({auth => 0}) ));
	}
	$driver->{config}->{auth} = { scheme => 'basic', principal => "no\tuser", credentials => "no\tpass" };
	return $driver;
}


# returns a transaction not connected to a server
# (convenience for unit tests)
sub transaction_unconnected {
	my (undef, $driver) = @_;
	
	$driver //= Neo4j::Driver->new;
	my $session = Neo4j::Driver::Session::HTTP->new( $driver );
	my $transaction = Neo4j::Driver::Transaction::HTTP->new( $session );
	return $transaction;
}


1;

__END__

These environment variables can be specified either in the shell (using
export/setenv) or in dist.ini (when using `dzil test`). The driver
does support connecting to a Neo4j server with authentication disabled.
However, without a password, these tests will never attempt a server
connection, instead relying on the REST simulator (Neo4j_Test::Sim).
To execute these tests on a real Neo4j server, you need to either specify
a password or explicitly ask for a net_module other than Neo4j::Sim using
TEST_NEO4J_NETMODULE. If the password is the only available setting,
default values will be used for the server URI and user name.

Examples:


#! bash

export TEST_NEO4J_SERVER=http://127.0.0.1:7474
export TEST_NEO4J_USERNAME=neo4j
export TEST_NEO4J_PASSWORD=neo4j

# server with auth disabled
export TEST_NEO4J_SERVER=http://127.0.0.1:7474
export TEST_NEO4J_NETMODULE=Neo4j::Driver::Net::HTTP::LWP


#! csh

setenv TEST_NEO4J_SERVER http://127.0.0.1:7474
setenv TEST_NEO4J_USERNAME neo4j
setenv TEST_NEO4J_PASSWORD neo4j
