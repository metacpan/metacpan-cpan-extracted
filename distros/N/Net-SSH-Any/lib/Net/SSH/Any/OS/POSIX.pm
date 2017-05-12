package Net::SSH::Any::OS::POSIX;

use strict;
use warnings;

use Carp;
use POSIX ();
use Fcntl ();
use Socket;
use Net::SSH::Any::Util qw($debug _debug _debug_hexdump _first_defined _warn);
use Net::SSH::Any::Constants qw(:error);
use File::Spec;
use Time::HiRes ();
use Errno;

require Net::SSH::Any::OS::_Base;
our @ISA = qw(Net::SSH::Any::OS::_Base);

sub _fileno_dup_over {
    my ($good_fn, $fh) = @_;
    if (defined $fh) {
        my $fn = fileno $fh;
        for (1..5) {
            $fn >= $good_fn and return $fn;
            $fn = POSIX::dup($fn);
        }
        POSIX::_exit(255);
    }
    undef;
}

sub has_working_socketpair { 1 }

sub socketpair {
    my $any = shift;
    my ($a, $b);
    unless (CORE::socketpair($a, $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC)) {
        $any->_set_error(SSHA_LOCAL_IO_ERROR, "socketpair failed: $!");
        return;
    }
    $debug and $debug & 1024 and _debug "socketpair => $a (", fileno($a), "), $b (", fileno($b), ")";
    ($a, $b);
}

sub make_dpipe {
    my ($any, $proc, $dpipe, $out) = @_;
    defined $out and die "internal error: out should be undefined but is $out";
    require Net::SSH::Any::OS::POSIX::DPipe;
    Net::SSH::Any::OS::POSIX::DPipe->_upgrade_fh_to_dpipe($dpipe, $any, $proc);
    $dpipe;
}

sub pipe {
    my $any = shift;
    my ($r, $w);
    unless (CORE::pipe $r, $w) {
        $any->_set_error(SSHA_LOCAL_IO_ERROR, "Unable to create pipe: $!");
        return
    }
    $debug and $debug & 1024 and _debug "pipe => $r (", fileno($r), "), $w (", fileno($w), ")";
    ($r, $w);
}

sub open4 {
    my ($any, $fhs, $close, $pty, $stderr_to_stdout, @cmd) = @_;
    my $pid = fork;
    unless ($pid) {
        unless (defined $pid) {
            $any->_set_error(SSHA_CONNECTION_ERROR, "unable to fork new process: $!");
            return;
        }

        $pty->make_slave_controlling_terminal if $pty;

        my @fds = map _fileno_dup_over(3 => $_), @$fhs;
        close $_ for grep defined, @$close;

        for (0..2) {
            my $fd = $fds[$_];
            POSIX::dup2($fd, $_) if defined $fd;
        }

        POSIX::dup2(1, 2) if $stderr_to_stdout;

        do { exec @cmd };
        POSIX::_exit(255);
    }
    return { pid => $pid};
}

my @retriable = (Errno::EINTR, Errno::EAGAIN);
push @retriable, Errno::EWOULDBLOCK if Errno::EWOULDBLOCK != Errno::EAGAIN;

sub io3 {
    my ($any, $proc, $timeout, $data, $in, $out, $err) = @_;
    my ($cin, $cout, $cerr) = map defined, $in, $out, $err;
    $timeout = $any->{timeout} unless defined $timeout;

    # removes undefs and zero length strings and copies the data
    # string so that we can modify them in place
    $data = $any->_os_io3_check_and_clean_data($data, $in);
    if ($cin and not @$data) {
        close $in;
        undef $cin;
    }

    my $bout = '';
    my $berr = '';
    my ($fnoout, $fnoerr, $fnoin);
    local $SIG{PIPE} = 'IGNORE';

 MLOOP: while ($cout or $cerr or $cin) {
        $debug and $debug & 1024 and _debug "io3 mloop, cin: " . ($cin || 0) .
            ", cout: " . ($cout || 0) . ", cerr: " . ($cerr || 0);
        my ($rv, $wv);

        if ($cout or $cerr) {
            $rv = '';
            if ($cout) {
                $fnoout = fileno $out;
                vec($rv, $fnoout, 1) = 1;
            }
            if ($cerr) {
                $fnoerr = fileno $err;
                vec($rv, $fnoerr, 1) = 1
            }
        }

        if ($cin) {
            $fnoin = fileno $in;
            $wv = '';
            vec($wv, $fnoin, 1) = 1;
        }

        my $recalc_vecs;
    FAST: until ($recalc_vecs) {
            $debug and $debug & 1024 and
                _debug "io3 fast, cin: " . ($cin || 0) .
                    ", cout: " . ($cout || 0) . ", cerr: " . ($cerr || 0);
            my ($rv1, $wv1) = ($rv, $wv);
            my $n = select ($rv1, $wv1, undef, $timeout);
            if ($n > 0) {
                if ($cout and vec($rv1, $fnoout, 1)) {
                    my $offset = length $bout;
                    my $read = sysread($out, $bout, 20480, $offset);
                    $debug and $debug & 1024 and _debug "stdout, bytes read: ", $read, " at offset $offset";
                    unless ($read) {
                        if (defined $read or not grep $! == $_, @retriable) {
                            close $out;
                            undef $cout;
                            $recalc_vecs = 1;
                        }
                    }
                }
                if ($cerr and vec($rv1, $fnoerr, 1)) {
                    my $read = sysread($err, $berr, 20480, length($berr));
                    $debug and $debug & 1024 and _debug "stderr, bytes read: ", $read;
                    unless ($read) {
                        if (defined $read or not grep $! == $_, @retriable) {
                            close $err;
                            undef $cerr;
                            $recalc_vecs = 1;
                        }
                    }
                }
                if ($cin and vec($wv1, $fnoin, 1)) {
                    my $written = syswrite($in, $data->[0], 20480);
                    $debug and $debug & 64 and _debug "stdin, bytes written: ", $written;
                    if ($written) {
                        substr($data->[0], 0, $written, '');
                        next FAST if length $data->[0];
                        shift @$data;
                        next FAST if @$data;
                        # fallback when stdin queue is exhausted
                    }
                    elsif (grep $! == $_, @retriable) {
                        next FAST;
                    }
                    close $in;
                    undef $cin;
                    $recalc_vecs = 1;
                }
            }
            else {
                next if $n < 0 and grep $! == $_, @retriable;
                $any->_set_error(SSHA_TIMEOUT_ERROR, 'slave command timed out');
                last MLOOP;
            }
        }
    }
    close $out if $cout;
    close $err if $cerr;
    close $in if $cin;

    $any->_wait_ssh_proc($proc, $timeout);

    $debug and $debug & 1024 and _debug "leaving io3()";
    return ($bout, $berr);
}

