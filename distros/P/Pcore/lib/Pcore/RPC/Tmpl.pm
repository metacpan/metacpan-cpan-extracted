package Pcore::RPC::Tmpl;

use Pcore;
use AnyEvent::Util;
use Pcore::Util::Data qw[from_cbor];

our ( $CPID, $R, $W, $QUEUE );

END {
    kill 'TERM', $CPID if defined $CPID;    ## no critic qw[InputOutput::RequireCheckedSyscalls]
}

_fork_tmpl();

sub _fork_tmpl {
    my ( $r1, $w1 ) = AnyEvent::Util::portable_pipe();
    ( my $r2, $W ) = AnyEvent::Util::portable_pipe();

    if ( $CPID = fork ) {
        Pcore::_CORE_INIT_AFTER_FORK();

        require Pcore::AE::Handle;

        # parent
        close $w1 or die $!;
        close $r2 or die $!;

        Pcore::AE::Handle->new(
            fh         => $r1,
            on_connect => sub ( $h, @ ) {
                $R = $h;

                return;
            },
        );

        $R->on_read( sub ($h) {
            $h->unshift_read(
                line => "\n",
                sub ( $h1, $line, $eol ) {
                    my $conn = eval { from_cbor $line };

                    if ($@) {
                        die 'RPC handshake error';
                    }
                    else {
                        my $cb = delete $QUEUE->{ $conn->{id} };

                        $cb->( bless { conn => $conn }, 'Pcore::RPC::_Proc' );
                    }

                    return;
                }
            );

            return;
        } );
    }
    else {

        # chile
        close $r1 or die $!;
        close $W  or die $!;

        _tmpl_proc( $r2, $w1 );
    }

    return;
}

sub _tmpl_proc ( $r, $w ) {

    # child
    $0 = 'Pcore::RPC::Tmpl';    ## no critic qw[Variables::RequireLocalizedPunctuationVars]

    local $SIG{TERM} = sub { exit 128 + 15 };

    while (1) {
        sysread $r, my $len, 4 or die $!;

        sysread $r, my $data, unpack 'L', $len or die $!;

        if ( !fork ) {
            close $r or die $!;

            undef $SIG{TERM};

            _rpc_proc( $w, P->data->from_cbor($data) );
        }
    }

    exit;
}

sub _rpc_proc ( $w, $data ) {
    Pcore::_CORE_INIT_AFTER_FORK();

    require Pcore::RPC::Server;

    $0 = $data->{type};    ## no critic qw[Variables::RequireLocalizedPunctuationVars]

    # redefine watcher in the forked process
    $SIG->{TERM} = AE::signal TERM => sub { exit 128 + 15 };

    P->class->load( $data->{type} );

    $data->{ctrl_fh} = $w;

    Pcore::RPC::Server::run( $data->{type}, $data );

    return;
}

sub run ( $type, $args, $cb ) {
    my $id = P->uuid->v1mc_str;

    $QUEUE->{$id} = $cb;

    my $data = P->data->to_cbor( {
        id        => $id,
        scandeps  => $ENV->{SCAN_DEPS} ? 1 : undef,
        type      => $type,
        parent_id => $args->{parent_id},
        listen    => $args->{listen},
        token     => $args->{token},
        buildargs => $args->{buildargs},
    } );

    syswrite $W, pack( 'L', length $data->$* ) . $data->$* or die $!;

    return;
}

package Pcore::RPC::_Proc;

use Pcore;

sub DESTROY ($self) {
    kill 'TERM', $self->{conn}->{pid} || 1;

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 20, 96               | Subroutines::ProtectPrivateSubs - Private subroutine/method used                                               |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::RPC::Tmpl

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
