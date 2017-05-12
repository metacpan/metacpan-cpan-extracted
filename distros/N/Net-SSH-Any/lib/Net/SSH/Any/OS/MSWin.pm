package Net::SSH::Any::OS::MSWin;

use strict;
use warnings;

use Carp;
use Socket;
use Errno;
use Net::SSH::Any::Util qw($debug _debug _debug_hexdump _first_defined _array_or_scalar_to_list _warn);
use Net::SSH::Any::Constants qw(:error);
use Time::HiRes qw(sleep time);
use Config ();
use Win32::API ();
use File::Spec ();

require Net::SSH::Any::OS::_Base;
our @ISA = qw(Net::SSH::Any::OS::_Base);

sub pipe {
    my $any = shift;
    my ($r, $w);
    unless (CORE::pipe $r, $w) {
        $any->_set_error(SSHA_LOCAL_IO_ERROR, "Unable to create pipe: $!");
        return
    }
    binmode $r;
    binmode $w;
    ($r, $w);
}

sub make_dpipe {
    my ($any, $proc, $in, $out) = @_;
    require Net::SSH::Any::OS::MSWin::DPipe;
    Net::SSH::Any::OS::MSWin::DPipe->_upgrade_fh_to_dpipe($out, $any, $proc, $in);
}

my $win32_set_named_pipe_handle_state;
my $win32_get_osfhandle;
my $win32_set_handle_information;
my $win32_open_process;
my $win32_get_exit_code_process;
my $win32_close_handle;
my $win32_get_version;
my $win32_get_final_path_name_by_handle;
my $win32_get_file_information_by_handle_ex;
my $win32_get_current_process_id;

my $win32_handle_flag_inherit = 0x1;
my $win32_pipe_nowait = 0x1;
my $win32_process_query_information = 0x0400;

sub __wrap_win32_functions {
    unless (defined $win32_set_named_pipe_handle_state) {
        $Config::Config{libperl} =~ /libperl(\d+)/
            or croak "unable to infer Perl DLL version";
        my $perl_dll = "perl$1.dll";
        $debug and $debug & 1024 and _debug "Perl DLL name is $perl_dll";
        $win32_get_osfhandle = Win32::API::More->new($perl_dll, <<FSIGN)
long WINAPIV win32_get_osfhandle(int fd);
FSIGN
            or croak "unable to wrap $perl_dll win32_get_osfhandle function";

        $win32_set_named_pipe_handle_state = Win32::API::More->new("kernel32.dll", <<FSIGN)
BOOL SetNamedPipeHandleState(HANDLE hNamedPipe,
                             LPDWORD lpMode,
                             int ignore1,
                             int ignore2)
FSIGN
            or croak "unable to wrap kernel32.dll SetNamedPipeHandleState function";
        $win32_set_handle_information = Win32::API::More->new("kernel32.dll", <<FSIGN)
BOOL WINAPI SetHandleInformation(HANDLE hObject,
                                 DWORD dwMask,
                                 DWORD dwFlags);
FSIGN
            or croak "unable to wrap kernel32.dll SetHandleInformation function";


        $win32_get_exit_code_process = Win32::API::More->new("kernel32.dll", <<FSIGN)
BOOL WINAPI GetExitCodeProcess(HANDLE hProcess,
                               LPDWORD lpExitCode)
FSIGN
            or croak "unable to wrap kernel32.dll GetExitCodeProcess";

        $win32_open_process = Win32::API::More->new("kernel32.dll", <<FSIGN)
HANDLE WINAPI OpenProcess(DWORD dwDesiredAccess,
                          BOOL bInheritHandle,
                          DWORD dwProcessId)
FSIGN
            or croak "unable to wrap kernel32.dll OpenProcess";

        $win32_close_handle = Win32::API::More->new("kernel32.dll", <<FSIGN)
BOOL WINAPI CloseHandle(HANDLE hObject)
FSIGN
            or croak "unable to wrap kernel32.dll CloseHandle";

        $win32_get_version = Win32::API::More->new("kernel32.dll", <<FSIGN)
DWORD WINAPI GetVersion()
FSIGN
            or croak "unable to wrap kernel32.dll GetVersion";


        $win32_get_current_process_id = Win32::API::More->new("kernel32.dll", <<FSIGN)
DWORD WINAPI GetCurrentProcessId();
FSIGN
            or croak "unable to wrap GetCurrentProcessId";

#         $win32_get_final_path_name_by_handle = Win32::API::More->new("kernel32.dll", <<FSIGN)
# DWORD WINAPI GetFinalPathNameByHandle(HANDLE hFile,
#                                       LPTSTR lpszFilePath,
#                                       DWORD cchFilePath,
#                                       DWORD dwFlags)
# FSIGN
#             or croak "unable to wrap kernel32.dll GetFinalPathNameByHandle";


#         $win32_get_file_information_by_handle_ex = Win32::API::More->new("kernel32.dll", <<FSIGN)
# BOOL WINAPI GetFileInformationByHandleEx(HANDLE hFile,
#                                          DWORD FileInformationClass,
#                                          LPVOID lpFileInformation,
#                                          DWORD dwBufferSize)
# FSIGN
#             or croak "unable to wrap kernel32.dll GetFileInformationByHandleEx";
    }
    1;
}

