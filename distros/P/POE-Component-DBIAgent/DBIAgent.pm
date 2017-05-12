package POE::Component::DBIAgent;

# {{{ POD

=head1 NAME

POE::Component::DBIAgent - POE Component for running asynchronous DBI calls.

=head1 SYNOPSIS

 sub _start {
    my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];

    $heap->{helper} = POE::Component::DBIAgent->new( DSN => [$dsn,
					       $username,
					       $password
					      ],
				       Queries => $self->make_queries,
				       Count => 3,
				       Debug => 1,
				     );

	# Queries takes a hashref of the form:
	# { query_name => 'select blah from table where x = ?',
	#   other_query => 'select blah_blah from big_view',
	#   etc.
	# }

    $heap->{helper}->query(query_name =>
			   { cookie => 'starting_query' },
			   session => 'get_row_from_dbiagent');

 }

 sub get_row_from_dbiagent {
    my ($kernel, $self, $heap, $row, $cookie) = @_[KERNEL, OBJECT, HEAP, ARG0, ARG1];
    if ($row ne 'EOF') {

 # {{{ PROCESS A ROW

	#row is a listref of columns

 # }}} PROCESS A ROW

    } else {

 # {{{ NO MORE ROWS

	#cleanup code here

 # }}} NO MORE ROWS

    }

 }


=head1 DESCRIPTION

DBIAgent is your answer to non-blocking DBI in POE.

It fires off a configurable number child processes (defaults to 3) and
feeds database queries to it via two-way pipe (or sockets ... however
POE::Component::Wheel::Run is able to manage it).  The primary method
is C<query>.

=head2 Usage

After initializing a DBIAgent and storing it in a session's heap, one
executes a C<query> (or C<query_slow>) with the query name,
destination session (name or id) and destination state (as well as any
query parameters, optionally) as arguments.  As each row of data comes
back from the query, the destination state (in the destination
session) is invoked with that row of data in its C<$_[ARG0]> slot.  When
there are no more rows to return, the data in C<$_[ARG0]> is the string
'EOF'.

Not EVERY query should run through the DBIAgent.  If you need to run a
short lookup from within a state, sometimes it can be a hassle to have
to define a whole seperate state to receive its value, and resume
processing from there..  The determining factor, of course, is how
long your query will take to execute.  If you are trying to retrieve
one row from a properly indexed table, use
C<$dbh-E<gt>selectrow_array()>.  If there's a join involved, or
multiple rows, or a view, you probably want to use DBIAgent.  If it's
a longish query and startup costs (time) don't matter to you, go ahead
and do it inline.. but remember the whole of your program suspends
waiting for the result.  If startup costs DO matter, use DBIAgent.

=head2 Return Values

The destination state in the destination session (specified in the
call to C<query()>) will receive the return values from the query in
its C<$_[ARG0]> parameter.  DBIAgent invokes DBI's C<fetch> method
internally, so the value will be a reference to an array.  If your
query returns multiple rows, then your state will be invoked multiple
times, once per row.  B<ADDITIONALLY>, your state will be called one
time with C<$_[ARG0]> containing the string 'EOF'. 'EOF' is returned I<even
if the query doesn't return any other rows>.  This is also what to
expect for DML (INSERT, UPDATE, DELETE) queries.  A way to utilise
this might be as follows:

 sub some_state {
     #...
     if ($enough_values_to_begin_updating) {

	 $heap->{dbiagent}->query(update_values_query =>
				  this_session =>
				  update_next_value =>
				  shift @{$heap->{values_to_be_updated}}
				 );
     }
 }

 sub update_next_value {
     my ($self, $heap) = @_[OBJECT, HEAP];
     # we got 'EOF' in ARG0 here but we don't care... we know that an
     # update has been executed.

     for (1..3) {		# Do three at a time!
	 my $value;
	 last unless defined ($value = shift @{$heap->{values_to_be_updated}});
	 $heap->{dbiagent}->query(update_values =>
				  this_session =>
				  update_next_value =>
				  $value
				 );
     }

 }

=cut

# }}} POD

#use Data::Dumper;
use Storable qw/freeze thaw/;
use Carp;

use strict;
use POE qw/Session Filter::Reference Wheel::Run Component::DBIAgent::Helper Component::DBIAgent::Queue/;

use vars qw/$VERSION/;

$VERSION = sprintf("%d.%02d", q$Revision: 0.26 $ =~ /(\d+)\.(\d+)/);

use constant DEFAULT_KIDS => 3;

sub debug { $_[0]->{debug} }
#sub debug { 1 }
#sub debug { 0 }

