package Parallel::DataPipe;

our $VERSION='0.11';
use 5.8.0;
use strict;
use warnings;
use IO::Select;
use List::Util qw(first min);
use constant PIPE_MAX_CHUNK_SIZE => $^O =~ m{linux|cygwin}? 16*1024 : 1024;
use constant _EOF_ => (-(1<<31));

sub run {
    my $param = {};
    my ($input,$map,$output) = @_;
    if (ref($input) eq 'HASH') {
        $param = $input;
    } else {
        $param = {input=>$input, process=>$map, output=>$output };
    }
    pipeline($param);
}

sub pipeline {
    my $class=shift;
    if (ref($class) eq 'HASH') {
        unshift @_, $class;
        $class = __PACKAGE__;
    }
    my @pipes;
    # init pipes
    my $default_input;
    for my $param (@_) {
        unless (exists $param->{input}) {
            $param->{input} = $default_input or die "You have to specify input for the first pipe";
        }
        my $pipe = $class->new($param);
        if (ref($pipe->{output}) eq 'ARRAY') {
            $default_input = $pipe->{output};
        }
        push @pipes, $pipe;
    }
    run_pipes(0,@pipes);
    my $result = $pipes[$#pipes]->{output};
    # @pipes=() kills parent
    # as well as its implicit destroying
    # destroy pipes one by one if you want to survive!!!
    undef $_ for @pipes;
    return unless defined(wantarray);
    return unless $result;
    return wantarray?@$result:$result;
}

sub run_pipes {
    my ($prev_busy,$me,@next) = @_;
    my $me_busy = $me->load_data || $me->busy_processors;
    while ($me_busy) {
        $me->receive_and_merge_data;
        $me_busy = $me->load_data || $me->busy_processors;
        my $next_busy = @next && run_pipes($prev_busy || $me_busy, @next);
        $me_busy ||= $next_busy;
        # get data from pipe if we have free_processors
        return $me_busy if $prev_busy && $me->free_processors;
    }
    return 0;
}

# input_iterator is either array or subroutine reference which get's data from queue or other way and returns it
# if there is no data it returns undef
sub input_iterator {
    my $self = shift;
    $self->{input_iterator}->(@_);
}

sub output_iterator {
    my $self = shift;
    $self->{output_iterator}->(@_);
}

# this is to set/create input iterator
sub set_input_iterator {
    my ($self,$param) = @_;
    my $old_behaviour = $param->{input_iterator};
    my ($input_iterator) = extract_param($param, qw(input_iterator input queue data));
    unless (ref($input_iterator) eq 'CODE') {
        die "array or code reference expected for input_iterator" unless ref($input_iterator) eq 'ARRAY';
        my $queue = $input_iterator;
        $self->{input} = $queue;
        if ($old_behaviour) {
            my $l = @$queue;
            my $i = 0;
            $input_iterator = sub {$i<$l?$queue->[$i++]:undef};
        } else {
            # this behaviour is introduced with 0.06
            $input_iterator = sub {$queue?shift(@$queue):undef};
        }
    }
    $self->{input_iterator} = $input_iterator;
}

sub set_output_iterator {
    my ($self,$param) = @_;
    my ($output_iterator) = extract_param($param, qw(merge_data output_iterator output output_queue output_data merge reduce));
    unless (ref($output_iterator) eq 'CODE') {
        my $queue = $output_iterator || [];
        $self->{output} = $queue;
        $output_iterator = sub {push @$queue,$_};
    }
    $self->{output_iterator} = $output_iterator;
}

# loads all free processor with data from input
# return the number of loaded processors
sub load_data {
    my $self = shift;
    my @free_processors = $self->free_processors;
    my $result = 0;
    for my $processor (@free_processors) {
        my $data = $self->input_iterator;
        # return number of processors loaded
        return $result unless defined($data);
        $result++;
        $self->load_data_processor($data,$processor);
    }
    return $result;
}

# this should work with Windows NT or if user explicitly set that
my $number_of_cpu_cores = $ENV{NUMBER_OF_PROCESSORS};
sub number_of_cpu_cores {
    #$number_of_cpu_cores = $_[0] if @_; # setter
    return $number_of_cpu_cores if $number_of_cpu_cores;
    eval {
        # try unix (linux,cygwin,etc.)
        $number_of_cpu_cores = scalar grep m{^processor\t:\s\d+\s*$},`cat /proc/cpuinfo 2>/dev/null`;
        # try bsd
        ($number_of_cpu_cores) = map m{hw.ncpu:\s+(\d+)},`sysctl -a` unless $number_of_cpu_cores;
    };
    # otherwise it sets number_of_cpu_cores to 2
    return $number_of_cpu_cores || 1;
}

sub freeze {
	my $self = shift;
	$self->{freeze}->(@_);
}

sub thaw {
	my $self = shift;
	$self->{thaw}->(@_);
}

# this inits freeze and thaw with Storable subroutines and try to replace them with Sereal counterparts
sub init_serializer {
    my ($self,$param) = @_;
    my ($freeze,$thaw) = grep $_ && ref($_) eq 'CODE',map delete $param->{$_},qw(freeze thaw);
    if ($freeze && $thaw) {
        $self->{freeze} = $freeze;
        $self->{thaw} = $thaw;
    } else {
        # try cereal
        eval q{
            use Sereal qw(encode_sereal decode_sereal);
            $self->{freeze} = \&encode_sereal;
            $self->{thaw} = \&decode_sereal;
            1;
        }
        or
        eval q{
            use Storable;
            $self->{freeze} = \&Storable::nfreeze;
            $self->{thaw} = \&Storable::thaw;
            1;
        };

    }
}


# this subroutine reads data from pipe and converts it to perl reference
# or scalar - if size is negative
# it always expects size of frozen scalar so it know how many it should read
# to feed thaw
sub _get_data {
    my ($self,$fh) = @_;
    my ($data_size,$data);
    $fh->sysread($data_size,4);
    $data_size = unpack("l",$data_size);
    return undef if $data_size == _EOF_; # this if for process_data terminating
    if ($data_size == 0) {
        $data = '';
    } else {
        my $length = abs($data_size);
        my $offset = 0;
        # allocate all the buffer for $data beforehand
        $data = sprintf("%${length}s","");
        while ($offset < $length) {
            my $chunk_size = min(PIPE_MAX_CHUNK_SIZE,$length-$offset);
            $fh->sysread(my $buf,$chunk_size);
            # use lvalue form of substr to copy data in preallocated buffer
            substr($data,$offset,$chunk_size) = $buf;
            $offset += $chunk_size;
        }
        $data = $self->thaw($data) if $data_size<0;
    }
    return $data;
}

# this subroutine serialize data reference. otherwise
# it puts negative size of scalar and scalar itself to pipe.
sub _put_data {
    my ($self,$fh,$data) = @_;
    unless (defined($data)) {
        $fh->syswrite(pack("l", _EOF_));
        return;
    }
    my $length = length($data);
    if (ref($data)) {
        $data = $self->freeze($data);
        $length = -length($data);
    }
    $fh->syswrite(pack("l", $length));
    $length = abs($length);
    my $offset = 0;
    while ($offset < $length) {
        my $chunk_size = min(PIPE_MAX_CHUNK_SIZE,$length-$offset);
        $fh->syswrite(substr($data,$offset,$chunk_size));
        $offset += $chunk_size;
    }
}

sub _fork_data_processor {
    my ($data_processor_callback) = @_;
    # create processor as fork
    my $pid = fork();
    unless (defined $pid) {
        #print "say goodbye - can't fork!\n"; <>;
        die "can't fork!";
    }
    if ($pid == 0) {
        local $SIG{TERM} = sub {
            exit;
        }; # exit silently from data processors
        # data processor is eternal loop which wait for raw data on pipe from main
        # data processor is killed when it's not needed anymore by _kill_data_processors
        $data_processor_callback->() while (1);
        exit;
    }
    return $pid;
}

sub _create_data_processor {
    my ($self,$process_data_callback) = @_;

    # parent <=> child pipes
    my ($parent_read, $parent_write) = pipely();
    my ($child_read, $child_write) = pipely();

    my $data_processor = sub {
        local $_ = $self->_get_data($child_read);
        unless (defined($_)) {
            exit 0;
        }
        $_ = $process_data_callback->($_);
        $self->_put_data($parent_write,$_);
    };

    # return data processor record
    return {
        pid => _fork_data_processor($data_processor),  # needed to kill processor when there is no more data to process
        child_write => $child_write,                 # pipe to write raw data from main to data processor
        parent_read => $parent_read,                 # pipe to write raw data from main to data processor
    };
}

sub extract_param {
    my ($param, @alias) = @_;
    return first {defined($_)} map delete($param->{$_}), @alias;
}

sub create_data_processors {
    my ($self,$param) = @_;
    my $process_data_callback = extract_param($param,qw(process_data process processor map));
    my $number_of_data_processors = extract_param($param,qw(number_of_data_processors number_of_processors));
    $number_of_data_processors = $self->number_of_cpu_cores unless $number_of_data_processors;
    die "process_data parameter should be code ref" unless ref($process_data_callback) eq 'CODE';
	die "\$number_of_data_processors:undefined" unless defined($number_of_data_processors);
    return [map $self->_create_data_processor($process_data_callback,$_), 0..$number_of_data_processors-1];
}

sub load_data_processor {
	my ($self,$data,$processor) = @_;
    $processor->{item_number} = $self->{item_number}++;
    die "no support of data processing for undef items!" unless defined($data);
    $processor->{busy} = 1;
    $self->_put_data($processor->{child_write},$data);
}

sub busy_processors {
    my $self = shift;
    return grep $_->{busy}, @{$self->{processors}};
}

sub free_processors {
    my $self = shift;
    return grep !$_->{busy}, @{$self->{processors}};
}

sub receive_and_merge_data {
	my $self = shift;
    my ($processors,$ready) = @{$self}{qw(processors ready)};
    $self->{ready} = $ready = [] unless $ready;
    @$ready = IO::Select->new(map $_->{busy} && $_->{parent_read},@$processors)->can_read() unless @$ready;
    my $fh = shift(@$ready);
    my $processor = first {$_->{parent_read} == $fh} @$processors;
    local $_ = $self->_get_data($fh);
    $processor->{busy} = undef; # make processor free
    $self->output_iterator($_,$processor->{item_number});
}

sub _kill_data_processors {
    my ($self) = @_;
    my $processors = $self->{processors};
    my @pid_to_kill = map $_->{pid}, @$processors;
    my %pid_to_wait = map {$_=>undef} @pid_to_kill;
    # put undef to input of data_processor - they know it's time to exit
    $self->_put_data($_->{child_write}) for @$processors;
    while (@pid_to_kill) {
        my $pid = wait;
        delete $pid_to_wait{$pid};
        @pid_to_kill = keys %pid_to_wait;
    }
}

sub new {
    my ($class, $param) = @_;
	my $self = {mypid=>$$};
    bless $self,$class;
    $self->set_input_iterator($param);
    # item_number for merge implementation
    $self->{item_number} = 0;
    # check if user want to use alternative serialisation routines
    $self->init_serializer($param);
    # @$processors is array with data processor info
    $self->{processors} = $self->create_data_processors($param);
    # data_merge is sub which merge all processed data inside parent thread
    # it is called each time after process_data returns some new portion of data
    $self->set_output_iterator($param);
    my $not_supported = join ", ", keys %$param;
    die "Parameters are redundant or not supported:". $not_supported if $not_supported;
	return $self;
}

sub DESTROY {
	my $self = shift;
    return unless $self->{mypid} == $$;
    $self->_kill_data_processors;
    #semctl($self->{sem_id},0,IPC_RMID,0);
}

=begin comment

Why I copied IO::Pipely::pipely instead of use IO::Pipely qw(pipely)?
1. Do not depend on installation of additional module
2. I don't know (yet) how to win race condition:
A) In Makefile.PL I would to check if fork & pipe works on the platform before creating Makefile.
But I am not sure if it's ok that at that moment I can use pipely to create pipes.
so
B) to use pipely I have to create makefile
For now I decided just copy code for pipely into this module.
Then if I know how do win that race condition I will get rid of this code and
will use IO::Pipely qw(pipely) instead and
will add dependency on it.