my @base_app_dirs = qw(/usr/lib /opt /usr/local);

sub find_cmd_by_app {
    my ($any, $name, $app) = @_;
    $app = $app->{POSIX} if ref $app;
    if (defined $app) {
        for my $app ($app, lc($app)) {
            for my $base (@base_app_dirs) {
                my $app_dir = "$base/$app";
                if (-d $app_dir) {
                    for my $bin (qw(bin sbin libexec .)) {
                        my $path = $any->_os_validate_cmd("$app_dir/$bin/$name");
                        defined $path and return $path;
                    }
                }
            }
        }
    }
    ()
}

sub find_user_dirs {
    my $any = shift;
    my $home = (getpwuid $<)[7];
    my @dirs;
    for my $name (@_) {
        my $posix_name = (ref $name ? $name->{POSIX} : $name);
        if (defined $posix_name and
            defined $home) {
            push @dirs, join('/', $home, $posix_name)
        }
    }
    grep -d $_, @dirs;
}

sub set_file_inherit_flag {
    my ($any, $file, $value) = @_;
    $debug and $debug & 1024 and _debug "setting inherit flag for file $file (",fileno($file),") to $value";
    my $flags = fcntl($file, Fcntl::F_GETFL(), 0);
    if ($value) {
        $flags &= ~Fcntl::FD_CLOEXEC();
    }
    else {
        $flags |= Fcntl::FD_CLOEXEC();
    }
    fcntl($file, Fcntl::F_SETFL(), $flags);
    1;
}

my $unique_ix = 0;

sub create_secret_file {
    my ($any, $name, $data) = @_;
    my $home = (getpwuid $<)[7];
    unless (defined $home) {
        $any->_os_set_error(SSHA_LOCAL_IO_ERROR, "Unable to determine user home directory: $!");
        return;
    }
    my $base = File::Spec->rel2abs('.libssh-net-any-perl', $home);
    mkdir $base, 0700 unless -d $base;
    unless (do { local $!; -d $base }) {
        $any->_or_set_error(SSHA_LOCAL_IO_ERROR, "Unable to create private directory $base: $!");
        return;
    }

    $name = File::Spec->rel2abs($name, $base);

    my $ext = '';
    if ($name =~ m|(.*)(\.[^/]*)$|) {
        $name = $1;
        $ext = $2;
    }

    while (1) {
        my $final = join("-", $name, $$, $unique_ix++, int rand 1000).$ext;
        if (sysopen(my $fh, $final,
		    Fcntl::O_RDWR()|Fcntl::O_CREAT()|Fcntl::O_EXCL(),
		    Fcntl::S_IRUSR()|Fcntl::S_IWUSR())) {
            print {$fh} $data;
            return $final if close $fh;
            $any->_or_set_error(SSHA_LOCAL_IO_ERROR, "Unable to write secret file $final: $!");
            unlink $final;
            return;
        }
        unless ($! == Errno::EEXIST()) {
            $any->_or_set_error(SSHA_LOCAL_IO_ERROR, "Unable to create secret file $final: $!");
            return;
        }
    }
}

sub unix_path { $_[1] }

sub version { 'POSIX' }

1;
