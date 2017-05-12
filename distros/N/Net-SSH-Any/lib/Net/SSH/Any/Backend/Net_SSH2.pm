package Net::SSH::Any::Backend::Net_SSH2;

use strict;
use warnings;

use Carp;
our @CARP_NOT = qw(Net::SSH::Any);

use Net::SSH::Any::Util qw($debug _debug _debug_hexdump _debug_dump _first_defined _warn);
use Net::SSH::Any::Constants qw(:error);

use Net::SSH2;
use File::Spec;
use Errno ();
use Fcntl ();
use Time::HiRes ();
use Socket qw(SO_LINGER SO_KEEPALIVE);
use IO::Socket::INET;

our $stdin_buffer_size  ||= 40000;
our $stdout_buffer_size ||= 262144;

my $windows = $^O =~ /^MSWin/;

use Config;
my %sig_name2num;
if (defined($Config{sig_name})) {
    my $i = 0;
    $sig_name2num{$_} = $i++ for split //, $Config{sig_name};
}

sub _sig_name2num {
    my $signal = shift;
    return 0 unless defined $signal and length $signal;
    my $num = $sig_name2num{$signal};
    (defined $num ? $num : 254);
}

sub _backend_api_version { 2 }

my %C = ( SOCKET_BLOCK_INBOUND => 1,
          SOCKET_BLOCK_OUTBOUND => 2,
          ERROR_EAGAIN => -37,
          ERROR_FILE => -16,
          ERROR_CHANNEL_CLOSED => -26,
          ERROR_CHANNEL_EOF_SENT => -27,
          KNOWNHOST_TYPE_PLAIN => 1,
          KNOWNHOST_KEYENC_RAW => 2,
          KNOWNHOST_KEY_SHIFT => (1<<18),
          KNOWNHOST_CHECK_MATCH => 0,
          KNOWNHOST_CHECK_MISMATCH => 1,
          KNOWNHOST_CHECK_NOTFOUND => 2,
          FLAG_COMPRESS => 2,
          TRACE_TRANS => (1<<1),
          TRACE_DUMP => (1<<10),
        );

do {
    local ($@, $SIG{__DIE__});
    for my $c (keys %C) {
        if (defined (my $v = eval "Net::SSH2::LIBSSH2_$c()")) {
            $C{$c} = $v;
        }
    }
};

sub __copy_error {
    my ($any, $code) = @_;
    my $ssh2 = $any->{be_ssh2}
        or die "internal error: __copy_error called, but there is no ssh2 object";
    my ($error, $error_name, $error_msg) = $ssh2->error;
    $error or die "internal error: __copy_error called, but there is no error";
    $error_msg ||= $error_name;

    if ($error == $C{ERROR_EAGAIN}) {
        # most libssh2 functions can't recover from an EAGAIN error
        # leaving the connection in a broken state. We catch that case
        # marking the connection as lost. Note that the functions that
        # can recover, return LIBSSH2_ERROR_EAGAIN but leave the
        # internal error field as 0
        $any->_set_error(SSHA_CONNECTION_ERROR,
                         "connection lost: internal libssh2 error, unhandled EAGAIN, $error_msg");
    }
    else {
        $any->_set_error($code || SSHA_CHANNEL_ERROR, $error_msg);
    }
    return;
}

