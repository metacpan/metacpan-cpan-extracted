package MojoX::CloudFlare::Simple;

use strict;
use warnings;
use v5.10;
use Carp qw/croak/;
use Mojo::Base -base;
use Mojo::UserAgent;

our $VERSION = '0.02';

has 'ua' => sub {
    my $ua = Mojo::UserAgent->new;
    $ua->transactor->name("MojoX-CloudFlare-Simple $VERSION");
    return $ua;
};

has 'url_prefix' => sub { 'https://api.cloudflare.com/client/v4/' };
has 'email';
has 'key';
has 'user_service_key';

sub request {
    my ($self, $method, $url, $params) = @_;

    croak 'email and key are all required' unless $self->email and $self->key;

    my $header = {
        'X-Auth-Email' => $self->email,
        'X-Auth-Key'   => $self->key,
        'Content-Type' => 'application/json',
    };
    $header->{'X-Auth-User-Service-Key'} = $self->user_service_key if $self->user_service_key;

    $url = '/' . $url unless $url =~ m{^/};
    $url = $self->url_prefix . $url;

    my @extra;
    if ($method eq 'GET') {
        my $uri = Mojo::URL->new($url);
        $uri->query($params);
        $url = $uri->to_string();
    } elsif (grep { $method eq $_ } ('POST', 'PUT', 'PATCH', 'DELETE')) {
        @extra = (json => $params);
    }

    my $tx = $self->ua->build_tx($method => $url => $header => @extra );
    $tx = $self->ua->start($tx);

    return $tx->res->json if ($tx->res->headers->content_type || '') =~ /json/;

    my $err = $tx->error;
    croak "$err->{code} response: $err->{message}" if $err->{code};
    croak "Connection error: $err->{message}";
}

1;
__END__

=encoding utf-8

=head1 NAME

MojoX::CloudFlare::Simple - simple cloudflare client without wrapper

=head1 SYNOPSIS

    use MojoX::CloudFlare::Simple;

    my $cloudflare = MojoX::CloudFlare::Simple->new(
        email => 'blabla@blabla.com',
        key   => 'secretkeyblabla',
    );

    my $zones = $cloudflare->request('GET', 'zones');
    say Dumper(\$zones);

    my $result = $cloudflare->request('DELETE', "zones/$zone_id/purge_cache", {
        files => [
            'http://bsportsfan.com/',
            'https://assets.bsportsfan.com/images/team/s/34953.png'
        ]
    });
    say Dumper(\$result);

=head1 DESCRIPTION

MojoX::CloudFlare::Simple is a simple client for cloudflare. it does not have any wrap or trick. it just simply send the requests and return your data. you need handle everything yourself.

You can get your key from L<https://www.cloudflare.com/a/account/my-account>

you can find some examples scripts like get zones, purge files under examples.

please use ENV MOJO_USERAGENT_DEBUG for debug.

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2016- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
