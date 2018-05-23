package Pcore::Util::PM::Proc;

use Pcore -class;
use Config;
use Pcore::AE::Handle;
use Pcore::Util::Scalar qw[refcount weaken is_blessed_ref];
use AnyEvent::Util qw[portable_socketpair];
use if $MSWIN, 'Win32::Process';
use overload    #
  q[bool] => sub {
    return $_[0]->is_success;
  },
  q[0+] => sub {
    return $_[0]->{status};
  },
  q[<=>] => sub {
    return !$_[2] ? $_[0]->{status} <=> $_[1] : $_[1] <=> $_[0]->{status};
  },
  fallback => undef;

has pid => ( is => 'ro', isa => PositiveInt, init_arg => undef );
has status => ( is => 'ro', isa => Maybe [Int], init_arg => undef );    # undef - process is still alive
has reason => ( is => 'ro', isa => Str, init_arg => undef );

has stdin  => ( is => 'ro', isa => InstanceOf ['Pcore::AE::Handle'], init_arg => undef );    # process STDIN, we can write
has stdout => ( is => 'ro', isa => InstanceOf ['Pcore::AE::Handle'], init_arg => undef );    # process STDOUT, we can read
has stderr => ( is => 'ro', isa => InstanceOf ['Pcore::AE::Handle'], init_arg => undef );    # process STDERR, we can read

has _on_finish => ( is => 'ro', isa => Maybe [CodeRef], init_arg => undef );                 # on_finish callback
has _win32_proc => ( is => 'ro', isa => InstanceOf ['Win32::Process'], init_arg => undef );  # MSWIN process descriptor
has _sigchild => ( is => 'ro', isa => Object, init_arg => undef );

our $CACHE = {};

sub DESTROY ( $self ) {
    if ( $self->{pid} ) {

        if ($MSWIN) {

            # https://perldoc.perl.org/perlport.html#DOS-and-Derivatives
            #
            # (Win32) kill doesn't send a signal to the identified process like it does on Unix platforms.
            # Instead kill($sig, $pid) terminates the process identified by $pid , and makes it exit immediately with exit status $sig.
            # As in Unix, if $sig is 0 and the specified process exists, it returns true without actually terminating it.
            #
            # (Win32) kill(-9, $pid) will terminate the process specified by $pid and recursively all child processes owned by it.
            # This is different from the Unix semantics, where the signal will be delivered to all processes in the same process group as the process specified by $pid.

            # kill process group, eg.: windows console subprocess
            kill '-KILL', $self->{pid};    ## no critic qw[InputOutput::RequireCheckedSyscalls]

            # kill process, because -SIG is ignored by process itself
            kill 'KILL', $self->{pid};     ## no critic qw[InputOutput::RequireCheckedSyscalls]
        }
        else {

            # term process
            kill 'TERM', $self->{pid};     ## no critic qw[InputOutput::RequireCheckedSyscalls]
        }
    }

    $self->_on_exit( 128 + 9 ) if ${^GLOBAL_PHASE} ne 'DESTRUCT';

    return;
}

