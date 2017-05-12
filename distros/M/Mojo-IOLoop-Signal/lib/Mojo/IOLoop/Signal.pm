package Mojo::IOLoop::Signal;
use Mojo::Base 'Mojo::EventEmitter';

use Config;
use IO::Handle;
use Mojo::IOLoop;
use Mojo::IOLoop::Stream;
use Scalar::Util 'weaken';

our $VERSION = '0.001';
my %SIGNAME = map { $_ => 1 } split /\s+/, $Config{sig_name};
our %EXCLUDE = map { $_ => 1 } qw(PIPE KILL);

sub _instance {
    state $SELF = __PACKAGE__->_new;
    ref $_[0] ? $_[0] : $SELF
}

sub singleton { _instance(shift) }

sub new { die "Cannot construct Mojo::IOLoop::Signal objects. It's a singleton.\n" }

sub _new {
    my $class = shift;
    my $reactor =  Mojo::IOLoop->singleton->reactor;
    my $is_ev;
    if ($reactor->isa('Mojo::Reactor::EV')) {
        $is_ev = 1;
    } elsif ($reactor->isa('Mojo::Reactor::Poll')) {
        $is_ev = 0;
    } else {
        die "Unsupported reactor: " . ref($reactor);
    }
    bless { keep => {}, is_ev => $is_ev }, $class;
}

sub DESTROY {
    my $self = shift;
    $self->stop;
}

sub stop {
    my $self = _instance(shift);
    if (!$self->{is_ev}) {
        if ($self->{write}) {
            $self->{write}->close;
            $self->{read}->stop;
            $self->{read}->close_gracefully;
            delete $self->{$_} for qw(write read);
        }
        for my $name (keys %{$self->{keep}}) {
            $SIG{$name} = $self->{keep}{$name};
        }
    }
    $self->{keep} = {};
    $self;
}

sub _is_signame {
    my ($class, $name) = @_;
    $SIGNAME{$name} and !$EXCLUDE{$name};
}

sub once {
    my ($self, $name, $cb) = (_instance(shift), @_);
    $self->SUPER::once($name, $cb);
}

sub on {
    my ($self, $name, $cb) = (_instance(shift), @_);
    if ($self->_is_signame($name) and !exists $self->{keep}{$name}) {
        if ($self->{is_ev}) {
            $self->{keep}{$name} = EV::signal($name => sub { $self->emit($name, $name) });
        } else {
            if (!$self->{write}) {
                pipe my $read, my $write;
                $write->autoflush(1);
                $self->{read} = Mojo::IOLoop::Stream->new($read),
                $self->{read}->timeout(0);
                $self->{write} = $write;
                weaken $self;
                $self->{read}->on(read => sub {
                    my (undef, $bytes) = @_;
                    $self->emit($_, $_) for split /\n/, $bytes;
                });
                $self->{read}->start;
            }
            $self->{keep}{$name} = $SIG{$name} || 'DEFAULT';
            $SIG{$name} = sub {
                Mojo::IOLoop->timer(0 => sub {
                    syswrite $self->{write}, "$name\n" or warn "pipe write: $!";
                });
            };
        }
    }
    $self->SUPER::on($name, $cb);
}

sub unsubscribe {
    my ($self, $name, @arg) = (_instance(shift), @_);
    $self->SUPER::unsubscribe($name, @arg);
    if ($self->_is_signame($name) and !$self->has_subscribers($name)) {
        if ($self->{is_ev}) {
            delete $self->{keep}{$name};
        } else {
            $SIG{$name} = delete $self->{keep}{$name};
        }
    }
    if (!%{$self->{keep}}) {
        $self->stop;
    }
    $self;
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojo::IOLoop::Signal - Non-blocking signal handler

=head1 SYNOPSIS

  use Mojo::IOLoop::Signal;

  Mojo::IOLoop::Signal->on(TERM => sub {
    my ($self, $name) = @_;
    warn "Got $name signal";
  });

  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

=head1 DESCRIPTION

Mojo::IOLoop::Signal is a Mojo::IOLoop based, non-blocking signal handler.

=head1 EVENTS

Mojo::IOLoop::Signal inherits all events from L<Mojo::EventEmitter> and can emit the following new ones.


=head2 signal names such as TERM, INT, QUIT, ...

See C<< $Config{sig_name} >> for a complete list.

  $ perl -MConfig -e 'print $Config{sig_name}'
  ZERO HUP INT QUIT ILL TRAP ABRT EMT FPE KILL BUS SEGV SYS PIPE ALRM TERM URG STOP TSTP CONT CHLD TTIN TTOU IO XCPU XFSZ VTALRM PROF WINCH INFO USR1 USR2 IOT

=head1 METHODS

Mojo::IOLoop::Signal inherits all methods from L<Mojo::EventEmitter> and implements the following new ones.

=head2 stop

  Mojo::IOLoop::Signal->stop;

Stop watching signals. You might want to use C<stop> like:

  Mojo::IOLoop::Signal->on(HUP => sub {
    my ($self, $name) = @_;
    # log rotate
  });
  Mojo::IOLoop::Signal->on(TERM => sub {
    my ($self, $name) = @_;
    $self->stop;
  });
  Mojo::IOLoop->start;

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
