package Mojolicious::Plugin::ClientIP;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.02';

has 'ignore';

sub register {
    my $self = shift;
    my ($app, $conf) = @_;

    $self->ignore([
        @{$conf->{private} || [qw(127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16) ]},
        @{$conf->{ignore} || []}
    ]);

    $app->helper(client_ip => sub {
        my ($c) = @_;

        state $key = '__plugin_clientip_ip';

        return $c->stash($key) if $c->stash($key);

        my $xff        = $c->req->headers->header('X-Forwarded-For') // '';
        my @candidates = reverse grep { $_ } split /,\s*/, $xff;
        my $ip         = $self->_find(\@candidates) // $c->tx->remote_address;
        $c->stash($key => $ip);

        return $ip;
    });
}

sub _find {
    my $self = shift;
    my ($candidates) = @_;

    state $octet = '(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})';
    state $ip4   = qr/\A$octet\.$octet\.$octet\.$octet\z/;

    for (@$candidates) {
        next unless /$ip4/;
        next if _match($_, $self->ignore);
        return $_;
    }

    return;
}

sub _match {
    my ($ip, $ips) = @_;

    my $ip_bit = _to_bit($ip);

    for (@$ips) {
        return 1 if $ip eq $_;

        if (my ($net, $prefix) = m{^([\d\.]+)/(\d+)$}) {
            my $match_ip_bit = _to_bit($1);
            return 1 if substr($ip_bit, 0, $2) eq substr($match_ip_bit, 0, $2);
        }
    }

    return;
}

sub _to_bit {
    my ($ip) = @_;

    join '', map { unpack('B8', pack('C', $_)) } split /\./, $ip;
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::ClientIP - Get client's IP address from X-Forwarded-For

=head1 SYNOPSIS

    use Mojolicious::Lite;

    plugin 'ClientIP';

    get '/' => sub {
        my $c = shift;
        $c->render(text => $c->client_ip);
    };

    app->start;

=head1 DESCRIPTION

Mojolicious::Plugin::ClientIP is a Mojolicious plugin to get an IP address looks like client, not proxy, from X-Forwarded-For header.

=head1 METHODS

=head2 client_ip

Find a client IP address from X-Forwarded-For. Private network addresses in XFF are ignored by default. If the good IP address is not found, it returns Mojo::Transaction#remote_address.

=head1 OPTIONS

=head2 ignore

Specify IP list to be ignored with ArrayRef.

    plugin 'ClientIP', ignore => [qw(192.0.2.1 192.0.2.16/28)];

=head2 private

Specify IP list which is handled as private IP address.
This is a optional parameter.
Default values are C<[qw(127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16)]> as defined in RFC 1918.

    plugin 'ClientIP', ignore => [qw(192.0.2.16/28)], private => [qw(10.0.0.0/8)];

=head1 LICENSE

Copyright (C) Six Apart Ltd. E<lt>sixapart@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ziguzagu E<lt>ziguzagu@cpan.orgE<gt>

=cut
