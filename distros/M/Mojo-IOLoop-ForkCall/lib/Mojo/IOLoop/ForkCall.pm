package Mojo::IOLoop::ForkCall;

use Mojo::Base 'Mojo::EventEmitter';

our $VERSION = '0.19';
$VERSION = eval $VERSION;

use Mojo::IOLoop;
use IO::Pipely 'pipely';
use POSIX ();
use Scalar::Util ();

use Perl::OSType 'is_os_type';
use constant IS_WINDOWS => is_os_type('Windows');
use constant IS_CYGWIN  => $^O eq 'cygwin';

use Exporter 'import';
our @EXPORT_OK = qw/fork_call/;

has 'ioloop'       => sub { Mojo::IOLoop->singleton };
has 'serializer'   => sub { require Storable; \&Storable::freeze };
has 'deserializer' => sub { require Storable; \&Storable::thaw   };
has 'weaken'       => 0;

sub run {
  my ($self, @args) = @_;
  my $delay = $self->ioloop->delay(sub{ $self->_run(@args) });
  $delay->catch(sub{ $self->emit( error => pop ) });
  return $self;
}

sub _run {
  my ($self, $job) = (shift, shift);
  my ($args, $cb);
  $args = shift if @_ and ref $_[0] eq 'ARRAY';
  $cb   = shift if @_;

  my ($r, $w) = pipely;

  my $child = fork;
  die "Failed to fork: $!" unless defined $child;

  if ($child == 0) {
    # child

    # cleanup running loops
    $self->ioloop->reset;
    delete $self->{ioloop}; # not sure this is needed
    Mojo::IOLoop->reset;
    close $r;

    my $serializer = $self->serializer;

    local $@;
    my $res = eval {
      local $SIG{__DIE__};
      $serializer->([undef, $job->(@$args)]);
    };
    $res = $serializer->([$@]) if $@;

    _send($w, $res);

    # attempt to generalize exiting from child cleanly on all platforms
    # adapted from POE::Wheel::Run mostly
    eval { POSIX::_exit(0) } unless IS_WINDOWS;
    eval { CORE::kill KILL => $$ };
    exit 0;

  } else {
    # parent
    close $w;
    my $parent = $$;
    $self->emit( spawn => $child );

    my $stream = Mojo::IOLoop::Stream->new($r)->timeout(0);
    $self->ioloop->stream($stream);

    my $buffer = '';
    $stream->on( read  => sub { $buffer .= $_[1] } );

    Scalar::Util::weaken($self) if $self->weaken;

    $stream->on( error => sub { $self->emit( error => $_[1] ) if $self } );

    my $deserializer = $self->deserializer;
    $stream->on( close => sub {
      return unless $$ == $parent; # not my stream!
      local $@;

      # clean up the zombie. It won't block, it's already dead.
      waitpid $child, 0;

      # attempt to deserialize, emit error and return early
      my $res = eval { $deserializer->($buffer) };
      if ($@) {
        $self->emit( error => $@ ) if $self;
        return;
      }

      # call the callback, emit error if it fails
      eval { $self->$cb(@$res) if $cb };
      $self->emit( error => $@ ) if $@ and $self;

      # emit the finish event, emit error if IT fails
      eval { $self->emit( finish => @$res ) if $self };
      $self->emit( error => $@ ) if $@ and $self;

    });
  }
}

## functions

sub fork_call (&@) {
  my $job = shift;
  my $cb  = pop;
  return __PACKAGE__->new->run($job, \@_, sub {
    # local $_ = shift; #TODO think about this
    shift;
    local $@ = shift;
    $cb->(@_);
  });
}

sub _send {
  my ($h, $data) = @_;
  if (IS_WINDOWS || IS_CYGWIN) {
    my $len = length $data;
    my $written = 0;
    while ($written < $len) {
      my $count = syswrite $h, $data, 65536, $written;
      unless (defined $count) { warn $!; last }
      $written += $count;
    }
  } else {
    warn $! unless defined syswrite $h, $data;
  }
}

1;


__END__

=head1 NAME

Mojo::IOLoop::ForkCall - run blocking functions asynchronously by forking

=head1 SYNOPSIS

 use Mojo::IOLoop::ForkCall
 my $fc = Mojo::IOLoop::ForkCall->new;
 $fc->run(
   \&expensive_function,
   ['arg', 'list'],
   sub { my ($fc, $err, @return) = @_; ... }
 );
 $fc->ioloop->start unless $fc->ioloop->is_running;

=head1 DESCRIPTION

Asynchronous programming can be benefitial for performance, however not all functions are
written for nonblocking interaction and external processes almost never are.
Still, all is not lost.

By forking the blocking call into a new process, the main thread may continue to run non-blocking, while the blocking call evaluates.
Mojo::IOLoop::ForkCall manages the forking and will emit an event (or execute a callback) when the forked process completes.
Return values are serialized and sent from the child to the parent via an appropriate pipe for your platform.

This module is heavily inspired by L<AnyEvent::Util>'s C<fork_call>.

For simple cases in a L<Mojolicious> web app, a helper is also available in L<Mojolicious::Plugin::ForkCall>.

