use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Mojo::File qw(path);
use Mojo::JSON qw(decode_json);
use Mojo::Server::Daemon;
use IO::Socket::INET;
use POSIX qw(_exit);
use Time::HiRes qw(sleep time);
use lib 'lib';
use Mogura::Scanner;
use Mogura::Server;
use Mogura::Protocol qw(random_id);

{

    package FixtureDisk;
    use Mojo::Base -base;
    sub mount_table { [] }

    sub inventory {
        return {
            disks => [
                {
                    name => '/dev/sdb',
                    targets => [
                        {
                            selectable => 1,
                            token => 'c' x 64,
                            identity =>
                                {disk => {name => '/dev/sdb'}, partition => {name => '/dev/sdb1'}}
                        }
                    ]
                }
            ]
        };
    }

    package CapacityCommand;
    use Mojo::Base -base;

    sub run {
        return "Avail\n9999999999\n" if $_[1][0] eq '/usr/bin/df';
        return '' if $_[1][0] eq '/usr/bin/prlimit';
        die 'Unexpected external command';
    }

    package FixtureScan;
    use Mojo::Base 'Mogura::Scanner::Scan';
    has command => sub { CapacityCommand->new };

    sub run {
        my ($self, $request) = @_;
        my $scan = $self->_start_scan($request);
        my $root = Mojo::File::path($self->config->state);
        open my $count, '>>', $root->child('starts') or die $!;
        print {$count} "$request->{id}\n";
        close $count;
        Time::HiRes::sleep(0.02) while -f $root->child('pause');
        for my $pair (
            ['syft', '{"source":{},"artifacts":[],"descriptor":{"name":"syft"}}'],
            ['cdx', '{"bomFormat":"CycloneDX","specVersion":"1.6"}'],
            ['grype', '{"matches":[],"descriptor":{"name":"grype"}}']
            )
        {
            $self->store->directory($request->{id})
                ->child(Mogura::Protocol::artifact_name($pair->[0]))
                ->spurt($pair->[1]);
        }
        $scan->{phase} = 'finished';
        $scan->{status} = 'completed';
        $scan->{cleanup_status} = 'unmounted';
        $self->store->save($scan);
    }

    package FaultyClient;
    use Mojo::Base 'Mogura::Scanner::Client';
    has 'lose_claim';
    has 'fail_upload';

    sub request {
        my ($self, $method, $route, @args) = @_;
        die 'offline' if $self->fail_upload && $method eq 'PUT';
        my $reply = $self->SUPER::request($method, $route, @args);
        if ($self->lose_claim && $route =~ m{/claim$}) { $self->lose_claim(0); die 'response lost' }
        return $reply;
    }
}

my $root = path(tempdir(CLEANUP => 1));
my $store = Mogura::Server::Store->new(state => "" . $root->child('server'))->initialize;
my $app = Mogura::Server->new(store => $store);
$app->log->level('fatal');
$app->routes->any('/api/delayed')->to(
    cb => sub {
        my ($c) = @_;
        my $sha = Digest::SHA::sha256_hex($c->req->body);
        $c->render_later;
        my $timer = Mojo::IOLoop->timer(1.5 => sub { $c->render(json => {sha256 => $sha}) });
        $c->on(finish => sub { Mojo::IOLoop->remove($timer) });
    }
);
my $daemon = Mojo::Server::Daemon->new(
    app => $app,
    listen => ['http://127.0.0.1:0', 'https://127.0.0.1:0'],
    silent => 1
)->start;
my $url = 'http://127.0.0.1:' . $daemon->ports->[0];
my $https = 'https://localhost:' . $daemon->ports->[1];
my $server = fork // die $!;
unless ($server) { $daemon->run; _exit(0) }
$daemon->stop;
my $owner = $$;

