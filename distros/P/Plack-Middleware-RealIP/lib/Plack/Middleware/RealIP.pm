package Plack::Middleware::RealIP;
use strict;
use warnings;
use 5.008;
our $VERSION = 0.03;
use parent qw/Plack::Middleware/;
use Net::Netmask;

use Plack::Util::Accessor qw( header trusted_proxy );

sub prepare_app {
    my $self = shift;

    if (my $trusted_proxy = $self->trusted_proxy) {
        my @trusted_proxy = map { Net::Netmask->new($_) } ref($trusted_proxy) ? @{ $trusted_proxy } : ($trusted_proxy);
        $self->trusted_proxy(\@trusted_proxy);
    }
}

sub call {
    my $self = shift;
    my $env  = shift;

    my $header;
    if ($header = $self->header) {
        ($header = uc $header) =~ tr/-/_/;
        $header = "HTTP_$header" unless $header =~ /^(?:HTTP|CONTENT|COOKIE)/;
    }

    my (@remote, @trusted_proxy);
    @remote = $env->{$header} =~ /([^,\s]+)/g if exists $env->{$header};
    @trusted_proxy = @{ $self->trusted_proxy } if $self->trusted_proxy;

    if (@remote and @trusted_proxy) {
        my @unconfirmed = (@remote, $env->{REMOTE_ADDR});

        while (my $addr = pop @unconfirmed) {
            my $has_matched = 0;
            foreach my $netmask (@trusted_proxy) {
                $has_matched++, last if $netmask->match($addr);
            }
            $env->{REMOTE_ADDR} = $addr, last unless $has_matched;
        }

        if (@unconfirmed) {
            $env->{$header} = join(', ', @unconfirmed);
        } else {
            delete $env->{$header};
        }
    }

    return $self->app->($env);
}

1;

=head1 NAME

Plack::Middleware::RealIP - Override client IP with header value provided by proxy/load balancer

=head1 SYNOPSIS

  enable 'Plack::Middleware::RealIP',
      header => 'X-Forwarded-For',
      trusted_proxy => [qw(192.168.1.0/24 192.168.2.1)];

=head1 DESCRIPTION

Plack::Middleware::RealIP is loose port of the Apache module
mod_remoteip. It overrides C<REMOTE_ADDR> with the IP address advertised
in the request header configured with C<header>.

When multiple, comma delimited IP addresses are listed in the header
value, they are processed from right to left. The first untrusted IP
address found, based on C<trusted_proxy>, stops the processing and is
set to be C<REMOTE_ADDR>. The header field is updated to this remaining
list of unconfirmed IP addresses, or if all IP addresses were trusted,
this header is removed from the request altogether.

=head1 CONFIGURATION

=head2 header

Sets a request header to trust as the client IP, e.g. X-Client-IP

=head2 trusted_proxy

A list of IP addresses or subnet blocks which are trusted to provide IP header.

=head1 AUTHOR

Sherwin Daganato E<lt>sherwin@daganato.comE<gt>

Most of the logic is based on L<Plack::Middleware::XForwardedFor> by Graham Barr

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<mod_remoteip|http://httpd.apache.org/docs/trunk/mod/mod_remoteip.html>

L<Plack::Middleware::XForwardedFor>

L<Plack::Middleware::ReverseProxy>

L<Net::Netmask>

=cut
