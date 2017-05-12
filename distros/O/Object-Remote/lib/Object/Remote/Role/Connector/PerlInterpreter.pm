package Object::Remote::Role::Connector::PerlInterpreter;

use IPC::Open3;
use IO::Handle;
use Symbol;
use Object::Remote::Logging qw(:log :dlog router);
use Object::Remote::ModuleSender;
use Object::Remote::Handle;
use Object::Remote::Future;
use Scalar::Util qw(blessed weaken);
use Moo::Role;

with 'Object::Remote::Role::Connector';

has module_sender => (is => 'lazy');
has watchdog_timeout => ( is => 'ro', required => 1, default => sub { undef });
has forward_env => (is => 'ro', required => 1, builder => 1);
has perl_command => (is => 'lazy');
has pid => (is => 'rwp');
has connection_id => (is => 'rwp');

#if no child_stderr file handle is specified then stderr
#of the child will be connected to stderr of the parent
has stderr => ( is => 'rw', default => sub { undef } );

BEGIN { router()->exclude_forwarding; }

sub _build_module_sender {
  my ($hook) =
    grep {blessed($_) && $_->isa('Object::Remote::ModuleLoader::Hook') }
      @INC;
  return $hook ? $hook->sender : Object::Remote::ModuleSender->new;
}

#By policy object-remote does not invoke a shell
sub _build_perl_command {
  my $perl_bin = 'perl';

  if (exists $ENV{OBJECT_REMOTE_PERL_BIN}) {
    $perl_bin = $ENV{OBJECT_REMOTE_PERL_BIN};
  }
  return [$perl_bin, '-'];
}

sub _build_forward_env {
  return [qw(
    OBJECT_REMOTE_PERL_BIN
    OBJECT_REMOTE_LOG_LEVEL OBJECT_REMOTE_LOG_FORMAT OBJECT_REMOTE_LOG_SELECTIONS
    OBJECT_REMOTE_LOG_FORWARDING
  )];
}

around connect => sub {
  my ($orig, $self) = (shift, shift);
  my $f = $self->$start::start($orig => @_);
  return future {
    $f->on_done(sub {
      my ($conn) = $f->get;
      $self->_setup_watchdog_reset($conn);
      my $sub = $conn->remote_sub('Object::Remote::Logging::init_remote_logging');
      $sub->('Object::Remote::Logging', router => router(), connection_id => $conn->_id);
      Object::Remote::Handle->new(
        connection => $conn,
        class => 'Object::Remote::ModuleLoader',
        args => { module_sender => $self->module_sender }
      )->disarm_free;
      require Object::Remote::Prompt;
      Object::Remote::Prompt::maybe_set_prompt_command_on($conn);
    });
    $f;
  } 2;
};

sub final_perl_command { shift->perl_command }

sub _start_perl {
  my $self = shift;
  my $given_stderr = $self->stderr;
  my $foreign_stderr;

  Dlog_verbose {
    s/\n/ /g; "invoking connection to perl interpreter using command line: $_"
  } @{$self->final_perl_command};

  if (defined($given_stderr)) {
    #if the stderr data goes to an existing file handle
    #an anonymous file handle is required
    #as the other half of a pipe style file handle pair
    #so the file handles can go into the run loop
    $foreign_stderr = gensym();
  } else {
    #if no file handle has been specified
    #for the child's stderr then connect
    #the child stderr to the parent stderr
    $foreign_stderr = ">&STDERR";
  }

  my $pid = open3(
    my $foreign_stdin,
    my $foreign_stdout,
    $foreign_stderr,
    @{$self->final_perl_command},
  ) or die "Failed to run perl at '$_[0]': $!";

  $self->_set_pid($pid);

  if (defined($given_stderr)) {
    Dlog_debug { "Child process STDERR is being handled via run loop" };

    Object::Remote->current_loop
                  ->watch_io(
                      handle => $foreign_stderr,
                      on_read_ready => sub {
                        my $buf = '';
                        my $len = sysread($foreign_stderr, $buf, 32768);
                        if (!defined($len) or $len == 0) {
                          log_trace { "Got EOF or error on child stderr, removing from watcher" };
                          $self->stderr(undef);
                          Object::Remote->current_loop->unwatch_io(
                                         handle => $foreign_stderr,
                                         on_read_ready => 1
                                       );
                          } else {
                            Dlog_trace { "got $len characters of stderr data for connection" };
                            print $given_stderr $buf or die "could not send stderr data: $!";
                          }
                         }
                      );
  }

  return ($foreign_stdin, $foreign_stdout, $pid);
}

sub _open2_for {
  my $self = shift;
  my ($foreign_stdin, $foreign_stdout, $pid) = $self->_start_perl(@_);
  my $to_send = $self->fatnode_text;
  log_debug { my $len = length($to_send); "Sending contents of fat node to remote node; size is '$len' characters" };
  Object::Remote->current_loop
                ->watch_io(
                    handle => $foreign_stdin,
                    on_write_ready => sub {
                      my $len = syswrite($foreign_stdin, $to_send, 32768);
                      if (defined $len) {
                        substr($to_send, 0, $len) = '';
                      }
                      # if the stdin went away, we'll never get Shere
                      # so it's not a big deal to simply give up on !defined
                      if (!defined($len) or 0 == length($to_send)) {
                        log_trace { "Got EOF or error when writing fatnode data to filehandle, unwatching it" };
                        Object::Remote->current_loop
                                      ->unwatch_io(
                                          handle => $foreign_stdin,
                                          on_write_ready => 1
                                      );
                      } else {
                          log_trace { "Sent $len bytes of fatnode data to remote side" };
                      }
                    }
                  );
  return ($foreign_stdin, $foreign_stdout, $pid);
}