=end comment

=cut

# IO::Pipely is copyright 2000-2012 by Rocco Caputo.
use Symbol qw(gensym);
use IO::Socket qw(
  AF_UNIX
  PF_INET
  PF_UNSPEC
  SOCK_STREAM
  SOL_SOCKET
  SOMAXCONN
  SO_ERROR
  SO_REUSEADDR
  inet_aton
  pack_sockaddr_in
  unpack_sockaddr_in
);
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use Errno qw(EINPROGRESS EWOULDBLOCK);

my (@oneway_pipe_types, @twoway_pipe_types);
if ($^O eq "MSWin32" or $^O eq "MacOS") {
  @oneway_pipe_types = qw(inet socketpair pipe);
  @twoway_pipe_types = qw(inet socketpair pipe);
}
elsif ($^O eq "cygwin") {
  @oneway_pipe_types = qw(pipe inet socketpair);
  @twoway_pipe_types = qw(inet pipe socketpair);
}
else {
  @oneway_pipe_types = qw(pipe socketpair inet);
  @twoway_pipe_types = qw(socketpair inet pipe);
}

sub pipely {
  my %arg = @_;

  my $conduit_type = delete($arg{type});
  my $debug        = delete($arg{debug}) || 0;

  # Generate symbols to be used as filehandles for the pipe's ends.
  #
  # Filehandle autovivification isn't used for portability with older
  # versions of Perl.

  my ($a_read, $b_write)  = (gensym(), gensym());

  # Try the specified conduit type only.  No fallback.

  if (defined $conduit_type) {
    return ($a_read, $b_write) if _try_oneway_type(
      $conduit_type, $debug, \$a_read, \$b_write
    );
  }

  # Otherwise try all available conduit types until one works.
  # Conduit types that fail are discarded for speed.

  while (my $try_type = $oneway_pipe_types[0]) {
    return ($a_read, $b_write) if _try_oneway_type(
      $try_type, $debug, \$a_read, \$b_write
    );
    shift @oneway_pipe_types;
  }

  # There's no conduit type left.  Bummer!

  $debug and warn "nothing worked";
  return;
}

