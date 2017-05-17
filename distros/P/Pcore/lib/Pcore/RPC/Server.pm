package Pcore::RPC::Server;

use Pcore;
use Pcore::AE::Handle;
use Pcore::HTTP::Server;
use Pcore::WebSocket;
use if $MSWIN, 'Win32API::File';

sub run ( $class, $RPC_BOOT_ARGS ) {
    $ENV->scan_deps if $RPC_BOOT_ARGS->{scandeps};

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
    my $rpc = $class->new( $RPC_BOOT_ARGS->{buildargs} // () );

    my $can_rpc_on_connect    = $rpc->can('RPC_ON_CONNECT');
    my $can_rpc_on_disconnect = $rpc->can('RPC_ON_DISCONNECT');

    # parse listen
    my $listen;

    if ( !$RPC_BOOT_ARGS->{listen} ) {

        # for windows use TCP loopback
        if ($MSWIN) {
            $listen = '127.0.0.1:' . P->sys->get_free_port('127.0.0.1');
        }

        # for linux use abstract UDS
        else {
            $listen = "unix:pcore-rpc-$$";
        }
    }
    else {

        # host without port
        if ( $RPC_BOOT_ARGS->{listen} !~ /:/sm ) {
            $listen = "$RPC_BOOT_ARGS->{listen}:" . P->sys->get_free_port( $RPC_BOOT_ARGS->{listen} eq '*' ? () : $RPC_BOOT_ARGS->{listen} );
        }

        # unix socket or fully qualified host:port
        else {
            $listen = $RPC_BOOT_ARGS->{listen};
        }
    }

    # create RPC_TERM message listener
    P->listen_events(
        'RPC_TERM',
        sub ( $event, @ ) {
            $rpc->RPC_ON_TERM if $rpc->can('RPC_ON_TERM');

            exit;
        }
    );

    my $listen_events = ['RPC_TERM'];

    {
        no strict qw[refs];

        if ( ${"${class}::RPC_LISTEN_EVENTS"} ) {
            push $listen_events->@*, ref ${"${class}::RPC_LISTEN_EVENTS"} eq 'ARRAY' ? ${"${class}::RPC_LISTEN_EVENTS"}->@* : ${"${class}::RPC_LISTEN_EVENTS"};
        }
    }

    # start websocket server
    my $http_server = Pcore::HTTP::Server->new(
        {   listen => $listen,
            app    => sub ($req) {
                Pcore::WebSocket->accept_ws(
                    'pcore', $req,
                    sub ( $ws, $req, $accept, $reject ) {
                        no strict qw[refs];

                        $accept->(
                            {   max_message_size => 1_024 * 1_024 * 100,     # 100 Mb
                                pong_interval    => 50,
                                compression      => 0,
                                on_disconnect    => sub ( $ws, $status ) {
                                    $rpc->RPC_ON_DISCONNECT($ws) if $can_rpc_on_disconnect;

                                    return;
                                },
                                on_rpc_call => sub ( $ws, $req, $tran ) {
                                    my $method_name = "API_$tran->{method}";

                                    if ( $rpc->can($method_name) ) {

                                        # call method
                                        eval { $rpc->$method_name( $req, $tran->{data} ? $tran->{data}->@* : () ) };

                                        $@->sendlog if $@;
                                    }
                                    else {
                                        $req->( [ 400, q[Method not implemented] ] );
                                    }

                                    return;
                                }
                            },
                            headers        => undef,
                            before_connect => {
                                listen_events  => $listen_events,
                                forward_events => ${"${class}::RPC_FORWARD_EVENTS"},
                            },
                            $can_rpc_on_connect ? ( on_connect => sub ($ws) { $rpc->RPC_ON_CONNECT($ws); return } ) : (),
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
        Win32API::File::OsFHandleOpen( *FH, $RPC_BOOT_ARGS->{ctrl_fh}, 'w' ) or die $!;
    }
    else {
        open *FH, '>&=', $RPC_BOOT_ARGS->{ctrl_fh} or die $!;    ## no critic qw[InputOutput::RequireBriefOpen]
    }

    print {*FH} "LISTEN:$listen\x00";

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
## |    3 | 9                    | Subroutines::ProhibitExcessComplexity - Subroutine "run" with high complexity score (23)                       |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 102                  | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 138                  | ValuesAndExpressions::ProhibitEscapedCharacters - Numeric escapes in interpolated string                       |
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
