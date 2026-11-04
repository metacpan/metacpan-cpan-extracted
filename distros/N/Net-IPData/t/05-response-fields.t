#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 60;
use File::Basename qw(dirname);
use File::Spec;

use_ok('Net::IPData');

# --- A mock user agent injected through ua => serves queued raw JSON bodies
#     exactly as the API would send them and records every request made. ---
{
    package Fixture::UA;

    sub new { return bless { queue => [], calls => [] }, shift }

    sub queue {
        my ($self, $status, $body) = @_;
        push @{ $self->{queue} }, [ $status, $body ];
        return $self;
    }

    sub get  { my ($self, $url) = @_;        return $self->_respond('GET',  $url) }
    sub post { my ($self, $url, $opts) = @_; return $self->_respond('POST', $url, $opts) }

    sub _respond {
        my ($self, $method, $url, $opts) = @_;
        push @{ $self->{calls} }, [ $method, $url, $opts ];
        my $next = shift @{ $self->{queue} } or die "No fixture queued for $method $url";
        my ($status, $body) = @$next;
        return {
            status  => $status,
            success => ($status >= 200 && $status < 300) ? 1 : 0,
            headers => { 'content-type' => 'application/json' },
            content => $body,
        };
    }

    sub last_url { return $_[0]{calls}[-1][1] }
}

my $fixture_dir = File::Spec->catdir(dirname(__FILE__), 'fixtures');

sub fixture {
    my ($name) = @_;
    my $path = File::Spec->catfile($fixture_dir, $name);
    open my $fh, '<:raw', $path or die "Cannot read $path: $!";
    local $/;
    return scalar <$fh>;
}

my $ua  = Fixture::UA->new;
my $ipd = Net::IPData->new(api_key => 'test_key', ua => $ua);

# --- Sample A: satellite ISP; is_anycast absent ---
{
    $ua->queue(200, fixture('satellite.json'));
    my $r = $ipd->lookup('98.97.34.0');

    is($r->{ip}, '98.97.34.0', 'satellite: ip');
    ok($r->{is_satellite}, 'satellite: is_satellite is true');
    ok(!$r->{is_eu}, 'satellite: is_eu is false');
    ok(!exists $r->{is_anycast}, 'satellite: is_anycast key is absent (API omits false flags)');
    ok(!$r->{is_anycast}, 'satellite: absent is_anycast reads as false');
    is($r->{asn}{name}, 'Space Exploration Technologies Corporation', 'satellite: nested asn passes through');
    is(ref $r->{threat}{blocklists}, 'ARRAY', 'satellite: blocklists is an arrayref');
    is(scalar @{ $r->{threat}{blocklists} }, 0, 'satellite: blocklists is empty');
    is($r->{threat}{scores}{trust_score}, 97, 'satellite: keys the module does not know (scores) pass through');
    is($r->{count}, '0', 'satellite: count passes through');
}

# --- Sample B: anycast address with dated blocklist entries ---
{
    $ua->queue(200, fixture('anycast.json'));
    my $r = $ipd->lookup('8.8.8.8');

    ok($r->{is_anycast}, 'anycast: is_anycast is true');
    ok(!exists $r->{is_satellite}, 'anycast: is_satellite key is absent');
    ok(!$r->{is_satellite}, 'anycast: absent is_satellite reads as false');
    ok(exists $r->{city} && !defined $r->{city}, 'anycast: null city decodes to undef');
    is($r->{country_code}, 'US', 'anycast: country_code');

    my $bl = $r->{threat}{blocklists};
    is(scalar @$bl, 2, 'anycast: two blocklist entries');
    is($bl->[0]{name},       'ipdata',     'anycast: blocklist name');
    is($bl->[0]{type},       'cloud',      'anycast: blocklist type');
    is($bl->[0]{first_seen}, '2026-11-02', 'anycast: first_seen');
    is($bl->[0]{last_seen},  '2026-11-02', 'anycast: last_seen');
    is($bl->[0]{days_seen},  1,            'anycast: days_seen');
    is(ref $bl->[0]{first_seen}, '', 'anycast: first_seen stays a plain YYYY-MM-DD string, not a date object');
    like($bl->[0]{last_seen}, qr/^\d{4}-\d{2}-\d{2}$/, 'anycast: last_seen keeps the YYYY-MM-DD format');
    is($bl->[1]{type}, 'open_resolvers', 'anycast: second blocklist entry');
    is($bl->[1]{days_seen}, 1, 'anycast: second entry days_seen');
    ok($r->{threat}{is_datacenter}, 'anycast: threat flags pass through');
}