#sub carp { warn @_ }
#sub croak { die @_ }

# {{{ new

=head2 new()

Creating an instance creates a POE::Session to manage communication
with the Helper processes.  Queue management is transparent and
automatic.  The constructor is named C<new()> (surprised, eh?  Yeah,
me too).  The parameters are as follows:

=over

=item DSN

An arrayref of parameters to pass to DBI->connect (usually a dsn,
username, and password).

=item Queries

A hashref of the form Query_Name => "$SQL".  For example:

 {
   sysdate => "select sysdate from dual",
   employee_record => "select * from emp where id = ?",
   increase_inventory => "update inventory
                          set count = count + ?
                          where item_id = ?",
 }

As the example indicates, DBI placeholders are supported, as are DML
statements.

=item Count

The number of helper processes to spawn.  Defaults to 3.  The optimal
value for this parameter will depend on several factors, such as: how
many different queries your program will be running, how much RAM you
have, how often you run queries, and most importantly, how many
queries you intend to run I<simultaneously>.

=item ErrorState

An listref containing a session and event name to receive error
messages from the DBI.  The message arrives in ARG0.

=back

=cut

sub new {
    my $type = shift;

    croak "$type needs an even number of parameters" if @_ & 1;
    my %params = @_;

    my $dsn = delete $params{DSN};
    croak "$type needs a DSN parameter" unless defined $dsn;
    croak "DSN needs to be an array reference" unless ref $dsn eq 'ARRAY';

    my $queries = delete $params{Queries};
    croak "$type needs a Queries parameter" unless defined $queries;
    croak "Queries needs to be a hash reference" unless ref $queries eq 'HASH';

    my $count = delete $params{Count} || DEFAULT_KIDS;
    #croak "$type needs a Count parameter" unless defined $queries;

    # croak "Queries needs to be a hash reference" unless ref $queries eq 'HASH';

    my $debug = delete $params{Debug} || 0;
    # $count = 1 if $debug;

    my $errorstate = delete $params{ErrorState} || undef;

    # Make sure the user didn't pass in parameters we're not aware of.
    if (scalar keys %params) {
	carp( "unknown parameters in $type constructor call: ",
	      join(', ', sort keys %params)
	    );
    }
    my $self = bless {}, $type;
    my $config = shift;

    $self->{dsn} = $dsn;
    $self->{queries} = $queries;
    $self->{count} = $count;
    $self->{debug} = $debug;
    $self->{errorstate} = $errorstate;
    $self->{finish} = 0;
    $self->{pending_query_count} = 0;
    $self->{active_query_count} = 0;
    $self->{cookies} = [];
    $self->{group_cache} = [];

#     POE::Session->new( $self,
# 		       [ qw [ _start _stop db_reply remote_stderr error ] ]
# 		     );

    POE::Session->create( object_states =>
                          [ $self => [ qw [ _start _stop db_reply remote_stderr error ] ] ]
                        );

    return $self;

}

# }}} new

# {{{ query

# {{{ POD

=head2 query(I<$query_name>, [ \%args, ] I<$session>, I<$state>, [ I<@parameters> ])

The C<query()> method takes at least three parameters, plus any bind
values for the specific query you are executing.

=over

=item $query_name

This parameter must be one of the keys to the Queries hashref you
passed to the constructor.  It is used to indicate which query you
wish to execute.

=item \%args

This is an OPTIONAL hashref of arguments to pass to the query.

Currently supported arguments:

=over 4

=item hash

Return rows hash references instead of array references.

=item cookie

A cookie to pass to this query.  This is passed back unchanged to the
destination state in C<$_[ARG1]>.  Can be any scalar (including
references, and even POE postbacks, so be careful!).  You can use this
as an identifier if you have one destination state handling multiple
different queries or sessions.

=item delay

Insert a 1ms delay between each row of output.

I know what you're thinking: "WHY would you want to slow down query
responses?!?!?"  It has to do with CONCURRENCY.  When a response
(finally) comes in from the agent after running the query, it floods
the input channel with response data.  This has the effect of
monopolizing POE's attention, so that any other handles (network
sockets, pipes, file descriptors) keep getting pushed further back on
the queue, and to all other processes EXCEPT the agent, your POE
program looks hung for the amount of time it takes to process all of
the incoming query data.

So, we insert 1ms of time via Time::HiRes's C<usleep> function.  In
human terms, this is essentially negligible.  But it is just enough
time to allow competing handles (sockets, files) to trigger
C<select()>, and get handled by the POE::Kernel, in situations where
concurrency has priority over transfer rate.

Naturally, the Time::HiRes module is required for this functionality.
If Time::HiRes is not installed, the delay is ignored.

