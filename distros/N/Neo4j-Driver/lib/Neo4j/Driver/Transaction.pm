use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Transaction;
# ABSTRACT: Logical container for an atomic unit of work
$Neo4j::Driver::Transaction::VERSION = '0.33';

use Carp qw(croak);
our @CARP_NOT = qw(
	Neo4j::Driver::Session
	Neo4j::Driver::Session::Bolt
	Neo4j::Driver::Session::HTTP
	Try::Tiny
);
use Scalar::Util qw(blessed);

use Neo4j::Driver::Result;


sub new {
	# uncoverable pod (private method)
	my ($class, $session) = @_;
	
	my $transaction = {
		cypher_params_v2 => $session->{cypher_params_v2},
		net => $session->{net},
		unused => 1,  # for HTTP only
		closed => 0,
		return_graph => 0,
		return_stats => 1,
	};
	
	return bless $transaction, $class;
}


sub run {
	my ($self, $query, @parameters) = @_;
	
	croak 'Transaction already closed' unless $self->is_open;
	
	warnings::warnif deprecated => __PACKAGE__ . "->{return_graph} is deprecated" if $self->{return_graph};
	
	my @statements;
	if (ref $query eq 'ARRAY') {
		warnings::warnif deprecated => "run() with multiple statements is deprecated";
		foreach my $args (@$query) {
			push @statements, $self->_prepare(@$args);
		}
	}
	elsif ($query) {
		@statements = ( $self->_prepare($query, @parameters) );
	}
	else {
		@statements = ();
	}
	
	my @results = $self->{net}->_run($self, @statements);
	
	if (scalar @statements <= 1) {
		my $result = $results[0] // Neo4j::Driver::Result->new;
		warnings::warnif deprecated => "run() in list context is deprecated" if wantarray;
		return wantarray ? $result->list : $result;
	}
	return wantarray ? @results : \@results;
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
use Try::Tiny;


sub _begin {
	my ($self) = @_;
	
	croak "Concurrent transactions are unsupported in Bolt (there is already an open transaction in this session)" if $self->{net}->{active_tx};
	
	$self->{bolt_txn} = $self->{net}->_new_tx;
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
	catch {
		$self->{net}->{active_tx} = 0;
		croak $_;
	};
	$self->{net}->{active_tx} = 0;
	
	return $results unless wantarray;
	warnings::warnif deprecated => "run() in list context is deprecated";
	return $results->list if ref $query ne 'ARRAY';
	return @$results;
}


sub commit {
	my ($self) = @_;
	
	croak 'Transaction already closed' unless $self->is_open;
	
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
my $RESULT_DATA_CONTENTS_GRAPH = ['row', 'rest', 'graph'];


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
	$json->{resultDataContents} = $RESULT_DATA_CONTENTS_GRAPH if $self->{return_graph};
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
	
	$self->_run_autocommit;
}


sub rollback {
	my ($self) = @_;
	
	croak 'Transaction already closed' unless $self->is_open;
	
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

version 0.33

=head1 SYNOPSIS

 use Neo4j::Driver;
 $session = Neo4j::Driver->new->basic_auth(...)->session;
 
 # Commit
 $tx = $session->begin_transaction;
 $node_id = $tx->run(
   'CREATE (p:Person) RETURN id(p)'
 )->single->get;
 $tx->run(
   'MATCH (p) WHERE id(p) = {id} SET p.name = {name}',
   {id => $node_id, name => 'Douglas'}
 );
 $tx->commit;
 
 # Rollback
 $tx = $session->begin_transaction;
 $tx->run('CREATE (a:Universal:Answer {value:42})');
 $tx->rollback;

=head1 DESCRIPTION

Logical container for an atomic unit of work that is either committed
in its entirety or is rolled back on failure. A driver Transaction
object corresponds to a server transaction.

Statements may be run lazily. Most of the time, you will not notice
this, because the driver automatically waits for statements to
complete at specific points to fulfill its contracts. If you require
execution of a statement to have completed, you need to use the
L<Result|Neo4j::Driver::Result>, for example by calling
one of the methods C<fetch()>, C<list()> or C<summary()>.

To create a new (unmanaged) transaction, call
L<Neo4j::Driver::Session/"begin_transaction">.

=head1 METHODS

L<Neo4j::Driver::Transaction> implements the following methods.

=head2 commit

 $transaction->commit;

Commits the transaction and returns the result.

After committing the transaction is closed and can no longer be used.

=head2 is_open

 $bool = $transaction->is_open;

Report whether this transaction is still open, which means commit
or rollback has not happened and the transaction has not timed out.

Bolt transactions by default have no timeout, while the default
C<dbms.rest.transaction.idle_timeout> for HTTP transactions is
S<60 seconds.>

=head2 rollback

 $transaction->rollback;

Rollbacks the transaction.

After rolling back the transaction is closed and can no longer be
used.

=head2 run

 $result = $transaction->run($query, %params);

Run a statement and return the L<Result|Neo4j::Driver::Result>.
This method takes an optional set of parameters that will be injected
into the Cypher statement by Neo4j. Using parameters is highly
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
   true   => \1,
   false  => \0,
   null   => undef,
   list   => [ ],
   map    => { },
 };

A Perl scalar may internally be represented as a number or a string
(see L<perldata/Scalar values>). Perl usually auto-converts one into
the other based on the context in which the scalar is used. However,
Perl cannot know the context of a Neo4j query parameter, because
queries are just opaque strings to Perl. Most often your scalars will
already have the correct internal flavour. A typical example for a
situation in which this is I<not> the case are numbers parsed out
of strings using regular expressions. If necessary, you can force
conversion of such values into the correct type using unary coercions
as shown in the example above.

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

Statement errors occur when the statement is executed on the server.
This may not necessarily have happened by the time C<run()> returns.
If you use C<try> to handle errors, make sure you use the
L<Result|Neo4j::Driver::Result> within the C<try> block, for example
by calling one of the methods C<fetch()>, C<list()> or C<summary()>.

Transactions are rolled back and closed automatically if the Neo4j
server encounters an error when running a query. However, if an
I<internal> error occurs in the driver or in one of its supporting
modules, explicit transactions remain open.

Typically, no particular handling of error conditions is required.
But if you wrap your transaction in a C<try> (or C<eval>) block,
you intend to continue using the same session even after an error
condition, I<and> you want to be absolutely sure the session is in
a defined state, you can roll back a failed transaction manually:

 use feature 'try';
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

=head1 EXPERIMENTAL FEATURES

L<Neo4j::Driver::Transaction> implements the following experimental
features. These are subject to unannounced modification or removal
in future versions. Expect your code to break if you depend upon
these features.

=head2 Execute multiple statements at once

 @statements = (
   [ 'RETURN 42' ],
   [ 'RETURN {value}', value => 'forty-two' ],
 );
 @results = $transaction->_run_multiple(@statements);
 foreach $result ( @results ) {
   say $result->single->get;
 }

The Neo4j HTTP API supports executing multiple statements within a
single HTTP request. This driver exposes this feature to the client.
It is only available on HTTP connections.

This feature might eventually be used to implement lazy statement
execution for this driver. The private C<_run_multiple()> method
which makes using this feature explicit is expected to remain
available at least until that time. See also
L<Neo4j::Driver::Plugin/"USE OF INTERNAL APIS">.

=head1 SEE ALSO

=over

=item * L<Neo4j::Driver>

=item * L<Neo4j::Driver::B<Result>>

=item * Equivalent documentation for the official Neo4j drivers:
L<Transaction (Java)|https://neo4j.com/docs/api/java-driver/5.2/org.neo4j.driver/org/neo4j/driver/Transaction.html>,
L<Transaction (JavaScript)|https://neo4j.com/docs/api/javascript-driver/5.2/class/lib6/transaction.js~Transaction.html>,
L<ITransaction (.NET)|https://neo4j.com/docs/api/dotnet-driver/5.2/html/b64c7dfe-87e9-8b85-5a02-8ff03800b67b.htm>,
L<Sessions & Transactions (Python)|https://neo4j.com/docs/api/python-driver/5.2/api.html#transaction>

=item * Neo4j L<Transactional Cypher HTTP API|https://neo4j.com/docs/http-api/5/actions/>

=item * L<Feature::Compat::Try>

=back

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

If you contact me by email, please make sure you include the word
"Perl" in your subject header to help beat the spam filters.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2022 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
