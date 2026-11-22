use strict;
use warnings;
use utf8;
use Test::More;
use Test::Mojo;
use File::Temp qw(tempdir);
use Mojo::File qw(path);
use Mojo::JSON qw(encode_json);
use lib 'lib';
use Mogura::Server;
use Mogura::Server::Store;
use Mogura::Scanner::Disk;
require './t/lib/server-fixture.pl';

# Seed the server database with small, public scan artifacts.
my $root = tempdir(CLEANUP => 1);
my $store = Mogura::Server::Store->new(state => $root)->initialize;
$store->register('fixture', 'a' x 64);
my $token = 'f' x 64;
save_inventory(
    $store,
    {
        updated_at => time,
        errors => [],
        disks => [
            {
                name => '/dev/example',
                size => 1000000000,
                serial => 'fixture',
                targets => [
                    {
                        name => '/dev/example1',
                        size => 900000000,
                        fstype => 'ext4',
                        selectable => 1,
                        reasons => [],
                        token => $token
                    }
                ]
            }
        ]
    }
);
my $id = 'a' x 32;
my $payload = '<script>alert("external")</script>';
my $scan = {
    id => $id,
    tags => [$payload],
    note => $payload,
    created_at => '2026-01-01T00:00:00Z',
    status => 'completed',
    phase => 'finished',
    cleanup_status => 'unmounted',
    warnings => [$payload]
};
seed_scan($store, $scan);
my $dir = $store->directory($id);
seed_artifact(
    $store, $id, 'syft',
    encode_json(
        {
            artifacts => [
                {
                    name => $payload,
                    version => '1.0',
                    type => 'deb',
                    foundBy => 'fixture',
                    locations => [{path => '/var/lib/dpkg/status'}]
                }
            ]
        }
    )
);
seed_artifact(
    $store, $id, 'grype',
    encode_json(
        {
            matches => [
                {
                    artifact => {name => $payload},
                    vulnerability => {
                        id => 'CVE-EXAMPLE-001',
                        severity => 'High',
                        fix => {versions => ['1.1'], state => 'fixed'}
                    }
                }
            ]
        }
    )
);
my $app = Mogura::Server->new(store => $store);
$app->log->level('error');
my $t = Test::Mojo->new($app);

$t->get_ok('/history?lang=ja')->status_is(200)->content_unlike(qr/<script>alert/);
$t->get_ok("/scans/$id")->status_is(200)->content_unlike(qr/<script>alert/);
$t->get_ok("/scans/$id/download/syft")
    ->status_is(200)
    ->content_is($dir->child('sbom.syft.json')->slurp);
$t->get_ok("/scans/$id/download/grype")
    ->status_is(200)
    ->content_is($dir->child('vulnerabilities.grype.json')->slurp);
$t->get_ok("/scans/$id/download/secret")->status_is(404);
$t->get_ok('/scans/invalid/download/metadata')->status_is(404);
$t->get_ok("/scans/$id/download/..%2F..%2Fweb.secret")->status_is(404);

my $results = Mogura::Server::Results->new(state => $root);
my $result_file = $results->location($id, 'grype');
$t->get_ok("/scans/$id/results/grype")->status_is(409);
ok(!-e $result_file, 'Reading an old result never creates its index');
$t->post_ok("/scans/$id/results/grype/rebuild")->status_is(403);
$t->get_ok("/scans/$id")->status_is(200);
my $result_csrf =
    $t->tx->res->dom->at('[data-result-build] input[name="csrf_token"]')->attr('value');
$t->post_ok("/scans/$id/results/grype/rebuild" => form => {csrf_token => $result_csrf})
    ->status_is(202);
my $status_url = $t->tx->res->json->{status_url};

