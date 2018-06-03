package Pcore::Node::Proc;

use Pcore -class;
use Fcntl;
use Pcore::AE::Handle;
use AnyEvent::Util qw[portable_pipe];
use if $MSWIN, 'Win32API::File';
use Pcore::Util::Data qw[to_cbor from_cbor];
use Pcore::Util::PM::Proc;

# TODO on_finish is not called, because we can't get SIGCHLD for non-direct child

around new => sub ( $orig, $self, $type, % ) {
    my %args = (
        server    => undef,    # node server credentials
        listen    => undef,    # Node listen
        buildargs => undef,    # class constructor arguments
        on_ready  => undef,
        on_finish => undef,
        @_[ 3 .. $#_ ],
    );

    # create handles
    my ( $fh_r, $fh_w ) = portable_pipe();

    my $boot_args = {
        script_path => $ENV->{SCRIPT_PATH},
        version     => $main::VERSION->normal,
        scandeps    => $ENV->{SCAN_DEPS} ? 1 : undef,
        server      => $args{server},
        listen      => $args{listen},
        buildargs   => $args{buildargs},
    };

    if ($MSWIN) {
        $boot_args->{fh} = Win32API::File::FdGetOsFHandle( fileno $fh_w );
    }
    else {
        fcntl $fh_w, Fcntl::F_SETFD, fcntl( $fh_w, Fcntl::F_GETFD, 0 ) & ~Fcntl::FD_CLOEXEC or die;

        $boot_args->{fh} = fileno $fh_w;
    }

    if ($Pcore::Util::PM::ForkTmpl::CHILD_PID) {
        Pcore::Util::PM::ForkTmpl::run_node( $type, $boot_args );

        $self->_handshake(
            $fh_r,
            sub ($res) {

                # TODO on_finish is not called, because we can't get SIGCHLD for non-direct child
                my $proc = bless {
                    pid        => $res->{pid},
                    _on_finish => $args{on_finish},
                  },
                  'Pcore::Util::PM::Proc';

                $args{on_ready}->($proc);

                return;
            }
        );
    }
    else {
        state $perl = do {
            if ( $ENV->{is_par} ) {
                "$ENV{PAR_TEMP}/perl" . ( $MSWIN ? '.exe' : q[] );
            }
            else {
                $^X;
            }
        };

        my $cmd = [];

        if ($MSWIN) {
            push $cmd->@*, $perl, "-MPcore::Node=$type";
        }
        else {
            push $cmd->@*, $perl, "-MPcore::Node=$type";
        }

        # create proc
        P->pm->run_proc(
            $cmd,
            stdin    => 1,
            on_ready => sub ($proc) {

                # send configuration to proc STDIN
                $proc->stdin->push_write( unpack( 'H*', to_cbor($boot_args)->$* ) . $LF );

                $self->_handshake(
                    $fh_r,
                    sub ($res) {
                        $args{on_ready}->($proc);

                        return;
                    }
                );

                return;
            },
            on_finish => $args{on_finish}
        );
    }

    return;
};

sub _handshake ( $self, $fh, $cb ) {

    # wrap control_fh
    Pcore::AE::Handle->new(
        fh         => $fh,
        on_connect => sub ( $h, @ ) {
            $h->push_read(
                line => $LF,
                sub ( $h1, $line, $eol ) {

                    # destroy control fh
                    $h->destroy;

                    my $res = eval { from_cbor pack 'H*', $line };

                    if ($@) {
                        die 'Node handshake error' . $@;
                    }
                    else {
                        $cb->($res);
                    }

                    return;
                }
            );

            return;
        },
    );

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Node::Proc

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
