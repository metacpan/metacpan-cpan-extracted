use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Net::Bolt;
# ABSTRACT: Network controller for Neo4j Bolt
$Neo4j::Driver::Net::Bolt::VERSION = '0.41';

# This package is not part of the public Neo4j::Driver API.


use Carp qw(croak);
our @CARP_NOT = qw(Neo4j::Driver::Transaction Neo4j::Driver::Transaction::Bolt);

use Try::Tiny;
use URI 1.25;

use Neo4j::Driver::Result::Bolt;
use Neo4j::Driver::ServerInfo;
use Neo4j::Error;


# Neo4j::Bolt < 0.10 didn't report human-readable error messages
# (perlbolt#24), so we re-create the most common ones here
my %BOLT_ERROR = (
	 61 => "Connection refused",
	-13 => "Unknown host",
	-14 => "Could not agree on a protocol version",
	-15 => "Username or password is invalid",
	-22 => "Statement evaluation failed",
);

my $RESULT_MODULE = 'Neo4j::Driver::Result::Bolt';


sub new {
	# uncoverable pod
	my ($class, $driver) = @_;
	
	croak "Concurrent transactions are unsupported in Bolt; use multiple sessions" if $driver->config('concurrent_tx');
	
	my $uri = $driver->config('uri');
	if (my $auth = $driver->config('auth')) {
		croak "Only Basic Authentication is supported" if $auth->{scheme} ne 'basic';
		$uri = $uri->clone;
		$uri->userinfo( $auth->{principal} . ':' . $auth->{credentials} );
	}
	
	my $net_module = $driver->config('net_module') || 'Neo4j::Bolt';
	if ($net_module eq 'Neo4j::Bolt') {
		croak "Protocol scheme 'bolt' is not supported (Neo4j::Bolt not installed)\n"
			. "Neo4j::Driver will support 'bolt' URLs if the Neo4j::Bolt module is installed.\n"
			unless eval { require Neo4j::Bolt; 1 };
	}
	
	my $cxn;
	if ($driver->config('encrypted')) {
		$cxn = $net_module->connect_tls("$uri", {
			timeout => $driver->config('timeout'),
			ca_file => $driver->config('trust_ca'),
		});
	}
	else {
		$cxn = $net_module->connect( "$uri", $driver->config('timeout') );
	}
	$class->_trigger_bolt_error( $cxn, $driver->{plugins} ) unless $cxn->connected;
	
	return bless {
		net_module => $net_module,
		connection => $cxn,
		uri => $uri,
		result_module => $net_module->can('result_handlers') ? ($net_module->result_handlers)[0] : $RESULT_MODULE,
		server_info => $driver->{server_info},
		cypher_types => $driver->config('cypher_types'),
		active_tx => 0,
	}, $class;
}


# Trigger an error using the given event handler.
# Meant to only be called after a failure has occurred.
# May also be called as class method.
# $ref may be a Neo4j::Bolt ResultStream, Cxn, Txn.
# $error_handler may be a coderef or the event manager.
sub _trigger_bolt_error {
	my ($self, $ref, $error_handler, $connection) = @_;
	my $error = 'Neo4j::Error';
	
	$error = $error->append_new( Server => {
		code => scalar $ref->server_errcode,
		message => scalar $ref->server_errmsg,
		raw => scalar try { $ref->get_failure_details },  # Neo4j::Bolt >= 0.41
	}) if try { $ref->server_errcode || $ref->server_errmsg };
	
	$error = $error->append_new( Network => {
		code => scalar $ref->client_errnum,
		message => scalar $ref->client_errmsg // $BOLT_ERROR{$ref->client_errnum},
		as_string => $self->_bolt_error($ref),
	}) if try { $ref->client_errnum || $ref->client_errmsg };
	
	$error = $error->append_new( Network => {
		code => scalar $ref->errnum,
		message => scalar $ref->errmsg // $BOLT_ERROR{$ref->errnum},
		as_string => $self->_bolt_error($ref),
	}) if try { $ref->errnum || $ref->errmsg };
	
	try {
		my $cxn = $connection // $self->{connection};
		$error = $error->append_new( Network => {
			code => scalar $cxn->errnum,
			message => scalar $cxn->errmsg // $BOLT_ERROR{$cxn->errnum},
			as_string => $self->_bolt_error($cxn),
		}) if try { $cxn->errnum || $cxn->errmsg } && $cxn != $ref;
		$cxn->reset_cxn;
		$error = $error->append_new( Internal => {  # perlbolt#51
			code => scalar $cxn->errnum,
			message => scalar $cxn->errmsg // $BOLT_ERROR{$cxn->errnum},
			as_string => $self->_bolt_error($cxn),
		}) if try { $cxn->errnum || $cxn->errmsg };
	};
	
	return $error_handler->($error) if ref $error_handler eq 'CODE';
	$error_handler->trigger(error => $error);
}


sub _bolt_error {
	my (undef, $ref) = @_;
	
	my ($errnum, $errmsg);
	($errnum, $errmsg) = ($ref->errnum, $ref->errmsg) if $ref->can('errnum');
	($errnum, $errmsg) = ($ref->client_errnum, $ref->client_errmsg) if $ref->can('client_errnum');
	
	$errmsg //= $BOLT_ERROR{$errnum};
	return "Bolt error $errnum: $errmsg" if $errmsg;
	return "Bolt error $errnum";
}


sub _server {
	my ($self) = @_;
	
	my $cxn = $self->{connection};
	return $self->{server_info} = Neo4j::Driver::ServerInfo->new({
		uri => $self->{uri},
		version => $cxn->server_id,
		protocol => $cxn->can('protocol_version') ? $cxn->protocol_version : '',
	});
}


# Update requested database name.
sub _set_database {
	my ($self, $database) = @_;
	
	$self->{database} = $database;
}


# Send statements to the Neo4j server and return a list of all results.
sub _run {
	my ($self, $tx, @statements) = @_;
	
	die "multiple statements not supported for Bolt" if @statements > 1;
	my ($statement) = @statements;
	
	my $statement_json = {
		statement => $statement->[0],
		parameters => $statement->[1],
	};
	
	my $query_runner = $tx->{bolt_txn} ? $tx->{bolt_txn} : $self->{connection};
	
	my ($stream, $result);
	if ($statement->[0]) {
		$stream = $query_runner->run_query( @$statement, $self->{database} );
		
		if (! $stream || $stream->failure) {
			# failure() == -1 is an error condition because run_query_()
			# always calls update_errstate_rs_obj()
			
			$tx->{closed} = 1;
			$self->{active_tx} = 0;
			$self->_trigger_bolt_error( $stream, $tx->{error_handler} );
		}
		
		$result = $self->{result_module}->new({
			bolt_stream => $stream,
			bolt_connection => $self->{connection},
			statement => $statement_json,
			cypher_types => $self->{cypher_types},
			server_info => $self->{server_info},
			error_handler => $tx->{error_handler},
		});
	}
	
	return ($result);
}


sub _new_tx {
	my ($self, $driver_tx) = @_;
	
	my $params = {};
	$params->{mode} = lc substr $driver_tx->{mode}, 0, 1 if $driver_tx->{mode};
	
	my $transaction = "$self->{net_module}::Txn";
	return unless $transaction->can('new');
	return $transaction->new( $self->{connection}, $params, $self->{database} );
}


1;