__wrap_win32_functions();

sub set_file_inherit_flag {
    my ($any, $file, $value) = @_;
    __wrap_win32_functions($any);
    my $fn = fileno $file;
    my $wh = $win32_get_osfhandle->Call($fn)
        or die "internal error: win32_get_osfhandle failed unexpectedly";
    my $flag = ($value ? $win32_handle_flag_inherit : 0);
    my $success = $win32_set_handle_information->Call($wh, $win32_handle_flag_inherit, $flag);
    $debug and $debug & 1024 and
        _debug "Win32::SetHandleInformation($wh, $win32_handle_flag_inherit, $flag) => $success",
            ($success ? () : (" \$^E: $^E"));
    $success;
}

sub export_handle {
    my ($any, $file) = @_;
    my $fn = fileno $file;
    return $win32_get_osfhandle->Call($fn) if $fn >= 0;
    ()
}

sub export_current_process {
    my $any = shift;
    $win32_get_current_process_id->Call()
}

sub get_file_name_from_handle {
    my ($any, $file) = @_;
    my $fn = fileno $file;
    my $wh = $win32_get_osfhandle->Call($fn);
    Net::SSH::Any::Util::_debugf("fileno: %d, handle: 0x%x", $fn, $wh);

    my $buffer = "1" x 256;
    my $ok = $win32_get_file_information_by_handle_ex->Call($wh, 0x2, $buffer, length($buffer) - 1);
    _debug_hexdump "name (ok: $ok)" => $buffer;
    ""
}

sub pty { croak "PTYs are not supported on Windows" }

sub open4 {
    my ($any, $fhs, $close, $pty, $stderr_to_stdout, @cmd) = @_;
    my (@old, @new, $pid, $error);

    $pty and croak "PTYs are not supported on Windows";
    grep tied $_, *STDIN, *STDOUT, *STDERR
        and croak "STDIN, STDOUT or STDERR is tied";
    grep { defined $_ and (tied $_ or not defined fileno $_) } @$fhs
        and croak "At least one of the given file-handles is tied or is not backed by a real OS file handle";

    for my $fd (0..2) {
        if (defined $fhs->[$fd]) {
            my $dir = ($fd ? '>' : '<');
            open $old[$fd], "$dir&", (\*STDIN, \*STDOUT, \*STDERR)[$fd] or $error = $!;
            open $new[$fd], "$dir&", $fhs->[$fd] or $error = $!;
        }
    }
    open $old[2], '<&', \*STDERR or $error = $! if $stderr_to_stdout;

    unless (defined $error) {
        if (not $new[0] or open STDIN, '<&', $new[0]) {
            if (not $new[1] or open STDOUT, '>&', $new[1]) {
                $new[2] = \*STDOUT if $stderr_to_stdout;
                if (not $new[2] or open STDERR, '>&', $new[2]) {
                    $pid = eval { system 1, @cmd } or $error = $!;
                    open STDERR, '>&', $old[2] or $error = $!
                        if $new[2]
                    }
                else {
                    $error = $!;
                }
                open STDOUT, '>&', $old[1] or $error = $!
                    if $new[1];
            }
            else {
                $error = $!
            }
            open STDIN, '<&', $old[0] or $error = $!
                if $new[0];
        }
        else {
            $error = $!;
        }
    }

    undef $_ for @old, @new;

    if (defined $error) {
        $any->_set_error(SSHA_CONNECTION_ERROR, "unable to start slave process: $error");
    }

    my $proc = { pid => $pid };
    bless $proc, 'Net::SSH::Any::OS::MSWin::Process';
    __wrap_win32_functions($any);
    $proc->{handle} = $win32_open_process->Call($win32_process_query_information, 0, $pid);
    $debug and $debug & 1024 and _debug "process $pid forked, process handle: $proc->{handle}";
    return $proc;
}