=item group

Sends the return event back when C<group> rows are retrieved from the
database, to avoid event spam when selecting lots of rows. NB: using
group means that C<$row> will be an arrayref of rows, not just a single
row.

=back

=item $session, $state

These parameters indicate the POE state that is to receive the data
returned from the database.  The state indicated will receive the data
in its C<$_[ARG0]> parameter.  I<PLEASE> make sure this is a valid
state, otherwise you will spend a LOT of time banging your head
against the wall wondering where your query data is.

=item @parameters

These are any parameters your query requires.  B<WARNING:> You must
supply exactly as many parameters as your query has placeholders!
This means that if your query has NO placeholders, then you should
pass NO extra parameters to C<query>.

Suggestions to improve this syntax are welcome.

=back

=cut

# }}} POD

sub query {
    my ($self, $query, $package, $state, @rest) = @_;
    my $options = {};

    if (ref $package) {
	unless (ref $package eq 'HASH') {
	    carp "Options has must be a HASH reference";
	}
	$options = $package;

	# this shifts the first element off of @rest and puts it into
	# $state
	($package, $state) = ($state, shift @rest);
    }

    # warn "QD: Running $query";

    my $agent = $self->{helper}->next;
    my $input = { query => $query,
		  package => $package, state => $state,
		  params => \@rest,
		  delay => 0,
		  id => "_",
		  %$options,
		};

    $self->{pending_query_count}++;
    if ($self->{active_query_count} < $self->{count} ) {

	$input->{id} = $agent->ID;
	$self->{cookies}[$input->{id}] = delete $input->{cookie};
	$agent->put( $input );
	$self->{active_query_count}++;
	$self->{group_cache}[$input->{id}] = [];

    } else {
	push @{$self->{pending_queries}}, $input;
    }

    $self->debug
      && warn sprintf("QA:(#%s) %d pending: %s => %s, return %d rows at once\n",
		      $input->{id}, $self->{pending_query_count},
		      $input->{query},
		      "$input->{package}::$input->{state}",
		      $input->{group} || 1,
		     );

}

# }}} query

#========================================================================================
# {{{ shutdown

=head2 finish()

The C<finish()> method tells DBIAgent that the program is finished
sending queries.  DBIAgent will shut its helpers down gracefully after
they complete any pending queries.  If there are no pending queries,
the DBIAgent will shut down immediately.

=cut

sub finish {
    my $self = shift;

    $self->{finish} = 1;

    unless ($self->{pending_query_count}) {
      $self->debug and carp "QA: finish() called without pending queries. Shutting down now.";
      $self->{helper}->exit_all();
    }
    else {
      $self->debug && carp "QA: Setting finish flag for later.\n";
    }
}

# }}} shutdown

#========================================================================================

# {{{ STATES

# {{{ _start

sub _start {
    my ($self, $kernel, $heap, $dsn, $queries) = @_[OBJECT, KERNEL, HEAP, ARG0, ARG1];

    $self->debug && warn __PACKAGE__ . " received _start.\n";

    # make this session accessible to the others.
    #$kernel->alias_set( 'qa' );

    my $queue = POE::Component::DBIAgent::Queue->new();
    $self->{filter} = POE::Filter::Reference->new();

    ## Input and output from the children will be line oriented
    foreach (1..$self->{count}) {
	my $helper = POE::Wheel::Run->new(
					  Program     => sub {
					      POE::Component::DBIAgent::Helper->run($self->{dsn}, $self->{queries});
					  },
					  StdoutEvent => 'db_reply',
					  StderrEvent => 'remote_stderr',
					  ErrorEvent  => 'error',
					  #StdinFilter => POE::Filter::Line->new(),
					  StdinFilter => POE::Filter::Reference->new(),
					  StdoutFilter => POE::Filter::Reference->new(),
					 )
	  or warn "Can't create new Wheel::Run: $!\n";
	$self->debug && warn __PACKAGE__, " Started db helper pid ", $helper->PID, " wheel ", $helper->ID, "\n";
	$queue->add($helper);
    }

    $self->{helper} = $queue;

}

# }}} _start
# {{{ _stop

sub _stop {
    my ($self, $heap) = @_[OBJECT, HEAP];

    $self->{helper}->kill_all();

    # Oracle clients don't like to TERMinate sometimes.
    $self->{helper}->kill_all(9);
    $self->debug && warn __PACKAGE__ . " has stopped.\n";

}

# }}} _stop

# {{{ db_reply

