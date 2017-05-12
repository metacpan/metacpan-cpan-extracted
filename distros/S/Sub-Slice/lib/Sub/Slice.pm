#############################################################################
## Name:        Sub::Slice
## Purpose:     Split long-running tasks into manageable chunks
## Author:      Simon Flack
## Modified by: $Author: colinr $ on $Date: 2005/11/23 14:31:51 $
## Created:     23/01/2003
## RCS-ID:      $Id: Slice.pm,v 1.48 2005/11/23 14:31:51 colinr Exp $
#############################################################################
package Sub::Slice;

use strict;
use vars qw/ $VERSION /;
use Carp;

$VERSION = sprintf"%d.%03d", q$Revision: 1.48 $ =~ /: (\d+)\.(\d+)/;

sub new {
	my $class = shift;
	confess "args: expecting flattened hash (even-numbered list)" if @_%2;
	my %args = @_;

	#Load backend
	my $backend_name = $args{backend} || 'Filesystem';
	croak("Invalid Sub::Slice::Backend - $backend_name") if($backend_name =~ m|[^\w:]|);
	$backend_name = "Sub::Slice::Backend::$backend_name" unless($backend_name =~ /::/); #If no namespace, assume in the Sub::Slice::Backend namespace
	eval "require $backend_name";
	die("Unable to load $backend_name - $@") if($@);
	my $backend = $backend_name->new($args{storage_options});

	#Create job	
	my $job;
	if ($args{token}) {
		my $token = $args{token};

		# Some serializers (XML::Simple?) refuse to serialize
		# a blessed object. We can now cope with an unblessed
		# token (though if it is blessed, we leave it as it is)
		confess "illegal scalar token" unless(ref $token && UNIVERSAL::isa($token, 'HASH'));
		$token = Sub::Slice::Token->rebless($token);
		$job = $backend->load_job( $token->{id} );
		TRACE($job->{token}->{pin}, $token->{pin});
		die("Signature from client doesn't match the value on the server") unless($job->{token}->{pin} == $token->{pin});
		$token->clean(); # remove cruft from last run
		$job->{'token'} = $token;
		$job->{'iterations'} = $token->{iterations} if(defined $token->{iterations});
	} else {
		my $id = $backend->new_id();
		$job = _create_job($id, \%args);
		bless $job, $class;
	}

	#Attach backend only for transient lifetime
	$job->{'backend'} = $backend; 
	$job->{'this_iteration'} = 0;
	return $job;
}

sub DESTROY {
	my $self = shift;
	TRACE("Sub::Slice destructor for $self");

	#Things not to persist
	delete $self->{'return_value'}; 
	my $backend = delete $self->{'backend'};

	my $new_eval_error;
	{
		# If DESTROY is being called as a result of something else dying, protect $@
		local $@; 

		my $job_id = $self->id;
		if($self->is_done || $self->abort) {
			TRACE("finished job: $job_id - deleting...");
			$backend->delete_job($job_id);
		} else {
			eval { $backend->save_job($self) };
			if ($new_eval_error = $@) {
				TRACE($new_eval_error);
				DUMP($self)
			}
			TRACE('DONE');
		}
	}
	$@ = $new_eval_error if $new_eval_error;
}

sub token {
	my $self = shift;
	croak("cannot set token") if @_;
	return $self->{'token'};
}

sub id {
	my $self = shift;
	croak("cannot set id") if @_;
	return $self->token->{id};	
}

sub set_estimate {
	my $self = shift;
	defined $_[0] and $self->token()->{estimate} = shift;
}

sub estimate {
	my $self = shift;
	croak("use set_estimate() to change estimate") if @_;
	return $self->token()->{estimate};
}

sub count {
	my $self = shift;
	croak("cannot set count") if @_;
	return $self->token()->{count};
}

sub is_done {
	my $self = shift;
	croak("use done() to mark job as completed") if @_;
	return $self->token()->{done};
}

sub done {
	my $self = shift;
	croak("done() doesn't take arguments") if @_;
	$self->token()->{done} = 1;
}

sub abort {
	my $self = shift;
	if (defined $_[0]) {
		$self->token()->{error} = shift;
		$self->token()->{abort} = 1;
	}
	return $self->token()->{'abort'};
}

sub status {
	my $self = shift;
	defined $_[0] and $self->token()->{status} = shift;
	return $self->token()->{status};
}

sub store {
	my $self = shift;
	while (@_) {
		my ($key, $value) = (shift, shift);
		croak("Usage: store( KEY, [VALUE] )") unless ($key);
		croak("Error: invalid key: $key") if ref $key;
		if(ref $value || !$self->{blob_threshold} || length($value) <= $self->{blob_threshold}) {
			$self->{'backend'}->store($self, $key, $value);
		} else {
			$self->store_blob($key, $value);
		}
	}
}

