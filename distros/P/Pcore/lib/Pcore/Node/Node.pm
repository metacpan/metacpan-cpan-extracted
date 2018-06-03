package Pcore::Node::Node;

use Pcore -res;
use Pcore::Node;
use Pcore::Util::Data qw[to_cbor];
use if $MSWIN, 'Win32API::File';

sub run ( $type, $args ) {
    $ENV->scan_deps if $args->{scandeps};

    # ignore SIGINT
    $SIG->{INT} = AE::signal INT => sub { };

    # create object
    my $rpc = $type->new( $args->{buildargs} // () );

    $rpc->{node} = Pcore::Node->new(
        server     => $args->{server},
        is_service => 1,
        listen     => $args->{listen},
        type       => $type,
        requires   => do {
            no strict qw[refs];

            ${"$type\::NODE_REQUIRES"};
        },
        forward_events => do {
            no strict qw[refs];

            ${"$type\::NODE_FORWARD_EVENTS"};
        },
        subscribe_events => do {
            no strict qw[refs];

            ${"$type\::NODE_SUBSCRIBE_EVENTS"};
        },
        on_subscribe => sub ( $h, $event ) {
            if ( !$h->{auth} ) {
                $h->disconnect( res 401 );

                return;
            }

            state $sub = $rpc->can('NODE_ON_SUBSCRIBE');

            return $rpc->$sub($event) if $sub;

            # silently subscribe to all events, if handler is not exists
            return 1;
        },
        on_event => sub ( $h, $ev ) {
            if ( !$h->{auth} ) {
                $h->disconnect( res 401 );

                return;
            }

            state $sub = $rpc->can('NODE_ON_EVENT');

            return $rpc->$sub($ev) if $sub;

            # silently forward all events, if handler is not exists
            P->forward_event($ev);

            return;
        },
        on_rpc => Coro::unblock_sub sub ( $h, $req, $tx ) {
            if ( !$h->{auth} ) {
                $h->disconnect( res 401 );

                return;
            }

            my $method_name = "API_$tx->{method}";

            if ( my $sub = $rpc->can($method_name) ) {

                # call method
                eval { $rpc->$sub( $req, $tx->{args} ? $tx->{args}->@* : () ) };

                $@->sendlog if $@;
            }
            else {
                $req->( [ 400, q[Method not implemented] ] );
            }

            return;
        },
    )->run;

    # open control handle
    if ($MSWIN) {
        Win32API::File::OsFHandleOpen( *FH, $args->{fh}, 'w' ) or die $!;
    }
    else {
        open *FH, '>&=', $args->{fh} or die $!;    ## no critic qw[InputOutput::RequireBriefOpen]
    }

    binmode *FH or die;

    my $data = to_cbor {                           #
        pid => $$,
    };

    syswrite *FH, unpack( 'H*', $data->$* ) . $LF or die $!;

    close *FH or die $!;

    AE::cv->recv;

    exit;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 79                   | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Node::Node

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
