package POE::Component::DBIAgent::Helper;

use DBI;
#use Daemon; # qw//;
use Data::Dumper;
use POE::Filter::Reference;

BEGIN {
    my $can_delay = 0;
    eval { require Time::HiRes; };
    unless ($@) {
	Time::HiRes->import(qw/usleep/);
	$can_delay = 1;
    }
    sub CAN_DELAY { $can_delay }

}
use strict;

use vars qw/$VERSION/;
$VERSION = sprintf("%d.%02d", q$Revision: 0.03 $ =~ /(\d+)\.(\d+)/);

use constant DEBUG => 0;
use constant DEBUG_NOUPDATE => 0;

my $filter = POE::Filter::Reference->new();

sub run {

    DEBUG && warn "  QA: start\n";
    DEBUG_NOUPDATE && warn "  QA: NO UPDATE\n";

    my ($type, $dsn, $queries) = @_;

    my $self = bless {}, $type;
    $self->_init_dbi($dsn, $queries);

    $| = 1;

    $self->{dbh}->{RaiseError} = 0;
    $self->{dbh}->{PrintError} = 0;

    DEBUG && warn "  QA: initialized\n";

    my ($row, $output);		# to hold DBI results
    while ( sysread( STDIN, my $buffer = '', 1024 ) ) {
	my $lines = $filter->get( [ $buffer ] );

	#++ look for the exit sign in the current set of commands
	my $exit = grep /^EXIT$/, map $_->{query}, @$lines;
	### DEBUG && warn "Exit? - ", $exit, "\n";

	foreach my $task (@$lines) {
	    ### DEBUG && warn "  QA: Got line: ", Dumper($task), "\n";

	    #++ this doesn't match what DBIAgent::Queue sends in exit_all();
	    # last if /^EXIT$/;	# allow parent to tell us to exit

	    # Set up query
	    my ($query_id);
	    $query_id = $task->{query};
	    my $rowtype = $task->{hash} ? 'fetchrow_hashref' : 'fetchrow_arrayref';

	    if ($query_id eq 'CREATE' or $query_id eq 'EXIT') {
		#++  make sure the EXIT event isn't actually sent to the db
		next;
	    }

	    ### DEBUG && warn "  QA: Read data: $query_id for $task->{state} (params @{$task->{params}})\n";

	    unless (exists $self->{$query_id}) {
		DEBUG && warn "  QA: No such query: $query_id";
		next;
	    }
	    DEBUG && warn "  QA: query $query_id exists\n";

	    my $rowcount = 0;

	    my $result = { package => $task->{package}, state => $task->{state},
			   data => undef,
			   query => $query_id,
			   id => $task->{id},
			   cookie => $task->{cookie} || undef, # XXX remove?
			   group => $task->{group},
			 };

	    if (ref $self->{$query_id}) { # Is it a DBI statement handle?

		# Normal query loop.  This is where we usually go.
		unless ( $self->{$query_id}->execute( @{$task->{params}} ) ) {
		    DEBUG && warn "  QA: error executing query: ", $self->{$query_id}->errstr,"\n";

		    # this goes to stderr.  If an ErrorState was
		    # supplied, the user will see this message.
		    warn "QA: error executing query: ", $self->{$query_id}->errstr,"\n";

		    $result->{data} = 'EOF';
		    $output = $filter->put( [ $result ] );
		    print @$output;

		    #print "ERROR|", $self->{$query_id}->errstr, "\n";
		} else {
		    DEBUG && warn "  QA: query running\n";

		    if ($self->{$query_id}{Active}) {
			while (defined ($row = $self->{$query_id}->$rowtype())) {

			    $rowcount++;

			    $result->{data} = $row;
			    $output = $filter->put( [ $result ] );

			    # This prevents monopolizing the parent with
			    # db responses.
			    CAN_DELAY and $task->{delay} and usleep(1);

			    print @$output;
			    #warn "  QA: got row $rowcount: ",,"\n";

			}
		    }

		    $result->{data} = 'EOF';
		    $output = $filter->put( [ $result ] );
		    print @$output;
		    DEBUG && warn "  QA: ROWS|$rowcount\n";

		}

	    } else {		# *NOT* a DBI statement handle

		# $queries->{$query_id} is a STRING query.  This is a
		# debug feature.  Print a debug message, and send back
		# EOF, but don't actually touch the database.
		my $query = $queries->{$query_id};

		my @params = @{$task->{params}};
		# Replace ? placeholders with bind values.
		$query =~ s/\?/@params/eg;

		DEBUG && warn "  QA: $query\n";

		$result->{data} = 'EOF';
		$output = $filter->put( [ $result ] );
		print @$output;

	    }
	}
	#++ put here to make sure all the queries in the current buffer are dealt with before disconnecting 
	last if $exit;
    }

    DEBUG && warn "  QA: Disconnect and Exit\n";
    $self->{dbh}->disconnect;

}

