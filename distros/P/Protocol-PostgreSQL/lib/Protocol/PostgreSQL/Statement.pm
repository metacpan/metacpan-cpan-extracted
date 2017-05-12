package Protocol::PostgreSQL::Statement;
BEGIN {
  $Protocol::PostgreSQL::Statement::VERSION = '0.008';
}
use strict;
use warnings;
use parent qw(Mixin::Event::Dispatch);
use Scalar::Util;
use Data::Dumper;

=head1 NAME

Protocol::PostgreSQL::Statement - prepared statement handling

=head1 VERSION

version 0.008

=head1 SYNOPSIS

 use Protocol::PostgreSQL;
 my %cache;
 # Helper method to apply the returned values
 my $set_cache = sub {
	my ($sth, $row) = @_;
	my ($k, $v) = map { $row->[$_]{data} } 0..1;
	warn "Set $k to $v\n";
	$cache{$k} = $v;
 };
 # Prepared statement to insert a new value, called when no existing value was found
 my $add_sth = Protocol::PostgreSQL::Statement->new(
 	dbh => $dbh,
	sql => 'insert into sometable (name) values $1 returning id, name',
	on_data_row	=> $set_cache,
	on_no_data	=> sub {
		die "Had no response when trying to add value";
	}
 );
 # Find existing value from table
 my $find_sth = Protocol::PostgreSQL::Statement->new(
 	dbh => $dbh,
	sql => 'select id, name from sometable where id = ?',
	on_data_row	=> $set_cache,
	on_no_data	=> sub {
		my ($sth) = shift;
		warn "No data found, inserting\n";
		$add_sth->execute($sth->current_bind_values);
	}
 );
 $find_sth->execute(471, "some data");
 print "Value for 471 was " . $cache{471};

=head1 DESCRIPTION

Provides prepared-statement support for L<Protocol::PostgreSQL>.

Sequence of events for a prepared statement:

=over 4

=item * Parse - check the supplied SQL, generate a prepared statement

=item * Bind - binds values to a statement to generate a portal ('' is the empty portal)

=item * Execute - execute a given portal

=item * Sync - inform the server we're done and that we want to go back to L<Protocol::PostgreSQL/ReadyForQuery> state.

=back

Once an execute is running, we avoid sending anything else to the server until we get a ReadyForQuery response.

On instantiation, the statement will be parsed immediately. When this is complete, we are able to bind then execute.
Any requests to bind or execute before the statement is ready will be queued.

=cut

=head1 METHODS

=cut

=head2 new

Instantiate a new object, takes the following named parameters:

=over 4

=item * dbh - L<Protocol::PostgreSQL>-compatible object for the parent database handle

=item * sql - actual SQL query to run, with placeholders specified as ?

=item * statement - name to assign to this statement

=back

Will send the parse request immediately.

=cut

sub new {
	my $class = shift;
	my %args = @_;
	die "No DBH?" unless $args{dbh};
	die "No SQL?" unless defined $args{sql};

	my $self = bless {
		dbh	        => $args{dbh},
		sql	        => $args{sql},
                  (exists $args{statement})
                ? (statement    => $args{statement})
                : (),
		state		=> 'parsing',
		rows_seen	=> 0,
		data_row	=> delete $args{data_row},
		no_data		=> delete $args{no_data},
		command_complete => delete $args{command_complete},
		bind_pending	=> [],
		execute_pending	=> [],
	}, $class;
	$self->{on_ready} = delete $args{on_ready} if exists $args{on_ready};

# We queue an initial Parse request. When we get around to sending it, we'll push a describe over as well.
	$self->dbh->queue(
		callback	=> $self->sap(sub {
			my $self = shift;
			my ($dbh) = shift;
			$dbh->debug('Sent Parse request, queuing describe');
			$self->describe;
		}),
		type		=> 'Parse',
		parameters	=> [
			sql => $args{sql},
			  (exists $args{statement})
			? (statement    => $args{statement})
			: ()
		]
	);
	return $self;
}

=head1 C<parse_complete>

Callback when parsing is complete.

=cut

sub parse_complete {
	my $self = shift;
	$self->{state} = 'describing';
}

=head2 execute

Bind variables to the current statement.

=cut

sub execute {
	my $self = shift;
	my $param = [ @_ ];
	my $msg = $self->dbh->message(
		'Bind',
		param => $param,
		sth => $self,
		  (exists $self->{statement})
		? (
			statement	=> $self->{statement},
			portal		=> $self->{statement},
		)
		: ()
	);

	if($self->{state} eq 'ready') {
		$self->{state} = 'bind';
		$self->dbh->queue(
			message => $msg,
			callback => $self->sap(sub {
				my $self = shift;
				$self->{state} = 'ready';
				$self->{current_bind_values} = $param;
				$self->_execute;
			})
		);
	} else {
		push @{ $self->{bind_pending} }, $msg;
	}
	return $self;
}

