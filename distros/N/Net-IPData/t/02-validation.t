#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 15;

use_ok('Net::IPData');

# --- A stand-in user agent injected through ua =>: validation happens before
#     any request is made, so a request reaching it means the arguments passed
#     validation. It records each URL and answers like the API would, so the
#     test needs no network access. ---
{
    package Validation::UA;

    sub new { return bless { urls => [] }, shift }

    sub get {
        my ($self, $url) = @_;
        push @{ $self->{urls} }, $url;
        return {
            status  => 200,
            success => 1,
            headers => { 'content-type' => 'application/json' },
            content => '{"ip":"8.8.8.8"}',
        };
    }

    sub post {
        my ($self, $url, $opts) = @_;
        push @{ $self->{urls} }, $url;
        return {
            status  => 200,
            success => 1,
            headers => { 'content-type' => 'application/json' },
            content => '[{"ip":"8.8.8.8"}]',
        };
    }

    sub last_url { return $_[0]{urls}[-1] }
    sub requests { return scalar @{ $_[0]{urls} } }
}

my $ua  = Validation::UA->new;
my $ipd = Net::IPData->new(api_key => 'test', ua => $ua);

# --- bulk validation ---
eval { $ipd->bulk('not_an_array') };
like($@, qr/array reference/i, 'bulk rejects non-arrayref');

eval { $ipd->bulk([]) };
like($@, qr/at least one/i, 'bulk rejects empty array');

eval { $ipd->bulk([('1.2.3.4') x 101]) };
like($@, qr/maximum/i, 'bulk rejects more than 100 IPs');

# --- field validation in lookup ---
eval { $ipd->lookup('8.8.8.8', fields => ['ip', 'bogus_field']) };
like($@, qr/Invalid field.*bogus_field/i, 'lookup rejects invalid fields');

# --- field validation in bulk ---
eval { $ipd->bulk(['8.8.8.8'], fields => ['not_real']) };
like($@, qr/Invalid field/i, 'bulk rejects invalid fields');

is($ua->requests, 0, 'nothing that failed validation was sent');

# --- valid fields accepted ---
eval { $ipd->lookup('8.8.8.8', fields => [qw(ip country_name asn)]) };
is($@, '', 'valid fields pass validation');
like($ua->last_url, qr/[?&]fields=ip,country_name,asn(?:&|$)/, 'valid fields are sent as the fields parameter');

# --- fields as comma-separated string ---
eval { $ipd->lookup('8.8.8.8', fields => 'ip,country_name') };
is($@, '', 'comma-separated fields pass validation');
like($ua->last_url, qr/[?&]fields=ip,country_name(?:&|$)/, 'comma-separated fields are sent as the fields parameter');

# --- lookup_field rejects fields not available via path ---
eval { $ipd->lookup_field('8.8.8.8', 'company') };
like($@, qr/Invalid field/, 'lookup_field rejects non-path field: company');

eval { $ipd->lookup_field('8.8.8.8', 'count') };
like($@, qr/Invalid field/, 'lookup_field rejects non-path field: count');

# --- lookup_field accepts valid path fields ---
eval { $ipd->lookup_field('8.8.8.8', 'country_name') };
is($@, '', 'valid path field passes validation');
like($ua->last_url, qr{/8\.8\.8\.8/country_name\?}, 'valid path field is requested as /{ip}/{field}');
