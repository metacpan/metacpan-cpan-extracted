package Net::SSH::Any::OS::AnyEvent;

use strict;
use warnings;

use Net::SSH::Any::Util qw($debug _debug _debug_hexdump);
use Net::SSH::Any::Constants qw(SSHA_LOCAL_IO_ERROR);
require Net::SSH::Any::OS::_Base;
our @ISA = qw(Net::SSH::Any::OS::_Base);

use AnyEvent::Util qw(portable_pipe portable_socketpair);

use Carp;
our @CARP_NOT = ('Net::SSH::Any::Backend::_Cmd');

sub socketpair {
    my ($os, $any) = @_;
    my ($a, $b) = portable_socketpair or do {
        $any->_set_error(SSHA_LOCAL_IO_ERROR, "AnyEvent::Util::portable_socketpair failed: $!");
        return;
    };
    ($a, $b)
}

sub pipe {
    my ($os, $any) = @_;
    my ($r, $w) = portable_pipe or do {
        $any->_set_error(SSHA_LOCAL_IO_ERROR, "AnyEvent::Util::portable_pipe failed: $!");
        return;
    };
    ($r, $w);
}

sub open4 {
    my ($os, $any, $fhs, $close, $pty, $stderr_to_stdout, @cmd) = @_;

    my $pid;
    my @opts = ('$$' => \$pid, close_all => 1);

    push @opts, '<' => $fhs->[0] if defined $fhs->[0];
    push @opts, '>' => $fhs->[1] if defined $fhs->[1];
    if ($stderr_to_stdout) {
        if (defined $fhs->[1]) {
            push @opts, '2>' => $fhs->[1]
        }
        else {
            push @opts, '2>' => \*STDOUT;
        }
    }
    else {
        push @opts, '2>' => $fhs->[2] if defined $fhs->[2];
    }

    # push @opts, on_prepare => sub { close $_ for @$close };

    my $cv = AnyEvent::Util::run_cmd(\@cmd, @opts);

    $debug and $debug & 1024 and _debug("cv: $cv");

    return { pid => $pid,
             cv => $cv };
}

sub export_proc {
    my ($os, $any, $proc) = @_;
    undef $proc->{cv};
    $proc->{pid};
}

my @retriable = (Errno::EINTR, Errno::EAGAIN);
push @retriable, Errno::EWOULDBLOCK if Errno::EWOULDBLOCK != Errno::EAGAIN;


sub io3 {
    my ($os, $any, $proc, $timeout, $data, $in, $out, $err) = @_;

    my $bout = '';
    my $berr = '';
    my ($inw, $wout, $werr);
    my $cv = AE::cv;
    $cv->begin;

    if (@$data) {
        $cv->begin;
        $inw = AE::io $in, 1, sub {
            my $bytes = syswrite($in, $data->[0], 2048);
            if ($bytes) {
                substr($data->[0], 0, $bytes, '');
                shift @$data unless length $data->[0];
                return unless @$data;
            }
            elsif (not defined $bytes and grep $! == $_, @retriable) {
                return
            }
            undef $inw;
            close $in;
            $cv->end;
            $debug and $debug & 1024 and _debug "in done";
        }
    }

    my $write = sub {
        my ($fh, $buf, $w) = @_;
        my $bytes = sysread($fh, $$buf, 20480, length $$buf);
        unless ($bytes) {
            if (defined $bytes or not grep $! == $_, @retriable) {
                close $fh;
                undef $$w;
                $cv->end;
                $debug and $debug & 1024 and _debug "out or err done";
            }
        }
    };

    if ($out) {
        $cv->begin;
        $wout = AE::io $out, 0, sub { $write->($out, \$bout, \$wout) };
    }

    if ($err) {
        $cv->begin;
        $werr = AE::io $err, 0, sub { $write->($err, \$berr, \$werr) };
    }

    $cv->end;
    $cv->recv;
    $debug and $debug & 1024 and _debug "waiting for child";
    $proc->{cv}->recv;

    return ($bout, $berr);
}

1;
