use v5.14;
use warnings;

package Neo4j::Driver::Net::Bolt 1.02;
# ABSTRACT: Network controller for Neo4j Bolt


# This package is not part of the public Neo4j::Driver API.


use Carp qw(croak);
our @CARP_NOT = qw(Neo4j::Driver::Transaction Neo4j::Driver::Transaction::Bolt);
use Feature::Compat::Try;

use Neo4j::Driver::Result::Bolt;
use Neo4j::Driver::ServerInfo;
use Neo4j::Error;


my $RESULT_MODULE = 'Neo4j::Driver::Result::Bolt';

our $verify_version = 1;


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
	
	my $net_module = $driver->{config}->{net_module} || 'Neo4j::Bolt';
	_verify_version() if $verify_version && $net_module eq 'Neo4j::Bolt';
	
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
	$class->_trigger_bolt_error( $cxn, $driver->{events} ) unless $cxn->connected;
	
	return bless {
		net_module => $net_module,
		connection => $cxn,
		uri => $uri,
		result_module => $net_module->can('result_handlers') ? ($net_module->result_handlers)[0] : $RESULT_MODULE,
		server_info => $driver->{server_info},
		active_tx => 0,
	}, $class;
}


# Some Neo4j::Client versions are known to provide broken versions of the lib.
# Known-good module version pairs:
#   +-- Neo4j::Bolt
#   |       +-- Neo4j::Client
#   |       |     +-- max recommended Neo4j server
#   |       |     |
#  0.5000  0.54  5.x
#  0.4203  0.46  4.4
#  0.20    0.17  3.4
#  0.12     -    3.4  (system libneo4j-client)
sub _verify_version {
	# Running this check once (for the first session) is enough.
	$verify_version = 0;
	
	try {
		require Neo4j::Bolt;
		my $bolt_version = Neo4j::Bolt->VERSION('0.4201');
		
		return if $bolt_version ge '0.5000';
		my $client_version = eval { Neo4j::Client->VERSION } // '';
		$client_version =~ m/^0\.5[012]$/ and die
			sprintf "Installed Neo4j::Client version %s is defective (known-good versions are 0.46 and 0.54 or later; you may also need to reinstall Neo4j::Bolt)\n", $client_version;
	}
	catch ($e) {
		$e =~ s/\.?\s*$//;
		croak sprintf "Protocol scheme 'bolt' is not supported (Neo4j::Bolt not installed).\nNeo4j::Driver will support 'bolt' URLs if the Neo4j::Bolt module is installed.\n%s", $e;
	}
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
		raw => scalar $ref->get_failure_details,
	}) if eval { $ref->server_errcode || $ref->server_errmsg };
	
	$error = $error->append_new( Network => {
		code => scalar $ref->client_errnum,
		message => scalar $ref->client_errmsg,
		as_string => $self->_bolt_error($ref),
	}) if eval { $ref->client_errnum || $ref->client_errmsg };
	
	$error = $error->append_new( Network => {
		code => scalar $ref->errnum,
		message => scalar $ref->errmsg,
		as_string => $self->_bolt_error($ref),
	}) if eval { $ref->errnum || $ref->errmsg };
	
	try {
		my $cxn = $connection // $self->{connection};
		$error = $error->append_new( Network => {
			code => scalar $cxn->errnum,
			message => scalar $cxn->errmsg,
			as_string => $self->_bolt_error($cxn),
		}) if eval { $cxn->errnum || $cxn->errmsg } && $cxn != $ref;
		$cxn->reset_cxn;
		$error = $error->append_new( Internal => {  # perlbolt#51
			code => scalar $cxn->errnum,
			message => scalar $cxn->errmsg,
			as_string => $self->_bolt_error($cxn),
		}) if eval { $cxn->errnum || $cxn->errmsg };
	}
	catch ($e) {}
	
	return $error_handler->($error) if ref $error_handler eq 'CODE';
	$error_handler->trigger(error => $error);
}


sub _bolt_error {
	my (undef, $ref) = @_;
	
	my ($errnum, $errmsg);
	($errnum, $errmsg) = ($ref->errnum, $ref->errmsg) if $ref->can('errnum');
	($errnum, $errmsg) = ($ref->client_errnum, $ref->client_errmsg) if $ref->can('client_errnum');
	
	return "Bolt error $errnum: $errmsg" if $errmsg;
	return "Bolt error $errnum";
}


sub _server {
	my ($self) = @_;
	
	my $cxn = $self->{connection};
	return $self->{server_info} = Neo4j::Driver::ServerInfo->new({
		uri => $self->{uri},
		version => $cxn->server_id,
		protocol => $cxn->protocol_version,
	});
}


# Update requested database name.
sub _set_database {
	my ($self, $database) = @_;
	
	$self->{database} = $database;
}


# Send queries to the Neo4j server and return a list of all results.
sub _run {
	my ($self, $tx, @queries) = @_;
	
	die "multiple queries not supported for Bolt" if @queries > 1;
	my ($query) = @queries;
	
	my $query_runner = $tx->{bolt_txn} ? $tx->{bolt_txn} : $self->{connection};
	
	my ($stream, $result);
	if ($query->[0]) {
		$stream = $query_runner->run_query( @$query, $self->{database} );
		
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
			query => $query,
			server_info => $self->{server_info},
			error_handler => $tx->{error_handler},
		});
	}
	else {
		$result = Neo4j::Driver::Result->new;
		$result->{server_info} = $self->{server_info};
	}
	
	return ($result);
}


sub _new_tx {
	my ($self, $driver_tx) = @_;
	
	my $params = {};
	$params->{mode} = lc substr $driver_tx->{mode}, 0, 1 if $driver_tx->{mode};
	
	my $transaction = "$self->{net_module}::Txn";
	return $transaction->new( $self->{connection}, $params, $self->{database} );
}


1;
