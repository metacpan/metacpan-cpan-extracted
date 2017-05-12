package Net::SSH::Any::Test::Isolated::_Slave;

use strict;
use warnings;
use feature qw(say);
use Scalar::Util;

$0 = "$^X (Net::SSH::Any::Test::Isolated::Slave)";
binmode STDOUT;
binmode STDIN;
$| = 1;

use parent 'Net::SSH::Any::Test::Isolated::_Base';
BEGIN { *debug = \$Net::SSH::Any::Test::Isolated::debug };
our $debug;

sub run {
    my $class = shift;
    $class->_new(@_)->_run;
}

sub _new {
    my $class = shift;
    $class->SUPER::_new('slave', \*STDIN, \*STDOUT);
}

sub _run {
    my $self = shift;
    while (1) {
        $self->_send_prompt;
        if (my ($head, @args) = $self->_recv_packet) {
            unless ($head eq 'close!') {
                if (my $method = $self->can("_do_$head")) {
                    #$self->_debug("calling $method(@args)");
                    my @r = eval { $self->$method(@args) };
                    if ($@) {
                        $self->_send_packet(exception => $@)
                    }
                    else {
                        $self->_send_packet(response => @r)
                    }
                }
                else {
                    $self->_send_packet(exception => "Internal error: invalid method $head");
                }
                next;
            }
        }

        # connection closed;
        $self->_debug("connection closed");
        return;
    }
}

sub _send_prompt { shift->_send('go!') }

sub __logger {
    my $self = shift;
    my $fh = shift;
    if ($self) {
        $self->_send_packet(log => @_);
    }
    else {
        print  {$fh} @_
    }
}

sub _do_start {
    my ($self, @opts) = @_;
    $self->_check_state('new');
    require Net::SSH::Any::Test;

    open my($logger_fh), '>', File::Spec->devnull;
    $logger_fh //= \*STDERR; # Just in case!

    my $weak_self = $self;
    Scalar::Util::weaken($weak_self);
    $self->{tssh} = Net::SSH::Any::Test->new(@opts,
                                             logger_fh => $logger_fh,
                                             logger => sub { __logger($weak_self, @_) });
    $self->{state} = 'running';
    1;
}

sub _do_forward {
    my $self = shift;
    my $method = shift;
    my $wantarray = shift;
    $self->_check_state('running');
    if ($wantarray) {
        return $self->{tssh}->$method(@_);
    }
    else {
        return scalar $self->{tssh}->$method(@_);
    }
}

sub _do_peek {
    my ($self, $key) = @_;
    $self->_check_state('running');
    $self->{tssh}{$key};
}

sub _do_poke {
    my ($self, $key, $value) = @_;
    $self->_check_state('running');
    $self->{tssh}{$key} = $value;
}

sub _do_eval {
    my ($self, $code) = @_;
    eval $code;
}

sub _do_stop {
    my $self = shift;
    $self->_check_state('running');
    undef $self->{tssh};
    $self->{state} = 'stopped';
}

sub _do_error {
    my $self = shift;
    $self->_check_state('running');
    my $error = $self->{tssh}->error // return;
    return ($error + 0, $error);
}

1;