END {
    if ($server && $$ == $owner) { kill 'TERM', $server; waitpid($server, 0) }
}
my %nodes;
for my $name (qw(east west)) {
    my $state = $root->child($name)->make_path;
    $state->child('spool')->make_path;
    my $token = random_id() . random_id();
    $store->register($name, $token);
    my $file = $state->child('token')->spurt($token);
    chmod 0600, $file;
    my $cfg = Mogura::Scanner::Config->from_options(
        {
            server => $url,
            'token-file' => "$file",
            state => "$state",
            runtime => "$state/run",
            jobs => 1
        }
    );
    my $client = FaultyClient->new(config => $cfg)->initialize;

    if ($name eq 'west') {
        $cfg->server($https);
        eval { $client->request('GET', '/identity') };
        like($@, qr/certificate|handshake|verify/i, 'Scanner rejects an untrusted TLS server');
        $client->ua->ca(
            path($INC{'Mojo/IOLoop/TLS.pm'})->sibling('resources', 'server.crt')->to_string);
    }
    my $spool = Mogura::Scanner::Spool->new(config => $cfg);
    my $node = Mogura::Scanner->new(
        config => $cfg,
        client => $client,
        disk => FixtureDisk->new,
        spool => $spool,
        scan => FixtureScan->new(config => $cfg, store => $spool)
    );
    $node->tick;
    $nodes{$name} = $node;
}
my ($east, $west) = @nodes{qw(east west)};
subtest 'A deadline applies to a whole file upload' => sub {
    my $file = $root->child('upload')->spurt('bounded transfer');
    my $client = $east->client;
    $client->config->upload_timeout(1);
    eval { $client->request('PUT', '/delayed', undef, $file) };
    like($@, qr/request timeout/i, 'Abort before the slow receipt arrives');
    is(
        $client->request('GET', '/delayed')->{sha256},
        Digest::SHA::sha256_hex(''),
        'A control request can outlast the short upload deadline'
    );
    $client->config->upload_timeout(5);
    is(
        $client->request('PUT', '/delayed', undef, $file)->{sha256},
        Digest::SHA::sha256_hex('bounded transfer'),
        'A longer deadline allows the same file to arrive'
    );
};
my ($a, $b) = map { random_id() } 1 .. 2;
is($store->submit($a, 'east', 'c' x 64, [], ''), 202, 'East job');
is($store->submit($b, 'west', 'c' x 64, [], ''), 202, 'West job for same device name');
$east->client->lose_claim(1);
eval { $east->tick };
like($@, qr/response lost/, 'Dropped response after real server claim');
my $intent = decode_json($east->spool->directory($a)->child('intent.json')->slurp);
ok($store->owns('east', $a, $intent->{run}) && !$intent->{started},
    'Persisted execution ID precedes processing');

# Close a real connection after one body fragment; the next PUT starts at byte zero.
{
    my $socket = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => Mojo::URL->new($url)->port,
        Proto => 'tcp'
    ) or die $!;
    my $bearer = $root->child('east/token')->slurp;
    print {$socket}
        "PUT /api/jobs/$a/$intent->{run}/files/log HTTP/1.1\r\nHost: 127.0.0.1\r\nAuthorization: Bearer $bearer\r\nContent-Length: 1000000\r\nContent-Type: application/octet-stream\r\n\r\nfragment";
    ok(
        until_true(
            sub {
                grep { -s $_ == 8 } path($store->state, 'incoming')->list->each;
            }
        ),
        'Upload streams into a temporary file'
    );
    close $socket;
    ok(until_true(sub { !path($store->state, 'incoming')->list->size }),
        'Disconnected partial upload is discarded');
    ok(!$store->artifact($a, 'log'), 'Disconnected upload has no receipt');
}
$east->client->fail_upload(1);
$east->{delivery_delay} = 0; # Previous successful delivery reset the backoff.
$root->child('west/pause')->spurt('');
$east->tick;
$west->tick;

sub until_true {
    my ($cb) = @_;
    my $end = time + 12;
    while (time < $end) { return 1 if $cb->(); sleep 0.05 }
    return 0;
}
ok(until_true(sub { -f $root->child('west/starts') && -f $east->spool->artifact($a, 'syft') }),
    'Both scan children started');
kill 'KILL', $west->active->{$b}{pid};
waitpid($west->active->{$b}{pid}, 0);