# Try a pipe by type.

sub _try_oneway_type {
  my ($type, $debug, $a_read, $b_write) = @_;

  # Try a pipe().
  if ($type eq "pipe") {
    eval {
      pipe($$a_read, $$b_write) or die "pipe failed: $!";
    };

    # Pipe failed.
    if (length $@) {
      warn "pipe failed: $@" if $debug;
      return;
    }

    $debug and do {
      warn "using a pipe";
      warn "ar($$a_read) bw($$b_write)\n";
    };

    # Turn off buffering.  POE::Kernel does this for us, but
    # someone might want to use the pipe class elsewhere.
    select((select($$b_write), $| = 1)[0]);
    return 1;
  }

  # Try a UNIX-domain socketpair.
  if ($type eq "socketpair") {
    eval {
      socketpair($$a_read, $$b_write, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair failed: $!";
    };

    if (length $@) {
      warn "socketpair failed: $@" if $debug;
      return;
    }

    $debug and do {
      warn "using a UNIX domain socketpair";
      warn "ar($$a_read) bw($$b_write)\n";
    };

    # It's one-way, so shut down the unused directions.
    shutdown($$a_read,  1);
    shutdown($$b_write, 0);

    # Turn off buffering.  POE::Kernel does this for us, but someone
    # might want to use the pipe class elsewhere.
    select((select($$b_write), $| = 1)[0]);
    return 1;
  }

  # Try a pair of plain INET sockets.
  if ($type eq "inet") {
    eval {
      ($$a_read, $$b_write) = _make_socket();
    };

    if (length $@) {
      warn "make_socket failed: $@" if $debug;
      return;
    }

    $debug and do {
      warn "using a plain INET socket";
      warn "ar($$a_read) bw($$b_write)\n";
    };

    # It's one-way, so shut down the unused directions.
    shutdown($$a_read,  1);
    shutdown($$b_write, 0);

    # Turn off buffering.  POE::Kernel does this for us, but someone
    # might want to use the pipe class elsewhere.
    select((select($$b_write), $| = 1)[0]);
    return 1;
  }

  # There's nothing left to try.
  $debug and warn "unknown pipely() socket type ``$type''";
  return;
}


1;

=head1 NAME

C<Parallel::DataPipe> - parallel data processing conveyor

=encoding utf-8

=head1 SYNOPSIS

    use Parallel::DataPipe;
    Parallel::DataPipe::run {
        input => [1..100],
        process => sub { "$_:$$" },
        number_of_data_processors => 100,
        output => sub { print "$_\n" },
    };


=head1 DESCRIPTION


If you have some long running script processing data item by item
(having on input some data and having on output some processed data i.e. aggregation, webcrawling,etc)
you can speed it up 4-20 times using parallel datapipe conveyour.
Modern computer (even modern smartphones ;) ) have multiple CPU cores: 2,4,8, even 24!
And huge amount of memory: memory is cheap now.
So they are ready for parallel data processing.
With this script there is an easy and flexible way to use that power.

