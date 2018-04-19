package Three;

use Modern::Perl '2017';
use strictures 2;

use Moo;
use Exporter ();
use Guard qw(scope_guard);
use IO::Async::Loop;
use MooX::Async;
use Object::Tap;
use Proc::Daemon;
use namespace::clean;

*import = \&Exporter::import;
our @EXPORT = qw( daemonise );

extends MooXAsync('Notifier');

with 'MooX::Role::Logger';

with 'MooX::Async::Console';

has _tcp_console => is => lazy => init_arg => undef,
  clearer   => 1,
  predicate => 1,
  builder   => sub {
    my $self = shift;
    $self->_launch_console(TCP => port => 1234)
  };

after _add_to_loop => sub { $_[0]->add_child($_[0]->_tcp_console) };

before _remove_from_loop => sub {
  $_[0]->remove_child($_[0]->_tcp_console);
  $_[0]->_clear_tcp_console;
};

has pidfn => is => ro => predicate => 1;

has _daemon => is => 'lazy', init_arg => undef, builder =>
  sub { Proc::Daemon->new };

has fork => is => ro => default => 0;

sub daemonise {
  my $self = shift || __PACKAGE__;
  $self = __PACKAGE__->new(@_) if not ref $self and $self eq __PACKAGE__;

  if ($self->fork) {
    my $pid = $self->_daemon->Init; # Propagate its die() on error.
    if ($pid < 0) {
      # Fuckup
      # Unreachable?
      $self->_logger->errorf('Failed to daemonise: ?');
      die;

    } elsif ($pid) {
      # Parent
      $self->_logger->informf('Spawned daemon with process ID: %s', $pid);
      if ($self->has_pidfn) {
        open my $pidfd, '>', $self->pidfile or do {
          # kill child? log?
          die "Cannot create pidfile (child: $pid): $!";
        };
        $pidfd->print($pid . "\n");
      }
      return 0;
    }
  }

  my $loop = IO::Async::Loop->new;
  $loop->add($self);
  scope_guard { $loop->remove($self) };
  $loop->run;
}

event cmd_die => sub {
  my $self = shift;
  my %args = @_;
  $self->_logger->noticef('dying');
  $self->loop->later(sub { $self->loop->stop(1) });
  $args{then}->done('shutdown');
};

event cmd_foo => sub {
  my $self = shift;
  my %args = @_;
  $self->_logger->inform('foo');
  $args{inform}->('this thing is happening');
  $args{then}->done('finished');
};

1;
