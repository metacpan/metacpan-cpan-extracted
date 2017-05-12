package Perlbal::Plugin::Extredirector;
BEGIN {
  $Perlbal::Plugin::Extredirector::AUTHORITY = 'cpan:WOLVERIAN';
}
{
  $Perlbal::Plugin::Extredirector::VERSION = 'v0.0.4';
}
# ABSTRACT: Use Squid rules in Perlbal.

use strict;
use warnings;
no  warnings qw(deprecated);

use Perlbal;
use Socket;
use IPC::Open2;
use Net::Netmask;

our %Services;  # service_name => $svc
our @Settings = ( qw/
    exec
    default_proto
    default_host
    default_service
/ );

# when "LOAD" directive loads us up
sub load {
    my $class = shift;

    Perlbal::register_global_hook('manage_command.extredirector', sub {
        my $mc = shift->parse(
            qr/^EXTREDIRECTOR\s+(?:(\w+)\s+)?(SET|ADD_DYNAMIC_SERVICE|SET_DYNAMIC_(?:SERVICE|POOL))\s+(\S+)(?:\s+=\s+(.+))?$/i,
            "Extredirector config usage:\n" .
            "EXTREDIRECTOR [<service>] SET exec = <command to execute>\n".
            "EXTREDIRECTOR [<service>] SET default_service = <service name>\n".
            "EXTREDIRECTOR [<service>] SET default_host = <default virtual host>\n".
            "EXTREDIRECTOR [<service>] SET default_proto = <default proto (http)>\n".
            "Dynamic service adding:\n".
            "EXTREDIRECTOR [<service>] ADD_DYNAMIC_SERVICE <hostname>[:<port>]\n".
            "EXTREDIRECTOR [<service>] ADD_DYNAMIC_SERVICE <ip>[:<port>]\n".
            "EXTREDIRECTOR [<service>] ADD_DYNAMIC_SERVICE <netmask>[:<port>]\n".
            "EXTREDIRECTOR [<service>] ADD_DYNAMIC_SERVICE *[:<port>]\n".
            "Dynamic service settings:\n".
            "EXTREDIRECTOR [<service>] SET_DYNAMIC_SERVICE <setting> = <value>\n".
            "Dynamic pool settings:\n".
            "EXTREDIRECTOR [<service>] SET_DYNAMIC_POOL <setting> = <value>\n"
        );
        my ($selname, $command, $name, $value) = $mc->args;
        unless ($selname ||= $mc->{ctx}{last_created}) {
            return $mc->err("omitted service name not implied from context");
        }

        my $ss = Perlbal->service($selname);
        return $mc->err("Service '$selname' is not a selector service")
            unless $ss && $ss->{role} eq "selector";

        if ( lc ( $command ) eq 'set' ) {
            $ss->{extra_config}{_extredirector}{settings}->{lc( $name )} = $value;
        }
        elsif ( lc ( $command ) eq 'set_dynamic_service' ) {
            $ss->{extra_config}{_extredirector}{dynamic_service_settings}->{lc( $name )} = $value;
        }
        elsif ( lc ( $command ) eq 'set_dynamic_pool' ) {
            $ss->{extra_config}{_extredirector}{dynamic_pool_settings}->{lc( $name )} = $value;
        }
        elsif ( lc ( $command ) eq 'add_dynamic_service' ) {
            my ( $host, $mask, $port ) = $name =~ /^([^\:\/]+)(?:\/(\d+))?(?:\:(\d+))?$/;
            $port = '*' unless $port && $port =~ /^\d+$/;
            if ( $mask ) {
                Net::Netmask->new( "$host/$mask" ); # die already here if invalid
                $ss->{extra_config}{_extredirector}{dynamic_service_masks}{"$host/$mask"}{$port} = 1;
            }
            else {
                $ss->{extra_config}{_extredirector}{dynamic_services}{lc( $host )}{$port} = 1;
            }
        }
        else {
            return $mc->err("unrecognized extredirector command");
        }

        return $mc->ok;
    });

    return 1;
}

sub unload {
    my ( $class ) = @_;

    Perlbal::unregister_global_hook('manage_command.extredirector');
    unregister($class, $_) foreach (values %Services);

    return 1;
}

sub register {
    my ($class, $svc) = @_;

    unless ($svc && $svc->{role} eq "selector") {
        die "You can't load the extredirector plugin on a service not of role selector.\n";
    }

    $svc->selector(\&extredirector_selector);
    $Services{"$svc"} = $svc;

    return 1;
}

sub unregister {
    my ($class, $svc) = @_;

    $svc->unregister_setters( $class );
    $svc->selector(undef);
    delete $svc->{extra_config}->{_extredirector};
    delete $Services{"$svc"};

    return 1;
}