So what are the benefits of this module?

1) because it uses input_iterator it does not have to know all input data before starting parallel processing

2) because it uses merge_data processed data is ready for using in main thread immediately.

1) and 2) remove requirements for memory which is needed to store data items before and after parallel work. and allows parallelize work on collecting, processing and using processed data.

If you don't want to overload your database with multiple simultaneous queries
you make queries only within input_iterator and then process_data and then flush it with merge_data.
On the other hand you usually win if make queries in process_data and do a lot of data processors.
Possibly even more then physical cores if database queries takes a long time and then small amount to process.

It's not surprise, that DB servers usually serves N queries simultaneously faster then N queries one by one.

Make tests and you will know.

To (re)write your script for using all processing power of your server you have to find out:

1) the method to obtain source/input data. I call it input iterator. It can be either array with some identifiers/urls or reference to subroutine which returns next portion of data or undef if there is nor more data to process.

2) how to process data i.e. method which receives input item and produce output item. I call it process_data subroutine. The good news is that item which is processed and then returned can be any scalar value in perl, including references to array and hashes. It can be everything that Storable can freeze and then thaw.

3) how to use processed data. I call it merge_data. In the example above it just prints an item, but you could do buffered inserts to database, send email, etc.

Take into account that 1) and 3) is executed in main script thread. While all 2) work is done in parallel forked threads. So for 1) and 3) it's better not to do things that block execution and remains hungry dogs 2) without meat to eat. So (still) this approach will benefit if you know that bottleneck in you script is CPU on processing step. Of course it's not the case for some web crawling tasks unless you do some heavy calculations

