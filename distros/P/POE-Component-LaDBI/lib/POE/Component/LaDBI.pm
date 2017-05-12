package POE::Component::LaDBI;

use 5.006_000;
use strict;
use warnings;

use IO::Handle;
use IO::File;
use Data::Dumper;

BEGIN {
  our $VERSION = '1.2.1';
}

use POE qw(
	   Wheel::Run
	   Filter::Reference
	   Filter::Stream
	  );

use POE::Component::LaDBI::Commands; # imports @COMMANDS
use POE::Component::LaDBI::Engine;
use POE::Component::LaDBI::Request;
use POE::Component::LaDBI::Response;



BEGIN {
  sub DEBUG_ON  () { 1 }
  sub DEBUG_OFF () { 0 }
  *DEBUG = $ENV{LADBI_DEBUG} ? \&DEBUG_ON : \&DEBUG_OFF;
}

sub import {
  if (grep { $_ eq ':DEBUG' } @_) {
    *DEBUG = \&DEBUG_ON;
  }
}

our $DEBUG_FILE = 'ladbi_run.log';

# Preloaded methods go here.

sub create {
  my $pkg = shift;
  my (%args) = @_;

  my $alias = 'ladbi';
  $alias = $args{Alias} if exists $args{Alias};

  my $s = POE::Session->create
    ( inline_states     =>
      { _start          => \&start_session      ,
	_stop           => \&stop_session       ,
	shutdown        => \&shutdown           ,
#	termsig         => \&termsig            ,
	register        => \&register           ,
	run_error       => \&run_error          ,
	run_stdout      => \&run_stdout         ,
	run_stderr      => \&run_stderr         ,
	map { lc($_) => \&dbi_request_handler } @COMMANDS,
      },
      args => [$alias]
    )
      or return;

  return $s;
} #end: create()



sub start_session {
  my ($k,$s,$h) = @_[KERNEL, SESSION, HEAP];
  my ($alias) = $_[ARG0];

  $k->alias_set($alias);
  $h->{alias} = $alias;

  # Register specific signal handlers
#  $k->sig($_ => 'termsig') for qw(HUP INT KILL QUIT TERM IDLE);


  my $wheel = POE::Wheel::Run->new
    (
     Program     => \&run       ,
     ErrorEvent  => 'run_error' ,
     StdoutEvent => 'run_stdout',
     StderrEvent => 'run_stderr',
     StdinFilter  => POE::Filter::Reference->new(),
     StdoutFilter => POE::Filter::Reference->new(),
     StderrFilter => POE::Filter::Stream->new(),
    )
      or return;

  $h->{wheel} = $wheel;

  $h->{req_ids} = {};

  $h->{registered_sessions} = {};

  return 1;
} #end: start_session()



sub stop_session {
  my ($k,$s,$h) = @_[KERNEL, SESSION, HEAP];

  delete $h->{req_ids};

  return 1;
} #end: stop_session()



sub shutdown {
  my ($k,$s,$h) = @_[KERNEL, SESSION, HEAP];
  my ($cause, $errstr) = @_[ARG0,ARG1];

  unless (defined $h->{alias}) {
    # shutdown already called
    return;
  }

  my $alias = delete $h->{alias};
  $k->alias_remove( $alias );

  for my $sid ( keys %{ $h->{registered_sessions} } ) {
    my $reg_info = $h->{registered_sessions}->{$sid};
    my $offline_event = $reg_info->[0];
    $k->post($sid => $offline_event, $cause, $errstr, $alias);
  }

  my $run_wheel = delete $h->{wheel};
  if (defined $run_wheel) {
    $run_wheel->kill(-9);
  }

  for my $req_id ( keys %{ $h->{req_ids} } ) {

    my ($session, $succ_ev, $fail_ev, $handle_id, $userdata) =
      @{ $h->{req_ids}->{ $req_id } };

    $k->post($session => $fail_ev,
	     $handle_id, 'SHUTDOWN', $cause, $errstr, $userdata);

  }

  return 1;
} #end: shutdown()


