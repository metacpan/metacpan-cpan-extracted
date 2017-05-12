package Net::SSH::Any::Test::Isolated;

use strict;
use warnings;
use feature qw(say);
use Carp;
use Scalar::Util ();
use Data::Dumper;
use IPC::Open2 qw(open2);

our $debug;

use parent qw(Net::SSH::Any::Test::Isolated::_Base);
use Net::SSH::Any::URI;


sub _default_logger {
    my ($fh, $text) = @_;
    print {$fh} $text;
}

sub _diag_logger {
    require Test::More;
    Test::More::diag($_[1]);
}

sub new {
    my ($class, %opts) = @_;
    my $self = $class->SUPER::_new('client');

    my $logger_fh = delete $opts{logger_fh} // \*STDERR;
    open my $logger_fh_dup, '>>&', $logger_fh;
    $self->{logger_fh} = $logger_fh_dup;
    my $logger = delete $opts{logger} // \&_default_logger;
    unless (ref $logger) {
        if ($logger eq 'diag') {
            $logger = \&_diag_logger;
        }
        else {
            croak "Bad logger argument '$logger'";
        }
    }
    $self->{logger} = $logger;
    $self->{perl} = $opts{local_perl_cmd} // $^X // 'perl';
    $self->_bootstrap;
    $self->_start(%opts);

    $self;
}

sub _log {
    my $self = shift;
    $self->{logger}->($self->{logger_fh}, @_);
}

sub _bootstrap {
    my $self = shift;
    $self->_check_state('new');
    my $perl = $self->{perl} or return;
    $self->{pid} = open2($self->{in}, $self->{out}, $^X);

    my $old = select($self->{out});
    $| = 1;
    select $old;

    my $inc = Data::Dumper::Dumper([grep defined && !ref, @INC]);
    my $debug_as_str = ($debug ? -1 : 'undef');

    my $code = <<EOC;

use lib \@{$inc};

use strict;
use warnings;

\$Net::SSH::Any::Test::Isolated::debug = $debug_as_str;

use Net::SSH::Any::Test::Isolated::_Slave;
Net::SSH::Any::Test::Isolated::_Slave->run;

__END__
EOC

    $self->_send($code);
    $self->{state} = 'bootstrapped';
}

sub _start {
    my $self = shift;
    $self->_check_state('bootstrapped');
    $self->_rpc(start => @_);
    $self->{state} = 'running';
}


sub _wait_for_prompt {
    my $self = shift;
    while (1) {
        my $out = $self->_recv_packet // return;
        return $out eq 'go!';
        $self->_fatal_error("Unexpected packet $out received");
    }
}

sub _rpc {
    my $self = shift;
    my $method = shift;
    $self->_wait_for_prompt;
    $self->_send_packet($method => @_);
    if (my ($head, @res) = $self->_recv_packet) {
        if ($head eq 'response') {
            return (wantarray ? @res : $res[0]);
        }
        elsif ($head eq 'exception') {
            die $res[0];
        }
        else {
            $self->_fatal_error("Internal error: unexpected response $head");
        }
    }
    else {
        $self->_fatal_error("Connection with slave lost")
    }
}

sub _peek { shift->_rpc(peek => @_) }
sub _poke { shift->_rpc(poke => @_) }
sub _eval { shift->_rpc(eval => @_) }

sub error {
    my $self = shift;
    my ($num, $str) = $self->_rpc('error');
    $num ? Scalar::Util::dualvar($num, $str) : $num;
}

sub is_localhost {
    my $self = shift;
    # avoid passing the client object around.
    $self->_check_state('running');
    $self->_rpc(forward => 'is_localhost', wantarray)
}

sub _fatal_error {
    my ($self, $exception) = @_;
    $self->_disconnect;
    croak $exception;
}

sub _stop {
    my $self = shift;
    if ($self->{state} eq 'running') {
        $self->_rpc('stop');
        $self->_send('close!');
        $self->{state} = 'stopped';
    }
}

sub _disconnect {
    my $self = shift;
    if (my $pid = $self->{pid}) {
        $self->_debug("closing pipes");
        close $self->{in};
        close $self->{out};
        waitpid $pid, 0;
    }
    $self->{state} = 'disconnected';
}

sub DESTROY {
    my $self = shift;
    $self->_stop;
    $self->_disconnect;
}

sub AUTOLOAD {
    our $AUTOLOAD;
    my $name = $AUTOLOAD;
    $name =~ s/.*://;
    if ($name =~ /^[a-z]\w+$/i) {
        my $sub = sub {
            my $self = shift;
            $self->_check_state('running');
            $self->_rpc(forward => $name, wantarray, @_)
        };
        no strict 'refs';
        *{$AUTOLOAD} = $sub;
        goto &$sub;
    }
    croak "Can't locate object method $name via package ".__PACKAGE__;
}

1;
