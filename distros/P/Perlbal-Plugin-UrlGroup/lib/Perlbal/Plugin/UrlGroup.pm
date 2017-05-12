package Perlbal::Plugin::UrlGroup;
use strict;
use warnings;
no  warnings qw(deprecated);

use URI::Escape;

our $VERSION = '0.03';

our %Services;  # service_name => $svc
my $manage_command = 'manage_command.group';
my $manage_command_regex = 'manage_command.group_regex';

my $group_regex = '';
my $group_postfix = '';
my %url_group;

# when "LOAD" directive loads us up
sub load {
    my $class = shift;

    Perlbal::register_global_hook($manage_command_regex, sub {
        my $mc = shift->parse(qr/^group_regex\s+(\S+)\s*=\s*(\w+)$/,
                              "usage: GROUP_REGEX <extension_regex> = <group_postfix>");
        ($group_regex,$group_postfix) = $mc->args;
        $url_group{$group_regex} = $group_postfix;
        return $mc->ok;
    });

    Perlbal::register_global_hook($manage_command, sub {
        my $mc = shift->parse(qr/^group\s+(?:(\w+)\s+)?(\S+)\s*=\s*(\w+)$/,
                              "usage: GROUP [<service>] <host_or_pattern> = <dest_service>");
        my ($selname, $host, $target) = $mc->args;
        unless ($selname ||= $mc->{ctx}{last_created}) {
            return $mc->err("omitted service name not implied from context");
        }

        my $ss = Perlbal->service($selname);
        return $mc->err("Service '$selname' is not a selector service")
            unless $ss && $ss->{role} eq "selector";

        $host = lc $host;
        return $mc->err("invalid host pattern: '$host'")
            unless $host =~ /^[\w\-\_\.\*\;\:\\]+$/;

        $ss->{extra_config}->{_use_wild_card} = 1 if $host =~ /\*/;

        $ss->{extra_config}->{_groups} ||= {};
        $ss->{extra_config}->{_groups}{$host} = $target;

        return $mc->ok;
    });
    return 1;
}

# unload our global commands, clear our service object
sub unload {
    my $class = shift;

    Perlbal::unregister_global_hook($manage_command);
    Perlbal::unregister_global_hook($manage_command_regex);
    unregister($class, $_) foreach (values %Services);
    return 1;
}

# called when we're being added to a service
sub register {
    my ($class, $svc) = @_;
    unless ($svc && $svc->{role} eq "selector") {
        die "You can't load the url_group plugin on a service not of role selector.\n";
    }

    $svc->selector(\&url_group_selector);
    $svc->{extra_config}->{_groups} = {};

    $Services{"$svc"} = $svc;
    return 1;
}

# called when we're no longer active on a service
sub unregister {
    my ($class, $svc) = @_;
    $svc->selector(undef);
    delete $Services{"$svc"};
    return 1;
}

# call back from Service via ClientHTTPBase's event_read calling service->select_new_service(Perlbal::ClientHTTPBase)
sub url_group_selector {
    my Perlbal::ClientHTTPBase $cb = shift;

    my $req = $cb->{req_headers};

    return $cb->_simple_response(404, "Not Found (no reqheaders)") unless $req;

    my $vhost = $req->header("Host");
    my $uri = $req->request_uri;
    my $maps = $cb->{service}{extra_config}{_groups} ||= {};

    $vhost =~ s/:\d+$//;

    my $target;
    if ( $cb->{service}{extra_config}{_use_wild_card} ) {
        for my $host_org (keys %$maps) {
            (my $host_name = $host_org) =~ s/\*/.+/g;

            if ( $vhost eq $host_name ) {
                $target = $maps->{$host_org};
                last;
            }

            if ($vhost =~ /^$host_name$/) {
                $target = $maps->{$host_org};
                # do more loop.
            }
        }
    } else {
        $target = $maps->{$vhost};
    }

    my $chk_uri = URI::Escape::uri_unescape($uri);
    # query¤ÏÌµ»ë
    $chk_uri =~ s/\?.+$//g;

    if ( $target ) {
        my $dest_service;
        for my $regex ( keys %url_group ) {
            if ( $chk_uri =~ /$regex/ ) {
                $dest_service = $target.$url_group{$regex};
                last;
            }
            $dest_service = $target;
        }

        my $svc = Perlbal->service($dest_service) || undef;
        unless ($svc) {
            $cb->_simple_response(404, "Not Found (no configured url_group's dest_service)");
            return 1;
        } else {
            $svc->adopt_base_client($cb);
            return 0;
        }
    } else {
        $cb->_simple_response(404, "Not Found (no configured url_group's vhost name)");
        return 1;
    }
}

1;

__END__

=head1 NAME

Perlbal::Plugin::UrlGroup - let URL match it in regular expression

=head1 SYNOPSIS

    in your perlbal.conf:

    LOAD UrlGroup
    CREATE SERVICE http_server
        SET listen          = 0.0.0.0:80
        SET role            = selector
        SET plugins         = UrlGroup
        GROUP_REGEX .(jpg|gif|png|js|css|swf)$ = _static
        GROUP_REGEX ^/app_s1/$ = _s1

        GROUP example.com = example
    ENABLE http_server
    
    CREATE SERVICE example
        SET role            = reverse_proxy
        SET pool            = example_pool
        SET enable_reproxy  = true
    ENABLE example
    
    CREATE SERVICE example_static
        SET role            = reverse_proxy
        SET pool            = example_static_pool
        #SET enable_reproxy  = true
    ENABLE example_static

=head1 DESCRIPTION

let URL match it in regular expression.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Atsushi Kobayashi  C<< <nekokak __at__ gmail dot com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Atsushi Kobayashi C<< <nekokak __at__ gmail dot com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

