package Pcore::Util::Sys::Proc;

use Pcore -const, -class, -export;
use Pcore::Util::Scalar qw[is_path is_ref is_plain_scalarref weaken];
use Pcore::Util::Text qw[encode_utf8];
use AnyEvent::Util qw[portable_socketpair];
use if $MSWIN, 'Win32::Process';
use if $MSWIN, 'Win32API::File';
use POSIX qw[:sys_wait_h];
use Config qw[%Config];
use overload    #
  q[bool]  => sub { return $_[0]->is_success },
  q[<=>]   => sub { return !$_[2] ? $_[0]->_get_exit_code <=> $_[1] : $_[1] <=> $_[0]->_get_exit_code },
  q[""]    => sub { return $_[0]->{status} . $SPACE . $_[0]->{reason} },
  fallback => undef;

our $EXPORT = { PROC_REDIRECT => [qw[$PROC_REDIRECT_SOCKET $PROC_REDIRECT_STDOUT $PROC_REDIRECT_FH]], };

has win32_alive_timeout => 0.5;
has kill_on_destroy     => 1;

has stdin  => ();
has stdout => ();
has stderr => ();

has pid       => ();
has exit_code => ();
has status    => ();
has reason    => ();

has child_stdin  => ( init_arg => undef );
has child_stderr => ( init_arg => undef );

has _win32_proc => ();
has _watcher    => ();
has _watcher_cb => ();

const our $PROC_REDIRECT_SOCKET => 1;
const our $PROC_REDIRECT_STDOUT => 2;
const our $PROC_REDIRECT_FH     => 3;

const our $PROC_STATUS_ACTIVE             => 0;
const our $PROC_STATUS_TERMINATED_SUCCESS => 200;
const our $PROC_STATUS_CREATE_ERROR       => 400;
const our $PROC_STATUS_TERMINATED_ERROR   => 500;

const our $STATUS_REASON => {
    $PROC_STATUS_CREATE_ERROR       => 'Error creating process',
    $PROC_STATUS_ACTIVE             => 'Active',
    $PROC_STATUS_TERMINATED_SUCCESS => 'Success',
    $PROC_STATUS_TERMINATED_ERROR   => 'Error',
};

sub IS_PCORE_RESULT { }

sub DESTROY ( $self ) {
    return if !$self->{kill_on_destroy};

    if ( !$self->{status} && $self->{pid} ) {

        # NOTE https://metacpan . org / source /MOB/ Forks-Super- 0.80 / lib / Forks / Super / Job / OS / Win32 . pm    #L261
        if ($MSWIN) {

            # NOTE https://perldoc.perl.org/perlport.html#DOS-and-Derivatives

            # (Win32) kill doesn't send a signal to the identified process like it does on Unix platforms.
            # Instead kill($sig, $pid) terminates the process identified by $pid , and makes it exit immediately with exit status $sig.
            # As in Unix, if $sig is 0 and the specified process exists, it returns true without actually terminating it.

            # (Win32) kill(-9, $pid) will terminate the process specified by $pid and recursively all child processes owned by it.
            # This is different from the Unix semantics, where the signal will be delivered to all processes in the same process group as the process specified by $pid.

            # kill process group, eg.: windows console subprocess
            CORE::kill '-KILL', $self->{pid};

            # kill process, because -SIG is ignored by process itself
            CORE::kill 'KILL', $self->{pid};
        }
        else {

            # term process
            CORE::kill 'TERM', $self->{pid};
        }
    }

    return;
}

