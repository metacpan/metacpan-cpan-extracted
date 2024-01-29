use strict;
use warnings;
package Neo4j_Test::MockQuery;

use parent 'Neo4j_Test::MockHTTP';

use List::Util qw( first );
use Scalar::Util qw( blessed );

sub query_result {
	my ($self, $query, $result, $commit_sub) = @_;
	$self->{query_result}{$query} = $result;
	$self->{commit_sub}{$query} = $commit_sub;
}

sub res {
	my ($self, $url, $query) = @_;
	
	my ($db, $tx, $commit) = $url =~ m<^/db/([^/]+)/tx(?:/([^/]+)(/commit)?)?>;
	return unless defined $db && $db eq $self->default_db;
	
	my %jolt = $self->_result_for_query($query) or return;
	my %http;
	my $info  = first { (keys %$_)[0] eq 'info'  } @{$jolt{jolt}};
	my $error = first { (keys %$_)[0] eq 'error' } @{$jolt{jolt}};
	
	if ($error) {
		# result is a Neo4j server error; implicit rollback
		delete $self->{tx}{$tx} if defined $tx;
	}
	elsif (! defined $tx) {
		# new tx
		$tx = ++$self->{tx}{counter};
		$info->{info} = $self->_jolt_info($tx);
		$self->{tx}{$tx} = [ $self->{commit_sub}{$query} ];
		$http{status} = '201';  # Created
		$http{location} = $info->{info}{commit};
		$http{location} =~ s|/commit$||;
	}
	elsif ($tx eq 'commit') {
		# autocommit
		$self->{commit_sub}{$query}->() if $self->{commit_sub}{$query};
	}
	elsif ($self->{tx}{$tx} && $commit) {
		# commit
		push @{$self->{tx}{$tx}}, $self->{commit_sub}{$query};
		$_->() for grep { defined } @{$self->{tx}{$tx}};
		delete $self->{tx}{$tx};
	}
	elsif ($self->{tx}{$tx} && $self->{method} eq 'DELETE') {
		# explicit rollback
		delete $self->{tx}{$tx};
	}
	elsif ($self->{tx}{$tx}) {
		# run in tx
		push @{$self->{tx}{$tx}}, $self->{commit_sub}{$query};
		$info->{info} = $self->_jolt_info($tx);
	}
	else {
		# tx doesn't exist; shouldn't happen
		warn "No tx '$url'";
		return;
	}
	
	$self->{res}{$url}{$query} = $self->_prep_response({ %jolt, %http });
	delete $self->{res}{$url}{$query}{jolt};
	return $self->{res}{$url}{$query};
}

sub _jolt_info {
	my ($self, $tx) = @_;
	
	my $default_db = $self->default_db;
	return {
		commit => "http://localhost:7474/db/$default_db/tx/$tx/commit",
		transaction => { expires => 'Tue, 1 Jan 2999 00:00:00 GMT' },
	};
}

sub _result_for_query {
	my ($self, $query) = @_;
	
	my $result = $self->{query_result}{$query};
	
	if (blessed $result && $result->isa('Neo4j::Error')) {
		return ( jolt => [
			{ error   => {
				errors => [{
					code    => $result->code,
					message => $result->message,
				}],
			}},
			{ info    => {} },
		]);
	}
	
	if ($query eq '' && ! defined $result) {
		# empty query usually means commit / rollback
		return ( jolt => [
			{ header  => { fields => [] } },
			{ summary => {} },
			{ info    => {} },
		]);
	}
	
	if ($self->_looks_like_jolt_value($result)) {
		return ( jolt => [
			{ header  => { fields => [0] } },
			{ data    => [$result] },
			{ summary => {} },
			{ info    => {} },
		]);
	}
	
	# At present, only a single sparse or strict Jolt value is accepted as result.
	
	# YAGNI?
	if (ref $result eq 'HASH') {
		# TODO: assemble single data row from $result->{row}
		# TODO: assemble single data column from $result->{column}
		# TODO: assemble full data table from $result->{table}
	}
	
	warn "No result for query '$query'";
	return;
}

sub _looks_like_jolt_value {
	my ($self, $result) = @_;
	return 1 if ref $result eq '' || ref $result eq 'ARRAY';  # sparse
	return 0 if ref $result ne 'HASH' || keys %$result != 1;
	no warnings 'qw';
	my $sigil = (keys %$result)[0];
	return !! first { $_ eq $sigil } qw| ? Z R U [] {} () -> <- .. @ T # |;
}

sub request {
	my $self = shift;
	$self->SUPER::request(@_);
	
	# Results are cached in {res}. The commit_sub logic is based on
	# side-effects of populating the cache. So, in order to support
	# that, we need to populate each cache at exactly the time the
	# request is made.
	$self->res( $self->{url}, $self->{query} );
}


1;

__END__

This is a small extension to the MockHTTP plugin that automates
transaction handling. It simplifies higher-level testing at the
expense of some degree of control over the mocked server response.
When using the Simulator or MockHTTP directly, it can be a bit
of a pain to run through test scenarios that involve explicit
transactions because the URL changes all the time. This extension
allows testers to avoid that problem.

While there is still no real database behind any of this, each
query can be equipped with a subroutine ref that is called when
the query is committed. This enables verification of
commit/rollback behaviour (essential for managed transactions).

Basic usage example:

use Neo4j::Driver;
use Neo4j_Test::MockQuery;
use Test::More;
use Test::Exception;

my $mock_plugin = Neo4j_Test::MockQuery->new;
$mock_plugin->query_result('foo' => 'bar');

my $s = Neo4j::Driver->new('http:')->plugin($mock_plugin)->session;

# Query works in an autocommit transaction:
is $s->run('foo')->single->get(0), 'bar';

# Query works in an explicit managed transaction:
is $s->execute_write(sub { shift->run('foo')->single })->get(0), 'bar';

# Query works in an explicit unmanaged transaction:
my $tx = $s->begin_transaction;
is $tx->run('foo')->single->get(0), 'bar';
$tx->rollback;

# Optional sub ref to simulate commit to database:
my $i = 0;
$mock_plugin->query_result('inc' => 'baz', sub { $i++ });
my $tx = $s->begin_transaction;
is $tx->run('inc')->single->get(0), 'baz';
is $i, 0;
$tx->commit;
is $i, 1;

# Have a query generate a server error:
my $error = Neo4j::Error->new( Server => {
	code => 'Neo.TransientError.General.OutOfMemoryError',
});
$mock_plugin->query_result('error' => $error);
throws_ok { $s->run('error') } qr/OutOfMemoryError/;

done_testing;