sub db_reply {
    my ($kernel, $self, $heap, $input) = @_[KERNEL, OBJECT, HEAP, ARG0];

    # Parse the "receiving state" and dispatch the input line to that state.

    # not needed for Filter::Reference
    my ($package, $state, $data, $cookie, $group);
    $package = $input->{package};
    $state = $input->{state};
    $data = $input->{data};
    $group = $input->{group} || 0;
    # change so cookies are no longer sent over the reference channel
    $cookie = $self->{cookies}[$input->{id}];

    unless (ref $data or $data eq 'EOF') {
	warn "QA: Got $data\n";
    }
    # $self->debug && $self->debug && warn "QA: received db_reply for $package => $state\n";

    unless (defined $data) {
	$self->debug && warn "QA: Empty input value.\n";
	return;
    }

    if ($data eq 'EOF') {
	# $self->debug && warn "QA: ${package}::${state} (#$input->{id}): EOF\n";
        $self->{pending_query_count}--;
	$self->{active_query_count}--;

	$self->debug
	  && warn sprintf("QA:(#%s) %d pending: EOF => %s\n",
			  $input->{id}, $self->{pending_query_count},
			 "$input->{package}::$input->{state}");

        # If this was the last query to go, and we've been requested
        # to finish, then turn out the lights.
        unless ($self->{pending_query_count}) {
          if ($self->{finish}) {
            $self->debug and warn "QA: Last query done, and finish flag set.  Shutting down.\n";
            $self->{helper}->exit_all();
          }
        }
        elsif ($self->debug and $self->{pending_query_count} < 0) {
          die "QA: Pending query count went negative (should never do that)";
        }

	# place this agent at the front of the queue, for next query
	$self->{helper}->make_next($input->{id});

	if ( $self->{pending_queries} and
	     @{$self->{pending_queries}} and
	     $self->{active_query_count} < $self->{count}
	   ) {

	    my $input = shift @{$self->{pending_queries}};
	    my $agent = $self->{helper}->next;

	    $input->{id} = $agent->ID;
	    $self->{cookies}[$input->{id}] = delete $input->{cookie};
	    $agent->put( $input );
	    $self->{active_query_count}++;

	    $self->debug &&
	      warn sprintf("QA:(#%s) %d pending: %s => %s\n",
			 $input->{id}, $self->{pending_query_count},
			   $input->{query},
			   "$input->{package}::$input->{state}"
			  );

	}
    }
    if ($group) {
        push @{ $self->{group_cache}[$input->{id}] }, $data;
	if (scalar @{ $self->{group_cache}[$input->{id}] } == $group || $data eq 'EOF') {
	    $kernel->post($package => $state => $self->{group_cache}[$input->{id}], $cookie);
	    $self->{group_cache}[$input->{id}] = [];
	}
    } else {
        $kernel->post($package => $state => $data => $cookie);
    }


}

# }}} db_reply

# {{{ remote_stderr

sub remote_stderr {
    my ($self, $kernel, $operation, $errnum, $errstr, $wheel_id, $data) = @_[OBJECT, KERNEL, ARG0..ARG4];

    $self->debug && warn defined $errstr ? "$operation: $errstr\n" : "$operation\n";

    $kernel->post(@{$self->{errorstate}}, $operation, $errstr, $wheel_id) if defined $self->{errorstate};
}

# }}} remote_stderr
# {{{ error

sub error {
    my ($self, $operation, $errnum, $errstr, $wheel_id) = @_[OBJECT, ARG0..ARG3];

    $errstr = "child process closed connection" unless $errnum;
    $self->debug and warn "error: Wheel $wheel_id generated $operation error $errnum: $errstr\n";

    $self->{helper}->remove_by_wheelid($wheel_id);
}

# }}} error

# }}} STATES

1;

__END__

=head1 NOTES

=over

=item *

Error handling is practically non-existent.

=item *

The calling syntax is still pretty weak... but improving.  We may
eventually add an optional attributes hash so that each query can be
called with its own individual characteristics.

=item *

I might eventually want to support returning hashrefs, if there is any
demand.

=item *

Every query is prepared at Helper startup.  This could potentially be
pretty expensive.  Perhaps a cached or deferred loading might be
better?  This is considering that not every helper is going to run
every query, especially if you have a lot of miscellaneous queries.

=back

Suggestions welcome!  Diffs I<more> welcome! :-)

=head1 AUTHOR

This module has been fine-tuned and packaged by Rob Bloodgood
E<lt>robb@empire2.comE<gt>.  However, most of the queuing code
originated with Fletch E<lt>fletch@phydeaux.orgE<gt>, either directly
or via his ideas.  Thank you for making this module a reality, Fletch!

However, I own all of the bugs.

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=cut
