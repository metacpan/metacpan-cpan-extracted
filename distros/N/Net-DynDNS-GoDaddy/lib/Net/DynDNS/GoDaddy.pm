package Net::DynDNS::GoDaddy;

use strict;
use warnings;

use Carp qw(croak);
use Data::Dumper;
use Exporter qw(import);
use File::HomeDir;
use HTTP::Tiny;
use JSON;

our $VERSION = '0.04';

our @EXPORT = qw(host_ip_get host_ip_set);
our @EXPORT_OK = qw(api_key_get api_key_set);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

my $home_dir;

BEGIN {
    $home_dir = File::HomeDir->my_home;
}

use constant {
    URL             => 'https://api.godaddy.com',
    API_KEY_FILE    => "$home_dir/godaddy_api.json",
};

my $client = HTTP::Tiny->new;
my ($key, $secret);

sub api_key_get {
    return($key, $secret) if $key && $secret;

    {
        local $/;
        open my $fh, '<', API_KEY_FILE
            or croak "GoDaddy API key/secret file ${\API_KEY_FILE} doesn't exist";

        my $data = decode_json(<$fh>);

        $key = $data->{api_key};
        $secret = $data->{api_secret};
    }

    return($key, $secret);
}
sub api_key_set {
    my ($key, $secret) = @_;

    if (! $key || ! $secret) {
        croak "api_key_set() requires an API key and an API secret sent in";
    }

    my $data = {
        api_key     => $key,
        api_secret  => $secret,
    };

    open my $fh, '>', API_KEY_FILE
        or croak "Can't open ${\API_KEY_FILE} for writing";

    print $fh JSON->new->pretty->encode($data);

    return 1;
}
sub host_ip_get {
    my ($host, $domain) = @_;

    if (! defined $host || ! defined $domain) {
        croak "host_ip_get() requires a hostname and domain name sent in";
    }

    my $ip = _get($host, $domain);

    return $ip;
}
sub host_ip_set {
    my ($host, $domain, $ip) = @_;

    if (! defined $host || ! defined $domain || ! defined $ip) {
        croak "host_ip_set() requires a hostname, domain and IP sent in";
    }

    if ($ip !~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
        croak "host_ip_get() received an invalid IP: $ip";
    }

    my $response = _set($host, $domain, $ip);

    return $response;
}

sub _api_key_file {
    # Returns the path and filename of the API key file (used for testing)
    return API_KEY_FILE;
}
sub _get {
    # Fetch the current IP of the host/domain pair

    my ($host, $domain) = @_;

    my $route = "/v1/domains/$domain/records/A/$host";

    my $uri = URL . $route;

    my ($api_key, $api_secret) = api_key_get();

    my $api_auth = "$api_key:$api_secret";

    my $headers = {
        'Authorization' => "sso-key $api_auth"
    };

    my $response = $client->request('GET', $uri, {headers => $headers});

    my $status = $response->{status};

    if ($status != 200) {
        warn "Failed to connect to $uri to get your address: $response->{content}";
        return '';
    }

    my $ip = decode_json($response->{content})->[0]{data};

    return $ip;
}
sub _set {
    # Set the host to a new IP

    my ($host, $domain, $ip) = @_;

    my $route = "/v1/domains/$domain/records/A/$host";

    my $uri = URL . $route;

    my ($api_key, $api_secret) = api_key_get();

    my $api_auth = "$api_key:$api_secret";

    my $headers = {
        'Authorization' => "sso-key $api_auth",
        'Content-Type'  => 'application/json',
    };

    my $content = [{ data => $ip }];
    my $content_json = encode_json($content);

    my $response = $client->request(
        'PUT',
        $uri,
        {
            headers => $headers,
            content => $content_json
        }
    );

    my $status = $response->{status};

    if ($status != 200) {
        warn "Failed to connect to $uri to get your address: $response->{content}";
        return 0;
    }

    return $response->{success};
}
sub __placeholder {}

1;
__END__

=head1 NAME

Net::DynDNS::GoDaddy - Provides Dynamic DNS functionality for your GoDaddy
domains

=for html
<a href="https://github.com/stevieb9/net-dyndns-godaddy/actions"><img src="https://github.com/stevieb9/net-dyndns-godaddy/workflows/CI/badge.svg"/></a>
<a href='https://coveralls.io/github/stevieb9/net-dyndns-godaddy?branch=main'><img src='https://coveralls.io/repos/stevieb9/net-dyndns-godaddy/badge.svg?branch=main&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use Net::DynDNS::GoDaddy;
    use Addr::MyIP;

    my $hostname = 'home';
    my $domain   = 'example.com';

    my $current_host_ip = host_ip_get($host, $domain);
    my $my_ip = myip();

    if ($current_host_ip ne $my_ip) {
        host_ip_set($host, $domain, $my_ip);
    }

=head1 DESCRIPTION

For end-users, see the documentation for the
L<update-ip binary|https://metacpan.org/pod/distribution/Net::DynDNS::GoDaddy/bin/update-ip.pod>.

Provides an interface to allow dynamically updating your GoDaddy domain's DNS
name to IP mapping.

You must have a C<~/godaddy_api.json> file containing your GoDaddy API key and
secret, in the following format:

    {
        "api_key": "KEY DATA",
        "api_secret": "API SECRET"
    }

The L<update-ip binary|https://metacpan.org/pod/distribution/Net::DynDNS::GoDaddy/bin/update-ip.pod>
binary will do this for you automatically on first run.

=head1 FUNCTIONS

=head2 host_ip_get($host, $domain)

Returns the currently set IP address of the DNS A record for the
host/domain pair.

I<Parameters>:

    $host

I<Mandatory, String>: The name of the host, eg. C<www>.

    $domain

I<Mandatory, String>: The name of the domain, eg. C<example.com>.

I<Returns>: String, the IP address that's currently set for the record.

=head2 host_ip_set($host, $domain, $ip)

Updates the DNS A record for the host/domain pair.

I<Parameters>:

    $host

I<Mandatory, String>: The name of the host, eg. C<www>.

    $domain

I<Mandatory, String>: The name of the domain, eg. C<example.com>.

    $ip

I<Mandatory, String>: The IP address to set the record to eg. C<192.168.10.10>.

I<Returns>: Bool, C<1> on success, C<0> on failure.

=head2 api_key_get

Fetch your GoDaddy API key and secret from the previously created
C<godaddy_api.json> in your home directory.

B<Not exported by default>, use the C<qw(:all)> tag to access it.

Croaks if the file can't be read.

I<Returns:> A list of two scalars, the API key and the API secret.

=head2 api_key_set($key, $secret)

Creates the C<godaddy_api.json> file in your home directory that contains your
GoDaddy API key and secret.

B<Not exported by default>, use the C<qw(:all)> tag to access it.

I<Parameters>:

    $key

I<Mandatory, String>: Your GoDaddy API key

    $secret

I<Mandatory, String>: Your GoDaddy API secret

I<Returns>: C<1> upon success.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2022 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
