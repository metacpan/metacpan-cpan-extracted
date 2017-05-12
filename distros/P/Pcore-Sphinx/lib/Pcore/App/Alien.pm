package Pcore::App::Alien;

use Pcore -class;
use POSIX qw[:sys_wait_h];

extends qw[Pcore::App::Base];

has alien_dir      => ( is => 'lazy', isa => Str, init_arg => undef );
has alien_data_dir => ( is => 'lazy', isa => Str, init_arg => undef );
has alien_bin_path => ( is => 'lazy', isa => Str, init_arg => undef );
has alien_cfg_path => ( is => 'lazy', isa => Str, init_arg => undef );

has alien_pid => ( is => 'rwp', isa => Int, init_arg => undef );

has term_state => ( is => 'rw', isa => Bool, default => 0, init_arg => undef );

# APP
sub store_alien_cfg ( $self, $cfg_ref ) {
    P->file->write_text( $self->alien_cfg_path, { mode => q[rw-r--r--] }, $cfg_ref );

    return;
}

around app_run => sub ( $orig, $self ) {
    $self->$orig;

    # alien process fork routine
    if ($MSWIN) {
        my $term = sub {
            exit 0;
        };

        $SIG->{HUP}  = AE::signal HUP  => $term;
        $SIG->{INT}  = AE::signal INT  => $term;
        $SIG->{QUIT} = AE::signal QUIT => $term;
        $SIG->{TERM} = AE::signal TERM => $term;
    }
    else {
        $self->_fork_child;

        my $IGNORE_TERM;

        my $EXIT_CODE = 0;

        # default exit signal handler
        my $term = sub {
            if ($IGNORE_TERM) {
                $IGNORE_TERM = 0;

                return;
            }

            # master process will be terminated on the next SIG CHILD
            $self->term_state(1);

            # send TERM to child process
            kill 'TERM', $self->alien_pid;    ## no critic qw[InputOutput::RequireCheckedSyscalls]

            return;
        };

        my $cv = AE::cv;

        # set default SIG handlers, they can be redefined later in master callback
        $SIG->{HUP}  = AE::signal HUP  => $term;
        $SIG->{INT}  = AE::signal INT  => $term;
        $SIG->{QUIT} = AE::signal QUIT => $term;
        $SIG->{TERM} = AE::signal TERM => $term;
        $SIG->{CHILD} = AE::child 0, sub ( $pid, $exit_code ) {
            if ( $self->term_state ) {
                $EXIT_CODE = $exit_code;

                $cv->send;
            }
            else {
                # kill process group
                $IGNORE_TERM = 1;

                kill '-TERM', $$;    ## no critic qw[InputOutput::RequireCheckedSyscalls]

                $self->_fork_child;  # re-up child
            }

            return;
        };

        # run master process callback if specified
        $self->master_proc;

        $cv->recv;

        exit $EXIT_CODE;
    }
};

sub _fork_child ($self) {
    if ( my $alien_pid = fork ) {    # parent process
        $self->_set_alien_pid($alien_pid);

        return;
    }
    else {                           # child process
        $self->alien_proc;

        exit 0;
    }
}

sub master_proc ($self) {
    ...;                             ## no critic qw[ControlStructures::ProhibitYadaOperator]

    return;
}

sub alien_proc ($self) {
    ...;                             ## no critic qw[ControlStructures::ProhibitYadaOperator]

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::Alien

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