=head1 SUBROUTINES

=head2 run

This is subroutine which covers magic of parallelizing data processing.
It receives paramaters with these keys via hash ref.

B<input> - reference to array or subroutine which should return data item to be processed.
    in case of subroutine it should return undef to signal EOF.
    In case of array it uses it as queue, i.e. shift(@$array) until there is no data item,
    This behaviour has been introduced in 0.06.
    Also you can use these aliases:
    input_iterator, queue, data

    Note: in version before 0.06 it was input_iterator and if reffered to array it remained untouched.
    while new behaviour is to treat this parameter like a queue.
    0.06 support old behaviour only for input_iterator,
    while in the future it will behave as a queue to make life easier

B<process> - reference to subroutine which process data items. they are passed via $_ variable
	Then it should return processed data. this subroutine is executed in forked process so don't
    use any shared resources inside it.
    Also you can update children state, but it will not affect parent state.
    Also you can use these aliases:
    process_data

These parameters are optional and has reasonable defaults, so you change them only know what you do

B<output> - optional. either reference to a subroutine or array which receives processed data item.
    subroutine can use $_ or $_[0] to access data item and $_[1] to access item_number.
	this subroutine is executed in parent thread, so you can rely on changes that it made.
    if you don't specify this parameter array with processed data can be received as a subroutine result.
    You can use this aliseases for this parameter:
    merge_data, merge

B<number_of_data_processors> - (optional) number of parallel data processors. if you don't specify,
    it tries to find out a number of cpu cores
	and create the same number of data processor children.
    It looks for NUMBER_OF_PROCESSORS environment variable, which is set under Windows NT.
    If this environment variable is not found it looks to /proc/cpuinfo which is availbale under Unix env.
    It makes sense to have explicit C<number_of_data_processors>
    which possibly is greater then cpu cores number
    if you are to use all slave DB servers in your environment
    and making query to DB servers takes more time then processing returned data.
    Otherwise it's optimal to have C<number_of_data_processors> equal to number of cpu cores.

B<freeze>, B<thaw> - you can use alternative serializer.
    for example if you know that you are working with array of words (0..65535) you can use
    freeze => sub {pack('S*',@{$_[0]})} and thaw => sub {[unpack('S*',$_[0])]}
    which will reduce the amount of bytes exchanged between processes.
    But do it as the last optimization resort only.
    In fact automatic choise is quite good and efficient.
    It uses encode_sereal and decode_sereal if Sereal module is found.
    Otherwise it use Storable freeze and thaw.