around new => sub ( $orig, $self, $cmd, %args ) {
    $cmd = [$cmd] if !is_ref $cmd;

    $self = $self->$orig( kill_on_destroy => $args{kill_on_destroy} // 1, );

    if ($MSWIN) {
        $self->{win32_alive_timeout} = $args{win32_alive_timeout} if defined $args{win32_alive_timeout};
        $args{win32_cflags} //= 0;    # NOTE handles redirect not works if not 0, Win32::Process::CREATE_NO_WINDOW(),
    }
    else {
        $args{setpgid} //= 1;
    }

    # redirect handles
    my $backup_stdin  = $args{stdin}  ? $self->_redirect_stdin( \%args )  : undef;
    my $backup_stdout = $args{stdout} ? $self->_redirect_stdout( \%args ) : undef;
    my $backup_stderr = $args{stderr} ? $self->_redirect_stderr( \%args ) : undef;

    # create process
    $self->_create_process(
        $cmd,
        \%args,
        sub {

            # restore original STD* handles
            open *STDIN,  '<&', $backup_stdin  or die $! if defined $backup_stdin;
            open *STDOUT, '>&', $backup_stdout or die $! if defined $backup_stdout;
            open *STDERR, '>&', $backup_stderr or die $! if defined $backup_stderr;

            return;
        }
    );

    return $self;
};

sub _redirect_stdin ( $self, $args ) {
    my ( $backup, $child );

    # backup
    open $backup, '<&', *STDIN or do {    ## no critic qw[InputOutput::RequireBriefOpen]

        # windows os native fh is invalid, reopen STDIN to NUL
        if ( $MSWIN && Win32API::File::GetOsFHandle(*STDIN) == 18446744073709551614 ) {
            open $backup, '<', 'NUL' or die $!;
        }
        else {
            die $!;
        }
    };

    # redirect to the temporary filehandle
    if ( is_plain_scalarref $args->{stdin} ) {
        my $temp = $self->{stdin} = P->file1->tempfile;

        P->file->write_bin( $temp, encode_utf8 $args->{stdin}->$* );

        open $child, '<:raw', $temp or die $!;    ## no critic qw[InputOutput::RequireBriefOpen]
    }

    # redirect to the socket
    elsif ( $args->{stdin} == $PROC_REDIRECT_SOCKET ) {
        ( $child, my $parent ) = portable_socketpair();

        $self->{stdin} = P->handle($parent);
    }
    else {
        die 'Invalid redirect target for STDIN';
    }

    # redirect
    open *STDIN, '<&', $child or die $!;

    return $backup;
}

sub _redirect_stdout ( $self, $args ) {
    my $backup;

    # backup
    open $backup, '>&', *STDOUT or do {    ## no critic qw[InputOutput::RequireBriefOpen]

        # windows os native fh is invalid, reopen STDOUT to NUL
        if ( $MSWIN && Win32API::File::GetOsFHandle(*STDERR) == 18446744073709551614 ) {
            open $backup, '>', 'NUL' or die $!;
        }
        else {
            die $!;
        }
    };

    # redirect to the temporary filehandle
    if ( $args->{stdout} == $PROC_REDIRECT_FH ) {
        $self->{stdout} = P->file1->tempfile;

        # redirect
        open *STDOUT, '>:raw', $self->{stdout} or die $!;
    }

    # redirect to the socket
    elsif ( $args->{stdout} == $PROC_REDIRECT_SOCKET ) {
        my ( $parent, $child ) = portable_socketpair();

        $self->{child_stdout} = $child;

        $self->{stdout} = P->handle($parent);

        # redirect
        open *STDOUT, '>&', $child or die $!;
    }
    else {
        die 'Invalid redirect target for STDOUT';
    }

    return $backup;
}

sub _redirect_stderr ( $self, $args ) {
    my $backup;

    # backup
    open $backup, '>&', *STDERR or do {    ## no critic qw[InputOutput::RequireBriefOpen]

        # windows os native fh is invalid, reopen STDERR to NUL
        if ( $MSWIN && Win32API::File::GetOsFHandle(*STDERR) == 18446744073709551614 ) {
            open $backup, '>', 'NUL' or die $!;
        }
        else {
            die $!;
        }
    };

    # redirect to the temporary filehandle
    if ( $args->{stderr} == $PROC_REDIRECT_FH ) {
        $self->{stderr} = P->file1->tempfile;

        # redirect STDERR
        open *STDERR, '>:raw', $self->{stderr} or die $!;
    }

    # redirect to the socket
    elsif ( $args->{stderr} == $PROC_REDIRECT_SOCKET ) {
        my ( $parent, $child ) = portable_socketpair();

        $self->{child_stderr} = $child;

        $self->{stderr} = P->handle($parent);

        # redirect
        open *STDERR, '>&', $child or die $!;
    }

    # redirect to the STDOUT
    elsif ( $args->{stderr} == $PROC_REDIRECT_STDOUT ) {
        if ( defined $self->{stdout} ) {
            open *STDERR, '>:raw', $self->{stdout} or die $!;
        }
        else {
            open *STDERR, '>&', *STDOUT or die $!;
        }
    }
    else {
        die 'Invalid redirect target for STDERR';
    }

    return $backup;
}

# TODO under windows run directly and handle process creation error
sub _create_process ( $self, $cmd, $args, $restore ) {

    # prepare environment
    # local $ENV{PERL5LIB} = join $Config{path_sep}, grep { !ref } @INC;
    local $ENV{PATH} = "$ENV{PATH}$Config{path_sep}$ENV{PAR_TEMP}" if $ENV->{is_par};

    my $chdir_guard = $args->{chdir} ? P->file->chdir( $args->{chdir} ) : undef;

    # run process
    if ($MSWIN) {

        # TODO unable to properly handle process creation error, when running via $ENV{COMSPEC}
        # but when running directly - handles redirects not works
        Win32::Process::Create(    #
            my $win32_proc,
            $ENV{COMSPEC},
            '/D /C "' . join( $SPACE, $cmd->@* ) . '"',
            1,                     # inherit STD* handles
            $args->{win32_cflags},
            '.'
        );

        $restore->();

        undef $chdir_guard;

        if ($win32_proc) {
            $self->{_win32_proc} = $win32_proc;

            # get PID
            $self->{pid} = $win32_proc->GetProcessID;

            # error creating process
            if ( !$self->{pid} ) {
                $self->_set_exit_code(-1);

                return;
            }

            $self->{status} = $PROC_STATUS_ACTIVE;
            $self->{reason} = $STATUS_REASON->{$PROC_STATUS_ACTIVE};

            $self->_set_watcher;
        }

        # error creating process
        else {
            $self->_set_exit_code(-1);

            return;
        }
    }
    else {
        my ( $r, $w ) = portable_socketpair();

        # child process
        unless ( $self->{pid} = fork ) {

            # run process in own session
            POSIX::setsid() if $args->{setsid};

            # run process in own PGRP
            POSIX::setpgid( 0, 0 ) if $args->{setpgid};

            local $SIG{__WARN__} = sub { };

            exec $cmd->@* or do {
                syswrite $w, "$!\n" or die $!;

                POSIX::_exit(-1);
            };
        }

        # parent process
        else {
            $restore->();

            undef $chdir_guard;

            $self->{status} = $PROC_STATUS_ACTIVE;
            $self->{reason} = $STATUS_REASON->{$PROC_STATUS_ACTIVE};

            $self->_set_watcher;

            close $w or die $!;

            my $h = P->handle($r);

            if ( my $err = $h->read_line("\n") ) {
                $self->_set_exit_code( -1, $err->$* );

                return;
            }
        }
    }

    return;
}

sub _set_watcher ($self) {
    return if $self->{status} != $PROC_STATUS_ACTIVE;

    weaken $self;

    if ($MSWIN) {
        $self->{_watcher} = AE::timer 0, $self->{win32_alive_timeout}, sub {

            # -1 - pid is unknown, 0 - active, > 0 - terminated
            if ( waitpid $self->{pid}, WNOHANG ) {
                undef $self->{_watcher};

                ( delete $self->{_win32_proc} )->GetExitCode( my $exit_code );

                $self->_set_exit_code($exit_code);

                if ( my $cb = delete $self->{_watcher_cb} ) {
                    $cb->();
                }

            }

            return;
        };
    }
    else {
        $self->{_watcher} = AE::child $self->{pid}, sub ( $pid, $exit_code ) {
            undef $self->{_watcher};

            $self->_set_exit_code( $exit_code >> 8 );

            if ( my $cb = delete $self->{_watcher_cb} ) {
                $cb->();
            }

            return;
        };
    }

    return $self;
}

sub wait ($self) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    return $self if $self->{status} != $PROC_STATUS_ACTIVE;

    ( $self->{_watcher_cb} = P->cv )->recv;

    return $self;
}

