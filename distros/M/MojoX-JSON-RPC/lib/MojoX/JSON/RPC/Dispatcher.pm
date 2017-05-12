package MojoX::JSON::RPC::Dispatcher;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw(decode_json);
use MojoX::JSON::RPC::Dispatcher::Method;
use MojoX::JSON::RPC::Service;

# process JSON-RPC call
sub call {
    my ($self) = @_;

    my $rpc_response = $self->_handle_methods( $self->_acquire_methods );
    if ( !$rpc_response ) {    # is notification
        $self->tx->res->code(204);
        return $self->rendered;
    }
    my $res = $self->tx->res;
    $res->code(
        $self->_translate_error_code_to_status(
            ref $rpc_response eq 'HASH' && exists $rpc_response->{error}
            ? $rpc_response->{error}->{code}
            : q{}
        )
    );
    $res->headers->content_type('application/json-rpc');
    return $self->render(json => $rpc_response);
}

sub _acquire_methods {
    my ($self) = @_;

    my $log    = $self->app->log;
    my $req    = $self->req;        # Mojo::Message::Request object
    my $method = $req->method;      # GET / POST
    my $request;

    if ( $method eq 'POST' ) {
        if ( $log->is_level('debug') ) {
            $log->debug( 'REQUEST: BODY> ' . $req->body );
        }
        
        my $decode_error;
        eval{ $request = decode_json( $req->body ); 1; } or $decode_error = $@;
        if ( $decode_error ) {
            $log->debug( 'REQUEST: JSON error> ' . $decode_error );
            return MojoX::JSON::RPC::Dispatcher::Method->new->parse_error(
                $decode_error );
        }
    }
    elsif ( $method eq 'GET' ) {
        my $params = $req->query_params->to_hash;
        my $decoded_params;

        if ( exists $params->{params} ) {
            my $decode_error;
            eval{ $decoded_params = decode_json( $params->{params} ); 1; } or $decode_error = $@;
            
            if ( $decode_error ) {
                return MojoX::JSON::RPC::Dispatcher::Method->new->parse_error(
                    $decode_error );
            }
        }
        $request = {
            method => $params->{method},
            exists $params->{id}    ? ( id     => $params->{id} )   : (),
            defined $decoded_params ? ( params => $decoded_params ) : ()
        };
    }
    else {
        return MojoX::JSON::RPC::Dispatcher::Method->new->invalid_request(
            qq{Invalid method type: $method});
    }

    if ( ref $request ne 'HASH' && ref $request ne 'ARRAY' ) {
        return MojoX::JSON::RPC::Dispatcher::Method->new->invalid_request(
            $request);
    }

    my @methods = ();
METHOD:
    foreach my $obj ( ref $request eq 'HASH' ? $request : @{$request} ) {
        if ( ref $obj ne 'HASH' ) {
            push @methods,
                MojoX::JSON::RPC::Dispatcher::Method->new->invalid_request;
            next METHOD;
        }
        my $method = $obj->{method} if exists $obj->{method};
        if (!(  defined $method
                && $method =~ m/^[A-Za-z_\.][A-Za-z0-9_\.]*$/xms
            )
            )
        {
            push @methods,
                MojoX::JSON::RPC::Dispatcher::Method->new->invalid_request(
                $method);
            next METHOD;
        }
        my $params = $obj->{params} if exists $obj->{params};
        if (   defined $params
            && ref $params ne 'ARRAY'
            && ref $params ne 'HASH' )
        {
            push @methods,
                MojoX::JSON::RPC::Dispatcher::Method->new->invalid_params(
                'NOT array or hash: ' . $params );
            next METHOD;
        }

        ## Hack to support JSON-RPC 1.1
        if (   !( exists $obj->{id} && defined $obj->{id} )
            && exists $obj->{version}
            && defined $obj->{version}
            && $obj->{version} eq '1.1' )
        {
            $obj->{id} = '#';    # TODO: fix this
        }

        ## Create method object
        my $m = MojoX::JSON::RPC::Dispatcher::Method->new(
            method => $method,
            id     => exists $obj->{id} ? $obj->{id} : undef
        );
        if ( !( exists $obj->{id} && defined $obj->{id} ) ) {
            $m->is_notification(1);
        }
        if ( defined $params ) {    # process parameters
            if ( ref $params ne 'ARRAY' && ref $params ne 'HASH' ) {
                $m->invalid_params($params);
            }
            else {
                $m->params($params);
            }
        }
        push @methods, $m;
    }
    return \@methods;
}