Note: run has also undocumented prototype for calling (\@\$) i.e.

    my @x2 = Parallel::DataPipe::run([1..100],sub {$_*2});

This feature is experimental and can be removed. Use it at your own risk.

=head2 pipeline

pipeline() is a chain of run() (parallel data pipes) executed in parallel
and input for next pipe is implicitly got from previous one.

  run {input => \@queue, process => \&process, output => \@out}

is the same as

  pipeline {input => \@queue, process => \&process, output => \@out}

But with pipeline you can create chain of connected pipes and run all of them in parallel
like it's done in unix with processes pipeline.

  pipeline(
    { input => \@queue, process => \&process1},
    { process => \&process2},
    { process => \&process3, output => sub {print "$_\n";} },
  );

And it works like in unix - input of next pipe is (implicitly) set to output from previous pipe.
You have to specify input for the first pipe explicitly (see example of parallel grep 'hello' below ).

If you don't specify input for next pipe it is assumed that it is output from previous pipe like in unix.
Also this assumption that input of next pipe depends on output of previous is applied for algorithm
on prioritizing of execution of pipe processors.
As long as the very right (last in list) pipe has input items to process it executes it's data processors.
If this pipe has free processor that is not loaded with data then the processors from previous pipe are executed
to produce an input data for next pipe.
This is recursively applied for all chain of pipes.

Here is parallel grep implemented in 40 lines of perl code:

  use List::More qw(part);
  my @dirs = '.';
  my @files;
  pipeline(
    # this pipe looks (recursively) for all files in specified @dirs
    {
        input => \@dirs,
        process => sub {
            my ($files,$dirs) = part -d?1:0,glob("$_/*");
            return [$files,$dirs];
        },
        output => sub {
            my ($files,$dirs) = @$_;
            push @dirs,@$dirs;# recursion is here
            push @files,@$files;
        },
    },
    # this pipe grep files for word hello
    {
        input => \@files,
        process => sub {
            my ($file) = $_;
            open my $fh, $file;
            my @lines;
            while (<$fh>) {
                # line_number : line
                push @lines,"$.:$_" if m{hello};
            }
            return [$file,\@lines];
        },
        output => sub {
            my ($file,$lines) = @$_;
            # print filename, line_number , line
            print "$file:$_" for @$lines;
        }
    }
  );

=head1 HOW parallel pipe (run) WORKS

1) Main thread (parent) forks C<number_of_data_processors> of children for processing data.

2) As soon as data comes from C<input_iterator> it sends it to next child using
pipe mechanizm.

3) Child processes data and returns result back to parent using pipe.

4) Parent firstly fills up all the pipes to children with data and then
starts to expect processed data on pipes from children.

5) If it receives result from chidlren it sends processed data to C<data_merge> subroutine,
and starts loop 2) again.

6) loop 2) continues until input data is ended (end of C<input_iterator> array or C<input_iterator> sub returned undef).

7) In the end parent expects processed data from all busy chidlren and puts processed data to C<data_merge>

8) After having all the children sent processed data they are killed and run returns to the caller.

Note:
 If C<input_iterator> or <process_data> returns reference, it serialize/deserialize data before/after pipe.
 That way you have full control whether data will be serialized on IPC.

=head1 SEE ALSO

L<fork|http://perldoc.perl.org/functions/fork.html>

L<subs::parallel>

L<Parallel::Loops>

L<MCE>

L<IO::Pipely> - pipes that work almost everywhere

L<POE> - portable multitasking and networking framework for any event loop

L<forks>

L<threads>

=head1 DEPENDENCIES

Only core modules are used.

if found it uses Sereal module for serialization instead of Storable as the former is more efficient.

=head1 BUGS

For all bugs please send an email to okharch@gmail.com.

=head1 SOURCE REPOSITORY

See the git source on github
 L<https://github.com/okharch/Parallel-DataPipe>

=head1 COPYRIGHT

Copyright (c) 2013 Oleksandr Kharchenko <okharch@gmail.com>

All right reserved. This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

  Oleksandr Kharchenko <okharch@gmail.com>

=cut