sub extredirector_selector {
    my Perlbal::ClientHTTPBase $cb = shift;

    my $req = $cb->{req_headers};
    return $cb->_simple_response(404, "Not Found (no reqheaders)") unless $req;

    $cb->{service}{extra_config}{_extredirector} ||= {};
    my $conf = $cb->{service}{extra_config}{_extredirector};

    $conf->{settings} ||= {};
    my $settings = $conf->{settings};

    unless ( $settings->{'exec'} ) {
        $cb->_simple_response(404, "Not Found (no exec defined for extredirector)");
        return 1;
    }

    unless ( $settings->{'exec_pid'} ) {
        unless ( eval { open_exec( $settings ) } ) {
            $cb->_simple_response(404, "Not Found (could not open extredirector exec: $@)");
            return 1;
        }
    }

    # This fills observed_ip_string
    $cb->check_req_headers;

    my $proto = $req->header("X-Forwarded-Proto") || $settings->{'default_proto'} || 'http';
    my $host = $req->header("Host") || $settings->{'default_host'} || '';
    my $uri = $req->request_uri;

    # send only normal requests to the redirector. In case of '*' (and other weird
    # requests) we pass only the host to the redirector and alter only the host.
    my $uri_string = ( $uri =~ /^\// ) ? "$proto://$host$uri" : "$proto://$host";
    my $string = $uri_string . ' ' . ( $cb->observed_ip_string || $cb->peer_ip_string || '' ) .
        '/  ' . ( $req->request_method || '' );

    my $return = eval{ run_redirect( $settings, $string ) };
    if ( $@ ) {
        unless ( eval { open_exec( $settings ) } ) {
            $cb->_simple_response(404, "Not Found (could not reopen extredirector exec: $@)");
            return 1;
        }
        $return = eval{ run_redirect( $settings, $string ) };
        if ( $@ ) {
            $cb->_simple_response(404, "Not Found (error communicating with extredirector exec)");
            return 1;
        }
    }

    if ( ! $return ) {
        my $default_svc = Perlbal->service( $settings->{'default_service'} );
        if ( $default_svc ) {
            $default_svc->adopt_base_client($cb);
        }
        elsif ( $settings->{'default_service'} ) {
            $cb->_simple_response(404, "Not Found (default service not valid)");
        }
        else {
            $cb->_simple_response(404, "Not Found (default service not specified)");
        }
        return 1;
    }


    my ( $code, $message ) = $return =~ /^(\d+)\:(\S*)/;
    if ( $code ) {
        if ( $code == 307 || $code == 301 || $code == 302 ) {
            # TODO: _simple_response could be modified to handle this
            # TODO: HTTPHeaders could support also 307
            my $res = $cb->{res_headers} = Perlbal::HTTPHeaders->new_response($code);
            $res->{responseLine} = "HTTP/1.1 $code";
            $res->header('Location', $message );
            $res->header('Server', 'Perlbal');

            $cb->setup_keepalive($res);

            $cb->state('xfer_resp');
            $cb->tcp_cork(1);  # cork writes to self
            $cb->write($res->to_string_ref);
            $cb->write(sub { $cb->http_response_sent; });

            return 1;
        }
        $cb->_simple_response( $code, $message );
        return 1;
    }

    my ( $complete_uri, $complete_host, $new_host, $new_port, $new_uri, $target_svc_name ) =
        $return =~ /^(\w+\:\/\/(([^\/\s\:]*)(?:\:(\d+))?)((?:\/\S*)?))(?:\s+(\w*))?/;

    if ( ! $complete_uri ) {
        $cb->_simple_response(404, "Not Found (redirector returned garble)");
        return 1;
    }

    # Alter request_uri only if it was passed to the redirector
    if ( $uri =~ /^\// ) {
        if ( ! $new_uri ) {
            $req->set_request_uri( '/' );
        }
        else {
            $req->set_request_uri( $new_uri );
        }
    }

    $new_host ||= '';
    $target_svc_name ||= '';

    my $target_svc = ( $target_svc_name =~ /^\w+$/ ) ? Perlbal->service($target_svc_name) : '';

    # Alter the Host header according to the result if:
    # 1) a target service was specified,
    # 2) returned host was a domain name (not an ip) or
    # 3) dynamic service generation was not allowed and the default service was used

    if ( $target_svc ) {
        $req->header("Host", $new_host );
    }
    else {
        $new_port ||= 80;
        my $exact = $conf->{dynamic_services}{ lc( $new_host ) };
        my $dynamic_allowed = ( $exact && ( $exact->{'*'} || $exact->{ $new_port } ) ) ? 1 : 0;

        unless ( $dynamic_allowed ) {
            # Specifically DO NOT RESOLVE NAMED HOSTS TO IPS here
            if ( $new_host =~ /^(\d+\.){3}\d+$/ && $conf->{dynamic_service_masks} ) {
                for my $mask ( keys %{ $conf->{dynamic_service_masks} } ) {
                    next unless $conf->{dynamic_service_masks}->{$mask}->{'*'} ||
                        $conf->{dynamic_service_masks}->{$mask}->{ $new_port };
                    my $block = Net::Netmask->new( $mask );
                    next unless $block->match( $new_host );
                    $dynamic_allowed = 1;
                    last;
                }
            }
        }

        if ( $dynamic_allowed ) {
            $req->header("Host", $new_host ) unless $new_host =~ /^(\d+\.){3}\d+$/;

            my $dyn_svc_name = 'dynamic_' . $new_host;
            $dyn_svc_name .= ':' . $new_port unless $new_port == 80;
            $dyn_svc_name =~ s/[^\w]/_/g;

            $target_svc = Perlbal->service( $dyn_svc_name );

            unless ( $target_svc ) {
                # IP resolving is done only once when the pool is created. This has both good and bad sides.
                my $target_host = ( $new_host =~ /^(\d+\.){3}\d+$/ ) ? $new_host : inet_ntoa( inet_aton( $new_host ) );
                my $dyn_target = $target_host . ':' . $new_port;

                my $ctx = Perlbal::CommandContext->new;

                Perlbal::run_manage_command('create pool ' . $dyn_svc_name . '__pool', undef, $ctx );
                Perlbal::run_manage_command('pool ' . $dyn_svc_name . '__pool ADD ' . $dyn_target, undef, $ctx );

                my $pool_settings = $conf->{dynamic_pool_settings} || {};
                Perlbal::run_manage_command('set ' .$_. ' = ' . $pool_settings->{$_}, undef, $ctx )
                    for keys %$pool_settings;

                Perlbal::run_manage_command('create service ' . $dyn_svc_name, undef, $ctx );
                Perlbal::run_manage_command('set role = reverse_proxy', undef, $ctx );
                Perlbal::run_manage_command('set pool = ' . $dyn_svc_name . '__pool', undef, $ctx );

                my $service_settings = $conf->{dynamic_service_settings} || {};
                Perlbal::run_manage_command('set ' .$_. ' = ' . $service_settings->{$_}, undef, $ctx )
                    for keys %$service_settings;

                $target_svc = Perlbal->service( $dyn_svc_name );
            }
        }
    }

    unless ($target_svc) {
        if ( $settings->{'default_service'} ) {
            $target_svc = Perlbal->service( $settings->{'default_service'} );
            $req->header("Host", $new_host );
        }
    }

    unless ($target_svc) {
        $cb->_simple_response(404, "Not Found ($target_svc_name not a defined service)");
        return 1;
    }

    $target_svc->adopt_base_client($cb);
    return 1;
}

sub open_exec {
    my ( $settings ) = @_;

    eval { kill( $settings->{'exec_pid'} ) } if $settings->{'exec_pid'};
    eval { close( $settings->{'exec_in'} ) } if $settings->{'exec_in'};
    eval { close( $settings->{'exec_out'} ) } if $settings->{'exec_out'};

    local ( *RIN, *ROUT );
    my $pid = open2( *RIN, *ROUT, $settings->{'exec'} );

    # THIS DOES NOT SEEM TO WORK ON OPEN2 PIPE :(
    #
    # nothing seems to come through if this is set :(
    #
    #    # Set the inbound handle to non-blocking mode
    #    my $flags = fcntl( RIN, F_GETFL, 0);
    #    fcntl(RIN, F_SETFL, $flags | O_NONBLOCK);

    $settings->{'exec_in'} = *RIN;
    $settings->{'exec_out'} = *ROUT;
    $settings->{'exec_pid'} = $pid;

    return $pid;
}

sub run_redirect {
    my ( $settings, $string ) = @_;

    # If writing fails, we signal that reopening the exec pipes
    # might be in order by dying
    my $out = $settings->{'exec_out'};
    print $out $string . "\n" or die;

    # I tried some suggested failsafes from google to prevent
    # this from blocking (setting O_NONBLOCK and vec + select )
    # but none of them seem to work with open2 pipe :(
    # Logically if the write succeeded, there should always be
    # something and this read should not block.. pray for it :D

    my $in = $settings->{'exec_in'};

    # THIS DOES NOT SEEM TO WORK ON OPEN2 PIPE :(
    #
    #    # Create a bitmask signalling we are interested in the inbound pipe
    #    my $iohandle_bitmask = '';
    #    vec( $iohandle_bitmask, fileno( $in ), 1 ) = 1;
    #    # Check if our inbound pipe can be read
    #    return '' unless select( $iohandle_bitmask, undef, undef, 0 ) > 0;
    #    # Check to be sure that it was out inbound pipe that can be read
    #    return '' unless vec( $iohandle_bitmask, fileno( $in ), 1 );

    # read everything and take the last output line with content
    # and pray that the redirector works so we don't hang :D
    my $buffer = '';
    sysread( $in, $buffer, 1024*1024 );

    return ( split /\n/, $buffer )[-1];
}

1;


__END__
=pod

=head1 NAME

Perlbal::Plugin::Extredirector - Use Squid rules in Perlbal.

=head1 VERSION

version v0.0.4

=encoding utf8

=head1 AUTHORS

=over 4

=item *

Ilmari Vacklin <ilmari@dicole.com>

=item *

Antti Vähäkotamäki <antti@dicole.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Dicole.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

