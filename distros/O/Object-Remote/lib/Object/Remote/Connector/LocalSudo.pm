package Object::Remote::Connector::LocalSudo;

use Object::Remote::Logging qw (:log :dlog);
use Symbol qw(gensym);
use Module::Runtime qw(use_module);
use IPC::Open3;
use Moo;

extends 'Object::Remote::Connector::Local';

has target_user => (is => 'ro', required => 1);

has password_callback => (is => 'lazy');

sub _build_password_callback {
  my ($self) = @_;
  my $pw_prompt = use_module('Object::Remote::Prompt')->can('prompt_pw');
  my $user = $self->target_user;
  return sub {
    $pw_prompt->("sudo password for ${user}", undef, { cache => 1 })
  }
}

has sudo_perl_command => (is => 'lazy');

sub _build_sudo_perl_command {
  my ($self) = @_;
  return
    'sudo', '-S', '-u', $self->target_user, '-p', "[sudo] password please\n",
    'perl', '-MPOSIX=dup2',
            '-e', 'print STDERR "GO\n"; exec(@ARGV);',
    $self->perl_command;
}

sub _start_perl {
  my $self = shift;
  my $sudo_stderr = gensym;
  my $pid = open3(
    my $foreign_stdin,
    my $foreign_stdout,
    $sudo_stderr,
    @{$self->sudo_perl_command}
  ) or die "open3 failed: $!";
  chomp(my $line = <$sudo_stderr>);
  if ($line eq "GO") {
    # started already, we're good
  } elsif ($line =~ /\[sudo\]/) {
    my $cb = $self->password_callback;
    die "sudo sent ${line} but we have no password callback"
      unless $cb;
    print $foreign_stdin $cb->($line, @_), "\n";
    chomp($line = <$sudo_stderr>);
    if ($line and $line ne 'GO') {
      die "sent password and expected newline from sudo, got ${line}";
    }
    elsif (not $line) {
      chomp($line = <$sudo_stderr>);
      die "sent password but next line was ${line}"
        unless $line eq "GO";
    }
  } else {
    die "Got inexplicable line ${line} trying to sudo";
  };
  Object::Remote->current_loop
                ->watch_io(
                    handle => $sudo_stderr,
                    on_read_ready => sub {
                      Dlog_debug { "LocalSudo: Preparing to read data from $_" } $sudo_stderr;
                      if (sysread($sudo_stderr, my $buf, 32768) > 0) {
                        log_trace { "LocalSudo: successfully read data, printing it to STDERR" };
                        print STDERR $buf;
                        log_trace { "LocalSudo: print() to STDERR is done" };
                      } else {
                        log_debug { "LocalSudo: received EOF or error on file handle, unwatching it" };
                        Object::Remote->current_loop
                                      ->unwatch_io(
                                          handle => $sudo_stderr,
                                          on_read_ready => 1
                                        );
                      }
                    }
                  );
  return ($foreign_stdin, $foreign_stdout, $pid);
};

no warnings 'once';

push @Object::Remote::Connection::Guess, sub {
  for ($_[0]) {
    # username followed by @
    if (defined and !ref and /^ ([^\@]*?) \@ $/x) {
      shift(@_);
      return __PACKAGE__->new(@_, target_user => $1);
    }
  }
  return;
};

1;
