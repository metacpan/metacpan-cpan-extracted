use strict;
use warnings;
package Perlbal::Plugin::SessionAffinity;
# ABSTRACT: Sane session affinity (sticky sessions) for Perlbal
$Perlbal::Plugin::SessionAffinity::VERSION = '0.101';
use Perlbal;
use Hash::Util;
use CGI::Cookie;
use MIME::Base64;
use Digest::MD5 'md5';
use Digest::SHA 'sha1_hex';

my $default_cookie_hdr = 'X-SERVERID';
my $cookie_hdr_sub     = sub { encode_base64( md5( $_[0] ) ) };
my $salt               = join q{}, map { $_ = rand 999; s/\.//; $_ } 1 .. 10;
my $use_salt           = 0;
my $use_domain         = 0;
my $use_dynamic_cookie = 0;

sub get_domain_from_req {
    my $req    = shift;
    my $domain = ref $req eq 'Perlbal::XS::HTTPHeaders' ?
                 $req->getHeader('host')                : # XS version
                 $req->{'headers'}{'host'};               # PP version

    return $domain;
}

# get the ip and port of the requested backend from the cookie
sub get_ip_port {
    my ( $svc, $req ) = @_;

    my $domain     = get_domain_from_req($req);
    my $cookie_hdr = $use_dynamic_cookie        ?
                     $cookie_hdr_sub->($domain) :
                     $default_cookie_hdr;

    my $cookie     = $req->header('Cookie');
    my %cookies    = ();

    if ( defined $cookie ) {
        %cookies = CGI::Cookie->parse($cookie);

        if ( defined $cookies{$cookie_hdr} ) {
            my $id      = $cookies{$cookie_hdr}->value || '';
            my $backend = find_backend_by_id( $svc, $id );

            ref $backend and return join ':', @{$backend};
        }
    }

    return;
}

# create a domain ID
sub create_domain_id {
    my $domain = shift || '';
    my @nodes  = @_;

    # the ID is determined by the specific server
    # that has the matching index for the domain
    my $index = domain_index( $domain, scalar @nodes );
    my $node  = join ':', @{ $nodes[$index] };
    return sha1_hex( $use_salt ? $salt . $node : $node );
}

# create an id from ip and optional port
sub create_id {
    my $ip   = shift;
    my $port = shift || '';
    my $str  = $use_salt ? $salt . "$ip:$port" : "$ip:$port";
    return sha1_hex($str);
}

# a nifty little trick:
# we create a numeric value of the domain name
# then we use that as a seed for the random function
# then create a random number which is predictable
# that is the index of the domain
sub domain_index {
    my $domain = shift;
    my $max    = shift;
    my $seed   = 0;

    foreach my $char ( split //, $domain ) {
        $seed += ord $char;
    }

    return ( $seed % $max);
}

# using an sha1 checksum id, find the matching backend
sub find_backend_by_id {
    my ( $svc, $id ) = @_;

    foreach my $backend ( @{ $svc->{'pool'}{'nodes'} } ) {
        my $backendid = create_id( @{$backend} );

        if ( $backendid eq $id ) {
            return $backend;
        }
    }

    return;
}

# TODO: refactor this function
sub find_backend_by_domain_id {
    my ( $svc, $id ) = @_;

    foreach my $backend ( @{ $svc->{'pool'}{'nodes'} } ) {
        my $backendid = create_id( @{$backend} );

        if ( $backendid eq $id ) {
            return $backend;
        }
    }

    return;
}

sub load {
    # the name of header in the cookie that stores the backend ID
    Perlbal::register_global_hook(
        'manage_command.affinity_cookie_header', sub {
            my $mc = shift->parse(qr/^\s*affinity_cookie_header\s+=\s+(.+)\s*$/,
                      "usage: AFFINITY_COOKIE_HEADER = <name>");

            ($default_cookie_hdr) = $mc->args;

            return $mc->ok;
        },
    );

    Perlbal::register_global_hook(
        'manage_command.affinity_salt', sub {
            my $mc = shift->parse(qr/^\s*affinity_salt\s+=\s+(.+)\s*$/,
                      "usage: AFFINITY_SALT = <salt>");

            ($salt) = $mc->args;

            return $mc->ok;
        },
    );

    Perlbal::register_global_hook(
        'manage_command.affinity_use_salt', sub {
            my $mc = shift->parse(qr/^\s*affinity_use_salt\s+=\s+(.+)\s*$/,
                      "usage: AFFINITY_USE_SALT = <boolean>");

            my ($res) = $mc->args;
            if ( $res eq 'yes' || $res == 1 ) {
                $use_salt = 1;
            } elsif ( $res eq 'no' || $res == 0 ) {
                $use_salt = 0;
            } else {
                die qq"affinity_use_salt must be boolean (yes/no/1/0)";
            }

            return $mc->ok;
        },
    );

    Perlbal::register_global_hook(
        'manage_command.affinity_use_domain', sub {
            my $mc = shift->parse(qr/^\s*affinity_use_domain\s+=\s+(.+)\s*$/,
                      "usage: AFFINITY_USE_DOMAIN = <boolean>");

            my ($res) = $mc->args;
            if ( $res eq 'yes' || $res == 1 ) {
                $use_domain = 1;
            } elsif ( $res eq 'no' || $res == 0 ) {
                $use_domain = 0;
            } else {
                die qq"affinity_use_domain must be boolean (yes/no/1/0)";
            }

            return $mc->ok;
        },
    );

    Perlbal::register_global_hook(
        'manage_command.affinity_use_dynamic_cookie', sub {
            my $mc = shift->parse(qr/^\s*affinity_use_dynamic_cookie\s+=\s+(.+)\s*$/,
                      "usage: AFFINITY_USE_DYNAMIC_COOKIE = <boolean>");

            my ($res) = $mc->args;
            if ( $res eq 'yes' || $res == 1 ) {
                $use_dynamic_cookie = 1;
            } elsif ( $res eq 'no' || $res == 0 ) {
                $use_dynamic_cookie = 0;
            } else {
                die qq"affinity_use_dynamic_cookie must be boolean (yes/no/1/0)";
            }

            return $mc->ok;
        },
    );

    return 1;
}

sub register {
    my ( $class, $gsvc ) = @_;

    my $check_cookie = sub {
        my $client = shift;
        my $req    = $client->{'req_headers'} or return 0;
        my $svc    = $client->{'service'};
        my $pool   = $svc->{'pool'};

        # make sure all nodes in this service have their own pool
        foreach my $node ( @{ $pool->{'nodes'} } ) {
            my ( $ip, $port ) = @{$node};

            # pool
            my $poolid = create_id( $ip, $port );
            exists $Perlbal::pool{$poolid} and next;

            my $nodepool = Perlbal::Pool->new($poolid);
            $nodepool->add( $ip, $port );
            $Perlbal::pool{$poolid} = $nodepool;

            # service
            my $serviceid = "${poolid}_service";
            exists $Perlbal::service{$serviceid} and next;

            my $nodeservice = Perlbal->create_service($serviceid);
            my $svc_role    = $svc->{'role'};

            # role sets up constraints for the rest
            # so it goes first
            $nodeservice->set( role => $svc_role );

            foreach my $tunable_name ( keys %{$Perlbal::Service::tunables} ) {
                # skip role because we had already set it
                $tunable_name eq 'role' and next;

                # persist_client_timeout is DEPRECATED
                # but not marked anywhere as deprecated. :(
                # (well, nowhere we can actually predictably inspect)
                $tunable_name eq 'persist_client_timeout' and next; 

                # we skip the pool because we're gonna set it to a specific one
                $tunable_name eq 'pool' and next;

                # make sure svc has value for this tunable
                defined $svc->{$tunable_name} or next;

                my $tunable = $Perlbal::Service::tunables->{$tunable_name};
                my $role    = $tunable->{'check_role'};

                if ( $role eq '*' || $role eq $svc_role ) {
                    $nodeservice->set( $tunable_name, $svc->{$tunable_name} );
                }
            }

            # restricted hashes are stupid
            # so we have to use the API to add them
            foreach my $hook_name ( keys %{ $svc->{'hooks'} } ) {
                foreach my $set ( @{ $svc->{'hooks'}{$hook_name} } ) {
                    my ( $plugin, $sub ) = @{$set};
                    $nodeservice->register_hook( $plugin, $hook_name, $sub );
                }
            }

            # add all the extra config and extra headers
            $nodeservice->{'extra_config'}  = $svc->{'extra_config'};
            $nodeservice->{'extra_headers'} = $svc->{'extra_headers'};

            $nodeservice->set( pool => $poolid );

            $Perlbal::service{$serviceid} = $nodeservice;
        }

        my $ip_port = get_ip_port( $svc, $req );

        if ( ! $ip_port ) {
            $use_domain or return 0;

            # we're going to override whatever Perlbal found
            # because we only care about the domain
            my $domain = get_domain_from_req($req);

            my @ordered_nodes = sort {
                ( join ':', @{$a} ) cmp ( join ':', @{$b} )
            } @{ $svc->{'pool'}{'nodes'} };

            my $id      = create_domain_id( $domain, @ordered_nodes );
            my $backend = find_backend_by_domain_id( $svc, $id );
            $ip_port = join ':', @{$backend};
        }

        my ( $ip, $port )    = split /:/, $ip_port;
        my $req_pool_id      = create_id( $ip, $port );
        my $req_svc          = $Perlbal::service{"${req_pool_id}_service"};
        $client->{'service'} = $req_svc;

        return 0;
    };

    my $set_cookie = sub {
        my $backend = shift; # Perlbal::BackendHTTP

        defined $backend or return 0;

        my $res        = $backend->{'res_headers'};
        my $req        = $backend->{'req_headers'};
        my $svc        = $backend->{'service'};
        my $backend_id = create_id( split /:/, $backend->{'ipport'} );
        my $domain     = get_domain_from_req($req);
        my $cookie_hdr = $use_dynamic_cookie        ?
                         $cookie_hdr_sub->($domain) :
                         $default_cookie_hdr;

        my %cookies = ();
        if ( my $cookie = $req->header('Cookie') ) {
            %cookies = CGI::Cookie->parse($cookie);
        }

        if ( ! defined $cookies{$cookie_hdr} ||
             $cookies{$cookie_hdr}->value ne $backend_id ) {

            my $backend_cookie = CGI::Cookie->new(
                -name  => $cookie_hdr,
                -value => $backend_id,
            );

            if ( defined $res->header('set-cookie') ) {
                my $value = $res->header('set-cookie') .
                            "\r\nSet-Cookie: "         .
                            $backend_cookie->as_string;

                $res->header( 'Set-Cookie' => $value );
            } else {
                $res->header( 'Set-Cookie' => $backend_cookie->as_string );
            }
        }

        return 0;
    };

    $gsvc->register_hook(
        'SessionAffinity', 'start_proxy_request', $check_cookie,
    );

    $gsvc->register_hook(
        'SessionAffinity', 'backend_response_received', $set_cookie,
    );

    return 1;
}

sub unregister {
    my ( $class, $svc ) = @_;

    # TODO: are we using setters?
    $svc->unregister_hooks('SessionAffinity');
    $svc->unregister_setters('SessionAffinity');

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perlbal::Plugin::SessionAffinity - Sane session affinity (sticky sessions) for Perlbal

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    LOAD SessionAffinity

    CREATE POOL backends
      POOL backends ADD 10.20.20.100
      POOL backends ADD 10.20.20.101
      POOL backends ADD 10.20.20.102

    CREATE SERVICE balancer
      SET listen          = 0.0.0.0:80
      SET role            = reverse_proxy
      SET pool            = backends
      SET persist_client  = on
      SET persist_backend = on
      SET verify_backend  = on
      SET plugins         = sessionaffinity
    ENABLE balancer

=head1 DESCRIPTION

L<Perlbal> doesn't support session affinity (or otherwise known as "sticky
sessions") out of the box. There is a plugin on CPAN called
L<Perlbal::Plugin::StickySessions> but there are a few problems with it.

This plugin should be do a much better job. Go ahead and read why you should
use this one and how it works.

=head1 WHY YOU SHOULD USE IT

Here are things that are unique in this plugin. I am comparing this with the
current available session affinity implementation available on CPAN
(L<Perlbal::Plugin::StickySessions>).

=over 4

=item * It supports session affinity for all requests

Unlike the other plugin, this one uses a proper hook that supports not just
file fetching, but for each and every request.

=item * No patches required

Unlike the other plugin, that comes with two patches (which were not
integrated into L<Perlbal> core), this one requires no patches whatsoever.

=item * It's up-to-date

Unlike the other plugin, that still requires a patch that includes a hook that
was already introduced (which shows it's clearly outdated), this plugin is
very much up to speed with things.

=item * It's thin and sane

Unlike the other plugin, which is mostly copy-pasted from some handling code
in L<Perlbal> itself (seriously!), this module contains no copy-pasted code,
is much smaller and leaner, and is much less likely to break between new
versions of Perlbal.

=item * No breakage

Unlike the other plugin, which - after close inspection - seemed breakable
(to say the least, since connect-aheads don't seem to get cleaned up), this
plugin uses a completely different method which emphasizes correctness and
the least intervention with Perlbal itself, and keeps Perlbal in charge of
the critical operations.

Small note here: this does not mean it will definitely play nice with
everything you already have. Specifically any hooks that rely on the name of
the service might be affected.

Please read further under B<Incompatibilities> to understand the issue
better.

=item * Much less security risk

Unlike the other plugin, which sets a cookie with the backend ID correlating
to the backend order in the pool, this plugin uses SHA1 checksum IDs (with an
optionally randomly-created salt) for each server, and allows you to change the
header name and add a checksum salt (whether randomly-created or your own) for
the cookie.

This makes it harder for an attacker to understand what the header represents
and how many backends exist (since there is no counter).

=item * Features

Unlike the other plugin, that simply has things hardcoded, this plugin allows
to change both the header name and the salt used to create the ID. By default
the salt is off but you can turn it on and then either use a randomly-created
one or set your own.

=back

=head1 HOW DOES IT WORK

=head2 Basic stuff

Basically, the module creates a SHA1 checksum for each backend node, and
provides the user with a cookie request. If the user provides that cookie in
return, it will try and find and provide the user with that specific node.

If the node is no longer in the service's pool, or the cookie matches a node
that doesn't exist, it will provide the user with a cookie again.

=head2 Advanced stuff

The plugin sets up dedicated pools and services for each service's node. This
is required since Perlbal has no way of actually allowing you to specify the
node a user will go to, only the service. Not to worry, this creation is done
lazily so it saves as much memory as it can.

When a user comes in with a cookie of a node that exist in the service's pool
it will create a pool for it (if one doesn't exist), and a matching service
for it (if one doesn't exist) and then direct to user to it.

The check against nodes and pools is done live and not against the static
configuration file. This means that if you're playing with the pools (changing
them live, for example), it will still work just fine.

A new service is created using configurations from the existing service. The
more interesting details is that reuse is emphasized so no new sockets are
created and instead this new service uses the already existing sockets (along
with existing connections) instead of firing new ones. It doesn't open a new
socket for listening or anything like that. This also means your SSL
connections work seamlessly. Yes, it's insanely cool, I know! :)

=head2 Incompatibilities

If you've read the B<Advanced stuff> section above, you might have guessed
a possible problem with anything that relies on the name of the service.

If you're using a plugin that relies on the name of the service, you might
notice it stops working properly. This is because the new service that is
generated by B<SessionAffinity> is no longer the previous service, and doesn't
contain its name. Instead it has its own name, which is not known to your
plugin.

If you're using the C<header> command to add headers to the backend, fear
not. We copy over the headers from the original service to the new one. That
still works just fine.

One possible way to fix it (implemented and later removed) is to include the
previous name in a new unofficial (and unauthorized) key in the service hash.

=head1 ATTRIBUTES

=head2 affinity_cookie_header

The name of the cookie header for the session.

Default: B<X-SERVERID>.

=head2 affinity_use_salt

Whether to use a salt or not when calculating SHA1 IDs.

    # both are equal
    affinity_use_salt = 1
    affinity_use_salt = yes

    # opposite meaning
    affinity_use_salt = 0
    affinity_use_salt = no

Default: B<no>.

=head2 affinity_salt

The salt that is used to create the backend's SHA1 IDs.

Default: the following code is run when you load
L<Perlbal::Plugin::SessionAffinity> to create the salt on start up:

    join q{}, map { $_ = rand 999; s/\.//; $_ } 1 .. 10;

If you want predictability with salt, you can override it as such:

    affinity_salt = helloworld

    # now the calculation will be:
    my $sha1 = sha1hex( $salt . $ip . $port );

=head2 affinity_use_domain

Uses domain-mode for finding the backend. This is an alternate way of
deciding the backend, which enables backends to persist per domain,
allowing you to avoid a fragmented cache. If you have a lot of cache misses
because of jumping between backends, try turning this feature on.

This feature ignores the cookie provided (and does not provide its own
cookie) since backends are decided by the domain name alone.

    # both are equal
    affinity_use_domain = 1
    affinity_use_domain = yes

    # opposite meaning
    affinity_use_domain = 0
    affinity_use_domain = no

Default: B<no>.

=head1 SUBROUTINES/METHODS

=head2 register

Registers our events.

=head2 unregister

Unregister our hooks and setters events.

=head2 get_ip_port

Parses a request's cookies and finds the specific cookie relating to session
affinity and get the backend details via the ID in the cookie.

=head2 find_backend_by_id

Given a SHA1 ID, find the correct backend to which it belongs.

=head2 find_backend_by_domain_id

Given a SHA1 ID for a domain, find the correct backend to which it belongs.

=head2 create_id

Creates a SHA1 checksum ID using L<Digest::SHA>. The checksum is composed
of the IP, port and salt. If you want to have more predictability, you can
provide a salt of C<0> or C<string> and then the checksum would be predictable.

This should make it clear on how it's created:

    if ( $has_salt ) {
        $checksum = sha1sum( $salt . "$ip:$port" );
    } else {
        $checksum = sha1sum( "$ip:$port" );
    }

=head2 create_domain_id

Same concept as the above C<create_id> function, except for the following
changes:

Accepts a domain and a list of nodes (which is assumed to be ordered), uses the
C<domain_index> function to get the index in the nodes of a domain and picks
the correct node from the list it receives by index.

=head2 domain_index

This function tries to fetch an index number for a given domain name. It
accepts a domain name and the maximum index number.

It translates the domain name to a long number, and uses mod (C<%>) on it.

=head1 DEPENDENCIES

=head2 Perlbal

Obviously.

=head2 CGI::Cookies

To parse and create cookies.

=head2 Digest::SHA

To provide a SHA1 checksum.

=head1 SEE ALSO

=head2 Perlbal::Plugin::StickySessions

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
