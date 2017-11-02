package Mojolicious::Plugin::ClientIP::Pluggable;

# ABSTRACT: Client IP header handling for Mojolicious requests

=head1 NAME

Mojolicious::Plugin::ClientIP::Pluggable - Customizable client IP detection plugin for Mojolicious

=head1 SYNOPSIS

    use Mojolicious::Lite;

    # CloudFlare-waware settings
    plugin 'ClientIP::Pluggable',
        analyze_headers => [qw/cf-pseudo-ipv4 cf-connecting-ip true-client-ip/],
        restrict_family => 'ipv4',
        fallbacks       => [qw/rfc-7239 x-forwarded-for remote_address/];


    get '/' => sub {
        my $c = shift;
        $c->render(text => $c->client_ip);
    };

    app->start;

=head1 DESCRIPTION

Mojolicious::Plugin::ClientIP::Pluggable is a Mojolicious plugin to get an IP address, which
allows to specify different HTTP-headers (and their priorities) for client IP address
extraction. This is needed as different cloud providers set different headers to disclose
real IP address.

If the address cannot be extracted from headers different fallback options are available:
detect IP address from C<X-Forwarded-For> header, detect IP address from C<forwarded> header
(rfc-7239), or use C<remote_address> environment.

The plugin is inspired by L<Mojolicious::Plugin::ClientIP>.

=head1 METHODS

=head2 client_ip

Find a client IP address from the specified headers, with optional fallbacks. The address is
validated that it is publicly available (aka routable) IP address. Empty string is returned
if no valid address can be found.

=head1 OPTIONS

=head2 analyzed_headers

Define order and names of cloud provider injected headers with client IP address.
For C<cloudflare> we found the following headers are suitable:

    plugin 'ClientIP::Pluggable',
        analyzed_headers => [qw/cf-pseudo-ipv4 cf-connecting-ip true-client-ip/].

This option is mandatory.

More details at L<https://support.cloudflare.com/hc/en-us/articles/202494830-Pseudo-IPv4-Supporting-IPv6-addresses-in-legacy-IPv4-applications>,
L<https://support.cloudflare.com/hc/en-us/articles/200170986-How-does-CloudFlare-handle-HTTP-Request-headers>,
L<https://support.cloudflare.com/hc/en-us/articles/206776727-What-is-True-Client-IP>

=head2 restrict_family

    plugin 'ClientIP::Pluggable', restrict_family => 'ipv4';
    plugin 'ClientIP::Pluggable', restrict_family => 'ipv6';

If defined only IPv4 or IPv6 addresses are considered valid among the possible addresses.

By default this option is not defined, allowing IPv4 and IPv6 addresses.

=head2 fallbacks

    plugin 'ClientIP::Pluggable',
        fallbacks => [qw/rfc-7239 x-forwarded-for remote_address/]);

Try to get valid client IP-address from fallback sources, if we fail to do that from
cloud-provider headers.

C<rfc-7239> uses C<forwarded> header, C<x-forwarded-for> use <x-forwarded-for> header
(appeared before rfc-7239 and still widely used) or use remote_address environment
(C<$c->tx->remote_address>).

Default value is C<[remote_address]>.

=head1 ENVIRONMENT

=head2 CLIENTIP_PLUGGABLE_ALLOW_LOOPBACK

Allows non-routable loopback address (C<127.0.0.1>) to pass validation. Use it for
test purposes.

Default value is C<0>, i.e. loopback addresses do not pass IP-address validation.


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 binary.com

=cut

use strict;
use warnings;

use Data::Validate::IP;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.01';

# for tests only
use constant ALLOW_LOOPBACK => $ENV{CLIENTIP_PLUGGABLE_ALLOW_LOOPBACK} || 0;

sub _check_ipv4 {
    my ($ip) = @_;
    return Data::Validate::IP::is_public_ipv4($ip)
        || (ALLOW_LOOPBACK && Data::Validate::IP::is_loopback_ipv4($ip));
}

sub _check_ipv6 {
    my ($ip) = @_;
    return Data::Validate::IP::is_public_ipv6($ip)
        || (ALLOW_LOOPBACK && Data::Validate::IP::is_loopback_ipv6($ip));
}

sub _classify_ip {
    my ($ip) = @_;
    return
          Data::Validate::IP::is_ipv4($ip) ? 'ipv4'
        : Data::Validate::IP::is_ipv6($ip) ? 'ipv6'
        :                                    undef;
}

sub _candidates_iterator {
    my ($c, $analyzed_headers, $fallback_options) = @_;
    my $headers    = $c->tx->req->headers;
    my @candidates = map { $headers->header($_) // () } @$analyzed_headers;
    my $comma_re   = qr/\s*,\s*/;
    for my $fallback (map { lc } @$fallback_options) {
        if ($fallback eq 'x-forwarded-for') {
            my $xff = $headers->header('x-forwarded-for');
            next unless $xff;
            my @ips = split $comma_re, $xff;
            push @candidates, @ips;
        } elsif ($fallback eq 'remote_address') {
            push @candidates, $c->tx->remote_address;
        } elsif ($fallback eq 'rfc-7239') {
            my $f = $headers->header('forwarded');
            next unless $f;
            my @pairs = map { split $comma_re, $_ } split ';', $f;
            my @ips = map {
                my $ipv4_mask = qr/\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}/;
                # it is not completely valid ipv6 mask, but enough
                # to extract address. It will be validated later
                my $ipv6_mask = qr/[\w:]+/;
                if (/for=($ipv4_mask)|(?:"?\[($ipv6_mask)\].*"?)/i) {
                    ($1 // $2);
                } else {
                    ();
                }
            } @pairs;
            push @candidates, @ips;
        } else {
            warn "Unknown fallback option $fallback, ignoring";
        }
    }
    my $idx = 0;
    return sub {
        if ($idx < @candidates) {
            return $candidates[$idx++];
        }
        return (undef);
    };
}

sub register {
    my ($self, $app, $conf) = @_;
    my $analyzed_headers = $conf->{analyze_headers} // die "Please, specify 'analyzed_headers' option";
    my %validator_for = (
        ipv4 => \&_check_ipv4,
        ipv6 => \&_check_ipv6,
    );
    my $restrict_family = $conf->{restrict_family};
    my $fallback_options = $conf->{fallbacks} // [qw/remote_address/];

    $app->helper(
        client_ip => sub {
            my ($c) = @_;

            my $next_candidate = _candidates_iterator($c, $analyzed_headers, $fallback_options);
            while (my $ip = $next_candidate->()) {
                # generic check
                next unless Data::Validate::IP::is_ip($ip);

                # classify & check
                my $address_family = _classify_ip($ip);
                next unless $address_family;

                # possibly limit to acceptable address family
                next if $restrict_family && $restrict_family ne $address_family;

                # validate by family
                my $validator = $validator_for{$address_family};
                next unless $validator->($ip);

                # address seems valid, return its textual representation
                return $ip;
            }
            return '';
        });

    return;
}

1;