sub capture ( $self, %args ) {
    $self->wait;

    # capture STDOUT
    if ( $self->{stdout} ) {

        # capture from the fh
        if ( is_path $self->{stdout} ) {
            $self->{stdout} = \P->file->read_bin( $self->{stdout} );
        }

        # capture from the socket
        else {
            undef $self->{child_stdout};

            $self->{stdout} = $self->{stdout}->read_eof( timeout => $args{timeout} );
        }
    }

    # capture STDERR
    if ( $self->{stderr} ) {

        # capture from the fh
        if ( is_path $self->{stderr} ) {
            $self->{stderr} = \P->file->read_bin( $self->{stderr} );
        }

        # capture from the socket
        else {
            undef $self->{child_stderr};

            $self->{stderr} = $self->{stderr}->read_eof( timeout => $args{timeout} );
        }
    }

    return $self;
}

sub is_active ($self) {
    return if $self->{status} != $PROC_STATUS_ACTIVE;

    # TRUE - terminated, -1 under linux, PID under windows
    if ( waitpid $self->{pid}, WNOHANG ) {
        my $exit_code;

        if ($MSWIN) {
            $self->{_win32_proc}->GetExitCode($exit_code);
        }
        else {
            $exit_code = $? >> 8;
        }

        $self->_set_exit_code($exit_code);

        return;
    }
    else {
        return 1;
    }
}

