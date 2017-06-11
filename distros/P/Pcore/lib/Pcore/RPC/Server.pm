package Pcore::RPC::Server;

use Pcore;
use Pcore::HTTP::Server;
use Pcore::WebSocket;
use if $MSWIN, 'Win32API::File';

sub run ( $class, $rpc_boot_args ) {
    $ENV->scan_deps if $rpc_boot_args->{scandeps};

    # ignore SIGINT
    $SIG->{INT} = AE::signal INT => sub {
        return;
    };

    # ignore SIGTERM
    $SIG->{TERM} = AE::signal TERM => sub {
        return;
    };

    my $cv = AE::cv;

    # create object
    my $rpc = $class->new( $rpc_boot_args->{buildargs} // () );

    my $can_rpc_on_connect    = $rpc->can('RPC_ON_CONNECT');
    my $can_rpc_on_disconnect = $rpc->can('RPC_ON_DISCONNECT');

    # parse listen
    my $listen;

    if ( !$rpc_boot_args->{listen} ) {

        # for windows use TCP loopback
        if ($MSWIN) {
            $listen = '127.0.0.1:' . P->sys->get_free_port('127.0.0.1');
        }

        # for linux use abstract UDS
        else {
            $listen = "unix:\x00pcore-rpc-$$";
        }
    }
    else {

        # host without port
        if ( $rpc_boot_args->{listen} !~ /:/sm ) {
            $listen = "$rpc_boot_args->{listen}:" . P->sys->get_free_port( $rpc_boot_args->{listen} eq '*' ? () : $rpc_boot_args->{listen} );
        }

        # unix socket or fully qualified host:port
        else {
            $listen = $rpc_boot_args->{listen};
        }
    }

    # create RPC.TERM event listener
    P->listen_events(
        'RPC.TERM',
        sub ( $ev ) {
            $rpc->RPC_ON_TERM if $rpc->can('RPC_ON_TERM');

            exit;
        }
    );

    # compose listen events
    my $listen_events = ['RPC.TERM'];

    {
        no strict qw[refs];

        if ( ${"$class\::RPC_LISTEN_EVENTS"} ) {
            push $listen_events->@*, ref ${"$class\::RPC_LISTEN_EVENTS"} eq 'ARRAY' ? ${"$class\::RPC_LISTEN_EVENTS"}->@* : ${"$class\::RPC_LISTEN_EVENTS"};
        }
    }

    # start websocket server
    my $http_server = Pcore::HTTP::Server->new(
        {   listen => $listen,
            app    => sub ($req) {
                Pcore::WebSocket->accept_ws(
                    'pcore', $req,
                    sub ( $req, $accept, $reject ) {

                        # check token
                        if ( $rpc_boot_args->{token} && ( !$req->{env}->{HTTP_AUTHORIZATION} || $req->{env}->{HTTP_AUTHORIZATION} !~ /\bToken\s+$rpc_boot_args->{token}\b/smi ) ) {
                            $reject->(401);

                            return;
                        }

                        no strict qw[refs];

                        $accept->(
                            max_message_size => 1_024 * 1_024 * 100,                # 100 Mb
                            pong_interval    => 50,
                            compression      => 0,                                  #
                            on_listen_event  => sub ( $ws, $mask ) { return 1 },    # RPC client can listen server events
                            on_fire_event    => sub ( $ws, $key ) { return 1 },     # RPC client can fire server events
                            before_connect   => {
                                listen_events  => $listen_events,
                                forward_events => ${"$class\::RPC_FORWARD_EVENTS"},
                            },
                            ( $can_rpc_on_connect ? ( on_connect => sub ($ws) { $rpc->RPC_ON_CONNECT($ws); return } ) : () ),    #
                            ( $can_rpc_on_disconnect ? ( on_disconnect => sub ( $ws, $status ) { $rpc->RPC_ON_DISCONNECT( $ws, $status ); return; } ) : () ),
                            on_rpc => sub ( $ws, $req, $tx ) {
                                my $method_name = "API_$tx->{method}";

                                if ( $rpc->can($method_name) ) {

                                    # call method
                                    eval { $rpc->$method_name( $req, $tx->{data} ? $tx->{data}->@* : () ) };

                                    $@->sendlog if $@;
                                }
                                else {
                                    $req->( [ 400, q[Method not implemented] ] );
                                }

                                return;
                            },
                        );

                        return;
                    },
                );

                return;
            },
        }
    )->run;

    # open control handle
    if ($MSWIN) {
        Win32API::File::OsFHandleOpen( *FH, $rpc_boot_args->{ctrl_fh}, 'w' ) or die $!;
    }
    else {
        open *FH, '>&=', $rpc_boot_args->{ctrl_fh} or die $!;
    }

    binmode *FH or die;

    print {*FH} "LISTEN:$listen\n";

    close *FH or die;

    $cv->recv;

    exit;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 8                    | Subroutines::ProhibitExcessComplexity - Subroutine "run" with high complexity score (27)                       |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 113                  | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 41                   | ValuesAndExpressions::ProhibitEscapedCharacters - Numeric escapes in interpolated string                       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::RPC::Server

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