=head2 current_bind_values

Returns the bind values from the currently-executing query, suitable for passing to L</execute>.

=cut

sub current_bind_values {
	my $self = shift;
	return unless $self->{current_bind_values};
	return @{ $self->{current_bind_values} };
}

=head2 data_row

Callback when we have a data row.

Maintains a running count of how many rows we've seen, and passes the data on to the C<data_row> callback if defined.

=cut

sub data_row {
	my $self = shift;
	++$self->{rows_seen};
	return $self unless $self->{data_row};

	my $row = shift;
	$self->{data_row}->($self, $row) if exists $self->{data_row};
}

=head2 command_complete

Callback for end of statement. We'll hit this if we completed without error and there's no more data available to read.

Will call the C<no_data> callback if we had no rows, and the C<command_complete> callback in either case.

=cut

sub command_complete {
	my $self = shift;
	$self->{no_data}->($self) if $self->{no_data} && !$self->{rows_seen};
	$self->{command_complete}->($self) if $self->{command_complete};
	$self->{rows_seen} = 0;
	return $self;
}

=head2 bind_complete

Called when the bind is complete. Since our bind+execute handling is currently combined, this doesn't
do anything at the moment.

=cut

sub bind_complete {
	my $self = shift;

#	$self->_execute;
	return $self;
}

=head2 _execute

Execute this query.

=cut

sub _execute {
	my $self = shift;
	if($self->{state} eq 'ready' || $self->{state} eq 'bind') {
		$self->dbh->row_description($self->row_description);
		$self->dbh->send_message(
			'Execute',
			param => [ @_ ],
			sth => $self,
			  (exists $self->{statement})
			? (portal => $self->{statement})
			: ()
		);
		$self->dbh->send_message(
			'Sync',
		);
	} else {
		$self->{execute_pending} = 1;
	}
}

=head2 describe

Describe this query. Causes PostgreSQL to send RowDescription response indicating what we expect to get back from the
server. Beats trying to parse the query for ourselves although it incurs an extra send/receive for each statement.

=cut

sub describe {
	my $self = shift;
	$self->{state} = 'describing';
	$self->dbh->send_message(
		'Describe',
		param => [ @_ ],
		  (exists $self->{statement})
		? (statement => $self->{statement})
		: (),
		sth => $self,
	);
	$self->dbh->debug('describe complete, now ready');
	$self->{state} = 'ready';
	$self->on_ready();
}

=head2 row_description

Accessor to return or update the internal row description information.

=cut

sub row_description {
	my $self = shift;
	if(@_) {
		$self->{row_description} = shift;
		return $self;
	}
	return $self->{row_description};
}

=head2 on_ready

Called when we've finished parsing and describing this query.

=cut

sub on_ready {
	my $self = shift;

	if(my $msg = shift(@{ $self->{bind_pending} })) {
		$self->dbh->debug("have bind pending");
		$self->{state} = 'binding';
		$self->dbh->queue(
			message => $msg,
			callback => $self->sap(sub {
				my $self = shift;
				$self->{state} = 'ready';
				$self->_execute;
			})
		);
	} else {
		$self->{on_ready}->() if exists $self->{on_ready};
	}
}

sub discard {
	my $self = shift;
	my %args = @_;

#	$self->add_handler_for_event(
#	) if exists $args{on_complete};

	$self->dbh->send_message(
		'Close',
		statement	=> defined($self->{statement}) ? $self->{statement} : '',
		  (exists $args{on_complete})
		? (on_complete	=> sub { $args{on_complete}->(); 0 })
		: (),
		sth		=> $self,
	);
	$self->dbh->send_message(
		'Sync',
	);
}

sub on_close_complete {
	my $self = shift;
	$self->invoke_event('close_complete' => );
	return $self;
}

=head2 finish

Finish the current statement.

Should issue a Sync to trigger a ReadyForQuery response, but that's now handled elsewhere.

=cut

sub finish {
	my $self = shift;
#	$self->dbh->send_message('Sync');
}

=head2 dbh

Accessor for the database handle (L<Protocol::PostgreSQL> object).

=cut

sub dbh { shift->{dbh} }

=head2 sap

Generate a callback with weakened copy of $self.

=cut

sub sap {
	my $self = shift;
	my $code = shift;
	Scalar::Util::weaken $self;
	return sub { $code->($self, @_) };
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2011. Licensed under the same terms as Perl itself.
