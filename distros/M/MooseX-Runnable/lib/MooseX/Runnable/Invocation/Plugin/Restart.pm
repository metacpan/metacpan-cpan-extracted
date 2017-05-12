package MooseX::Runnable::Invocation::Plugin::Restart;

our $VERSION = '0.10';

use Moose::Role;
use MooseX::Types::Moose qw(Str);
use AnyEvent;
use namespace::autoclean;

with 'MooseX::Runnable::Invocation::Plugin::Restart::Base',
  'MooseX::Runnable::Invocation::Plugin::Role::CmdlineArgs';

has 'completion_condvar' => (
    is       => 'ro',
    isa      => 'AnyEvent::CondVar',
    required => 1,
    default  => sub { AnyEvent->condvar },
);

has 'kill_signal' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    default  => sub { 'INT' },
);

has 'restart_signal' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    default  => sub { 'HUP' },
);

sub _build_initargs_from_cmdline {
    my ($class, @args) = @_;
    confess 'Bad args passed to Restart plugin'
      unless @args % 2 == 0;

    my %args = @args;

    my %res;
    if(my $kill = $args{'--kill-signal'}){
        $res{kill_signal} = $kill;
    }
    if(my $res = $args{'--restart-signal'}){
        $res{restart_signal} = $res;
    }
    return \%res;
}

after '_restart_parent_setup' => sub {
    my $self = shift;
    my ($kw, $rw);
    $kw = AnyEvent->signal( signal => $self->kill_signal, cb => sub {
        $self->kill_child;
        undef $kw;
        $self->completion_condvar->send(0); # parent exit code
    });

    $rw = AnyEvent->signal( signal => $self->restart_signal, cb => sub {
        $rw = $rw; # closes over $rw and prevents it from being GC'd
        $self->restart;
    });
};

sub run_parent_loop {
    my $self = shift;
    print {*STDERR} "Control pid is $$\n";
    return $self->completion_condvar->wait;
}

1;