# {{{ _init_dbi

sub _init_dbi {
    my ($heap, $dsn, $queries) = @_;

    my $dbh = DBI->connect(@$dsn, { AutoCommit => 1, RaiseError => 0, PrintError => 0 }) or die DBI->errstr;
    $heap->{dbh} = $dbh;

    #$dbh->{RowCacheSize} = 500;

    if (defined $queries) {
	foreach (keys %$queries) {
	    if ($queries->{$_} =~ /insert|update|delete/i and DEBUG_NOUPDATE) {
		$heap->{$_} = $queries->{$_};
	    } else {
		$heap->{$_} = $dbh->prepare($queries->{$_}) or die $dbh->errstr;
	    }
	}

	return;
    }

}

# }}} _init_dbi

1;

__END__

=head1 NAME

POE::Component::DBIAgent::Helper - DBI Query Helper for DBIAgent

=head1 SYNOPSYS

 use Socket qw/:crlf/;
 use POE qw/Filter::Line Wheel::Run Component::DBIAgent::Helper/;

 sub _start {
     my $helper = POE::Wheel::Run ->new(
	     Program     => sub {
		 POE::Component::DBIAgent::Helper->run($self->{dsn},
						       $self->{queries}
						      );
	     },
	     StdoutEvent => 'db_reply',
	     StderrEvent => 'remote_stderr',
	     ErrorEvent  => 'error',
	     StdinFilter => POE::Filter::Line->new(),
	     StdoutFilter => POE::Filter::Line->new( Literal => CRLF),
	     StderrFilter => POE::Filter::Line->new(),
	    )
      or carp "Can't create new DBIAgent::Helper: $!\n";

 }

 sub query {
      my ($self, $query, $package, $state, @rest) = @_;

      $self->{helper}->put(join '|', $query, $package, $state, @rest);
 }

 sub db_reply {
    my ($kernel, $self, $heap, $input) = @_[KERNEL, OBJECT, HEAP, ARG0];

    # $input is either the string 'EOF' or a Storable object.

 }

=head1 DESCRIPTION

This is our helper routine for DBIAgent.  It accepts queries on STDIN,
and returns the results on STDOUT.  Queries are returned on a
row-by-row basis, followed by a row consisting of the string 'EOF'.

Each row is the return value of $sth->fetch, which is an arrayref.
This row is then passed to Storable for transport, and printed to
STDOUT.  HOWEVER, Storable uses newlines ("\n") in its serialized
strings, so the Helper is designed to use the "network newline" pair
CR LF as the line terminator for STDOUT.

When fetch() returns undef, one final row is returned to the calling
state: the string 'EOF'.  Sessions should test for this value FIRST
when being invoked with input from a query.

=head2 Initialization

The Helper has one public subroutine, called C<run()>, and is invoked
with two parameters:

=over

=item The DSN

An arrayref of parameters to pass to DBI->connect (usually a dsn,
username, and password).

=item The Queries.

A hashref of the form Query_Name => "$SQL".  See
L<POE::Component::DBIAgent> for details.

=back

=head1 BUGS

I have NO idea what to do about handling signals intelligently.
Specifically, under some circumstances, Oracle will refuse to
acknowledge SIGTERM (presumably since its libraries are non-reentrant)
so sometimes SIGKILL is required to terminate a Helper process.

=head1 AUTHOR

This module has been fine-tuned and packaged by Rob Bloodgood
E<lt>robb@empire2.comE<gt>.  However, most of the code came directly
from Fletch E<lt>fletch@phydeaux.orgE<gt>, either directly
(Po:Co:DBIAgent:Queue) or via his ideas.  Thank you, Fletch!

However, I own all of the bugs.

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=cut

