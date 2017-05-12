package POE::Component::Pool::DBI;
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------
# A rather simple pooled database resource.

use strict;
use warnings FATAL => "all";

use POE qw( Component::Pool::Thread );
use DBI;
use threads::shared;
use constant {
    DEBUG               => 0,
    REFCOUNT_IDENTIFIER => "queries",
};

our $VERSION = 0.014;

sub new {
    my ($class, %args) = @_;

    my $self = bless \%args, $class;

    # For tracking the job id.
    $self->{current_id} = 0;

    print "Connections: $args{connections}";

    # This creates the threadpool which does the actual work.  The entry point
    # for the actual threads themselves is the query_database function.
    $self->{session} = POE::Component::Pool::Thread->new
        ( MaxFree       => $args{connections},
          StartThreads  => $args{connections},
          MaxThreads    => $args{connections},
          EntryPoint    => \&query_database,
          CallBack      => \&send_response,
          inline_states => {
            query   => sub {
                my ($kernel, $heap, $sender, $callback, $ud, $query, $args) =
                    @_[ KERNEL, HEAP, SENDER, ARG0 .. $#_ ];

                my $id = $self->{current_id}++;

                $args ||= [];
                $heap->{data}{$id} = $ud;

                DEBUG && print "got query, calling run state";

                $kernel->yield(run => "query", @$self{qw( dsn username
                password)}, $id, $sender->ID, $callback, $query, @$args);
            },

            do      => sub {
                my ($kernel, $heap, $sender, $callback, $ud, $query, $args) =
                    @_[ KERNEL, HEAP, SENDER, ARG0 .. $#_ ];

                my $id = $self->{current_id}++;

                $args ||= [];
                $heap->{data}{$id} = $ud;

                $kernel->yield(run => "do", @$self{qw( dsn username password)},
                $id, $sender->ID, $callback, $query, @$args);
            },
          }
        );

    return $self;
}

# You can call this method...It's just for convenience.
sub query {
    my ($self, %args) = @_;

    DEBUG && print "->query(): dispatching event: \"query\"";

    # We post from here so we can enter the session context of the component.
    $poe_kernel->post($self->{session}->ID, query => @args{qw( callback
                userdata query params)});

    # Keep the calling session alive until this finished.
    # XXX Possible room for optimization.
    $poe_kernel->refcount_increment( 
        $poe_kernel->get_active_session->ID, REFCOUNT_IDENTIFIER
        );
}

# Do will run a query without fetching records, use this for inserts.
sub do {
    my ($self, %args) = @_;

    DEBUG && print "->do(): dispatching event: \"do\"";

    $poe_kernel->post($self->{session}->ID, do => @args{qw( callback userdata
                query params)});

    # XXX Possible room for optimization.
    $poe_kernel->refcount_increment( 
        $poe_kernel->get_active_session->ID, REFCOUNT_IDENTIFIER
        );
}

sub shutdown {
    my ($self) = @_;

    # Simply piggyback off of PoCo:P:T
    $poe_kernel->post($self->{session}->ID, "shutdown");
}

# This thread entry point (the job of our thread pool) simply creates a
# connection if it doesn't already have one that's good, and then it runs the
# query supplied.  It will 
sub query_database {
    DEBUG && warn "thread entry point";

    # I pass the DSN info in every time, because otherwise it won't be
    # available in the entry point.   This method has not access to the parent
    # object.  (perl threads are strange that way).
    my ($action, $dsn, $user, $pass, $id, $caller, $cb, $query, @args) = @_;

    my @response = eval {
        DEBUG && warn "testing & creating database connection";
    
        # "our" is a shared variable, but it's only shared within each thread
        # (assuming that crunch_data is never called outside a thread).  This
        # statement will call DBI->connect if, and only if, the $dbh is not defined
        # and you cannot call $dbh->ping if it is defined.
        #
        # I do this rather than connect_cached, just incase any initialized
        # connections were made before the ithread was created.  This mechanism
        # provides a bit more safety in terms of ensuring that we get a unique
        # connection per thread.
        our $dbh = DBI->connect($dsn, $user, $pass)
            unless defined $dbh && $dbh->ping;
    
        DEBUG && warn "preparing query";
        # prepare_cached should be safe, since we should have a unique connection
        # per our previous statement, and my tests showed this optimizes querying
        # by up to 8x over creating a new prepared statement each time.
        my $sth = $dbh->prepare_cached($query);
    
        DEBUG && warn "executing query";
        $sth->execute(@args);
    
        if ($action eq "do") {
            $sth->finish;
            return $id, $caller, $cb;
        }
        elsif ($action eq "query") {
            DEBUG && warn "fetching results";
            my $results = $sth->fetchall_arrayref({});
            my @response;
    
            for my $record (@$results) {
                # Create a shared hashref.
                my $r = &share({});
    
                # Copy all values into the hashref.
                @$r{keys %$record} = values %$record;
    
                # Put the shared hashref into the response
                push @response, $r;
            }
    
            DEBUG && warn "returnning to caller";
    
            $sth->finish;
    
            # This is automatically placed in a shared array, as per
            # PoCo::Thread::Pool
            return @response;
        }
    };
    if ($@) {
        warn "An unexpected error was trapped while trying to run a query: $@";
        warn "The query was: $query";
    }

    return $id, $caller, $cb, @response;
}

# This component will send a message to the caller session, with the data
# returned from the query as it's argument.
sub send_response {
    my ($kernel, $heap, $id, $caller, $callback, @results) = 
        @_[ KERNEL, HEAP, ARG0 .. $#_ ];

    # Pass the results along as ARG0, and any user data as ARG0.  delete
    # removes it from the heap at the same time so we don't leap memory.
    my $userdata = delete $heap->{data}{$id};

    if (defined $callback) {
        if (DEBUG) {
            use Data::Dumper;

            print "dispatching response ($caller, $callback)",
                  Dumper(\@results);
        }

        $kernel->post($caller, $callback, \@results, $userdata);
    }

    # The pending state->post (if applicable) will keep the calling session
    # alive, so we can release our reference here.
    $kernel->refcount_decrement($caller, REFCOUNT_IDENTIFIER);
}

# All perl modules must return a true value.
1;

=head1 NAME

POE::Component::Pool::DBI - Simplified DBI access through a pooled resource.

=head1 SYNOPSIS

use POE qw( Component::Pool::DBI );

 POE::Session->create(
     inline_states => {
         _start => sub {
             my ($kernel, $heap) = @_[ KERNEL, HEAP ];
 
             my $dbpool = POE::Component::Pool::DBI->new(
                 connections     => 10,
                 dsn             => "DBI:mysql:database=test",
                 username        => "username",
                 password        => "password"
             );
 
             # Outstanding queries keep the calling session alive.
             $dbpool->query(
                 callback => "handle_result",
                 query    => "select foo from bar where foo = ?",
                 params   => [ "foo" ],
                 userdata => "example"
             );

             $heap->{dbpool} = $dbpool;
         },
 
         handle_result => sub {
             my ($kernel, $heap, $results, $userdata) = 
                 @_[ KERNEL, HEAP, ARG0, ARG1 ];
 
             # Will be an arrayref of hashrefs.
             for my $record (@$results) {
                 print $record->{foo};
             }
 
             my $dbpool = $heap->{dbpool};
 
             # Queries which do not return data should use the do method.
             # If no callback is supplied, no callback happens.  This is
             # suitable for queries where the result is not necessarily
             # important.
             $dbpool->do(
                 query => "INSERT INTO results (query, count) VALUES (?,?)",
                 args  => [ $udata, @$results ],
             );
 
             # Ask for a clean shutdown.
             $dbpool->shutdown;
         },
     },
 );
 
 POE::Kernel->run();

=head1 DESCRIPTION

This component provides a threadpool-backed DBI connection pool.  It's fairly
well optimized for high throughput (particularly insert) servers which rely on
a relational database.  It enables pooled connectivity by being implemented
upon a limited-availability thread pool, with each thread maintaining a
connection.  It uses an asyncronous queue for allowing excess queries to 'stack
up', in order to enable availability.


=head1 RATIONALE

Why yet *another* DBI interface for POE?  There are already about 6.  But in
looking for a solution for a high availability UDP server I was unable to find
one which managed pooling effectively, and I always thought this would be a
reasonable application of the partner component, POE::Component::Pool::Thread.

=head1 CONSTRUCTORS

=over 4

=item new LOTS_OF_THINGS

=over 4

=item connections

The size, in number of threads and connections, of the resource pool.

=item dsn

The database service name, as per the DBI->connect method.

=item username

The username on the database (L<DBI>->connect).

=item password

The password on the database (L<DBI>->connect).

=back

=back

=head1 METHODS

=over 4

=item query ARGUMENTS

The query method enqueues a query to be run by the job pool.  The preparation
of the query will be cached, so it's suggested you use placeholders to ensure
the fastest response times and to avoid leaking statements.

=over 4

=item query

The query argument holds the SQL or PL/SQL statement to execute.  The statement
will be invoked immediately, but it will be cached within the connection
(see L<DBI> prepare_cached).

=item params

The arguments to provide to DBI's execute method (see L<DBI>).

=item callback

The state to invoke wihen the operation is complete. The state will be provided
with the results of the query (if applicable), as an array of hashref
(faciliated by DBI's fetchall_arrayref({})) assuming your driver supports this
functionality (most do).

=item userdata

Assuming a callback has been provided, this data will be provided to the
callback.  This data is cached within the controlling session, and is not
"available" from inside the job threads.  It needs not be shared in any way.

=back

=item do ARGUMENTS

The do operation will invoke a query, but forgo attempting to fetch any results
from the query.  This method should be used for statements which do not return
result sets, such as INSERT or UPDATE statements on most databases.  This
operation accepts the same arguments as the query method, which are documented
above.

=item shutdown

The shutdown operation piggybacks off of POE::Component::Pool::Thread (the
PoCo:P:T session is used as the management session for this component).  It
simply asks all the threads to shut down.

=back

=head1 BUGS

=over

=item *

This component intentionally doesn't allow fine graned control over prepared
statement objects. 

=item *

Some types of data sharing in ithreads have been known to leak, 

=item *

My tests have shown this component, as well as POE::Component::Pool::Thread,
does not work with the forks pragma.

=item *

This module doesn't particularly support transactional operations.

=back

=head1 AUTHOR

Scott S. McCoy (tag@cpan.org)