sub finish_result_jobs {
    my $deadline = time + 10;
    while (keys %{$app->{result_jobs} // {}} && time < $deadline) {
        Mojo::IOLoop->one_tick;
    }
    ok(!keys %{$app->{result_jobs} // {}}, 'Result build finishes');
}
finish_result_jobs();
$t->get_ok($status_url)->status_is(200)->json_is('/state', 'ready');
my $result_url = $t->tx->res->json->{url};
$t->get_ok($result_url)
    ->status_is(200)
    ->json_is('/total', 1)
    ->json_is('/rows/0/0', 'CVE-EXAMPLE-001')
    ->json_is('/rows/0/1', $payload)
    ->json_is('/rows/0/2', '');
$t->get_ok("$result_url&query=missing")->status_is(200)->json_is('/count', 0);
$t->get_ok("$result_url&column=3&descending=1")->status_is(200);
$t->get_ok("$result_url&column=0%3BDELETE")->status_is(400);
$t->get_ok("$result_url&start=-1")->status_is(400);
$t->get_ok("/scans/$id/results/grype?version=old")->status_is(409);
$t->get_ok("/scans/$id/results/log")->status_is(404);
$t->get_ok('/scans/invalid/results/grype')->status_is(404);

# Rebuilding unchanged JSON must still invalidate cached pages.
my $original_json = $dir->child('vulnerabilities.grype.json')->slurp;
$t->post_ok("/scans/$id/results/grype/rebuild" => form => {csrf_token => $result_csrf})
    ->status_is(202);
$status_url = $t->tx->res->json->{status_url};
finish_result_jobs();
$t->get_ok($status_url)->status_is(200)->json_is('/state', 'ready');
my $rebuilt_url = $t->tx->res->json->{url};
isnt($rebuilt_url, $result_url, 'Rebuild invalidates cached pages even with unchanged input');
$t->get_ok($result_url)->status_is(409);
$t->get_ok($rebuilt_url)->status_is(200)->json_is('/total', 1);
is($dir->child('vulnerabilities.grype.json')->slurp,
    $original_json, 'Rebuild leaves raw JSON untouched');
{
    my $lock = $results->build_lock($result_file);
    $t->post_ok("/scans/$id/results/grype/rebuild" => form => {csrf_token => $result_csrf})
        ->status_is(409);
}
{
    no warnings 'redefine';
    local *Mogura::Server::Results::verify = sub { die 'Injected verification failure' };
    $t->post_ok("/scans/$id/results/grype/rebuild" => form => {csrf_token => $result_csrf})
        ->status_is(202);
    $status_url = $t->tx->res->json->{status_url};
    finish_result_jobs();
}
$t->get_ok($status_url)->status_is(200)->json_is('/state', 'failed');
$t->get_ok($rebuilt_url)->status_is(200)->json_is('/total', 1);
ok(!-e "$result_file.part", 'Failed rebuild cleans temporary index');
{
    no warnings 'redefine';
    my $save_status = Mogura::Server::Results->can('save_build_status');
    local *Mogura::Server::Results::save_build_status = sub {
        die 'Injected status write failure' unless $_[2]{state} eq 'running';
        return $save_status->(@_);
    };
    $t->post_ok("/scans/$id/results/grype/rebuild" => form => {csrf_token => $result_csrf})
        ->status_is(202);
    $status_url = $t->tx->res->json->{status_url};
    finish_result_jobs();
}
$t->get_ok($status_url)->status_is(200)->json_is('/state', 'failed');
{
    my $lock = $results->build_lock($result_file);
    ok($lock, 'Status write failure cannot leave rebuilds locked');
}
$scan->{status} = 'running';
$store->db->do('UPDATE jobs SET record=? WHERE id=?', undef, Mojo::JSON::to_json($scan), $id);
$t->post_ok("/scans/$id/results/grype/rebuild" => form => {csrf_token => $result_csrf})
    ->status_is(409);
$scan->{status} = 'completed';
$store->db->do('UPDATE jobs SET record=? WHERE id=?', undef, Mojo::JSON::to_json($scan), $id);

sub job_count {
    return $store->db->selectrow_array('SELECT COUNT(*) FROM jobs WHERE finished=0');
}

for my $host ('localhost:8080', '127.0.0.1:8080', '192.0.2.10:8080', 'scanner.example:8080') {
    $t->get_ok('/scans/' . $id => {Host => $host})->status_is(200);
    $t->post_ok(
        '/scans' => {Host => $host} => form => {
            scan_id => 'b' x 32,
            target => "fixture:$token",
        }
    )->status_is(403);
}
$t->post_ok('/scans' => form => {scan_id => 'b' x 32, target => "fixture:$token"})->status_is(403);
is(job_count(), 0, 'Rejected requests cannot enqueue privileged scan work');

$t->get_ok('/')->status_is(200);
my $csrf = $t->tx->res->dom->at('input[name="csrf_token"]')->attr('value');
my $new_id = $t->tx->res->dom->at('input[name="scan_id"]')->attr('value');
my %form = (
    csrf_token => $csrf,
    scan_id => $new_id,
    target => "fixture:$token",
    tags => ['clone-test', '日本語', 'team,blue'],
    new_tag => 'pending-tag',
    note => '',
);
$t->post_ok('/scans' => form => \%form)->status_is(303);
is_deeply(
    $store->get($new_id)->{tags},
    ['clone-test', '日本語', 'team,blue', 'pending-tag'],
    'Submission preserves separate Unicode tags, literal commas, and the unfinished input'
);
$t->post_ok('/scans' => form => \%form)->status_is(302);
is(job_count(), 1, 'A clone scan needs no confirmation flag and cannot be scheduled twice');

# Rejected edits must leave all existing annotations and original artifacts intact.
$t->post_ok("/scans/$id/tags" => form => {operation => 'add', tag => 'denied'})->status_is(403);
$t->post_ok("/scans/$id/note" => form => {note => 'denied'})->status_is(403);
is_deeply($store->get($id)->{tags}, [$payload], 'Missing CSRF cannot change tags');
is($store->get($id)->{note}, $payload, 'Missing CSRF cannot change a note');

$t->post_ok(
    "/scans/$id/tags" => {Accept => 'application/json'} => form => {
        csrf_token => $csrf,
        operation => 'add',
        tag => 'production'
    }
)->status_is(200)->json_is('/tags', [$payload, 'production']);
$t->post_ok(
    "/scans/$id/tags" => form => {
        csrf_token => $csrf,
        operation => 'add',
        tag => 'x' x 121
    }
)->status_is(400);
is_deeply(
    $store->get($id)->{tags},
    [$payload, 'production'],
    'An invalid edit cannot overwrite existing tags'
);
$t->post_ok("/scans/$id/tags" => form => {csrf_token => $csrf, tags => ''})->status_is(400);
is_deeply(
    $store->get($id)->{tags},
    [$payload, 'production'],
    'An obsolete overwrite request cannot clear tags'
);
$t->get_ok('/history?tag=production')
    ->status_is(200)
    ->content_like(qr/\Q$id\E/)
    ->content_unlike(qr/\Q$new_id\E/);
$t->get_ok('/history?tag=prod')->status_is(200)->content_unlike(qr/\Q$id\E/);
$t->post_ok(
    "/scans/$id/tags" => form => {
        csrf_token => $csrf,
        operation => 'remove',
        tag => 'production'
    }
)->status_is(303);
is_deeply($store->get($id)->{tags}, [$payload], 'Removing one tag preserves every other tag');

my $note = "日本語のメモ\n$payload";
$t->post_ok(
    "/scans/$id/note" => {Accept => 'application/json'} => form => {
        csrf_token => $csrf,
        note => $note
    }
)->status_is(200)->json_is('/note', $note);
$t->get_ok("/scans/$id")->status_is(200)->content_unlike(qr/<script>alert/);
$t->get_ok("/scans/$id/download/metadata")
    ->status_is(200)
    ->json_is('/note', $note)
    ->json_is('/tags', [$payload]);
$t->post_ok("/scans/$id/note" => form => {csrf_token => $csrf, note => 'x' x 2001})->status_is(400);
is($store->get($id)->{note}, $note, 'An invalid note edit preserves the previously saved value');
$t->post_ok('/scans/' . ('f' x 32) . '/note' => form => {csrf_token => $csrf, note => ''})
    ->status_is(404);
$t->post_ok("/scans/$id/note" => form => {csrf_token => $csrf, note => ''})->status_is(303);
is($store->get($id)->{note}, '', 'Clearing a note persists rather than restoring its old value');
is(job_count(), 1, 'Annotation edits never enqueue or replay disk work');

# Target authorization comes from current inventory, never a claimed kind or
# an old browser form. Verify rejection by the unchanged queue as well as HTTP.
my $inventory =
    Mojo::JSON::from_json($store->db->selectrow_array('SELECT inventory FROM scanners'));
my $host_token = 'e' x 64;
$inventory->{host} = {kind => 'host', selectable => 1, token => $host_token};
save_inventory($store, $inventory);
my %host_form = (
    csrf_token => $csrf,
    scan_id => Mogura::Server::random_id(),
    target => "fixture:$host_token"
);
$t->post_ok('/scans' => form => \%host_form)->status_is(303);
is(job_count(), 2, 'Live-host scanning uses the same submission contract as clone scanning');
$host_form{scan_id} = Mogura::Server::random_id();
$host_form{target} = "fixture:$token";
$host_form{kind} = 'host';
$t->post_ok('/scans' => form => \%host_form)->status_is(409);
$host_form{target} = "fixture:$host_token";
$inventory->{updated_at} = time - 60;
save_inventory($store, $inventory);
$t->post_ok('/scans' => form => \%host_form)->status_is(409);
$inventory->{updated_at} = time;
$inventory->{blocked} = ['/run/mogura/mounts/fixture'];
save_inventory($store, $inventory);
$t->post_ok('/scans' => form => \%host_form)->status_is(409);
is(job_count(), 2, 'Forged targets, stale inventory, and residual mounts cannot create scan jobs');

# Polling renders current disk controls even while earlier scans are active.
$inventory->{updated_at} = time;
$inventory->{blocked} = [];
my $new_token = 'd' x 64;
my $new_disk = {
    name => '/dev/hotplug',
    targets => [
        {
            name => '/dev/hotplug1',
            token => $new_token,
            fstype => 'ext4',
            selectable => 1,
            reasons => [],
            size => 1000,
        }
    ],
};
push @{$inventory->{disks}}, $new_disk;
save_inventory($store, $inventory);
$t->get_ok('/inventory')
    ->status_is(200)
    ->header_is('Cache-Control', 'no-store')
    ->element_exists('input[value="fixture:' . $new_token . '"]')
    ->element_exists_not('textarea[name="note"]');
my $async_id = Mogura::Server::random_id();
my %async_form = (csrf_token => $csrf, scan_id => $async_id, target => "fixture:$new_token");
$t->post_ok('/scans' => {Accept => 'application/json'} => form => \%async_form)
    ->status_is(202)
    ->json_is('/id', $async_id)
    ->json_is('/url', "/scans/$async_id");
like($t->tx->res->json->{next_id}, qr/\A[0-9a-f]{32}\z/,
    'Response supplies the next submission ID');
$t->post_ok('/scans' => {Accept => 'application/json'} => form => \%async_form)
    ->status_is(200)
    ->json_is('/id', $async_id);
is(job_count(), 3, 'Retrying an asynchronous submission is idempotent');
$async_form{scan_id} = Mogura::Server::random_id();
$t->post_ok('/scans' => {Accept => 'application/json'} => form => \%async_form)->status_is(409);
is(job_count(), 3, 'A second submission ID cannot duplicate a pending target');
$inventory->{updated_at} = time - 60;
save_inventory($store, $inventory);
$t->get_ok('/inventory')
    ->status_is(200)
    ->element_exists('input[value="fixture:' . $new_token . '"][disabled]');

# Render real classification output so neither page loads nor polling hide
# unsupported layout details or offer BIOS boot partitions for scanning.
my %layout_nodes = (
    '8:16' => {
        name => '/dev/clone',
        type => 'disk',
        'maj:min' => '8:16',
        pttype => 'gpt',
        serial => 'clone',
        diskseq => 1,
    },
    '8:17' => {
        name => '/dev/clone1',
        type => 'part',
        'maj:min' => '8:17',
        fstype => 'ext4',
        start => 2048,
    },
    '8:18' => {
        name => '/dev/clone2',
        type => 'part',
        'maj:min' => '8:18',
        parttype => '21686148-6449-6e6f-744e-656564454649',
        fstype => '',
        start => 34,
    },
);
my %layout_parents = ('8:17' => {'8:16' => 1}, '8:18' => {'8:16' => 1});
my $classifier = Mogura::Scanner::Disk->new;
my $layout = $classifier->classify(\%layout_nodes, \%layout_parents, {}, [], 'boot-test');
save_inventory($store, $layout);
my ($bios_target, $root_target) = @{$layout->{disks}[0]{targets}};
for my $route ('/', '/inventory') {
    $t->get_ok($route)
        ->status_is(200)
        ->element_exists('input[value="fixture:' . $bios_target->{token} . '"][disabled]')
        ->element_exists('input[value="fixture:' . $root_target->{token} . '"]:not([disabled])')
        ->content_like(qr/BIOS boot partition（起動用・スキャン対象外）/)
        ->content_like(qr/ファイルシステム: なし \/ 未検出/)
        ->content_unlike(qr/未対応/);
}
my %bios_form = (
    csrf_token => $csrf,
    scan_id => Mogura::Server::random_id(),
    target => "fixture:$bios_target->{token}",
);
$t->post_ok('/scans' => form => \%bios_form)->status_is(409);
is(job_count(), 3, 'A forged BIOS boot selection cannot enqueue a scan');

$layout_nodes{'8:18'}{parttype} = '';
$layout_nodes{'8:19'} = {
    name => '/dev/clone3' . $payload,
    type => 'part',
    'maj:min' => '8:19',
    parttype => 'unknown',
    fstype => 'LVM2_member',
    start => 4096,
};
$layout_parents{'8:19'} = {'8:16' => 1};
$layout = $classifier->classify(\%layout_nodes, \%layout_parents, {}, [], 'boot-test');
save_inventory($store, $layout);

for my $route ('/', '/inventory') {
    $t->get_ok($route)
        ->status_is(200)
        ->content_like(qr/未対応または不明なパーティション: \/dev\/clone2/)
        ->content_like(qr/未対応または不明なパーティション: \/dev\/clone3/)
        ->content_like(qr/PTTYPE=gpt, TYPE=part, PARTTYPE=&lt;empty&gt;, FSTYPE=&lt;empty&gt;/)
        ->content_like(qr/PARTTYPE=unknown, FSTYPE=LVM2_member/)
        ->content_unlike(qr/<script>alert/)
        ->element_exists_not('input[name="target"]:not([disabled])');
    my $reason_text = $t->tx->res->dom->find('p')->map('all_text')->join(' ');
    is(() = $reason_text =~ /未対応または不明なパーティション/g,
        2, 'Each unsupported partition is explained once at disk level');
}
for my $table ('sun', '') {
    $layout_nodes{'8:16'}{pttype} = $table;
    $layout = $classifier->classify(\%layout_nodes, \%layout_parents, {}, [], 'boot-test');
    save_inventory($store, $layout);
    my $expected = $table || '&lt;empty&gt;';
    $t->get_ok('/inventory')->status_is(200)->content_like(qr/未対応のパーティションテーブル: \Q$expected\E/);
}

subtest 'Disconnecting a disk accounts for all its partitions' => sub {
    my $db = Mogura::Server::Store->new(state => tempdir(CLEANUP => 1))->initialize;
    my $web = Test::Mojo->new(Mogura::Server->new(store => $db));
    my %nodes = (
        '8:16' => {
            type => 'disk',
            name => '/dev/sdb',
            'maj:min' => '8:16',
            diskseq => 7,
            serial => 'alpha',
            pttype => 'gpt'
        },
        '8:17' => {
            type => 'part',
            name => '/dev/sdb1',
            'maj:min' => '8:17',
            fstype => 'ext4',
            start => 2048
        },
        '8:18' => {
            type => 'part',
            name => '/dev/sdb2',
            'maj:min' => '8:18',
            fstype => 'ext4',
            start => 8192
        },
        '8:32' => {
            type => 'disk',
            name => '/dev/sdc',
            'maj:min' => '8:32',
            diskseq => 8,
            serial => 'beta',
            fstype => 'xfs'
        },
    );
    my $parents = {'8:17' => {'8:16' => 1}, '8:18' => {'8:16' => 1}};
    my $snapshot = Mogura::Scanner::Disk->new->classify(\%nodes, $parents, {}, [], 'boot-a');
    my ($attached, $independent) = @{$snapshot->{disks}};
    my ($a, $b) = map { $_->{token} } @{$attached->{targets}};
    my $other = $independent->{targets}[0]{token};

    for my $scanner (qw(fixture remote)) {
        $db->register($scanner, Mogura::Server::random_id() x 2);
        save_inventory($db, $snapshot, $scanner);
    }
    my $submit = sub {
        my ($scanner, $token) = @_;
        my $id = Mogura::Server::random_id();
        is($db->submit($id, $scanner, $token, [], ''), 202, "Queue partition on $scanner");
        return $id;
    };
    my $id = $submit->('fixture', $a);
    my $run = Mogura::Server::random_id();
    my $final =
        {sequence => 1, phase => 'finished', status => 'partial', cleanup_status => 'unmounted'};
    ok($db->claim('fixture', $id, $run) && $db->update_run('fixture', $id, $run, $final, 1));
    my $page = sub {
        my ($safe, $why) = @_;
        $web->get_ok("/scans/$id")->status_is(200);
        like($web->tx->res->text,
            $safe ? qr/Safe to disconnect/ : qr/Do not disconnect this disk/, $why);
    };
    $submit->('remote', $b);
    $submit->('fixture', $other);
    $page->(1, 'Independent disks and scanners can keep working');

    my $sibling = $submit->('fixture', $b);
    $page->(0, 'Another partition is queued');
    ok($db->claim('fixture', $sibling, $run));
    $page->(0, 'Another partition is running');
    ok($db->cancel($sibling));
    $page->(0, 'Another partition is cancelling');
    ok($db->update_run('fixture', $sibling, $run, {%$final, cleanup_status => 'needs_cleanup'}, 1));
    $page->(0, 'Finished sibling still needs cleanup');
    ok($db->update_run('fixture', $sibling, $run, {%$final, sequence => 2}, 1));
    $page->(1, 'Both partitions are unmounted');

    my $current = $snapshot->{disks}[0]{targets}[0]{identity};
    for my $boot (undef, 'new-boot') {
        $current->{boot_id} = $boot;
        save_inventory($db, $snapshot);
        $page->(0, 'Inventory must confirm the original attachment');
    }
    $current->{boot_id} = 'boot-a';
    delete $current->{disk}{diskseq};
    save_inventory($db, $snapshot);
    $page->(0, 'A device name alone cannot confirm removal');
    $current->{disk}{diskseq} = 7;
    $current->{disk}{serial} = 'replacement';
    save_inventory($db, $snapshot);
    $page->(0, 'Conflicting hardware identity cannot confirm removal');
    $current->{disk}{serial} = 'alpha';
    delete $snapshot->{disks}[0]{targets}[1]{identity}{disk}{diskseq};
    save_inventory($db, $snapshot);
    my $unknown = $submit->('fixture', $b);
    $page->(0, 'A queued target without a disk identity could be on the same disk');
    ok($db->cancel($unknown));
    $page->(1, 'Cancelling before claim needs no cleanup');
    $snapshot->{updated_at} = time - 60;
    save_inventory($db, $snapshot);
    $page->(0, 'Stale inventory cannot confirm removal');
    delete $snapshot->{updated_at};
    save_inventory($db, $snapshot);
    $db->db->do("UPDATE scanners SET seen=NULL WHERE id='fixture'");
    $page->(0, 'An offline scanner cannot confirm removal');
};

done_testing;
