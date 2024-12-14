use v5.14;
use warnings;

package Neo4j::Driver::Transaction 1.02;
# ABSTRACT: Logical container for an atomic unit of work


use Carp qw(croak);
our @CARP_NOT = qw(
	Neo4j::Driver::Session
	Neo4j::Driver::Session::Bolt
	Neo4j::Driver::Session::HTTP
);
use Scalar::Util qw(blessed);

use Neo4j::Driver::Result;


sub new {
	# uncoverable pod (private method)
	my ($class, $session, $mode) = @_;
	
	my $events = $session->{driver}->{events};
	my $transaction = {
		cypher_params_v2 => $session->{cypher_params_v2},
		net => $session->{net},
		mode => $mode,
		unused => 1,  # for HTTP only
		closed => 0,
		return_stats => 1,
		error_handler => sub { $events->trigger(error => shift) },
	};
	
	return bless $transaction, $class;
}


sub run {
	my ($self, $query, @parameters) = @_;
	
	croak 'Transaction already closed' unless $self->is_open;
	
	croak sprintf 'The %s->{return_graph} feature was removed', __PACKAGE__ if $self->{return_graph};
	
	my @statements;
	if (ref $query eq 'ARRAY') {
		croak 'Call run() with a single query statement only';
		# Consider using the private internal method _run_multiple() if you really have to
	}
	elsif ($query) {
		@statements = ( $self->_prepare($query, @parameters) );
	}
	else {
		@statements = ();
	}
	
	my @results = $self->{net}->_run($self, @statements);
	
	my $result = $results[0] // Neo4j::Driver::Result->new;
	return $result;
}