sub _handle_methods {
    my ( $self, $methods ) = @_;

    my $log = $self->app->log;

    if ( ref $methods eq 'MojoX::JSON::RPC::Dispatcher::Method' ) {
        if ( $methods->has_error ) {
            return $methods->response;
        }
        $methods = [$methods];
    }
    if ( scalar @{$methods} == 0 ) {    # empty
        return
            MojoX::JSON::RPC::Dispatcher::Method->new->invalid_request
            ->response;
    }

    my @responses;
    my $service = $self->stash('service');
    my $rpcs    = $service->{_rpcs};
METHOD:
    foreach my $m ( ref $methods eq 'ARRAY' ? @{$methods} : $methods ) {
        if ( $m->has_error ) {
            push @responses, $m->response;
            next METHOD;
        }
        my $rpc = $rpcs->{ $m->method }
            if exists $rpcs->{ $m->method };
        my $code_ref = $rpc->{method}
            if defined $rpc && exists $rpc->{method};
        if ( defined $code_ref ) {

            # deal with params and calling
            # pass in svc obj and mojo tx if necessary
            eval {
                $m->result(
                    $code_ref->(
                        exists $rpc->{with_svc_obj}
                            && $rpc->{with_svc_obj} ? $service : (),
                        exists $rpc->{with_mojo_tx}
                            && $rpc->{with_mojo_tx} ? $self->tx : (),
                        exists $rpc->{with_self}
                            && $rpc->{with_self} ? $self : (),
                        defined $m->params
                        ? ref $m->params eq 'ARRAY'
                                ? @{ $m->params }
                                : $m->params
                        : ()
                    )
                );
            };
            if ($@) {
                my $err = $@;
                my $handler = $self->stash('exception_handler');
                if (ref $handler eq 'CODE') {
                    $handler->($self, $err, $m);
                }
                else {
                    $m->internal_error($@);
                }
            }
        }
        else {
            $m->method_not_found( $m->method );
        }
        if ( !$m->is_notification || $m->has_error ) {
            push @responses, $m->response;
        }
    }
    return scalar @responses > 1 ? \@responses : $responses[0];
}

# Translate JSON-RPC error code to HTTP status.
sub _translate_error_code_to_status {
    my ( $self, $code ) = @_;
    my %trans = (
        q{}      => 200,
        '-32600' => 400,
        '-32601' => 404,
        '-32602' => 200,    # wants the user to get the rpc error
        '-32700' => 400
    );
    $code ||= q{};
    return exists $trans{$code} ? $trans{$code} : 500;
}

1;

__END__

=head1 NAME

MojoX::JSON::RPC::Dispatcher - A JSON-RPC 2.0 server for Mojolicious

=head1 SYNOPSIS

    # lib/your-application.pm

    use base 'Mojolicious';
    use MojoX::JSON::RPC::Service;

    sub startup {
        my $self = shift;
        my $svc = MojoX::JSON::RPC::Service->new;

        $svc->register(
            'sum',
            sub {
                my @params = @_;
                my $sum = 0;
                $sum += $_ for @params;
                return $sum;
            }
        );

        $self->plugin(
            'json_rpc_dispatcher',
            services => {
               '/jsonrpc' => $svc
            }
        );
   }

=head1 DESCRIPTION

Using this module you can handle JSON-RPC 2.0 requests within Mojolicious.

=head1 ATTRIBUTES

L<MojoX::JSON::RPC::Dispatcher> inherits all attributes from L<Mojolicious::Controller> and
implements the following attributes.

=head2 C<json>

JSON encoder / decoder

=head2 C<error_code>

Error code.

=head2 C<error_message>

Error message.

=head2 C<error_data>

Error data.

=head2 C<id>

=head1 METHODS

L<MojoX::JSON::RPC::Dispatcher> inherits all methods from L<Mojolicious::Controller> and implements the
following new ones.

=head2 C<call>

Process JSON-RPC call.

=head1 SEE ALSO

L<MojoX::JSON::RPC>, L<Mojolicious::Plugin::JsonRpcDispatcher>

=cut