=head1 WARNINGS

Some platforms do not fork well, some platforms don't pipe well.
This module and the libraries it relies on do their best to smooth over these differences.
Still some attention should be paid to platform specific usage, especially on Windows.
Efficiency/performance on Windows is not likely to be very good.

N.B. There was previously a warning about using event-based programming in the child.
As of version 0.10, this warning is lifted as the child process will reset the singleton loop, as well as the loop refered to in the ForkCall instance.
Still, use with caution, and no running with scissors!

=head1 EVENTS

This module inherits all events from L<Mojo::EventEmitter> and implements the following addtional ones.

=head2 error

 $fc->on( error => sub { my ($fc, $err) = @_; } );

Emitted in the parent when the parent process encounters an error.
Fatal if not handled.

=head2 finish

 $fc->on( finish => sub {
   my ($fc, $err, @return_values) = @_;
   ...
 });

Emitted in the parent process once the child process completes and sends its results.
The callback is passed the ForkCall instance, any error, then all deserialized results from the child.
Note that this event is called for each C<run> completion; to schedule a callback for a single call, pass the callback to C<run> itself.

=head2 spawn

 $fc->on( spawn => sub { my ($fc, $child_pid) = @_; ... } );

Emitted in the parent process when a child process is spawned.
The callback is passed the ForkCall instance and the child pid.

=head1 ATTRIBUTES

This module inherits all attributes from L<Mojo::EventEmitter> and implements the following additional ones.

=head2 ioloop

The L<Mojo::IOLoop> instance which is used internally.
Defaults to C<< Mojo::IOLoop->singleton >>.

=head2 serializer

A code reference to serialize the results of the child process to send to the parent.
Note that as this code reference is called in the child, some care should be taken when setting it to something other than the defaults.
Defaults to C<\&Storable::freeze>.

The code reference will be passed a single array reference.
The first argument will be any error or undef if no error occured.
If there was no error, the remaining elements of the array will be the values returned by the job (evaluated in list context).

=head2 deserializer

A code reference used to deserialize the results of the child process.
Defaults to C<\&Storable::thaw>.
This should be the logical inverse of the C<serializer>.

=head2 weaken

If true, the reference to the ForkCall object will be weakened in the internals to prevent a possible memory leak should the child process never close.
In this case, if you do not maintain a reference to the ForkCall object, the first argument to the callback will be undef.
Additionally, the finish event may not be emitted.
Defaults to false.
Do not use this unless you know what you are doing and why!

=head1 METHODS

This module inherits all METHODS from L<Mojo::EventEmitter> and implements the following additional ones.

=head2 run

 my $fc = Mojo::IOLoop::ForkCall->new;
 $fc = $fc->run(
   sub { my @args = @_; ... return @res },
   \@args,
   sub { my ($fc, $err, @return_values) = @_; ... }
 );

Takes a code reference (required) which is the job to be run on the child.
If the next argument is an array reference, these will be passed to the child job.
If the last argument is a code reference, it will be called immediately before the finish event is emitted, its arguments are the same as the C<finish> event.


=head1 EXPORTED FUNCTIONS

Upon request this module exports the following functions.

=head2 fork_call

 fork_call { my @args = @_; child code; return @res } @args, sub { my @res = @_; parent callback }

This function is a drop-in replacement for L<AnyEvent::Util>'s C<fork_call>, with the exception of the fork limiting/queueing that that function provides.
Because it is attempting to mimic that function the api is different to that provided by the OO interface descibed above.
This function is provided for ease of porting from AnyEvent's function; for new code, please use the OO syntax.

The function takes a block to be performed in the child, a list of arguments to pass to the block, and a callback to be run on completion.
Note that the callback is required and that the arguments are given as a list, not an arrayreference (unlike the OO style).
The callback will receive the deserialized return values from the child block as C<@_>.
Any error will be available in C<$@>.

The underlying ForkCall object will use its default attributes.
The return value is the created ForkCall instance.

WARNING: In Perl versions before 5.14, if the parent callback dies, the exception is silently ignored.
This is a limitation in those Perl interpreters and was fixed in L<5.14|perl5140delta/"Exception Handling">.
Yet another reason to use the object-oriented interface, which does not suffer from this limitation!

=head1 SEE ALSO

=over

=item L<Mojo::IOLoop>

=item L<AnyEvent::Util>

=item L<IO::Pipely>

=back

=head1 FUTURE WORK

=over

=item *

Investigate hooking into the L<Mojo::IOLoop::Stream/timeout> event to kill runaway children.

=back

=head1 KNOWN ISSUES

=over

=item *

Although in concept this module works on windows, in practical cases running real-world apps with this module on windows might spectularly crash.
This is unfortunately not solvable from the Perl level and must be addressed in the C level interpreter code.
The good news is that recent interpreters seem not to be having this issue.
See L<https://github.com/jberger/Mojo-IOLoop-ForkCall/issues/5>.

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojo-IOLoop-ForkCall>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 CONTRIBUTORS

=over

=item Dan Book (Grinnz)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2015 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