sub fetch {
	my $self = shift;
	my $key = shift;
	croak("Usage: fetch( KEY )") unless ($key);
	croak("Error: invalid key") if ref $key;
	my $d = $self->{'backend'}->fetch($self, $key);
	return defined $d ? $d : $self->fetch_blob($key);
}

sub store_blob {
	my $self = shift;
	my ($key, $data) = @_;
	$self->{'backend'}->store_blob($self, $key, $data);
}

sub fetch_blob {
	my $self = shift;
	my ($key) = @_;
	return $self->{'backend'}->fetch_blob($self, $key);
}

sub stage {
	my $self = shift;
	croak("use next_stage() to set stage") if @_;
	return $self->{'stage'};
}

sub return_value {
	my $self = shift;
	if (@_) {
		$self->{return_value} = [@_];
		return @_;
	}
	my $rv = $self->{return_value};
	if ($rv) {
		return (@$rv)[0..$#$rv] if $#$rv >= 0;
	} else {
		return ()
	}
}

sub next_stage {
	my $self = shift;
	my $stage = shift;
	croak("Error: invalid stage") if (ref $stage || !defined $stage);
	$self->{'stage'} = $stage;
	$self->{'token'}->{'stage'} = $stage;
}

sub at_start ($&) {
	my $self = shift;
	my ($code) = @_;
	return if $self->{'initialised'} || $self->stage();
	TRACE(sprintf 'Running at_start for job %s', $self->id);
	$self->{'initialised'}++;

	eval {$self->return_value($code->($self))};
	if (my $error = $@) {
		$self->abort($error);
		die $error;
	}

	return $self->return_value;
}

sub at_stage ($$&) {
	my $self = shift;
	my ($this_stage, $code) = @_;

	croak("undefined stage") unless defined $this_stage;

	return unless $self->{'initialised'};
	if (my $stage = $self->stage()) {
		return unless defined $this_stage && $this_stage eq $stage;
	} else {
		$self->next_stage($this_stage);
	}

	TRACE(sprintf'Running stage:%s for job %s', $this_stage, $self->id);

	while (1) {
		last if ( $self->is_done() || $this_stage ne $self->stage() );
		my $iterate = $self->{'iterations'};
		last if $iterate && $self->{'this_iteration'} >= $iterate;
		$self->{'this_iteration'}++;
		$self->token()->{count}++;

		eval {$self->return_value($code->($self))}; #Trap any exceptions
		if (my $error = $@) {
			$self->abort($error); #Record error message
			die $error; #Re-throw exception
		}
	}

	return 1;
}

sub at_end ($&) {
	my $self = shift;
	my ($code) = @_;
	return unless $self->{'initialised'};
	return unless $self->is_done;
	TRACE(sprintf 'Running at_end for job %s', $self->id);

	eval {$self->return_value($code->($self))};
	if (my $error = $@) {
		$self->abort($error);
		die $error;
	}

	return $self->return_value;
}


#############################################################################
# Private Functions

sub _create_job {
	my ($id, $options) = @_;

	my $iterations = $options->{iterations};
	$iterations = 1 unless defined $iterations;

	my ($fh, $token, %job);
	DUMP('Sub::Slice storage options', $options->{storage_options});
	$job{'storage_options'} = $options->{storage_options};
	$job{'storage_options'}->{path} ||= File::Spec::Functions::tmpdir();    
	$job{'iterations'} = $iterations;
	$job{'token'} = Sub::Slice::Token->new($id, $options->{pin_length});
	$job{'blob_threshold'} = $options->{auto_blob_threshold};

	return \%job;
}

# Log::Trace stubs
sub TRACE {}
sub DUMP  {}

#############################################################################
# Sub::Slice::Token
#############################################################################
package Sub::Slice::Token;

use constant DEFAULT_PIN_LENGTH => 1e9;
use vars '$AUTOLOAD';
use Carp;
use POSIX qw(log10 ceil);

sub rebless { 
	my ($class, $token) = @_;
	$class = ref $class || $class;
	bless $token, $class if (ref $token eq "HASH");
	return $token;
}

sub new {
	my $class = shift;
	my ($id, $pin_length) = @_;
	$pin_length = DEFAULT_PIN_LENGTH unless($pin_length);

	my $self = bless { 
		id => $id,
		estimate => 0,
		count => 0,
		done => 0,
		abort => "",
		error => "",
		stage => "",
		pin => $class->random_pin($pin_length),
	}, $class;
	return $self;
}

sub random_pin {
	my ($self, $pin_length) = @_;
	my $figs = ceil(log10($pin_length));
	return sprintf("%0${figs}d", int(rand($pin_length))); #Fixed length random number padded with zeros
}

sub clean {
	my $self = shift;
	$self->{$_} = "" for qw( abort error status );
	return $self;
}

sub DESTROY {};

sub AUTOLOAD {
	my $self = shift;
	(my $name = $AUTOLOAD) =~ s/.*://;
	if (!exists $self->{$name}) {
		croak("undefined method: $name");
	} else {
		return $self->{$name}
	}
}

1;


=head1 NAME

Sub::Slice - split long-running tasks into manageable chunks

=head1 SYNOPSIS

	# Client
	# Assume methods in the Server:: package are magically remoted
	my $token = Server::create_token();
	for(1 .. MAX_ITERATIONS) {
		Server::do_work($token);
		last if $token->{done};
	}

	# Server
	# Imagine this is on a remote machine
	package Server;
	use Sub::Slice;

	sub create_token {
		# create a new job:
		my $job = new Sub::Slice(
			backend         => 'Filesystem',
			storage_options => {
				path  => '/var/tmp/myproject/',
			}
		);
		return $job->token;
	}

	sub do_work {
		# loading an existing job:
		my $job = new Sub::Slice(
			token           => $token
			backend         => 'Filesystem',
			storage_options => {
				path  => '/var/tmp/myproject/',
			}
		);

		at_start $job
			sub {
				$job->store('foo', '1');
				$job->store('bar', { abc = > 'def' });
				# store data, initialise
				$job->set_estimate(10); # estimate number of steps
				return ( $job->fetch('foo') );
			};

		my $foo = $job->fetch('foo');

		at_stage $job "stage_one",
			sub {
				my $bar = $job->fetch('bar');
				# do stuff
				$job->next_stage('stage_two') if $some_condition;
			};

		at_stage $job "stage_two",
			sub {
				# ...do more stuff...
				# mark job as ready to be deleted
				$job->done() if $job->count() == $job->estimate();
			};

		return $job->return_value(); #Pass back any return value from coderefs
	}

=head1 DESCRIPTION

Sub::Slice breaks up a long process into smaller chunks that can be executed
one at a time over a stateless protocol such as HTTP/SOAP so that progress may
be reported.  This means that the client can display progress or cancel the
operation part-way through.

It works by the client requesting a token from the server, and passing the
token back to the server on each iteration.  The token passed to the client
contains status information which the client can use to determine if the job
has completed/failed and to display status/error messages.

Within the routine called on each iteration, the server defines a set of
coderefs, one of which will be called for a given iteration.  In addition the
server may define coderefs to be called at the start and end of the job.  The
server may provide the client with an estimate of the number of iterations the
job is likely to take.

It is possible to balance performance/usability by modifying the number of
iterations that will be executed before returning progress to the client.

=head1 METHODS

=over 4

=item new( %options )

Create a new job object. Valid options are:

=over 4

=item token

A token for an existing job (optional)

=item iterations

The number of chunks to execute before saving the state and returning. Defaults to '1'.
This value may be overridden later on by setting the value in the token.
Set to 0 for unlimited.

=item backend

The storage backend.
This should either be a fully qualified package name or if no namespace is included it's assumed to be in the 
Sub::Slice::Backend namespace (e.g. Database would be interpreted as Sub::Slice::Backend::Database).
Defaults to Sub::Slice::Backend::Filesystem.

=item pin_length

The size of the random PIN used to sign the token.  Default is 1e9.

=item random_pin ($l)

Generates a random PIN of length $l. We do this using rand(). 
You might want to override this method if you require 
cryptographic-quality randomness for your environment.

=item auto_blob_threshold

If this is set, any strings longer than this number of bytes will be stored as BLOBs automatically
(possibly taking advantage of a more efficient BLOB storage mechanism offered by the backend).
Note that this does not apply when you store references, only to strings of characters/bytes.

=item storage_options

A hash of configuration options for the backend storage.  
See the POD of the backend module (default is L<Sub::Slice::Backend::Filesystem>).

=back

Returns an existing job object with session data for C<$token>

=back

=head2 METHODS DEFINING STAGES OF ITERATION

=over 4

=item at_start $job \&coderef

Code to initialise the job. This isn't counted as an iteration and will only
run once per job. 

=item at_stage $job $stage_name, \&coderef

Executes C<\E<amp>coderef> up-to C<iterate> times, B<if> C<$stage_name> is the
current stage B<and> if the number of executions in the current session is not
greater than C<iterate>.  It is currently required that you have at least one
C<at_stage> defined.

If the current stage hasn't been set with C<next_stage()>, it will implicitly be set to the first
C<at_stage> block that is seen.

=item at_end $job \&coderef

Code to run after the last iteration (unless the job is aborted before then).  This isn't counted as an iteration and will only
run once per job.  It's typically used as a "commit" stage.

=back

If a job dies in one of these blocks, Sub::Slice sets $job->abort($@) and rethrows the exception.  
Note that C<at_end> may not be run if a job is aborted during one of the earlier stages.
See L<Sub::Slice::Manual> for an example of defensive coding to prevent resources allocated in C<at_start>
leaking if the job is aborted part-way through.

=head2 ACCESSOR METHODS

=over 4

=item $job->token()

Returns the token object for this job.  The token object will be updated
automatically as stages of the sub execute.  The token has the following
properties which the client can make use of:

=over 4

=item done

Read/write boolean value.  Is the job done?  
Setting this to 1 on the client will cause iterations on the server to cease,
and any C<at_end> cleanup to be done.

=item abort

Read-only boolean value.  Was the job aborted on the server?

=item error

Read-only.  Error message if the job was aborted.

=item count

Read-only.  Number of iterations performed so far.

=item estimate

Read-only.  An estimate of the total number of iterations that will be performed.  This may
not be totally accurate, depending if new work is "discovered" as the
iterations proceed.

=item status

Read-only.  Status message.

=item stage

Read-only.  The next stage that the job will run.

=item iterations

A write-only property the client can use to 
control the number of iterations run on the server in the next call.  This overrides the 
default number of iterations set in the Sub::Slice constructor.

=back

=item $job->id()

Returns the ID of the job (issued by the C<new_id> function in the backend).
This is mainly of interest if you are writing a backend and need to get the ID from a job.

=item $job->count()

Returns the total number of iterations that have been executed.

=item $job->estimate()

Returns an estimate of how many iterations are required for the job.

=item $job->is_done()

Returns a boolean value.  Is the job done?

=item $job->stage()

Returns the name of the executing code block, as set by C<next_stage()>

=item $job->fetch( $key )

Returns the user data stored under C<$key>.
If no data is found against C<$key>, it automatically tries C<fetch_blob> to see if data was stored as a blob.

=item $job->fetch_blob($key)

Returns a lump of data stored using C<store_blob> - see the MUTATOR METHODS.

=item $job->return_value()

C<return_value()> returns the return value of the stage. This C<return_value()>
method will help you avoid mistakes like this:

	sub do_work {
		my $job = new Sub::Slice(token => shift());	
		at_stage $job 'mystage', sub {
			#  do stuff
			return 'abc' #only returns 1 level up
		};
		#nowt returned from do_work
	}

The caller of do_work() will not receive the return value inside the 'mystage' sub {}
This might be better written as :

	sub do_work {
		my $job = new Sub::Slice(token => shift());
		at_stage $job 'mystage', sub {
			#  do stuff
			return 'abc' #only returns 1 level up
		};
		return $job->return_value(); # 'abc'
	}

=back

=head2 MUTATOR METHODS THAT SET VALUES IN THE TOKEN

=over 4

=item $job->set_estimate( $int )

Populates the C<estimate> field in the token with an estimate of how many
iterations are required for this job to complete.

=item $job->done()

Mark the job as completed successfully. This sets the done flag in the token.
Serialised object data will be removed when the object is destroyed.

=item $job->abort( $reason )

Mark the job as aborted. This sets the abort flag in the token.
The optional $reason message will be stored in the token's error string.
Serialised object data will be removed when the object is destroyed.

=item $job->status( $status_text )

Set the status field in the token.  This might be useful to inform users about
what is about to happen in the next iteration of the job.

=back

=head2 OTHER MUTATOR METHODS

=over 4

=item $job->next_stage( $stage_name )

Tell the C<$job> object that the next time the routine is called, it should
execute the block named C<$stage_name>.  Unless C<next_stage> is set, the first
at_stage block will be executed.

=item $job->store( $key => $value, $key2 => $value2, ... )

Store some user data in the object. C<$value> can be a scalar containing any
perl data type (such as hash/array references) - it will be automatically
serialised.

Note that some objects may not be suited to serialisation. For example if
an object is blessed into a package that is C<require>d at runtime, when it is
deserialised, the required package may not actually be loaded.

There may also be issues serialising some objects like DBI database handles and
XML::Parser objects, although this is potentially backend-specific (Filesystem
uses Storable, and some objects may provide serialisation hooks).

C<$value> is optional (if not specified, C<$value> will be set to undef).

=item $job->store_blob($key => $blob)

Allows large lumps of data to be stored efficiently by the back end.

=back

=head1 VERSION

	$Revision: 1.48 $ on $Date: 2005/11/23 14:31:51 $ by $Author: colinr $

=head1 AUTHOR

Simon Flack and John Alden with additions by Tim Sweetman <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut
