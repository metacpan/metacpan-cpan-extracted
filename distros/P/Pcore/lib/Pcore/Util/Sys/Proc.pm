package Pcore::Util::Sys::Proc;

use Pcore -const, -class;
use Pcore::Util::Scalar qw[is_ref];
use AnyEvent::Util qw[portable_socketpair];
use if $MSWIN, 'Win32::Process';
use POSIX qw[:sys_wait_h];
use Config qw[%Config];
use overload    #
  q[bool] => sub { return $_[0]->is_success },
  q[<=>]  => sub { return !$_[2] ? $_[0]->_get_exit_code <=> $_[1] : $_[1] <=> $_[0]->_get_exit_code },
  q[""]   => sub { return $_[0]->{status} . $SPACE . $_[0]->{reason} },
  fallback => undef;

has win32_alive_timeout => 0.5;
has kill_on_destroy     => 1;

has stdin  => ();
has stdout => ();
has stderr => ();

has pid       => ();
has exit_code => ();
has status    => ();
has reason    => ();

has _win32_proc => ();

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

    $self = $self->$orig( kill_on_destroy => $args{kill_on_destroy} // 1 );

    if ($MSWIN) {
        $self->{win32_alive_timeout} = $args{win32_alive_timeout} if defined $args{win32_alive_timeout};
        $args{win32_cflags} //= $args{win32_create_no_window} ? Win32::Process::CREATE_NO_WINDOW() : 0;    # NOTE handles redirect not works if not 0, Win32::Process::CREATE_NO_WINDOW(),
    }

    my ( $child_stdin,  $child_stdout,  $child_stderr );
    my ( $backup_stdin, $backup_stdout, $backup_stderr );

    # redirect STDIN
    if ( $args{stdin} ) {
        ( $child_stdin, my $parent_stdin ) = portable_socketpair();

        $self->{stdin} = P->handle($parent_stdin);

        # backup and redirect
        open $backup_stdin, '<&', *STDIN       or die $!;    ## no critic qw[InputOutput::RequireBriefOpen]
        open *STDIN,        '<&', $child_stdin or die $!;
    }

    # redirect STDOUT
    if ( $args{stdout} ) {
        ( my $parent_stdout, $child_stdout ) = portable_socketpair();

        $self->{child_stdout} = $child_stdout;

        $self->{stdout} = P->handle($parent_stdout);

        # backup and redirect
        open $backup_stdout, '>&', *STDOUT       or die $!;    ## no critic qw[InputOutput::RequireBriefOpen]
        open *STDOUT,        '>&', $child_stdout or die $!;
    }

    # redirect STDERR
    if ( $args{stderr} ) {

        # redirect STDERR to STDOUT
        if ( $args{stderr} == 2 ) {

            # redirect STDERR to child STDOUT
            if ( $args{stdout} ) {
                $child_stderr = $child_stdout;
            }

            # redirect STDERR to parent STDOUT
            else {
                open $child_stderr, '>&', *STDOUT or die $!;    ## no critic qw[InputOutput::RequireBriefOpen]
            }
        }
        else {
            ( my $parent_stderr, $child_stderr ) = portable_socketpair();

            $self->{child_stderr} = $child_stderr;

            $self->{stderr} = P->handle($parent_stderr);
        }

        # backup and redirect
        open $backup_stderr, '>&', *STDERR       or die $!;     ## no critic qw[InputOutput::RequireBriefOpen]
        open *STDERR,        '>&', $child_stderr or die $!;
    }

    # create process
    $self->_create_process(
        $cmd,
        $args{win32_cflags},
        sub {
            # restore old STD* handles
            open *STDIN,  '<&', $backup_stdin  or die $! if defined $backup_stdin;
            open *STDOUT, '>&', $backup_stdout or die $! if defined $backup_stdout;
            open *STDERR, '>&', $backup_stderr or die $! if defined $backup_stderr;

            return;
        }
    );

    return $self;
};

# TODO under windows run directly and handle process creation error
sub _create_process ( $self, $cmd, $win32_cflags, $restore ) {

    # prepare environment
    local $ENV{PERL5LIB} = join $Config{path_sep}, grep { !ref } @INC;
    local $ENV{PATH} = "$ENV{PATH}$Config{path_sep}$ENV{PAR_TEMP}" if $ENV->{is_par};

    # run process
    if ($MSWIN) {

        # TODO unable to properly handle process creation error, when running via $ENV{COMSPEC}
        # but when running directly - handles redirects not works
        Win32::Process::Create(    #
            my $win32_proc,
            $ENV{COMSPEC},
            '/D /C "' . join( $SPACE, $cmd->@* ) . '"',
            1,                     # inherit STD* handles
            $win32_cflags,
            '.'
        );

        $restore->();

        if ($win32_proc) {
            $self->{_win32_proc} = $win32_proc;

            # get PID
            $self->{pid} = $win32_proc->GetProcessID;

            # error creating process
            if ( !$self->{pid} ) {
                $self->_set_exit_code(-1);

                return;
            }
        }

        # error creating process
        else {
            $self->_set_exit_code(-1);

            return;
        }
    }
    else {
        my ( $r, $w ) = portable_socketpair();

        unless ( $self->{pid} = fork ) {

            # run process in own PGRP
            setpgrp;    ## no critic qw[InputOutput::RequireCheckedSyscalls]

            local $SIG{__WARN__} = sub { };

            exec $cmd->@* or do {
                syswrite $w, "$!\n" or die $!;

                POSIX::_exit(-1);
            };
        }
        else {
            $restore->();

            close $w or die $!;

            my $h = P->handle($r);

            if ( my $err = $h->read_line("\n") ) {
                $self->_set_exit_code( -1, $err->$* );

                return;
            }
        }
    }

    $self->{status} = $PROC_STATUS_ACTIVE;
    $self->{reason} = $STATUS_REASON->{$PROC_STATUS_ACTIVE};

    return;
}

sub wait ($self) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    return $self if $self->{status} != $PROC_STATUS_ACTIVE;

    my $cv = P->cv;

    my $watcher;

    if ($MSWIN) {
        $watcher = AE::timer 0, $self->{win32_alive_timeout}, sub {

            # -1 - pid is unknown, 0 - active, > 0 - terminated
            if ( waitpid $self->{pid}, WNOHANG ) {
                $self->{_win32_proc}->GetExitCode( my $exit_code );

                $cv->($exit_code);
            }

            return;
        };
    }
    else {
        $watcher = AE::child $self->{pid}, sub ( $pid, $exit_code ) {
            $cv->( $exit_code >> 8 );

            return;
        };
    }

    $self->_set_exit_code( $cv->recv );

    return $self;
}

sub capture ( $self, %args ) {
    undef $self->{child_stdout};
    $self->{stdout} = $self->{stdout}->read_eof( timeout => $args{timeout} ) if $self->{stdout};

    undef $self->{child_stderr};
    $self->{stderr} = $self->{stderr}->read_eof( timeout => $args{timeout} ) if $self->{stderr};

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
## |    3 | 1                    | Modules::ProhibitExcessMainComplexity - Main code has high complexity score (27)                               |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Sys::Proc

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
