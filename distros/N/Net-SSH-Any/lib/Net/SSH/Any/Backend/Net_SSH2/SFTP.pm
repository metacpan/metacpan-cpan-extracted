package Net::SSH::Any::Backend::Net_SSH2::SFTP;

use strict;
use warnings;

use Net::SSH::Any::Util qw($debug _debug);
use Net::SSH::Any::Constants qw(SSHA_CONNECTION_ERROR);

use Carp;
our @CARP_NOT = qw(Net::SFTP::Foreign);

sub _new {
    my ($class, $any, $dpipe) = @_;
    my $self = { any => $any,
                 dpipe => $dpipe };
    $dpipe->blocking(0);
    bless $self, $class;
}

sub _defaults { ( queue_size => 32) }

sub _dpipe_error {
    my $self = shift;
    my $error =  $self->{dpipe}->error;
    join (": ", @_, sprintf("%s (%d)", $error, $error));
}

sub _conn_failed {
    my ($self, $sftp, @msg) = @_;
    $sftp->_conn_failed($self->_dpipe_error(@msg))
}


sub _conn_lost {
    my ($self, $sftp, @msg) = @_;
    $sftp->_conn_lost(undef, undef, $self->_dpipe_error(@msg));
}

sub _init_transport {}

sub _after_init {}

sub _do_io {
    my ($self, $sftp, $timeout) = @_;
    my $dpipe = $self->{dpipe};
    return undef if $self->{any}->error == SSHA_CONNECTION_ERROR;

    my $bin = \$sftp->{_bin};
    my $bout = \$sftp->{_bout};
    my $deadline;
    my $len;
    my $first = 1;
    while (1) {
        my $delay = not $first;

        if ($first) {
            undef $first;
        }
        else {
            if (length $$bout) {
                my $bytes = syswrite $dpipe, $$bout;
                if ($bytes) {
                    $delay = 0;
                    substr $$bout, 0, $bytes, '';
                }
                elsif (defined $bytes or $! != Errno::EAGAIN()) {
                    $self->_conn_lost($sftp, "write failed");
                    return undef;
                }
            }
        }

        $debug and $debug & 4096 and _debug "SFTP reading...";
        my $bytes = sysread $dpipe, $$bin, 64 * 1024, length($$bin);
        $debug and $debug & 4096 and _debug "SFTP read " . ($bytes//'<undef>') . " bytes";
        if ($bytes) {
            $delay = 0
        }
        elsif (defined $bytes or $! != Errno::EAGAIN()) {
            $self->_conn_lost($sftp, "read failed");
            return undef;
        }

        my $lbin = length $$bin;
        $debug and $debug & 4096 and _debug "SFTP buffers, input: $lbin, ouput: ".length($$bout);

        if (defined $len) {
            return 1 if $lbin >= $len;
        }
        elsif ($lbin >= 4) {
            $len = 4 + unpack N => $$bin;
            $debug and $debug & 4096 and _debug "receiving packet of $len bytes";
            if ($len > 256 * 1024) {
                $sftp->_set_status(Net::SFTP::Foreign::Constants::SSH2_FX_BAD_MESSAGE);
                $sftp->_set_error(Net::SFTP::Foreign::Constants::SFTP_ERR_REMOTE_BAD_MESSAGE,
                                  "bad remote message received");
                return undef;
            }
            return 1 if $lbin >= $len;
        }

        if ($delay) {
            if (defined $timeout) {
                return unless $timeout;
                if (defined $deadline) {
                    return undef if $deadline < time;
                }
                else {
                    $deadline = time + $timeout + 1;
                }
            }
            my ($rv, $wv);
            vec ($rv='', fileno($dpipe), 1) = 1;
            $wv = $rv if length $$bout;
            select ($rv, $wv, undef, 0.1);
        }
        else {
            undef $deadline
        }
    }
}

sub DESTROY {
    my $self = shift;
    local ($@, $!, $?, $SIG{__DIE__});
    eval { close $self->{dpipe} };
}

1;