around new => sub ( $orig, $self, $cmd, @ ) {
    $cmd = [$cmd] if !ref $cmd;

    my $blocking = defined wantarray;

    my %args = (
        stdin                  => 0,
        stdout                 => 0,
        stderr                 => 0,        # NOTE 2 - merge STDERR with STDOUT
        on_ready               => undef,    # CodeRef
        on_finish              => undef,    # CodeRef
        win32_cflags           => 0,        # NOTE not works if not 0, Win32::Process::CREATE_NO_WINDOW(),
        win32_create_no_window => 0,        # NOTE preventing to redirect handles
        win32_alive_timeout    => 0.5,
        @_[ 3 .. $#_ ],
    );

    $args{win32_cflags} = Win32::Process::CREATE_NO_WINDOW() if $MSWIN && delete $args{win32_create_no_window};

    my $hdl = $self->_redirect_std( \%args );

    # create process
    my $proc = $self->_create_process( $args{win32_cflags}, $cmd );

    # restore old STD* handles
    open STDIN,  '<&', $hdl->{old_in}  or die if $hdl->{old_in};
    open STDOUT, '>&', $hdl->{old_out} or die if $hdl->{old_out};
    open STDERR, '>&', $hdl->{old_err} or die if $hdl->{old_err};

    # handle error creating process
    if ( !$proc->pid ) {
        $proc->{status} = -1;

        $proc->{reason} = 'Error creating process';

        $args{on_finish}->($proc) if $args{on_finish};

        if ($blocking) {
            return $proc;
        }
        else {
            die $proc->{reason};
        }
    }

    # store proc attributes
    $proc->{_on_finish} = $args{on_finish};

    # create and store AE handles
    $proc->_create_handles($hdl);

    # create and start SIGCHILD listener
    $proc->_create_sigchild( $args{win32_alive_timeout} ) if !$blocking;

    # call on_ready callback if present
    $args{on_ready}->($proc) if $args{on_ready};

    $CACHE->{ $proc->{pid} } = $proc if !$blocking && refcount($proc) == 1;

    if ($blocking) {
        if ($MSWIN) {

            # blocking wait
            $proc->{_win32_proc}->Wait( Win32::Process::INFINITE() );

            $proc->{_win32_proc}->GetExitCode( my $status );

            $proc->_on_exit($status);
        }
        else {

            # blocking wait
            waitpid $proc->{pid}, 0 or die;

            $proc->_on_exit( $? >> 8 );
        }
    }

    return $blocking ? $proc : ();
};

sub _redirect_std ( $self, $args ) {
    my $hdl;

    # create STDIN
    if ( $args->{stdin} ) {
        ( $hdl->{in_r}, $hdl->{in_w} ) = portable_socketpair();

        # backup current STDIN handle
        open $hdl->{old_in}, '<&', *STDIN or die;
    }

    # create STDOUT
    if ( $args->{stdout} ) {
        ( $hdl->{out_r}, $hdl->{out_w} ) = portable_socketpair();

        # backup current STDOUT handle
        binmode *STDOUT or die if $MSWIN;
        open $hdl->{old_out}, '>&', *STDOUT or die;
        Pcore::config_stdout(*STDOUT) if $MSWIN;
    }

    # create STDERR
    if ( $args->{stderr} ) {
        if ( $args->{stderr} == 2 ) {
            ( $hdl->{out_r}, $hdl->{out_w} ) = portable_socketpair() if !$args->{stdout};
        }
        else {
            ( $hdl->{err_r}, $hdl->{err_w} ) = portable_socketpair();
        }

        # backup current STDERR handle
        binmode *STDERR or die if $MSWIN;
        open $hdl->{old_err}, '>&', *STDERR or die;
        Pcore::config_stdout(*STDERR) if $MSWIN;
    }

    # redirect STD* handles
    open STDIN,  '<&', $hdl->{in_r}  or die if $args->{stdin};
    open STDOUT, '>&', $hdl->{out_w} or die if $args->{stdout};
    open STDERR, '>&', $args->{stderr} == 2 ? $hdl->{out_w} : $hdl->{err_w} or die if $args->{stderr};

    return $hdl;
}

sub _create_process ( $self, $win32_cflags, $cmd ) {

    # prepare environment
    local $ENV{PERL5LIB} = join $Config{path_sep}, grep { !ref } @INC;
    local $ENV{PATH} = "$ENV{PATH}$Config{path_sep}$ENV{PAR_TEMP}" if $ENV->{is_par};

    my $proc = bless {}, $self;

    # run process
    if ($MSWIN) {
        Win32::Process::Create(    #
            my $win32_proc,
            $ENV{COMSPEC},
            q[/D /C "] . join( q[ ], $cmd->@* ) . q["],
            1,                     # inherit STD* handles
            $win32_cflags,
            q[.]
        );

        if ($win32_proc) {
            $proc->{_win32_proc} = $win32_proc;

            $proc->{pid} = $proc->{_win32_proc}->GetProcessID;
        }
    }
    else {
        unless ( $proc->{pid} = fork ) {

            # run process in own PGRP
            setpgrp;    ## no critic qw[InputOutput::RequireCheckedSyscalls]

            exec $cmd->@* or die $!;
        }
    }

    return $proc;
}

sub _create_handles ( $self, $hdl ) {
    weaken $self;

    # create STDIN handle
    if ( $hdl->{in_w} ) {
        Pcore::AE::Handle->new(
            fh         => $hdl->{in_w},
            on_connect => sub ( $h, @ ) {
                $self->{stdin} = $h;

                return;
            },
        );
    }

    # create STDOUT handle
    if ( $hdl->{out_r} ) {
        Pcore::AE::Handle->new(
            fh         => $hdl->{out_r},
            on_connect => sub ( $h, @ ) {
                $self->{stdout} = $h;

                return;
            },
            on_error => sub ( $h, $fatal, $msg ) {
                $self->{stdout} = delete $h->{rbuf};

                return;
            },
            on_read => sub { },
        );
    }

    # create STDERR handle
    if ( $hdl->{err_r} ) {
        Pcore::AE::Handle->new(
            fh         => $hdl->{err_r},
            on_connect => sub ( $h, @ ) {
                $self->{stderr} = $h;

                return;
            },
            on_error => sub ( $h, $fatal, $msg ) {
                $self->{stderr} = delete $h->{rbuf};

                return;
            },
            on_read => sub { },
        );
    }

    return;
}

sub _create_sigchild ( $self, $win32_alive_timeout ) {
    weaken $self;

    if ($MSWIN) {
        $self->{_sigchild} = AE::timer 0, $win32_alive_timeout, sub {
            $self->{_win32_proc}->GetExitCode( my $status );

            if ( $status != Win32::Process::STILL_ACTIVE() ) {
                undef $self->{_sigchild};    # remove timer

                $self->_on_exit($status);
            }

            return;
        };
    }
    else {
        $self->{_sigchild} = AE::child $self->pid, sub ( $pid, $status ) {
            undef $self->{_sigchild};        # remove timer

            $self->_on_exit( $status >> 8 );

            return;
        };
    }

    return;
}

sub is_success ($self) {
    return if !$self->pid;

    return !$self->{status};
}

sub _on_exit ( $self, $status ) {
    return if defined $self->{status};

    # set status
    $self->{status} = $status;

    # set reason
    $self->{reason} //= do {
        if ( $self->{status} == 0 ) {
            'OK';
        }
        else {
            'Process terminated with exit code: ' . $self->{status};
        }
    };

    # cleanup
    delete $self->@{qw[stdin _win32_proc _sigchild]};

    delete $CACHE->{ $self->{pid} };

    if ( $self->{stdout} && is_blessed_ref $self->{stdout} ) {
        $self->{stdout} = delete $self->{stdout}->{rbuf};
    }

    if ( $self->{stderr} && is_blessed_ref $self->{stderr} ) {
        $self->{stderr} = delete $self->{stderr}->{rbuf};
    }

    if ( my $on_finish = delete $self->{_on_finish} ) {
        $on_finish->($self);
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
## |    3 | 1                    | Modules::ProhibitExcessMainComplexity - Main code has high complexity score (25)                               |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 148                  | Subroutines::ProhibitExcessComplexity - Subroutine "_redirect_std" with high complexity score (23)             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::PM::Proc

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