sub __check_host_key {
    my $any = shift;
    my $ssh2 = $any->{be_ssh2} or croak "internal error: be_ssh2 is not set";
    my $be_opts = $any->{be_opts};

    my $hostkey_method = $ssh2->can('remote_hostkey');
    unless ($hostkey_method) {
        carp "The version of Net::SSH2 installed ($Net::SSH2::VERSION) doesn't support " .
            "checking the host key against a known_hosts file. This script is exposed to ".
                "man-in-the-middle atacks!!!";
        return 1;
    }

    my ($key, $type) = $hostkey_method->($ssh2);

    my $known_hosts_path = $be_opts->{known_hosts_path};
    unless (defined $known_hosts_path) {
        my $config_dir;
        if ($windows) {
            $any->_load_module('Win32') or return;
            my $appdata = Win32::GetFolderPath(Win32::CSIDL_APPDATA());
            unless (defined $appdata) {
                $any->_set_error(SSHA_CONNECTION_ERROR, "unable to determine directory for user application data");
                return;
            }
            $config_dir = File::Spec->join($appdata, 'libnet-ssh-any-perl');
        }
        else {
            my $home = (getpwuid $>)[7];
            $home = $ENV{HOME} unless defined $home;
            unless (defined $home) {
                $any->_set_error(SSHA_CONNECTION_ERROR, "unable to determine user home directory");
                return;
            }
            $config_dir = File::Spec->join($home, '.ssh');
        }
        unless (-d $config_dir or mkdir $config_dir, 0700) {
            $any->_set_error(SSHA_CONNECTION_ERROR, "unable to create directory '$config_dir': $^E");
            return;
        }
        $known_hosts_path = File::Spec->join($config_dir, 'known_hosts');
    }

    $debug and $debug & 1024 and _debug "reading known host keys from '$known_hosts_path'";

    local ($@, $SIG{__DIE__});

    my $kh = $ssh2->known_hosts;
    my $ok = eval { $kh->readfile($known_hosts_path) };
    unless (defined $ok) {
        $debug and $debug & 1024 and _debug "unable to read known hosts file: " . $ssh2->error;
        if ($ssh2->error == $C{ERROR_FILE}) {
            if (-f $known_hosts_path) {
                $any->_set_error(SSHA_CONNECTION_ERROR, "unable to read known_hosts file at '$known_hosts_path'");
                return;
            }
            # a non-existent file is not an error, continue...
        }
        else {
            $any->_set_error(SSHA_CONNECTION_ERROR,
                             "Unable to parse known_hosts file at '$known_hosts_path': ". ($ssh2->error)[2]);
            return;
        }
    }

    if ($debug and $debug & 1024) {
        _debug "remote key is of type $type";
        _debug_hexdump("key", $key);
    }

    my $key_type = ( $C{KNOWNHOST_TYPE_PLAIN} |
                     $C{KNOWNHOST_KEYENC_RAW} |
                     (($type + 1) << $C{KNOWNHOST_KEY_SHIFT}) );

    my $check = $kh->check($be_opts->{host}, $be_opts->{port}, $key, $key_type);

    if ($check == $C{KNOWNHOST_CHECK_MATCH}) {
        $debug and $debug & 1024 and _debug("host key matched");
        return 1;
    }
    elsif ($check == $C{KNOWNHOST_CHECK_MISMATCH}) {
        $debug and $debug & 1024 and _debug("host key found but did not match");
        $any->_set_error(SSHA_CONNECTION_ERROR, "The host key for '$be_opts->{host}' has changed");
        return;
    }
    elsif ($check == $C{KNOWNHOST_CHECK_NOTFOUND}) {
        $debug and $debug & 1024 and _debug("host key not found in known_hosts");
        if ($be_opts->{strict_host_key_checking}) {
            $any->_set_error(SSHA_CONNECTION_ERROR, "the authenticity of host '$be_opts->{host}' can't be established");
            return;
        }
        else {
            $debug and $debug & 1024 and _debug "saving host key to '$known_hosts_path'";
            eval {
                $kh->add($be_opts->{host}, '', $key, "added by Perl module Net::SSH::Any (Net::SSH2 backend)", $key_type);
                $kh->writefile($known_hosts_path);
            };
            return 1;
        }
    }

    $debug and $debug & 1024 and _debug("host key check failure (check: $check)!");
    $any->_set_error(SSHA_CONNECTION_ERROR, "unable to check host key, libssh2_knownhost_check failed");
    ()
}

