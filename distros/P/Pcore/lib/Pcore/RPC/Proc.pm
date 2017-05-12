package Pcore::RPC::Proc;

use Pcore -class;
use Fcntl;
use Config;
use Pcore::AE::Handle;
use AnyEvent::Util qw[portable_socketpair];
use if $MSWIN, 'Win32API::File';
use Pcore::Util::Data qw[:CONST];
use Pcore::Util::Scalar qw[weaken];

has proc => ( is => 'ro', isa =>, InstanceOf ['Pcore::Util::PM::Proc'], init_arg => undef );
has listen => ( is => 'ro', isa => Str, init_arg => undef );    # RPC server listen addr.
has on_finish => ( is => 'rw', isa => Maybe [CodeRef] );

around new => sub ( $orig, $self, @ ) {
    my %args = (
        listen    => undef,                                     # RPC server listen
        class     => undef,                                     # mandatory
        buildargs => undef,                                     # class constructor arguments
        on_ready  => undef,
        on_finish => undef,
        @_[ 2 .. $#_ ],
    );

    # create self instance
    $self = $self->$orig( { on_finish => $args{on_finish} } );

    # create handles
    my ( $ctrl_r, $ctrl_w ) = portable_socketpair();

    state $perl = do {
        if ( $ENV->is_par ) {
            "$ENV{PAR_TEMP}/perl" . ( $MSWIN ? '.exe' : q[] );
        }
        else {
            $^X;
        }
    };

    my $boot_args = {
        script_path => $ENV->{SCRIPT_PATH},
        version     => $main::VERSION->normal,
        scandeps    => $ENV->{SCAN_DEPS} ? 1 : undef,
        listen      => $args{listen},
        buildargs   => $args{buildargs},
    };

    if ($MSWIN) {
        $boot_args->{ctrl_fh} = Win32API::File::FdGetOsFHandle( fileno $ctrl_w );
    }
    else {
        fcntl $ctrl_w, Fcntl::F_SETFD, fcntl( $ctrl_w, Fcntl::F_GETFD, 0 ) & ~Fcntl::FD_CLOEXEC or die;

        $boot_args->{ctrl_fh} = fileno $ctrl_w;
    }

    # serialize CBOR + HEX
    $boot_args = P->data->to_cbor( $boot_args, encode => $DATA_ENC_HEX )->$*;

    my $cmd = [];

    if ($MSWIN) {
        push $cmd->@*, $perl, "-M$args{class}";
    }
    else {
        push $cmd->@*, $perl, "-M$args{class}";
    }

    # needed for PAR, pass current @INC libs to child process via $ENV{PERL5LIB}
    local $ENV{PERL5LIB} = join $Config{path_sep}, grep { !ref } @INC;

    my $weaken_self = $self;
    weaken $weaken_self;

    # create proc
    P->pm->run_proc(
        $cmd,
        stdin    => 1,
        on_ready => sub ($proc) {
            $self->{proc} = $proc;

            # send configuration to RPC STDIN
            $proc->stdin->push_write( $boot_args . $LF );

            # wrap AE handles and perform handshale
            $self->_handshake(
                $ctrl_r,
                sub {
                    $args{on_ready}->($self);

                    return;
                }
            );

            return;
        },
        on_finish => sub ($proc) {
            $weaken_self->{on_finish}->($weaken_self) if $weaken_self && $weaken_self->{on_finish};

            return;
        }
    );

    return;
};

sub _handshake ( $self, $ctrl_fh, $cb ) {

    # wrap control_fh
    Pcore::AE::Handle->new(
        fh         => $ctrl_fh,
        on_connect => sub ( $h, @ ) {
            $h->push_read(
                line => "\x00",
                sub ( $h1, $line, $eol ) {

                    # destroy control fh
                    $h->destroy;

                    if ( $line =~ /\ALISTEN:(.+)\z/sm ) {
                        $self->{listen} = $1;

                        $cb->();
                    }
                    else {
                        die 'RPC handshake error';
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
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 115                  | ValuesAndExpressions::ProhibitEscapedCharacters - Numeric escapes in interpolated string                       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::RPC::Proc

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
