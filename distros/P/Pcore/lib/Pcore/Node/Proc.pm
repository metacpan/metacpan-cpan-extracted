package Pcore::Node::Proc;

use Pcore -class;
use Fcntl;
use AnyEvent::Util qw[portable_socketpair];
use if $MSWIN, 'Win32API::File';
use Pcore::Util::Data qw[to_cbor from_cbor];
use Pcore::Util::Scalar qw[weaken];
use Pcore::Util::Sys::Proc qw[:PROC_REDIRECT];

has fh        => ();    # fh
has on_finish => ();    # CodeRef->($self)

our $WIN32_MUTEX;

sub DESTROY ($self) {

    # inform node process, that parent is terminated
    $self->{fh}->shutdown if defined $self->{fh};

    return;
}

around new => sub ( $orig, $self, $type, % ) {
    my %args = (
        server    => undef,    # node server credentials
        listen    => undef,    # node listen
        buildargs => undef,    # class constructor arguments
        on_finish => undef,
        @_[ 3 .. $#_ ],
    );

    # create handles
    my ( $fh_r, $fh_w ) = portable_socketpair;

    $fh_r = P->handle($fh_r);

    my $boot_args = {
        script_path => $ENV->{SCRIPT_PATH},
        version     => $main::VERSION->normal,
        scandeps    => $ENV->{SCANDEPS},
        parent_pid  => $$,
        server      => $args{server},
        listen      => $args{listen},
        buildargs   => $args{buildargs},
    };

    if ($MSWIN) {
        require Win32::Mutex;

        my $mutex_name = P->uuid->v1mc_str;

        # TODO need to cleanup mutexes on child process exit
        push $WIN32_MUTEX->@*, Win32::Mutex->new( 1, $mutex_name );

        $boot_args->{win32_mutex} = $mutex_name;

        $boot_args->{fh} = Win32API::File::FdGetOsFHandle( fileno $fh_w );
    }
    else {

        # do not close fh on exec
        fcntl $fh_w, Fcntl::F_SETFD, fcntl( $fh_w, Fcntl::F_GETFD, 0 ) & ~Fcntl::FD_CLOEXEC or die;

        $boot_args->{fh} = fileno $fh_w;
    }

    my $proc;

    # run via fork tmpl
    if ($Pcore::Util::Sys::ForkTmpl::CHILD_PID) {
        Pcore::Util::Sys::ForkTmpl::run_node( $type, $boot_args );

        my $res = $self->_handshake($fh_r);

        $proc = bless { pid => $res->{pid}, kill_on_destroy => 1 }, 'Pcore::Util::Sys::Proc';
    }

    # run via run_proc
    else {
        state $perl = do {
            if ( $ENV->{is_par} ) {
                "$ENV{PAR_TEMP}/perl" . ( $MSWIN ? '.exe' : $EMPTY );
            }
            else {
                $^X;
            }
        };

        # create proc
        $proc = P->sys->run_proc(
            [ $perl, "-MPcore::Node=$type" ],
            stdin           => $PROC_REDIRECT_SOCKET,
            kill_on_destroy => 1
        );

        # send configuration to the proc STDIN
        $proc->{stdin}->write( unpack( 'H*', to_cbor $boot_args ) . "\n" );

        my $res = $self->_handshake($fh_r);
    }

    $self = bless {
        proc      => $proc,
        fh        => $fh_r,
        on_finish => delete $args{on_finish},
    }, $self;

    if ( $self->{on_finish} ) {
        Coro::async {
            weaken $self;

            # blocks until $fh is closed
            $fh_r->can_read(undef);

            return if !defined $self;

            $self->{on_finish}->($self);

            return;
        };
    }

    return $self;
};

sub _handshake ( $self, $fh ) {
    my $data = $fh->read_line( "\n", timeout => undef );

    die 'Node handshake error' if !$data;

    my $res = eval { from_cbor pack 'H*', $data->$* };

    die 'Node handshake error' . $@ if $@;

    return $res;
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