sub register {
  my ($k,$s,$h) = @_[KERNEL,SESSION,HEAP];
  my (%a) = @_[ARG0..$#_];

  my %args = map { lc($_) => $a{$_} } keys %a;

  return unless defined $args{offlineevent};
  my $offline_event = $args{offlineevent};

  my $sid = $_[SENDER]->ID;

  $h->{registered_sessions}->{$sid} = [ $offline_event ];

  return;
} #end: register()


# sub termsig {
#   my ($k,$s) = @_[KERNEL,SESSION];
#   my ($sig) = $_[ARG0];
# 
#   $k->call($s, 'shutdown', 'signal', $sig);
# 
#   return 1;
# } #end: termsig()



sub run_error {
  my ($k,$s,$h) = @_[KERNEL,SESSION,HEAP];
  my ($sysret, $errno, $errstr, $wheel_id, $handle) = @_[ARG0..ARG4];

  $k->yield('shutdown', 'run_error', $errstr);

  return 1;
} #end: run_error()



sub run_stdout {
  my ($k,$s,$h) = @_[KERNEL,SESSION,HEAP];
  my ($resp, $wheel_id) = @_[ARG0,ARG1];

  my ($sender, $succ_ev, $fail_ev, $handle_id, $userdata) =
    @{ delete $h->{req_ids}->{ $resp->id } };

  my ($ev, $id, $type, @data);
  $id   = $resp->handle_id;
  $type = $resp->datatype;

  if     ($resp->code eq 'OK')
    {
      # On Success:
      #   @data will have one element
      #
      $ev   = $succ_ev;
      @data = ($resp->data);
    }
  elsif ($resp->code eq 'FAILED')
    {
      # On Failure:
      #   @data will have two elements
      #
      $ev   = $fail_ev;
      my $err = $resp->data;

      if ($resp->datatype eq 'ERROR') {
	@data = ($err->{errstr}, $err->{errnum});
      }
      elsif ($resp->datatype eq 'EXCEPTION') {
        @data = ($err, undef);
      }
      else {
	$type = 'UNKNOWN ERROR TYPE';
	@data = (undef, undef);
      }
    }
  elsif ($resp->code eq 'INVALID_HANDLE_ID')
    {
      # On Operational Error:
      #   @data will have two elements
      #
      $type = 'INVALID_HANDLE_ID';
      @data = ('', undef);
    }
  else {
    $ev = $fail_ev;
    $type = 'UNKNOWN RESPONSE CODE';
  }

  $k->post($sender, $ev, $id, $type, @data, $userdata);

  $k->refcount_decrement($sender->ID, 'ladbi');

  return 1;
} #end: run_stdout()



sub run_stderr {
  my ($k,$s,$h) = @_[KERNEL,SESSION,HEAP];
  my ($input, $wheel_id) = @_[ARG0,ARG1];

  DEBUG && print STDERR map { (__PACKAGE__, " > " , $_ , "\n") }
                        split("\n", $input);


  return 1;
} #end: run_stderr()



sub dbi_request_handler {
  my ($k,$s,$h) = @_[KERNEL,SESSION,HEAP];
  my ($state, $sender) = @_[STATE,SENDER];
  my (%a) = @_[ARG0..$#_];

  my (%args) = map { lc($_), $a{$_} } keys %a;

  my $handle_id = $args{handleid};
  my $succ_ev   = $args{successevent};
  my $fail_ev   = $args{failureevent};
  my $userdata  = $args{userdata};
  my $args      = $args{args};

  my $req = POE::Component::LaDBI::Request->new
    (
     Cmd      => $state     ,
     Data     => $args      ,
     HandleId => $handle_id
    )
      or do {
	# Operational Error
	#
	$k->post($sender, $fail_ev,
		 $handle_id       ,  # $_[ARG0] : handle_id
		 'INVALID_REQUEST',  # $_[ARG1] : errtype
		 '',                 # $_[ARG2] : errstr
		 undef,              # $_[ARG3] : err
		 $userdata           # $_[ARG4] : userdata
		);
	return;
      };

  $k->refcount_increment($sender->ID, 'ladbi');

  $h->{req_ids}->{ $req->id } = [ $sender    ,
				  $succ_ev   ,
				  $fail_ev   ,
				  $handle_id ,
				  $userdata   ];

  $h->{wheel}->put( $req );

  return 1;
} #end: request_handler()



sub run {
  my $ret = 1;
  my $READ_SIZE = 1024;

  my ($debug_fh);
  if (DEBUG) {
    $debug_fh = IO::File->new($DEBUG_FILE, 'a')
      or die("Failed to open DEBUG_FILE=$DEBUG_FILE\n");
    $debug_fh->autoflush(1);
  }

  my $engine = POE::Component::LaDBI::Engine->new();
  my $filter = POE::Filter::Reference->new();

  local $/ = undef;

  my $stdin = \*STDIN;
  my $stdout = \*STDOUT;
  my $stderr = \*STDERR;

  my $rin = '';
  vec($rin, $stdin->fileno, 1) = 1;

 REQUEST_LOOP:
  while (1) {
    my $input = '';
    my ($reqs);
  READ_LOOP:
    while (1) {
      my ($rout);

      my $nfound = select($rout=$rin, undef, undef, 1);
      unless ($nfound) {
	DEBUG && $debug_fh->print((caller(0))[3], " timeout\n");

	next READ_LOOP;
      }

      unless ($rout) {
	DEBUG && $debug_fh->print((caller(0))[3], " WTF!; \$nfound > 0 && \$rout == 0\n");


	next READ_LOOP;
      }

      my $buf = '';
      my $nread = 0;

      $nread = $stdin->sysread($buf, $READ_SIZE);
      if ($nread < 1) {
	DEBUG && $debug_fh->print((caller(0))[3], " NORMAL EXIT; \$nread <= 0 && \$rout == 0\n");

	last REQUEST_LOOP;
      }

      $input .= $buf;

      if ($nread == $READ_SIZE) {
        DEBUG && $debug_fh->print((caller(0))[3], " $nread == $READ_SIZE\n");
        next READ_LOOP;
      }

      $reqs = $filter->get( [$input] );

      last READ_LOOP if @$reqs;
    } #end: while(1) READ_LOOP

    for my $req (@$reqs) {

      DEBUG && $debug_fh->print(join('', (caller(0))[3], "\nREQ=", Dumper($req)));


      my $resp = $engine->request($req);

      DEBUG && $debug_fh->print(join('', (caller(0))[3], "\nRESP=", Dumper($resp)));

      my $enc_resps = $filter->put( [$resp] );

      DEBUG && $debug_fh->print(join('', (caller(0))[3], "\nENC RESPS=", Dumper($enc_resps)));


      $stdout->syswrite($_, length($_)) for @$enc_resps;

    } #end: foreach request

  } #end: while(1) REQUEST_LOOP

  return 1;
} #end: run()


1;
__END__

=head1 NAME

POE::Component::LaDBI - POE Component that spawns a perl subprocess to
handle non-blocking access to the DBI API.

=head1 SYNOPSIS

 use POE::Component::LaDBI;

 POE::Component::LaDBI->create( Alias => "ladbi" );

 $k->call(ladbi => "register",
          OfflineEvent => 'db_offline');

 $k->post(ladbi => "connect",
          SuccessEvent => "connected",
          FailureEvent  => "connect_failed",
          Args => ["dbi:Pg:dbname=$dbname", $user, $passwd],
          UserData => $stuff );

 $k->post(ladbi => "disconnect",
          SuccessEvent => "disconnected",
          FailureEvent  => "disconnect_failed",
          HandleId => $dbh_id,
          UserData => $stuff);

 $k->post("ladbi" => "prepare",
          SuccessEvent => "prepared",
          FailureEvent => "prepare_failed",
          HandleId => $dbh_id,
          Args => [$sql], 
          UserData => $stuff);

 $k->post("ladbi" => "finish",
          SuccessEvent => "finished",
          FailureEvent => "finish_failed",
          HandleId => $sth_id,
          UserData => $stuff);

 $k->post("ladbi" => "execute",
          SuccessEvent => "executed",
          FailureEvent => "execute_failed",
          HandleId => $sth_id,
          Args => [$bind_val0, $bind_val1, ...],
          UserData => $stuff);

 $k->post("ladbi" => "rows",
          SuccessEvent => "rows_found",
          FailureEvent => "rows_failed",
          HandleId => $sth_id,
          UserData => $stuff);

 $k->post("ladbi" => "fetchrow",
          SuccessEvent => "row_fetched",
          FailureEvent => "fetch_failed",
          HandleId => $sth_id,
          UserData => $stuff);

 $k->post("ladbi" => "fetchrow_hash",
          SuccessEvent => "row_fetched",
          FailureEvent => "fetch_failed",
          HandleId => $sth_id,
          UserData => $stuff);

 $k->post("ladbi" => "fetchall",
          SuccessEvent => "all_fetched",
          FailureEvent => "fetchall_failed",
          HandleId => $sth_id,
          Args => [ @optional_indicies ],
          UserData => $stuff);

 $k->post("ladbi" => "fetchall_hash",
          SuccessEvent => "all_fetched",
          FailureEvent => "fetchall_failed",
          HandleId => $sth_id,
          Args => [ @optional_keys ],
          UserData => $stuff);

 $k->post("ladbi" => "ping",
         SuccessEvent => "check_ping_results",
         FailureEvent => "ping_failed",
         HandleId => $dbh_id,
         UserData => $stuff);

 $k->post("ladbi" => "do",
          SuccessEvent => "check_do_results",
          FailureEvent => "do_failed",
          HandleId => $dbh_id,
          Args => [ $sql, $attr_hashref, @bind_values ],
          UserData => $stuff);

 $k->post("ladbi" => "begin_work",
          SuccessEvent => "check_transactions_enabled",
          FailureEvent => "begin_work_failed",
          HandleId => $dbh_id,
          UserData => $stuff);

 $k->post("ladbi" => "commit",
          SuccessEvent => "check_commit",
          FailureEvent => "commit_failed",
          HandleId => $dbh_id,
          UserData => $stuff);

 $k->post("ladbi" => "rollback",
          SuccessEvent => "check_rollback",
          FailureEvent => "rollback_failed",
          HandleId => $dbh_id,
          UserData => $stuff);

 $k->post("ladbi" => "selectall",
          SuccessEvent => "check_results",
          FailureEvent => "selectall_failed",
          HandleId => $dbh_id,
          Args => [ $sql ],
          UserData => $stuff);

 $k->post("ladbi" => "selectall_hash",
          SuccessEvent => "check_results",
          FailureEvent => "selectall_failed",
          HandleId => $dbh_id,
          Args => [ $sql, $key_field ],
          UserData => $stuff);

 $k->post("ladbi" => "selectcol",
          SuccessEvent => "check_results",
          FailureEvent => "selectcol_failed",
          HandleId => $dbh_id,
          Args => [ $sql, $attr_hashref ],
          UserData => $stuff);

 $k->post("ladbi" => "selectrow",
          SuccessEvent => "check_results",
          FailureEvent => "selectrow_failed",
          HandleId => $dbh_id,
          Args => [ $sql, $attr_hashref ],
          UserData => $stuff);

 $k->post("ladbi" => "quote",
          SuccessEvent => "use_quote_results",
          FailureEvent => "quote_failed",
          HandleId => $dbh_id,
          Args => [ $value ],
          UserData => $stuff);



=head1 DESCRIPTION

=head2 LaDBI Session Events

=over 4

=item C<shutdown>

This tells the LaDBI session to shutdown. It takes two optional
arguments, C<$cause> and C<$errstr>. Both arguments get posted
back to all registered sessions and all outstanding requests.

For registered sessions the C<OfflineEvent> is called with
C<$cause> and C<$errstr> as ARG0 and ARG1.

For the outstanding requests C<FailureEvent> is called with
C<$cause> as ARG1 and C<$errstr> as ARG2.

=item C<register>

C<register> is a callable as well as postable event, which registers
your session with the LaDBI session. All the other events you can
post to a LaDBI session are request-response events. C<register>
allows you to get events posted back to your session when events
occur which effect the LaDBI session as a whole.

=over 4

=item C<OfflineEvent>

LaDBI can loose it's sub-process (which is actually doing the DBI calls).
In this case an C<OfflineEvent> will be posted to all the client
sessions which have registered with this LaDBI session.

The C<OfflineEvent> passes two arguments back to the client session.

 sub db_offline {
   my ($cause, $errstr, $alias) = @_[ARG0,ARG1,ARG2];
   ...
 }

The C<$cause> is the either "SHUTDOWN" or the error string from the
C<ErrorEvent> of LaDBI's internal POE::Wheel::Run .

The C<$errstr> is the value passed to the "shutdown" event or
the C<ARG0> of the internal POE::Wheel::Run ErrorEvent.

The C<$alias> is the alias of the C<POE::Component::LaDBI> session
which has lost it's subprocess and is shutting downn. This allows the
registered user of the C<POE::Component::LaDBI> session to track LaDBI
sessions from start up to shutdown.


=back

=back

=head2 LaDBI Request Events

All request events have the same handler. This is because the handler merely
creates a request message and sends it to the perl sub-process which is doing
the actuall DBI calls.

The handler takes the same arguments. Not all events use the all the argument
fields. The arguments fields/keys are:

=over 4

=item C<UserData>

C<UserData> is a tool you, the programmer, may use to correlate
LaDBI requests with LaDBI responses. Both C<SuccessEvent> and
C<ErrorEvent> handlers will be passed the C<UserData> originally
submitted in the C<<$k->post()>>.

C<UserData> must be a scalar. As a scalar it may be a reference
to a hash, or array, or object, or anything your twisted mind
may come up with. Therefor you may use any data in the scalar
to correlate the response to the original request. Further, you
may just use this as a clever way to pass data from the subroutine
where the request was done to the response handler.

=item C<SuccessEvent>

All C<POE::Component::LaDBI> events require C<SuccessEvent>.

The C<SuccessEvent> is fired off if the DBI call returned successfully.
"Returning Successfully" means that no exeption was called (as the
C<RaiseError> attribute might cause) AND that the return value from the DBI
call was a C<defined()> value.

However a C<SuccessEvent> B<does not> mean that the SQL completed in what
you might commonly think of as a successful manner. For instance, a SELECT
statement might not return anything. In that case, the returned data will be
an empty array ref. Further, somecalls, while well formed, will return an
error because that feature (like transactions ala C<$dbh-E<gt>begin_work>)
are not implemented in your DBI driver.

The handler for the  C<SuccessEvent> is invoked the following arguments.

  sub success_event_handler {
     ...
     my ($handle_id, $datatype, $data, $userdata) = @_[ARG0..ARG3];
     ...
  }

=over 4

=item C<$handle_id>

This is a cookie representing a DBI handle object. There are two kinds of
DBI handle objects,  database handles and statement handles. You use
C<$handle_id> to refer to a DBI handle object you want to call methods on.

Both, C<connect> and C<prepare> B<generate> new handle ids. The
C<SuccessEvent> called by the C<connect> handler is passed a new database
handle id. The same is true for C<prepare> but the C<$handle_id> represents
a DBI statement handler object instead.

All other C<POE::Component::LaDBI> events just return the C<$handle_id>
that was used to invoke them. For exmple, the C<execute> event requires a
statement handle id. When the C<SuccessEvent> for that C<execute> is called
it just returns the same statement handle id.

=item C<$datatype>

The value of C<$datatype> is a string that tells you what kind of data
structure is contained in C<$data>. C<$data> can be a return code "RC", a
return value "RV", an array ref of array refs "TABLE", a hash ref of hash
refs "NAMED_TABLE", an array ref representing a row "ROW", a hash ref
representing a row "NAMED_ROW", an array ref representing a column "COLUMN",
or a string meant to represent a part of a SQL statement "SQL" (like from
C<$dbh->quote()>).

Here is a some rough descriptions of the format of the values of C<$datatype>:

=over 4

=item C<TABLE>

Data is an array ref of array refs to scalars.

  Data = [
          [row0col0, row0col1, ...],
          [row1col0, row1col1, ...],
          ...
         ]

=item C<NAMED_TABLE>

This one is odd. See the description of C<selectall_hashref()> in L<DBI>.
For C<*_hashref()> calls in L<DBI> you have to provide the database table field
which will be the hash key into this hash table. The values corresponding
to each key is a hash of the rows returned from the select or fetch. I did
not invent this and do not quite understand why is is this way.

  Data = {
          row0colX_val => {col0_name => row0_val, col1_name => row0_val, ...},
	  row1colX_val => {col0_name => row1_val, col1_name => row1_val, ...},
           ...
         }

=item C<ROW>

Data is an array ref of scalars.

  Data = [ elt0, elt1, ... ]

=item C<NAMED_ROW>

Data is an hash ref containing name-value pairs of each data item
in the row; the name is the column name, the value is the column value.

  Data = { col0_name => elt0, col1_name => elt1, ... }

=item C<COLUMN>

  Data = [ elt0, elt1, ... ]

=item C<RC>

Return code is a scalar valude returned from the DBI call.

  Data = $rc

=item C<RV>

Return Value is a scalar value returned from the DBI call.

  Data = $rv

=item C<SQL>

This is the data type for the return value from DBI::quote() call.

  Data = $sql_string

=back

=item C<$data>

This is scalar value or a reference to a more complex data structure
(see above).

Some calls may return successfully with $data a defined value, yet $data may
be a "zero-but-true" value. For example look at the L<DBI> description of
C<$dbh-E<gt>ping>.

=item C<$userdata>

The scalar passed into the original request which resulted in this response.
It is entirely programmer defined what is held in this scalar value.
 Hint: you can set a hash ref as the user data,
       aka \%stuff_assoc_with_ladbi_call

=back

=item C<FailureEvent>

All C<POE::Component::LaDBI> events require C<FailureEvent>.

When C<FailureEvent> is invoked, it can be for several different reasons.

One common reason is that your SQL is malformed. This one gets me all the
time.

Another common reason is that you did not provide the correct arguements
to the C<POE::Component::LaDBI> event. The arguements you provide in
the C<Args> field are passed literally to the L<DBI> call. Bad arguements,
or the wrong number, will cause the L<DBI> call to throw an execption.

Another reason might be that you are using an invalid C<$handle_id>. The
C<$handle_id> might be invalid because it is garbled, or it has be deleted
due to a previous use of C<disconnect> or C<finish>.

Finnally, it might just be that something bad happened internally to
C<POE::Component::LaDBI::Engine> or C<DBI> itself.

A C<FailureEvent> is provided the following arguments.

  sub failure_event {
    ...
    my ($handle_id, $errtype, $errstr, $err, $userdata) =
          @_[ARG0..ARG4];
    ...
  }

The argument C<$handle_id> is either C<undef>, a statement handle, or a
database handle depending on the type of request which was submitted
and now failed.

The argument C<$errtype> can be "SHUTDOWN", "ERROR", "EXCEPTION",
"INVALID_REQUEST".

The C<$errtype eq "EXCEPTION"> results from the fact that all the actual
DBI command are wrapped in and C<eval {}> and the C<$@> checked. In this
case, C<$errstr> is set to C<$@> and C<$err> is undefined.

The C<$errtype eq "ERROR"> results from the fact that the results of the
DBI command is checked for C<undef>. Then the appropriate DBI
C<$DBI::errstr> and C<$DBI::err> are passed back as C<$errstr> and
C<$err> respectively.

The C<$errtype eq "SHUTDOWN"> results from abnomal termination of the
C<POE::Component::LaDBI> session. C<$err> is set to the cause and C<$errstr>
is set to a string explanation of the cause. C<$errstr> can be "signal" or
a POE::Wheel::Run operation. And C<$err> is set to the signal type or
wheel operation string value of C<$!>.

The C<$errtype eq "INVALID_REQUEST"> means that C<POE::Component::LaDBI>
failed to instantiate a C<POE::Component::LaDBI::Request> object. Hence,
nothing was sent to the sub-process running C<POE::Component::LaDBI::Engine>
for execution. C<$errstr> is set to an empty string and C<$err> is set
to undef.

The C<$errtype eq "INVALIE_HANDLE_ID"> means that a
C<POE::Component::LaDBI::Request> object was create and the message sent to
the sub-process, but the C<POE::Component::LaDBI::Engine> object in the
sub-process did not have a record of that handle id. C<$errstr> is set
to empty string and C<$err> is set to undef.

=item C<HandleId>

This is either a database handle id, a statement handle id to use, or
C<undef> if a DBI handle type is not required for the LaDBI command.

=item C<Args>

This is always an array ref. The array is exact the arguemnts to pass to
the appropriate DBI method. You are required to pass the correct ones, else
you will recieve a C<FailureEvent>, probably of C<EXCEPTION> type.

=back

=head2 EXAMPLE

  use strict;
  use warnings;

  use POE;
  use POE::Component::LaDBI;

  my $LADBI_ALIAS = "ladbi";

  my $DSN = "dbi:Pg:dbname=test";
  my $USER = "dbuser";
  my $PASSWD = "secret";

  my $SQL = "SELECT * FROM contacts";


  POE::Component::LaDBI->create(Alias => $LADBI_ALIAS)
    or die "Failed to create a POE::Component::LaDBI session\n";

  POE::Session->create
    (args => [$DSN, $USER, $PASSWD, $SQL],
     inline_states =>
      {
       _start          => sub {
  	 my ($dsn, $user, $passwd, $sql) = @_[ARG0..ARG3];
  	 print STDERR "_start: args=($dsn,$user,$passwd)\n";
  	 $_[HEAP]->{sql} = $sql;
  	 $_[KERNEL]->post($LADBI_ALIAS => "connect",
  			  SuccessEvent => "selectall",
  			  FailureEvent => "dberror",
  			  Args => [ $dsn, $user, $passwd ]);
       },

       _stop           => sub {
         print STDERR "_stop: client session ended.\n";
       },

       shutdown        => sub {
  	 print STDERR "shutdown: sending shutdown to $LADBI_ALIAS\n";
  	 $_[KERNEL]->post($LADBI_ALIAS => "shutdown");
       },

       selectall       => sub {
  	 my ($dbh_id, $datatype, $data) = @_[ARG0..ARG2];
  	 $_[HEAP]->{dbh_id} = $dbh_id;
  	 print STDERR "selectall: dbh_id=$dbh_id\n";
  	 $_[KERNEL]->post($LADBI_ALIAS => "selectall",
  			  SuccessEvent => "display_results",
  			  FailureEvent => "dberror",
  			  HandleId     => $dbh_id,
  			  Args         => [ $_[HEAP]->{sql} ] );
       },

       display_results => sub {
  	 my ($dbh_id, $datatype, $data) = @_[ARG0..ARG2];
  	 print STDERR "display_results: dbh_id=$dbh_id\n";
  	 for my $row ( @$data ) {
  	   print join(",", @$row), "\n";
  	 }
  	 $_[KERNEL]->post($LADBI_ALIAS => "disconnect",
  			  SuccessEvent => "shutdown",
  			  FailureEvent => "dberror",
  			  HandleId     => $dbh_id);
       },

       dberror         => sub {
  	 my ($dbh_id, $errtype, $errstr, $err) = @_[ARG0..ARG3];
  	 print STDERR "dberror: dbh_id  = $dbh_id\n";
  	 print STDERR "dberror: errtype = $errtype\n";
  	 print STDERR "dberror: errstr  = $errstr\n";
  	 print STDERR "dberror: err     = $err\n" if $errtype eq "ERROR";
  	 $_[KERNEL]->yield("shutdown");
       }
      } #end: inline_states
    ) #end: POE::Session->create()
  or die "Failed to instantiate POE::Session\n";

  $poe_kernel->run();

  exit 0;
  __END__


=head2 DEBUGGING

If the environment variable LADBI_DEBUG is set to a true value (perl-wise),
or the ":DEBUG" symbol is in the use statement import list
(eg C<use POE::Component::LaDBI qw(:DEBUG)>), then debugging will be turned
on.

When debuggind is turned on, POE::Component::LaDBI->run() will open and log
messages to a file whos name is indicated in
$POE::Component::LaDBI::DEBUG_FILE.

The debug log is set to "ladbi_run.log" by default.

=head2 EXPORT

None by default.


=head1 AUTHOR

Sean M. Egan, E<lt>seanegan:bigfoot_comE<gt>

=head1 SEE ALSO

L<perl>, L<POE>, L<DBI>, L<POE::Component::LaDBI::Engine>,
L<POE::Component::LaDBI::Request>, L<POE::Component::LaDBI::Response>

=cut