sub _setup_watchdog_reset {
  my ($self, $conn) = @_;
  my $timer_id;

  return unless $self->watchdog_timeout;

  Dlog_trace { "Creating Watchdog management timer for connection id $_" } $conn->_id;

  weaken($conn);

  $timer_id = Object::Remote->current_loop->watch_time(
    every => $self->watchdog_timeout / 3,
    code => sub {
      unless(defined($conn)) {
        log_warn { "Weak reference to connection in Watchdog was lost, terminating update timer $timer_id" };
        Object::Remote->current_loop->unwatch_time($timer_id);
        return;
      }

      unless($conn->is_valid) {
        log_warn { "Watchdog timer found an invalid connection, removing the timer" };
        Object::Remote->current_loop->unwatch_time($timer_id);
        return;
      }

      Dlog_trace { "Reseting Watchdog for connection id $_" } $conn->_id;
      #we do not want to block in the run loop so send the
      #update off and ignore any result, we don't need it
      #anyway
      $conn->send_class_call(0, 'Object::Remote::WatchDog', 'reset');
    }
  );

  $conn->on_close->on_ready(sub {
    log_debug { "Removing watchdog for connection that is now closed" };
    Object::Remote->current_loop->unwatch_time($timer_id);
  });
}

sub fatnode_text {
  my ($self) = @_;
  my $connection_timeout = $self->timeout;
  my $watchdog_timeout = $self->watchdog_timeout;
  my $text = '';

  require Object::Remote::FatNode;

  if (defined($connection_timeout)) {
    $text .= "alarm($connection_timeout);\n";
  }

  if (defined($watchdog_timeout)) {
    $text .= "my \$WATCHDOG_TIMEOUT = $watchdog_timeout;\n";
  } else {
    $text .= "my \$WATCHDOG_TIMEOUT = undef;\n";
  }

  $text .= $self->_create_env_forward(@{$self->forward_env});

  #Action at a distance but at least it's not spooky - the logging
  #system needs to know if a node is remote but there is a period
  #during init where the remote connection information has not been
  #setup on the remote side yet so this flag allows a graceful
  #degredation to happen
  $text .= '$Object::Remote::FatNode::REMOTE_NODE = "1";' . "\n";

  $text .= <<'END';
$INC{'Object/Remote/FatNode.pm'} = __FILE__;
$Object::Remote::FatNode::DATA = <<'ENDFAT';
END
  $text .= do { no warnings 'once'; $Object::Remote::FatNode::DATA };
  $text .= "ENDFAT\n";
  $text .= <<'END';
eval $Object::Remote::FatNode::DATA;
die $@ if $@;
END

  $text .= "__END__\n";
  return $text;
}

sub _create_env_forward {
  my ($self, @env_names) = @_;
  my $code = '';

  foreach my $name (@env_names) {
    next unless exists $ENV{$name};
    my $value = $ENV{$name};
    $name =~ s/'/\\'/g;
    if(defined($value)) {
      $value =~ s/'/\\'/g;
      $value = "'$value'";
    } else {
      $value = 'undef';
    }
    $code .= "\$ENV{'$name'} = $value;\n";
  }

  return $code;
}

1;

=head1 NAME

Object::Remote::Role::Connector::PerlInterpreter - Role for connections to a Perl interpreter

=head1 SYNOPSIS

  use Object::Remote;

  my %opts = (
    perl_command => [qw(nice -n 10 perl -)],
    watchdog_timeout => 120, stderr => \*STDERR,
  );

  my $local_connection = Object::Remote->connect('-', %opts);
  my $hostname = Sys::Hostname->can::on($remote, 'hostname');

=head1 DESCRIPTION

This is the role that supports connections to a Perl interpreter that is executed in a
different process. The new Perl interpreter can be either on the local or a remote machine
and is configurable via arguments passed to the constructor.

=head1 ARGUMENTS

=over 4

=item perl_command

By default the Perl interpeter will be executed as "perl -" but this can be changed by
providing an array reference as the value to the perl_command attribute during construction.

=item stderr

If this value is defined then it will be used as the file handle that receives the output
of STDERR from the Perl interpreter process and I/O will be performed by the run loop in a
non-blocking way. If the value is undefined then STDERR of the remote process will be connected
directly to STDERR of the local process with out the run loop managing I/O. The default value
is undefined.

There are a few ways to use this feature. By default the behavior is to form one unified STDERR
across all of the Perl interpreters including the local one. For small scale and quick operation
this offers a predictable and easy to use way to get at error messages generated anywhere. If
the local Perl interpreter crashes then the remote Perl interpreters still have an active STDERR
and it is possible to still receive output from them. This is generally a good thing but can
cause issues.

When using a file handle as the output for STDERR once the local Perl interpreter is no longer
running there is no longer a valid STDERR for the remote interpreters to send data to. This means
that it is no longer possible to receive error output from the remote interpreters and that the
shell will start to kill off the child processes. Passing a reference to STDERR for the local
interpreter (as the SYNOPSIS shows) causes the run loop to manage I/O, one unified STDERR for
all Perl interpreters that ends as soon as the local interpreter process does, and the shell will
start killing children when the local interpreter exits.

It is also possible to pass in a file handle that has been opened for writing. This would be
useful for logging the output of the remote interpreter directly into a dedicated file.

=item watchdog_timeout

If this value is defined then it will be used as the number of seconds the watchdog will wait
for an update before it terminates the Perl interpreter process. The default value is undefined
and will not use the watchdog. See C<Object::Remote::Watchdog> for more information.

=back

=head1 SEE ALSO

=over 4

=item C<Object::Remote>

=back

=cut