sub is_success ($self) {
    $self->wait if $self->{status} == $PROC_STATUS_ACTIVE;

    return !$self->{exit_code};
}

sub is_error ($self) {
    $self->wait if $self->{status} == $PROC_STATUS_ACTIVE;

    return !!$self->{exit_code};
}

sub _get_exit_code ($self) {
    $self->wait if $self->{status} == $PROC_STATUS_ACTIVE;

    return $self->{exit_code};
}

sub _set_exit_code ( $self, $exit_code, $reason = undef ) {
    return if $self->{status};

    $self->{exit_code} = $exit_code;

    # success
    if ( !$exit_code ) {
        $self->{status} = $PROC_STATUS_TERMINATED_SUCCESS;
        $self->{reason} = $reason // "$STATUS_REASON->{$PROC_STATUS_TERMINATED_SUCCESS}, exit code: 0";
    }

    elsif ( $exit_code == -1 ) {
        $self->{status} = $PROC_STATUS_CREATE_ERROR;
        $self->{reason} = $reason // $STATUS_REASON->{$PROC_STATUS_CREATE_ERROR};
    }

    # error
    else {
        $self->{status} = $PROC_STATUS_TERMINATED_ERROR;
        $self->{reason} = $reason // "$STATUS_REASON->{$PROC_STATUS_TERMINATED_ERROR}, exit code: $exit_code";
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 132, 172, 213        | ValuesAndExpressions::RequireNumberSeparators - Long number not separated with underscores                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Sys::Proc

=head1 SYNOPSIS

    my $proc = P->sys->run_proc(
        $cmd,
        stdin                  => 0,
        stdout                 => 0,
        stderr                 => 0,
        setsid                 => 0,
        setpgid                => 1,
        win32_alive_timeout    => 0.5,
        kill_on_destroy        => 1,
    )->wait;

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