sub native_rc {
    my ($tssh, $proc) = @_;
    my $native_rc = 0;
    $win32_get_exit_code_process->Call($proc->{handle}, $native_rc);
    return $native_rc;
}

my @retriable = (Errno::EINTR, Errno::EAGAIN, Errno::ENOSPC, Errno::EINVAL);
push @retriable, Errno::EWOULDBLOCK if Errno::EWOULDBLOCK != Errno::EAGAIN;


sub __set_pipe_blocking {
    my ($any, $pipe, $blocking) = @_;
    if (defined $pipe) {
        __wrap_win32_functions($any);
        my $fileno = fileno $pipe;
        my $handle = $win32_get_osfhandle->Call($fileno);
        $debug and $debug & 1024 and _debug("setting pipe (pipe: ", $pipe,
                                            ", fileno: ", $fileno,
                                            ", handle: ", $handle, ") to",
                                            ($blocking ? " " : " non "), "blocking");
        my $success = $win32_set_named_pipe_handle_state->Call($handle,
                                                               ($blocking ? 0 : $win32_pipe_nowait),
                                                               0, 0);
        $debug and $debug & 1024 and _debug("Win32::SetNamedPipeHandleState => $success",
                                            ($success ? () : " ($^E)"));
    }
}

sub io3 {
    my ($any, $proc, $timeout, $data, $in, $out, $err) = @_;
    $timeout = $any->{timeout} unless defined $timeout;

    $debug and $debug & 1024 and _debug "io3 handles: ", $in, ", ", $out, ", ", $err;

    $data = $any->_os_io3_check_and_clean_data($data, $in);

    __set_pipe_blocking($any, $in,  0);
    __set_pipe_blocking($any, $out, 0);
    __set_pipe_blocking($any, $err, 0);

    $debug and $debug & 1024 and _debug "data array has ".scalar(@$data)." elements";

    my $bout = '';
    my $berr = '';
    while (defined $in or defined $out or defined $err) {
        my $delay = 1;
        if (defined $in) {
            while (@$data) {
                unless (defined $data->[0] and length $data->[0]) {
                    shift @$data;
                    next;
                }
                my $bytes = syswrite $in, $data->[0];
                if ($bytes) {
                    $debug and $debug & 1024 and _debug "$bytes bytes of data sent";
                    substr $data->[0], 0, $bytes, '';
                    undef $delay;
                }
                else {
                    unless (grep $! == $_, @retriable) {
                        $any->_set_error(SSHA_LOCAL_IO_ERROR, "failed to write to slave stdin channel: $!");
                        close $in;
                        undef $in;
                        undef $delay;
                    }
                    last;
                }
            }
            unless (@$data) {
                $debug and $debug & 1024 and _debug "closing slave stdin channel";
                close $in;
                undef $in;
                undef $delay;
            }
        }

        if (defined $out) {
            my $bytes = sysread($out, $bout, 20480, length($bout));
            if (defined $bytes) {
                $debug and $debug & 1024 and _debug "received ", $bytes, " bytes of data over stdout";
                undef $delay;
                unless ($bytes) {
                    $debug and $debug & 1024 and _debug "closing slave stdout channel at EOF";
                    close $out;
                    undef $out;
                }
            }
            else {
                unless (grep $! == $_, @retriable) {
                    $any->_set_error(SSHA_LOCAL_IO_ERROR, "failed to read from slave stdout channel: $!");
                    close $out;
                    undef $out;
                    undef $delay;
                }
            }
        }

        if (defined $err) {
            my $bytes = sysread($err, $berr, 20480, length($berr));
            if (defined $bytes) {
                $debug and $debug & 1024 and _debug "received ", $bytes, " bytes of data over stderr";
                undef $delay;
                unless ($bytes) {
                    $debug and $debug & 1024 and _debug "closing slave stderr channel at EOF";
                    close $err;
                    undef $err;
                }
            }
            else {
                unless (grep $! == $_, @retriable) {
                    $any->_set_error(SSHA_LOCAL_IO_ERROR, "failed to read from slave stderr channel: $!");
                    close $err;
                    undef $err;
                    undef $delay;
                }
            }
        }
        if ($delay) {
            # $debug and $debug & 1024 and _debug "delaying...";
            sleep 0.02; # experimentation has show the load introduced
                        # with this delay is not noticeable!
        }
    }

    $debug and $debug & 1024 and _debug "waiting for child";
    # FIXME: _io3 is not limited to ssh processes
    $any->_wait_ssh_proc($proc, $timeout);

    $debug and $debug & 1024 and _debug "leaving io3()";
    return ($bout, $berr);
}

