package RPC::Serialized::Server;
{
  $RPC::Serialized::Server::VERSION = '1.123630';
}

use strict;
use warnings FATAL => 'all';

use base 'RPC::Serialized';

use UNIVERSAL;
use RPC::Serialized::Config;
use RPC::Serialized::Exceptions;
use RPC::Serialized::AuthzHandler;

__PACKAGE__->mk_ro_accessors(qw/
    timeout
/);
__PACKAGE__->mk_accessors(qw/
    trace handler_namespaces args_suppress_log callbacks
/);

sub new {
    my $class = shift;
    my $params = RPC::Serialized::Config->parse(@_);

    my $ns = $params->rpc_serialized->{handler_namespaces};
    $params->rpc_serialized->{handler_namespaces} =
        (!defined $ns ? [] : (!ref $ns ? [$ns] : $ns));

    my $self = $class->SUPER::new($params);

    if ($self->trace) {
        eval { require Log::Dispatch::Syslog };

        if ($@) {
            throw_app "Failed to load Log::Dispatch but trace is on: $@";
        }
        else {
            $self->trace( Log::Dispatch::Syslog->new(
                $params->log_dispatch_syslog,
            ));
        }
    }

    # FIXME erm, should these be accessors?
    $self->{HANDLER} = $params->rpc_serialized->{handlers}
        if exists $params->rpc_serialized->{handlers};
    $self->{AUTHZ_HANDLER} = RPC::Serialized::AuthzHandler->new;
    $self->{CALLBACKS} = $params->rpc_serialized->{callbacks}
        if exists $params->rpc_serialized->{callbacks};

    return $self;
}

sub log {
    my $self = shift;
    return unless $self->trace;

    ( my $log = $self->ds->raw_serialize(@_) ) =~ s/^/[$$] /gm;
    $self->trace->log( level => $self->trace->{min_level}, message => $log);
}

sub log_call {
    my $self = shift;
    my ( $call, $args ) = @_;

    # strip suppressed (sensitive) arguments, e.g. password fields
    if (scalar @{$args} % 2 == 0
        and exists $self->args_suppress_log->{$call}
        and ref $self->args_suppress_log->{$call} eq ref []) {

        my %args = @{$args};
        foreach ( @{ $self->args_suppress_log->{$call} } ) {
            if ( exists $args{$_} ) {
                $args{$_} = '[suppressed]';
            }
        }
        $args = [%args];
    }

    $self->log( { CALL => $call, SUBJECT => $self->subject, ARGS => $args } );
}

sub log_response {
    my $self     = shift;
    my $response = shift;
    $self->log($response);
}

sub handler {
    my $self = shift;
    my $call = shift;

    if (@_) {
        $self->{HANDLER}->{$call} = shift;
    }

    return $self->{HANDLER}->{$call}
        if exists $self->{HANDLER}->{$call};
    return;
}

sub authz_handler {
    my $self = shift;

    if (@_) {
        my $handler = shift;

        throw_app 'Not a RPC::Serialized::AuthzHandler'
            unless UNIVERSAL::isa( $handler, 'RPC::Serialized::AuthzHandler' );
        $self->{AUTHZ_HANDLER} = $handler;
    }

    return $self->{AUTHZ_HANDLER};
}

sub recv {
    my $self = shift;
    my ($data, @token) = $self->SUPER::recv or return;

    my $call = $data->{CALL};
    throw_proto 'Invalid or missing CALL'
        unless $call and not ref($call);

    my $args = $data->{ARGS};
    throw_proto 'Invalid or missing ARGS'
        unless $args and ref($args) eq 'ARRAY';

    return ( $call, $args, @token );
}

sub subject {
    my $self = shift;
    return undef;
}

sub authorize {
    my $self   = shift;
    my $call   = shift;
    my $target = shift;
    $self->authz_handler->check_authz( $self->subject, $call, $target );
}