sub _validate_backend_opts {
    my ($any, %be_opts) = @_;
    my $mod_ver = do { no warnings; 0 + $Net::SSH2::VERSION };
    if ($mod_ver < 0.59) {
        $any->_set_error(SSHA_CONNECTION_ERROR,
                         "The version of Net::SSH2 available ($Net::SSH2::VERSION) is too old. ".
                         "0.59 or later required");
        return;
    }

    my @lib_ver = Net::SSH2::version();
    $debug and $debug & 1024 and _debug "libssh2 version $lib_ver[2]";
    if ($lib_ver[1] < 0x010500) {
        $any->_set_error(SSHA_CONNECTION_ERROR,
                         "Net::SSH2 was compiled against an old unsupported version of libssh2 ($lib_ver[2])");
        return;
    }

    my $ssh2 = $any->{be_ssh2} = Net::SSH2->new;
    unless ($ssh2) {
        $any->_set_error(SSHA_CONNECTION_ERROR, "Unable to create Net::SSH2 object");
        return;
    }
    $debug and $debug & 2048 and $ssh2->trace(~0); #~$C{TRACE_TRANS});

    $ssh2->timeout(1000 * ($be_opts{timeout} // $be_opts{io_timeout}));

    if ($be_opts{compress}) {
        if (defined(my $flag_method = $ssh2->can('flag'))) {
            $debug and $debug & 1024 and _debug "enabling compression";
            $flag_method->($ssh2, $C{FLAG_COMPRESS}, 1);
        }
    }

    $any->{be_opts} = \%be_opts;
    1;
}

sub _connect {
    my $any = shift;
    my $ssh2 = $any->{be_ssh2} or return;
    my $be_opts = $any->{be_opts};
    my $socket = IO::Socket::INET->new(PeerHost => $be_opts->{host},
                                       PeerPort => ($be_opts->{port} || 22),
                                       ($be_opts->{timeout} ? (Timeout => $be_opts->{timeout}) : ()));
    if ($socket) {
        $socket->sockopt(SO_LINGER, pack(SS => 0, 0));
        $socket->sockopt(SO_KEEPALIVE, 1);
    }
    unless ($socket and $ssh2->connect($socket)) {
        return $any->_set_error(SSHA_CONNECTION_ERROR, "Unable to connect to remote host");
    }
    $debug and $debug & 1024 and _debug 'COMP_SC: ' . $ssh2->method('COMP_SC') . ' COMP_CS: ' .$ssh2->method('COMP_CS');

    __check_host_key($any) or return;

    my %aa;
    $aa{username} = _first_defined($be_opts->{user},
                                   eval { (getpwuid $<)[0] },
                                   eval { getlogin() });
    $aa{password} = $be_opts->{password} if defined $be_opts->{password};
    $aa{passphrase} = $be_opts->{passphrase} if defined $be_opts->{passphrase};
    if (defined (my $private = $be_opts->{key_path})) {
        unless (-f $private) {
            $any->_set_error(SSHA_CONNECTION_ERROR, "Private key '$private' does not exist on file system");
            return;
        }
        my $public = $private.".pub";
        unless (-f $public) {
            $any->_set_error(SSHA_CONNECTION_ERROR, "Public key '$public' does not exist on file system");
            return;
        }
        $aa{privatekey} = $private;
        $aa{publickey}  = $public;
    }
    # TODO: use default user keys on ~/.ssh/id_dsa and ~/.ssh/id_rsa

    $debug and $debug & 1024 and _debug_dump "Net::SSH2 authentication args", \%aa;

    $ssh2->auth(%aa, interact => !$be_opts->{batch_mode});
    unless ($ssh2->auth_ok) {
        $any->_set_error(SSHA_CONNECTION_ERROR, "Authentication failed");
        return;
    }

    $any->{be_fileno} = fileno $ssh2->sock;
    $debug and $debug & 1024 and _debug("SSH socket file descriptor: $any->{be_fileno}");
    $any->{be_select_bm} = '';
    vec ($any->{be_select_bm}, $any->{be_fileno}, 1) = 1;
    1;
}

# those are the operations that can be safely carried on in a
# non-blocking fashion:
my %non_blocking_method = (read => 1);

sub _channel_do {
    my $any = shift;
    my $channel = shift;
    my $blocking = shift;
    my $method = shift;
    if ($any->error == SSHA_CONNECTION_ERROR) {
        $debug and $debug & 1024 and _debug "skipping $channel->$method call because connection is broken";
        return
    }
    my $ssh2 = $any->{be_ssh2};
    $blocking ||= !$non_blocking_method{$method};
    $ssh2->blocking($blocking);

    $debug and $debug & 1024 and _debug "calling $channel->$method with ", scalar(@_), " args";

    my $time_limit = time + $any->{io_timeout};
    while (1) {
        my $rc = $channel->$method(@_);
        $debug and $debug & 1024 and _debug "$channel->$method rc: ", $rc;
        return $rc if defined $rc;
        my ($error, $error_name, $error_msg) = $ssh2->error;
        # We assume Net::SSH2 masked a LIBSSH2_ERROR_EAGAIN if
        # both $rc and $ssh->error are unset
        $debug and $debug & 1024 and _debug("rc: ", $rc, "error: ", $error, ", name: ",
                                            $error_name, ", msg: ", $error_msg);
        if ($error == $C{ERROR_EAGAIN} and not $blocking) {
            # When an EAGAIN arrives and there is data queued for
            # writting we have to repeat the operation unchanged until
            # it succeeds or the timeout is reached otherwise we risk
            # corrupting the connection!
            if ($ssh2->block_directions & $C{SOCKET_BLOCK_OUTBOUND}) {
                if ($time_limit < time) {
                    $any->_set_error(SSHA_CONNECTION_ERROR, "connection lost, timeout");
                    return;
                }
                $debug and $debug & 1024 and _debug "waiting for the socket to become writable";
                select(undef, "$any->{__select_bm}", undef, 1);
            }
            else {
                # otherwise we can safely return
                $debug and $debug & 1024 and _debug "operation $method skipped";
                return 0
            }
        }
        else {
            unless ($error == $C{ERROR_CHANNEL_CLOSED} or
                    $error == $C{ERROR_CHANNEL_EOF_SENT}) {
                $error_msg ||= $error_name || "unknown libssh2 error";
                if ($error == $C{ERROR_EAGAIN}) {
                    $any->_set_error(SSHA_CONNECTION_ERROR,
                                     "connection lost: internal libssh2 error, unhandled EAGAIN, $error_msg");
                }
                else {
                    $any->_set_error(SSHA_CHANNEL_ERROR, $error_msg);
                }
            }
            return
        }
    }
}

sub __parse_fh_opts {
    my ($any, $opts, $channel) = @_;
    my @name = qw(stdout stderr);
    my $in_fh;
    my @out_fh;
    my $in_fh_comes_from_the_outside;

    my $stdin_data = delete $opts->{stdin_data};
    unless (defined $stdin_data) {
        if (defined (my $stdin_file = delete $opts->{stdin_file})) {
            $in_fh = $any->_open_file('<', $stdin_file) or return;
        }
        elsif (defined(my $fh = delete $opts->{stdin_fh})) {
            $in_fh = $fh;
            $in_fh_comes_from_the_outside = 1;
        }
    }

    if ($in_fh and (-s $in_fh or (not $windows and -p $in_fh))) {
        if ($in_fh_comes_from_the_outside) {
            $in_fh = $any->_open_file('<&', $in_fh) or return;
        }
        binmode $in_fh;
        if ($windows) {
            my $true = 1;
            ioctl($in_fh, 0x8004667e, \$true);
        }
        else {
            my $flags = fcntl($in_fh, Fcntl::F_GETFL(), 0);
            fcntl($in_fh, Fcntl::F_SETFL(), $flags | Fcntl::O_NONBLOCK());
        }
    }

    for my $stream (qw(stdout stderr)) {
        my $fh = delete $opts->{"${stream}_fh"};
        unless ($fh) {
            my $file = ( ( $stream eq 'stdout' and
			   delete($opts->{"stdout_discard"}) )
                         ? File::Spec->devnull
                         : delete $opts->{"${stream}_file"} );
            if (defined $file) {
                $fh = $any->_open_file('>', $file) or return;
            }
            if ($stream eq 'stderr' and not defined $fh) {
                if (delete $opts->{stderr_to_stdout}) {
                    $channel->ext_data('merge');
                }
                elsif (delete $opts->{stderr_discard}) {
                    $channel->ext_data('ignore');
                }
            }
        }
        push @out_fh, $fh;
    }

    grep /^std(?:out|err|in)_/, keys %$opts and
        croak "invalid option(s) '" . join("', '", grep /^std(?:out|err)_/, keys %$opts) . "'";
    return ($stdin_data, $in_fh, @out_fh);
}

sub __open_channel_and_exec {
    my ($any, $opts, $cmd) = @_;
    my $ssh2 = $any->{be_ssh2} or return;
    my $window_size = delete $opts->{_window_size} || 2 * 1024 * 1024;
    my $subsystem = delete $opts->{subsystem};
    croak "subsystem name missing" if $subsystem and not defined $cmd;

    if (my $channel = $ssh2->channel("session", $window_size)) {
        my @fhs = __parse_fh_opts($any, $opts, $channel) or return;
        if ($any->_channel_do($channel, 1,
                              'process',
                              ( (defined $cmd and length $cmd)
                                ? ( ($subsystem ? 'subsystem' : 'exec') => $cmd)
                                : 'shell'))) {
            return ($channel, @fhs);
        }
    }
    return;
}

sub _system {
    my ($any, $opts, $cmd) = @_;
    my ($channel, $in_data, $in_fh, $out_fh, $err_fh) = __open_channel_and_exec($any, $opts, $cmd) or return;
    __io3($any, $channel, $opts->{timeout},
	  $in_data, $in_fh, $out_fh || \*STDOUT, $err_fh || \*STDERR);
}

sub _capture {
    my ($any, $opts, $cmd) = @_;
    my ($channel, $in_data, $in_fh, $out_fh, $err_fh) = __open_channel_and_exec($any, $opts, $cmd) or return;
    die 'Internal error: $out_fh is not undef' if $out_fh;
    (__io3($any, $channel, $opts->{timeout},
	   $in_data, $in_fh, undef, $err_fh || \*STDERR))[0];
}

sub _capture2 {
    my ($any, $opts, $cmd) = @_;
    my ($channel, $in_data, $in_fh, $out_fh, $err_fh) = __open_channel_and_exec($any, $opts, $cmd) or return;
    die 'Internal error: $out_fh is not undef' if $out_fh;
    die 'Internal error: $err_fh is not undef' if $err_fh;
    __io3($any, $channel, $opts->{timeout}, $in_data, $in_fh);
}

sub __write_all {
    my $any = shift;
    my $fh = shift;
    if (ref $fh eq 'CODE') {
	unless ($fh->($_[0])) {
	    $any->_set_error(SSHA_LOCAL_IO_ERROR, "Couldn't handle remote data, callback failed");
	    return;
	}
    }
    elsif (defined $_[0]) {
        my $off = 0;
	while (length($_[0]) > $off) {
	    if (my $bytes = syswrite $fh, $_[0], 40000, $off) {
		$off += $bytes;
	    }
	    elsif ($! == Errno::EAGAIN()) {
		select undef, undef, undef, 0.05;
	    }
	    else {
		$any->_set_error(SSHA_LOCAL_IO_ERROR, "Couldn't write to pipe", $!);
		return;
	    }
	}
    }
    return 1;
}

sub _channel_close {
    my ($any, $channel) = @_;

    $any->_channel_do($channel, 1, 'close');
    $any->_channel_do($channel, 1, 'wait_closed');

    if ($any->error) {
        $? = (255 << 8);
    }
    else {
        my $code = $channel->exit_status || 0;
        my $signal = _sig_name2num($channel->exit_signal) || 0;
        $? = (($code << 8) | $signal);
    }
    1
}

sub __io3 {
    my ($any, $channel, $timeout, $in_data, $in_fh, @out_fh) = @_;
    my $ssh2 = $any->{be_ssh2} or return;
    my $in = '';
    my $out;
    my ($in_at_eof, $in_refill);
    my @cap = ('', '');
    my ($eof_sent, $eof_received);
    $timeout ||= $any->{timeout};
    my $start = time;
    my $select_bm = $any->{be_select_bm};
    my $total = 0;

 OUTER:
    while (1) {
        my $delay = 3;
        unless ($eof_sent) {
            my $window_write = $channel->window_write;
            $debug and $debug & 1024 and _debug("window write: ", $window_write);
            if ($window_write) {
                if (length $in < $stdin_buffer_size and not $in_at_eof) {
                    if ($in_data and @$in_data) {
                        $in .= shift @$in_data while @$in_data and length $in < $stdin_buffer_size;
                    }
                    elsif ($in_fh) {
			if (ref $in_fh eq 'CODE') {
			    if (defined (my $data = $in_fh->($stdin_buffer_size - length $in))) {
				$in .= $data;
			    }
			    else {
				undef $in_fh;
			    }
			}
			else {
			    my $bytes = sysread($in_fh, $in, $stdin_buffer_size, length $in);
			    $debug and $debug and _debug "stdin sysread: ", $bytes, " \$!: ", $!;
			    if (not defined $bytes and $! == Errno::EAGAIN()) {
				$in_refill = 1;
			    }
			    else {
				$in_refill = 0;
				unless ($bytes) {
				    $debug and $debug & 1024 and _debug "end of in file reached";
				    undef $in_fh;
				}
			    }
			}
		    }
		    else {
                        $debug and $debug & 1024 and _debug "in_at_eof = 1";
                        $in_at_eof = 1;
                    }
                }
                if (length $in) {
                    $debug and $debug & 1024 and _debug "bytes in stdin buffer: ", length $in;
                    if (select(undef, "$select_bm", undef, 0) > 0) {
                        my $bytes = $any->_channel_do($channel, 1, 'write', $in);
                        defined $bytes or last OUTER;
                        if ($bytes) {
                            $total += $bytes;
                            $delay = 0;
                            substr($in, 0, $bytes, '');
                        }
                    }
                    else {
                        $debug and $debug & 1024 and _debug "socket is not ready for writting";
                    }
                }
                elsif ($in_at_eof) {
                    $any->_channel_do($channel, 1, 'send_eof') or last;
                    $eof_sent = 1;
                }
            }
        }
        unless ($eof_received) {
            if ($debug and $debug & 1024) {
                my ($size, $avail, $size0) = $channel->window_read;
                _debug "window_read avail: $avail, size: $size/$size0";
            }
            for my $ext (0, 1) {
                my $bytes = $any->_channel_do($channel, 0, 'read', $out, $stdout_buffer_size, $ext);
                defined $bytes or last OUTER;
                if ($bytes) {
                    $total += $bytes;
                    $delay = 0;
		    if ($out_fh[$ext]) {
			__write_all($any, $out_fh[$ext], $out) or last OUTER;
                    }
                    else {
                        $cap[$ext] .= $out;
                    }
                    # we reuse out to avoid the allocation of 256KB every time
                    $out = '';
                }
            }
	    if ($channel->eof) {
		$eof_received = 1;
		$debug and $debug & 1024 and _debug "eof_received";
		for my $fh (@out_fh) {
		    __write_all($any, $_) or last OUTER;
		}
            }
        }
        last if $eof_sent and $eof_received;

        $debug and $debug & 1024 and _debug "channel receive_window: ", join(', ', $channel->window_read);

	if ($timeout) {
	    if ($delay) {
		my $now = Time::HiRes::time();
		$start ||= $now;
		if ($now - $start > $timeout) {
		    $any->_set_error(SSHA_TIMEOUT_ERROR, "command timed out");
		    last;
		}
	    }
	    else {
		undef $start;
	    }
	}
        $any->_wait_for_data(!$eof_sent, $delay, ($in_refill ? [$in_fh] : ()));
    }

    # clear buffer memory
    undef $in; undef $out;

    $debug and $debug & 1024 and _debug "data moved:", $total;

    $any->_channel_close($channel);
    return @cap;
}

sub _wait_for_data {
    my ($any, $write, $max_delay, $extra_read) = @_;
    $debug and $debug & 1024 and _debug "waiting for data, write: " . ($write//'<undef>') .
        ", max_delay: " . ($max_delay//'<undef>') . ", extra_read: " . ($extra_read//'<undef>');
    if ($max_delay) {
        my $rbm = $any->{be_select_bm};
        my $wbm = ($write ? $rbm : '');
        if ($extra_read) {
            vec($rbm, fileno($_), 1) = 1 for @$extra_read;
        }
        my $n = select($rbm, $wbm, undef, $max_delay);
        $debug and $debug & 1024 and _debug "active sockets: ", $n;
    }
}

sub _channel_read {
    my $any = shift;
    my $channel = shift;
    my $blocking = shift;
    while (1) {
        $debug and $debug & 1024 and _debug "iterating inside _channel_read loop";
        my $rc = $any->_channel_do($channel, 0, 'read', @_);
        return $rc if $rc or not defined $rc or not $blocking;
        return if $channel->eof;
        $any->_wait_for_data(0, 1);
    }
}

sub _dpipe {
    my ($any, $opts, $cmd) = @_;
    my ($channel) = __open_channel_and_exec($any, $opts, $cmd) or return;
    # TODO: do something with the parsed options?
    require Net::SSH::Any::Backend::Net_SSH2::DPipe;
    Net::SSH::Any::Backend::Net_SSH2::DPipe->_make($any, $channel);
}

sub _sftp {
    my ($any, $opts) = @_;
    my $ssh2 = $any->{be_ssh2} or return;
    my $dpipe = $any->dpipe({subsystem => 1}, 'sftp');
    require Net::SSH::Any::Backend::Net_SSH2::SFTP;
    my $sftp_backend = Net::SSH::Any::Backend::Net_SSH2::SFTP->_new($any, $dpipe);
    my $sftp = Net::SFTP::Foreign->new(backend => $sftp_backend,
                                       autodisconnect => 2,
                                       %$opts);
    if ($sftp->error) {
        $any->_set_error(SSHA_CHANNEL_ERROR, $sftp->error);
    }
    $sftp;
}

1;