# Recreate the process-local supervisor from the persisted execution record.
$west = Mogura::Scanner->new(
    config => $west->config,
    client => $west->client,
    disk => $west->disk,
    spool => $west->spool,
    scan => $west->scan
);
$east->tick;
ok(
    until_true(
        sub {
            $east->tick;
            ($east->{delivery_delay} // 0) > 0;
        }
    ),
    'Transfer failure retains local files'
);
ok($east->spool->artifact($a, 'syft'), 'Unacknowledged SBOM retained');
$east->client->fail_upload(0);
ok(
    until_true(
        sub {
            $_->tick for $east, $west;
            return $store->get($a)->{status} eq 'completed'
                && $store->get($b)->{status} eq 'interrupted';
        }
    ),
    'Recovery finishes delivery without replaying the interrupted scan'
);
for my $pair (['east', $a], ['west', $b]) {
    is($root->child($pair->[0], 'starts')->slurp,
        "$pair->[1]\n", 'Exactly one start on assigned scanner');
}
subtest 'Browser cancellation stops only its assigned run' => sub {
    my $web = Mojo::UserAgent->new;
    my $id = random_id();
    is($store->submit($id, 'west', 'c' x 64, [], ''), 202, 'Submit scan');
    my $endpoint = "$url/scans/$id/cancel";
    my $form = $web->get("$url/scans/$id")->result->dom->at('form[action$="/cancel"]');
    my $csrf = $form->at('input[name="csrf_token"]')->attr('value');
    is($web->post($endpoint)->result->code, 403, 'Missing CSRF token cannot stop work');
    is($web->post($endpoint => form => {csrf_token => $csrf})->result->code,
        303, 'Cancel from detail page');
    ok(!$store->offer('west'), 'Cancelled queued scan cannot be claimed');
    is($store->get($id)->{status}, 'cancelled', 'Unstarted scan cancelled immediately');

    $id = random_id();
    $store->submit($id, 'west', 'c' x 64, [], '');
    $west->config->inventory_interval(0);
    $west->{inventory_due} = 0;
    ok(until_true(sub { $west->tick; return $west->spool->get($id) }), 'Assigned scan started');
    $endpoint = "$url/scans/$id/cancel";
    $web->post($endpoint => form => {csrf_token => $csrf});
    is($store->get($id)->{status}, 'cancelling', 'Request is pending until scanner confirms');
    is_deeply($east->client->request('POST', '/inventory', $east->disk->inventory)->{cancel},
        [], 'Other scanner receives no stop request');
    ok(until_true(sub { $west->tick; return $store->get($id)->{status} eq 'cancelled' }),
        'Scanner stops the child and delivers the final outcome');
    is($store->get($a)->{status}, 'completed', 'Other scanner result preserved');

    $id = random_id();
    $store->submit($id, 'east', 'c' x 64, [], '');
    $east->client->lose_claim(1);
    eval { $east->tick };
    like($@, qr/response lost/, 'Claim accepted before the connection failed');
    $web->post("$url/scans/$id/cancel" => form => {csrf_token => $csrf});
    $east->tick;
    is($store->get($id)->{status}, 'cancelled', 'Retry confirms cancellation before starting');
    unlike($root->child('east/starts')->slurp, qr/\Q$id\E/, 'Cancelled claim never ran');
};
my $crashed = {id => random_id(), token => 'c' x 64};
my $mount = $west->config->mounts . "/$crashed->{id}";
my $recovered = $west->_recover($crashed, [$mount]);
is($recovered->{cleanup_status}, 'needs_cleanup', 'Residual mount blocks detach after restart');
{
    my $child_lock = $west->scan->_acquire_lock("scan-$crashed->{id}");
    is($west->_recover($crashed, [])->{cleanup_status},
        'needs_cleanup', 'A surviving lock blocks detach even with an empty mount table');
}
is($west->_recover($crashed, [])->{cleanup_status},
    'unmounted', 'Cleanup confirmed after mount and lock both disappear');
$west->config->spool_limit(1048576);
my $pending = $west->spool->directory($crashed->{id})->child('pending')->open('>');
truncate $pending, $west->config->spool_limit or die $!;
close $pending or die $!;
is($west->_capacity, 0, 'Unsent data at the spool limit prevents new scans');

for my $node ($east, $west) { waitpid($_->{pid}, 0) for values %{$node->active} }
done_testing;