sub _prepare {
	my ($self, $query, @parameters) = @_;
	
	if (ref $query) {
		croak 'Query cannot be unblessed reference' unless blessed $query;
		# REST::Neo4p::Query->query is not part of the documented API
		$query = '' . $query->query if $query->isa('REST::Neo4p::Query');
	}
	
	my $params;
	if (ref $parameters[0] eq 'HASH') {
		$params = $parameters[0];
	}
	elsif (@parameters) {
		croak 'Query parameters must be given as hash or hashref' if ref $parameters[0];
		croak 'Odd number of elements in query parameter hash' if scalar @parameters % 2 != 0;
		$params = {@parameters};
	}
	
	if ($self->{cypher_params_v2} && defined $params) {
		my @params_quoted = map {quotemeta} keys %$params;
		my $params_re = join '|', @params_quoted, map {"`$_`"} @params_quoted;
		$query =~ s/\{($params_re)}/\$$1/g;
	}
	
	my $statement = [$query, $params // {}];
	return $statement;
}




package # private
        Neo4j::Driver::Transaction::Bolt;
use parent -norequire => 'Neo4j::Driver::Transaction';

use Carp qw(croak);
use Feature::Compat::Try;


sub _begin {
	my ($self) = @_;
	
	croak "Concurrent transactions are unsupported in Bolt (there is already an open transaction in this session)" if $self->{net}->{active_tx};
	
	try {
		$self->{bolt_txn} = $self->{net}->_new_tx($self);
	}
	catch ($e) {
		die $e if $e !~ m/\bprotocol version\b/i;  # Bolt v1/v2
	}
	$self->{net}->{active_tx} = 1;
	$self->run('BEGIN') unless $self->{bolt_txn};
	return $self;
}


sub _run_autocommit {
	my ($self, $query, @parameters) = @_;
	
	croak "Concurrent transactions are unsupported in Bolt (there is already an open transaction in this session)" if $self->{net}->{active_tx};
	
	$self->{net}->{active_tx} = 1;  # run() requires an active tx
	my $results;
	try {
		$results = $self->run($query, @parameters);
	}
	catch ($e) {
		$self->{net}->{active_tx} = 0;
		croak $e;
	}
	$self->{net}->{active_tx} = 0;
	
	return $results;
}


sub commit {
	my ($self) = @_;
	
	croak 'Transaction already closed' unless $self->is_open;
	croak 'Use `return` to commit a managed transaction' if $self->{managed};
	
	if ($self->{bolt_txn}) {
		$self->{bolt_txn}->commit;
	}
	else {
		$self->run('COMMIT');
	}
	$self->{closed} = 1;
	$self->{net}->{active_tx} = 0;
}


sub rollback {
	my ($self) = @_;
	
	croak 'Transaction already closed' unless $self->is_open;
	croak 'Explicit rollback of a managed transaction' if $self->{managed};
	
	if ($self->{bolt_txn}) {
		$self->{bolt_txn}->rollback;
	}
	else {
		$self->run('ROLLBACK');
	}
	$self->{closed} = 1;
	$self->{net}->{active_tx} = 0;
}


sub is_open {
	my ($self) = @_;
	
	return 0 if $self->{closed};  # what is closed stays closed
	return $self->{net}->{active_tx};
}




package # private
        Neo4j::Driver::Transaction::HTTP;
use parent -norequire => 'Neo4j::Driver::Transaction';

use Carp qw(croak);

# use 'rest' in place of broken 'meta', see neo4j #12306
my $RESULT_DATA_CONTENTS = ['row', 'rest'];


sub _run_multiple {
	my ($self, @statements) = @_;
	
	croak 'Transaction already closed' unless $self->is_open;
	
	return $self->{net}->_run( $self, map {
		croak '_run_multiple() expects a list of array references' unless ref eq 'ARRAY';
		croak '_run_multiple() with empty statements not allowed' unless $_->[0];
		$self->_prepare(@$_);
	} @statements );
}


sub _prepare {
	my ($self, $query, @parameters) = @_;
	
	my $statement = $self->SUPER::_prepare($query, @parameters);
	my ($cypher, $parameters) = @$statement;
	
	my $json = { statement => '' . $cypher };
	$json->{resultDataContents} = $RESULT_DATA_CONTENTS;
	$json->{includeStats} = \1 if $self->{return_stats};
	$json->{parameters} = $parameters if %$parameters;
	
	return $json;
}


sub _begin {
	my ($self) = @_;
	
	# no-op for HTTP
	return $self;
}


sub _run_autocommit {
	my ($self, $query, @parameters) = @_;
	
	$self->{transaction_endpoint} = $self->{commit_endpoint};
	$self->{transaction_endpoint} //= URI->new( $self->{net}->{endpoints}->{new_commit} )->path;
	
	return $self->run($query, @parameters);
}


sub commit {
	my ($self) = @_;
	
	croak 'Use `return` to commit a managed transaction' if $self->{managed};
	
	$self->_run_autocommit;
}


sub rollback {
	my ($self) = @_;
	
	croak 'Transaction already closed' unless $self->is_open;
	croak 'Explicit rollback of a managed transaction' if $self->{managed};
	
	$self->{net}->_request($self, 'DELETE') if $self->{transaction_endpoint};
	$self->{closed} = 1;
}


sub is_open {
	my ($self) = @_;
	
	return 0 if $self->{closed};
	return 1 if $self->{unused};
	return $self->{net}->_is_active_tx($self);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Transaction - Logical container for an atomic unit of work

=head1 VERSION

version 1.02

=head1 SYNOPSIS

 # Managed transaction function
 $session->execute_write( sub ($transaction) {
   $transaction->run( ... );
   # Automatic commit upon subroutine return
   
   if ( my $failure = ... ) {
     die;   # any exception will cause a rollback
     $transaction->rollback;  # explicit rollback
   }
 });
 
 # Unmanaged explicit transaction
 $transaction = $session->begin_transaction;
 $transaction->run( ... );
 if ( my $success = ... ) {
   $transaction->commit;
 } else {
   $transaction->rollback;
 }
 
 # Query parameters
 $query = "RETURN \$param";
 $transaction->run( $query, { param => $value, ... } );
 $transaction->run( $query,   param => $value, ...   );
 
 # Neo4j v2 syntax for query parameters
 $driver->config( cypher_params => v2 );
 $query = "RETURN {param}";

=head1 DESCRIPTION

Logical container for an atomic unit of work that is either committed
in its entirety or is rolled back on failure. A driver Transaction
object corresponds to a server transaction.

Queries may be run lazily. Most of the time, you will not notice
this, because the driver automatically waits for queries to
complete at specific points to fulfill its contracts. If you require
execution of a query to have completed (S<e. g.> to check for
query errors), you need to call any method in the
L<Result|Neo4j::Driver::Result>, such as C<has_next()>.

Neo4j drivers allow the creation of different kinds of transactions.
See L<Neo4j::Driver::Session> for details.

=head1 METHODS

L<Neo4j::Driver::Transaction> implements the following methods.

=head2 commit

 $transaction->commit;

Commits an unmanaged transaction.

After committing, the transaction is closed and can no longer be used.

=head2 is_open

 $bool = $transaction->is_open;

Report whether this transaction is still open, which means commit
or rollback has not happened and the transaction has not timed out.

Bolt transactions by default have no timeout. If necessary, the
timeout for idle HTTP transactions may be configured in the Neo4j
server using the setting C<dbms.rest.transaction.idle_timeout> or
C<server.http.transaction_idle_timeout>, depending on the version.

=head2 rollback

 $transaction->rollback;

Rolls back a transaction.

After rolling back the transaction is closed and can no longer be
used.

=head2 run

 $result = $transaction->run($query);
 $result = $transaction->run($query, \%params);

Run a query and return the L<Result|Neo4j::Driver::Result>.
This method takes an optional set of parameters that will be injected
into the Cypher query by Neo4j. Using parameters is highly
encouraged: It helps avoid dangerous Cypher injection attacks and
improves database performance as Neo4j can re-use query plans more
often.

Parameters are given as Perl hashref. Alternatively, they may be
given as a hash / balanced list.

 # all of these are semantically equal
 $result = $transaction->run('...', {key => 'value'});
 $result = $transaction->run('...',  key => 'value' );
 %hash = (key => 'value');
 $result = $transaction->run('...', \%hash);
 $result = $transaction->run('...',  %hash);

When used as parameters, Perl values are converted to Neo4j types as
shown in the following example:

 $parameters = {
   number =>  0 + $scalar,
   string => '' . $scalar,
   true   => builtin::true,   # or JSON::PP::true
   false  => builtin::false,  # or JSON::PP::false
   null   => undef,
   list   => [ ],
   map    => { },
 };

For details and for known issues with type mapping see
L<Neo4j::Driver::Types>.

Running empty queries is supported. They yield an empty result
(having zero records). With HTTP connections, the empty result is
retrieved from the server, which resets the transaction timeout.
This feature may also be used to test the connection to the server.
For Bolt connections, the empty result is generated locally in the
driver.

 $result = $transaction->run;

Queries are usually strings, but may also be L<REST::Neo4p::Query> or
L<Neo4j::Cypher::Abstract> objects. Such objects are automatically
converted to strings before they are sent to the Neo4j server.

 $transaction->run( REST::Neo4p::Query->new('RETURN 42') );
 $transaction->run( Neo4j::Cypher::Abstract->new->return(42) );

=head1 ERROR HANDLING

This driver always reports all errors using C<die()>. Error messages
received from the Neo4j server are passed on as-is.
See L<Neo4j::Driver::Plugin/"error"> for accessing error details.

Query errors can occur when the query is executed on the server.
This may not necessarily have happened by the time C<run()> returns.
If you use L<C<try>/C<catch>|Feature::Compat::Try> to handle errors,
make sure you actually I<use> the L<Result|Neo4j::Driver::Result>
within the C<try> block, for example by retrieving a record or
calling the method C<has_next()>.

Transactions are rolled back and closed automatically if the Neo4j
server encounters an error when running a query. However, if an
error with the network connection to the server occurs, or if an
internal error occurs in the driver or in one of its supporting
modules, I<unmanaged> transactions may remain open.

Typically, no particular handling of error conditions is required.
But if you use L<C<try>/C<catch>|Feature::Compat::Try>,
you intend to continue using the same session even after an error
condition, I<and> you want to be absolutely sure the session is in
a defined state, you can roll back a failed transaction manually:

 use Feature::Compat::Try;
 $tx = $session->begin_transaction;
 try {
   ...;
   $tx->commit;
 }
 catch ($e) {
   say "Database error: $e";
   ...;
   $tx->rollback if $tx->is_open;
 }
 # at this point, $session is safe to use

=head1 SEE ALSO

=over

=item * L<Neo4j::Driver>

=item * L<Neo4j::Driver::B<Result>>

=item * L<Neo4j::Driver::Types>

=back

=head1 AUTHOR

Arne Johannessen (L<AJNN|https://metacpan.org/author/AJNN>)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2024 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