# --- Sample C: VPN exit; neither flag present, one blocklist entry without dates ---
{
    $ua->queue(200, fixture('vpn_blocklists.json'));
    my $r = $ipd->lookup('187.13.250.1');

    ok(!exists $r->{is_satellite} && !exists $r->{is_anycast}, 'vpn: neither top-level flag is present');
    ok(!$r->{is_satellite} && !$r->{is_anycast}, 'vpn: both flags read as false');
    ok($r->{threat}{is_vpn}, 'vpn: is_vpn is true');

    my $bl = $r->{threat}{blocklists};
    is(scalar @$bl, 6, 'vpn: six blocklist entries');
    is($bl->[0]{name}, 'Gluetun', 'vpn: first entry name');
    is($bl->[0]{first_seen}, '2026-10-31', 'vpn: first entry first_seen');
    is($bl->[0]{last_seen},  '2026-11-02', 'vpn: first entry last_seen');
    is($bl->[0]{days_seen},  2,            'vpn: first entry days_seen');

    my $undated = $bl->[2];
    is($undated->{name}, 'ipdata', 'vpn: third entry is the ipdata feed');
    is($undated->{type}, 'vpn',    'vpn: third entry is the vpn feed');
    ok(!exists $undated->{first_seen}, 'vpn: undated entry has no first_seen');
    ok(!exists $undated->{last_seen},  'vpn: undated entry has no last_seen');
    ok(!exists $undated->{days_seen},  'vpn: undated entry has no days_seen');
    is(scalar(grep { exists $_->{days_seen} } @$bl), 5, 'vpn: the other five entries carry the dates');
}

# --- Bulk responses carry the same shape per item ---
{
    my $bulk_body = '[' . join(',', fixture('satellite.json'), fixture('anycast.json'), fixture('vpn_blocklists.json')) . ']';
    $ua->queue(200, $bulk_body);
    my $results = $ipd->bulk(['98.97.34.0', '8.8.8.8', '187.13.250.1']);

    is(scalar @$results, 3, 'bulk: three results');
    ok($results->[0]{is_satellite} && !$results->[0]{is_anycast}, 'bulk: item 0 is satellite only');
    ok($results->[1]{is_anycast} && !$results->[1]{is_satellite}, 'bulk: item 1 is anycast only');
    ok(!$results->[2]{is_satellite} && !$results->[2]{is_anycast}, 'bulk: item 2 has neither flag');
    is($results->[1]{threat}{blocklists}[0]{first_seen}, '2026-11-02', 'bulk: dated blocklist entry');
    ok(!exists $results->[2]{threat}{blocklists}[2]{days_seen}, 'bulk: undated blocklist entry');
}

# --- Field-name validation accepts the two new names ---
{
    $ua->queue(200, '{"ip":"98.97.34.0","is_satellite":true}');
    my $r = $ipd->lookup('98.97.34.0', fields => [qw(ip is_satellite is_anycast)]);
    like($ua->last_url, qr/[?&]fields=ip,is_satellite,is_anycast(?:&|$)/, 'lookup fields => accepts is_satellite and is_anycast');
    ok($r->{is_satellite}, 'filtered lookup returns is_satellite');

    $ua->queue(200, '[{"ip":"8.8.8.8","is_anycast":true}]');
    $ipd->bulk(['8.8.8.8'], fields => 'is_anycast,is_satellite');
    like($ua->last_url, qr/[?&]fields=is_anycast,is_satellite(?:&|$)/, 'bulk fields => accepts both new names as a string');

    $ua->queue(200, 'true');
    ok($ipd->lookup_field('98.97.34.0', 'is_satellite'), 'lookup_field accepts is_satellite');
    like($ua->last_url, qr{/98\.97\.34\.0/is_satellite\?}, 'lookup_field requests /{ip}/is_satellite');

    $ua->queue(200, 'true');
    ok($ipd->lookup_field('8.8.8.8', 'is_anycast'), 'lookup_field accepts is_anycast');
    like($ua->last_url, qr{/8\.8\.8\.8/is_anycast\?}, 'lookup_field requests /{ip}/is_anycast');

    $ua->queue(200, 'true');
    ok($ipd->is_satellite('98.97.34.0'), 'is_satellite convenience method');
    like($ua->last_url, qr{/98\.97\.34\.0/is_satellite\?}, 'is_satellite requests the is_satellite path field');

    $ua->queue(200, 'true');
    ok($ipd->is_anycast('8.8.8.8'), 'is_anycast convenience method');
    like($ua->last_url, qr{/8\.8\.8\.8/is_anycast\?}, 'is_anycast requests the is_anycast path field');

    eval { $ipd->lookup('8.8.8.8', fields => ['is_satelite']) };
    like($@, qr/Invalid field: is_satelite/, 'a misspelt field name is still rejected');

    is(scalar @{ $ua->{queue} }, 0, 'every queued fixture was consumed');
}