sub validate_cmd {
    my ($any, $cmd) = @_;
    return unless defined $cmd;
    $any->SUPER::validate_cmd($cmd) //
        $any->SUPER::validate_cmd("$cmd.EXE");
}

my @cygwin_variants = qw(Cygwin MinGW MinGW\\MSYS\\1.0);

sub find_cygwin_cmd {
    my ($any, $name) = @_;

    $any->_load_module('Win32::TieRegistry') or return;
    my %reg;
    Win32::TieRegistry->import(TiedHash => \%reg);

    my @rootdirs = grep defined,
        $reg{'HKEY_CURRENT_USER\\SOFTWARE\\Cygwin\\setup\\rootdir'},
        $reg{'HKEY_LOCAL_MACHINE\\SOFTWARE\\Cygwin\\setup\\rootdir'};

    if (defined (my $drive = $ENV{SystemDrive})) {
        push @rootdirs, File::Spec->catpath($drive, $_)
            for @cygwin_variants;
    }

    for my $rootdir (@rootdirs) {
        next unless -d $rootdir;
        for my $bin (qw(bin sbin usr\\bin usr\\sbin)) {
            my $cmd = $any->_os_validate_cmd(File::Spec->join($rootdir, $bin, $name));
            return $cmd if defined $cmd;
        }
    }
}

sub find_cmd_by_app {
    my ($any, $name, $app) = @_;
    $app = $app->{MSWin} if ref $app;
    if (defined $app) {
        lc($app) eq 'cygwin' and
            return $any->_os_find_cygwin_cmd($name);

        for my $env (qw{ProgramFiles ProgramFiles(x86)}) {
            if (defined (my $pf = $ENV{$env})) {
                my $cmd = $any->_os_validate_cmd(join('\\', $pf, $app, $name));
                return $cmd if defined $cmd;
            }
        }
    }
    ()
}

sub find_user_dirs {
    my $any = shift;
    my $drive = $ENV{SystemDrive};
    my $user = $ENV{USERNAME};
    my $appdata = $ENV{APPDATA};
    my @dirs;
    for my $name (@_) {
        my $mswin_name = (ref $name ? $name->{MSWin} : $name);
        if (defined $mswin_name and
            defined $appdata) {
            push @dirs, join('\\', $appdata, $mswin_name);
        }
        my $cygwin_name = (ref $name ? $name->{Cygwin} // $name->{POSIX} : $name);
        if (defined $cygwin_name and
            defined $drive and
            defined $user) {
            for my $path (@cygwin_variants) {
                push @dirs, join('\\', $drive, $path, 'home', $user, $cygwin_name);
            }
        }
    }
    grep -d $_, @dirs;
}

sub create_secret_file {
    my ($any, $name, $data) = @_;
    $any->_load_module('Win32::SecretFile') or return;
    my $path = Win32::SecretFile::create_secret_file(File::Spec->join('libnet-ssh-any-perl', $name),
                                                     $data,
                                                     local_appdata => 1,
                                                     short_path => 1,
                                                     unique => 1);
    defined $path or
        $any->_or_set_error(SSHA_LOCAL_IO_ERROR,
                            "Unable to create secret file: $^E [". ($^E+0) . "]");
    $path;
}

sub version {
    my $any = shift;
    my $v = $win32_get_version->Call();
    $v & 0x80000000 and croak "This OS is a joke!";
    my $mayor = $v & 0xff;
    my $minor = ($v >> 8) & 0xff;
    my $build = ($v >> 16);
    wantarray ? ('MSWin', $mayor, $minor, $build) : "MSWin-$mayor.$minor.$build";
}

# This method is used by Cygwin commands as most of then can not
# handle native Windows paths correctly.
sub unix_path {
    my ($any, $path) = @_;
    return "/dev/null" if $path eq 'nul';
    my ($drive, @rest) = File::Spec->splitpath(File::Spec->rel2abs($path));
    $drive =~ s/:$//;
    s{\\}{/}g for @rest;
    return "/cygdrive/$drive" . join('/', @rest);
}

our $debug; # make debug visible below
package Net::SSH::Any::OS::MSWin::Process;

sub DESTROY {
    my $proc = shift;
    if (defined(my $handle = delete $proc->{handle})) {
        $debug and $debug & 1024 and Net::SSH::Any::Util::_debug("closing process handle $handle");
        $win32_close_handle->Call($handle);
    }
}



1;