sub dispatch {
    my $self = shift;
    my $call = shift;
    my $args = shift;

    my $hc = undef;
    if ($hc = $self->handler($call)) {
        eval "require $hc"
            or throw_system "Failed to load $hc: $@";
    }
    else {
        $call = quotemeta($call);
        throw_app "Cannot search for invalid name: $call"
            if $call =~ m/\W/;

        (my $name = $call) =~ s/_([a-z])/::\u$1/g;
        $name = ucfirst $name;

        foreach my $ns (@{ $self->handler_namespaces }) {
            eval "require ${ns}::${name}" or next;

            # install the handler class we have just found
            $hc = "${ns}::$name";
            $self->handler($call, $hc);
            last;
        }
    }

    throw_app "No handler for $call"
        if !defined $hc;

    throw_app "$hc not a RPC::Serialized::Handler"
        unless $hc->isa('RPC::Serialized::Handler');

    $self->authorize( $call, $hc->target(@$args) )
        or throw_authz "Permission denied";

    if ($self->callbacks->{pre_handler_argument_filter}) {
        eval {
            $args = [ $self->callbacks->{pre_handler_argument_filter}->(
                { call => $call, server => $self },
                @$args) ];
        };
        if ($@) {
            throw_app sprintf("Callback '%s' for call '%s' returned %s"
              ,  'pre_handler_argument_filter'
              ,  $call
              ,  $@);
        }
    }
    
    return { RESPONSE => $hc->invoke(@$args) };
}

sub exception {
    my $self = shift;
    my $err  = shift;

    my $exception;
    if ( UNIVERSAL::isa( $err, 'RPC::Serialized::X' ) ) {
        $exception = {
            CLASS   => ref($err),
            MESSAGE => $err->message
        };
    }
    else {
        $exception = {
            CLASS   => 'RPC::Serialized::X',
            MESSAGE => "$err"
        };
    }

    return { EXCEPTION => $exception };
}

sub process {
    my $self = shift;

    my $alarm_bak = 0;
    my @token_bak = ();

    while ( 1 ) {
        my ($response, @token);

        eval {
            local $SIG{ALRM} = sub { die "Timeout on Receive\n" };
            $alarm_bak = alarm $self->timeout;
            (my ($call, $args), @token) = ($self->recv);
            alarm $alarm_bak;

            if ($call) {
                $self->log_call( $call, $args );

                local $SIG{ALRM} = sub { die "Timeout on Dispatch\n" };
                $alarm_bak = alarm $self->timeout;
                $response = $self->dispatch( $call, $args );
                alarm $alarm_bak;
            }
        };
        if ($@) {
            alarm $alarm_bak;
            $response = $self->exception($@);
        }

        last unless $response;
        $self->log_response($response);

        # use same serializer for response as on received msg
        @token_bak = $self->set_token(@token)
            if !$self->debug;

        eval {
            local $SIG{ALRM} = sub { die "Timeout on Send\n" };
            $alarm_bak = alarm $self->timeout;
            $self->send($response);
            alarm $alarm_bak;
        };
        if ($@) {
            alarm $alarm_bak;
            $self->restore_token(@token_bak) if !$self->debug;
            throw_system $@; # likely caught outside of RPC::Serialized
        }

        # restore our default serializer
        $self->restore_token(@token_bak) if !$self->debug;
    }

    alarm $alarm_bak;
}

sub restore_token {
    my $self = shift;
    my ($serializer, $cipher, $digester, $encoding, $compressor) = @_;

    $self->ds->serializer($serializer);
    $self->ds->cipher($cipher);
    $self->ds->digester($digester);
    $self->ds->encoding($encoding);
    $self->ds->compressor($compressor);
}

sub set_token {
    my $self = shift;
    my ($serializer, $cipher, $digester, $encoding, $compressor) = @_;

    my @retval = (
        $self->ds->serializer,
        $self->ds->cipher,
        $self->ds->digester,
        $self->ds->encoding,
        $self->ds->compressor,
    );

    $self->restore_token(@_);
    return @retval;
}

1;

