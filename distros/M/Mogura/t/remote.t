use strict;
use warnings;
use Test::More;
use Test::Mojo;
use POSIX qw(_exit);
use Mojo::UserAgent;
use Mojo::Server::Daemon;
use File::Temp qw(tempdir);
use Mojo::File qw(path);
use Digest::SHA qw(sha256_hex);
use lib 'lib';
use Mogura::Server;
use Mogura::Protocol qw(random_id);

my $state = tempdir(CLEANUP => 1);
my $store = Mogura::Server::Store->new(state => $state);
my $app = Mogura::Server->new(store => $store);
my $t = Test::Mojo->new($app);
my %auth = (
    alpha => {Authorization => 'Bearer ' . ('a' x 64)},
    beta => {Authorization => 'Bearer ' . ('b' x 64)}
);
my $token = 'd' x 64;
my $snapshot = {
    scanner_id => 'forged',
    disks => [
        {
            name => '/dev/sdb',
            targets => [
                {
                    token => $token,
                    selectable => 1,
                    identity => {disk => {name => '/dev/sdb'}, partition => {name => '/dev/sdb1'}}
                }
            ]
        }
    ]
};

for my $name (sort keys %auth) {
    $store->register($name, substr($auth{$name}{Authorization}, 7));
    $t->post_ok('/api/inventory' => $auth{$name} => json => $snapshot)->status_is(200);
}
$t->get_ok('/api/jobs')->status_is(401);
my ($id, $other, $run) = map { random_id() } 1 .. 3;
is($store->submit($id, 'alpha', $token, [], ''), 202, 'Job submitted to alpha');
is($store->submit($other, 'beta', $token, [], ''), 202, 'Same disk token on a different scanner');
$t->get_ok('/api/jobs' => $auth{beta})->status_is(200)->json_is('/job/id', $other);
my $route = "/api/jobs/$id/$run";
$t->post_ok("$route/claim" => $auth{beta} => json => {})->status_is(409);
for (1 .. 2) { $t->post_ok("$route/claim" => $auth{alpha} => json => {})->status_is(200) }
$t->post_ok("/api/jobs/$id/" . random_id() . "/claim" => $auth{alpha} => json => {})
    ->status_is(409);
my $progress = {sequence => 2, phase => 'sbom', cleanup_status => 'mounted'};
$t->post_ok("$route/progress" => $auth{beta} => json => $progress)->status_is(409);
$t->post_ok("$route/progress" => $auth{alpha} => json => $progress)->status_is(200);
my $completed =
    {sequence => 5, status => 'completed', phase => 'finished', cleanup_status => 'unmounted'};
$t->post_ok("$route/complete" => $auth{alpha} => json => $completed)->status_is(409);
my %files = (
    syft => '{"source":{},"artifacts":[],"descriptor":{"name":"syft"}}',
    cdx => '{"bomFormat":"CycloneDX","specVersion":"1.6"}',
    grype => '{"matches":[],"descriptor":{"name":"grype"}}'
);

sub upload {
    my ($name, $kind, $bytes, $hash) = @_;
    return $t->put_ok(
        "$route/files/$kind" => {
            %{$auth{$name}},
            'Content-Type' => 'application/octet-stream',
            'X-Content-SHA256' => $hash // sha256_hex($bytes)
        } => $bytes
    );
}
upload('alpha', 'log', "binary\0data")->status_is(409);
upload('beta', 'syft', $files{syft})->status_is(403);
upload('alpha', 'syft', '{}')->status_is(409);
upload('alpha', 'syft', $files{syft}, '0' x 64)->status_is(409);

# Crash the daemon and its validation subprocess between linking the file
# and committing the receipt. Only this throwaway server uses the trigger.
{

    package CrashStore;
    use Mojo::Base 'Mogura::Server::Store';
    has 'daemon_pid';

    sub db {
        my ($self) = @_;
        my $db = $self->SUPER::db;
        if ($$ != $self->daemon_pid && ($self->{armed} // 0) != $$) {
            $self->{armed} = $$;
            $db->sqlite_create_function(
                'interrupt_receipt',
                0,
                sub {
                    kill 'KILL', $self->daemon_pid;
                    POSIX::_exit(73);
                }
            );
            $db->do(
                'CREATE TEMP TRIGGER stop_before_receipt BEFORE INSERT ON receipts BEGIN SELECT interrupt_receipt(); END'
            );
        }
        return $db;
    }
}
pipe my $port_reader, my $port_writer or die $!;
my $pid = fork // die $!;
unless ($pid) {
    close $port_reader;
    Mojo::IOLoop->reset;
    my $server = Mogura::Server->new(store => CrashStore->new(state => $state, daemon_pid => $$));
    my $daemon =
        Mojo::Server::Daemon->new(app => $server, listen => ['http://127.0.0.1:0'], silent => 1)
        ->start;
    print {$port_writer} $daemon->ports->[0], "\n";
    close $port_writer;
    $daemon->run;
    _exit(1);
}
close $port_writer;
my $port = <$port_reader>;
chomp $port;
my $response = Mojo::UserAgent->new->request_timeout(5)->put(
    "http://127.0.0.1:$port$route/files/syft" => {
        %{$auth{alpha}},
        'Content-Type' => 'application/octet-stream',
        'X-Content-SHA256' => sha256_hex($files{syft})
    } => $files{syft}
);
ok(!$response->res->is_success, 'Hard stop loses upload acknowledgement');
my $exited = waitpid($pid, POSIX::WNOHANG());
if (!$exited) { kill 'TERM', $pid; waitpid($pid, 0) }
is($? & 127, 9, 'Server was killed at the receipt boundary');
ok(-f $store->directory($id)->child('sbom.syft.json'), 'Final file survives interrupted receipt');
ok(!$store->artifact($id, 'syft'), 'Unconfirmed file is not downloadable');
$t = Test::Mojo->new(Mogura::Server->new(store => Mogura::Server::Store->new(state => $state)));

for my $kind (sort keys %files) {
    upload('alpha', $kind, $files{$kind})->status_is(200);
    upload('alpha', $kind, $files{$kind})->status_is(200);
}
upload('alpha', 'syft', $files{syft} . "\n")->status_is(409);
$t->post_ok(
    "$route/complete" => $auth{alpha} => json => {%$completed, cleanup_status => 'needs_cleanup'})
    ->status_is(409);
for (1 .. 2) {
    $t->post_ok("$route/complete" => $auth{alpha} => json => $completed)->status_is(200);
}
$t->post_ok("$route/progress" => $auth{alpha} => json => {%$progress, sequence => 8})
    ->status_is(200);
is($store->get($id)->{status}, 'completed', 'Late progress preserves final outcome');
$store->db->do("UPDATE scanners SET digest=NULL WHERE id='alpha'");
$t->get_ok('/api/jobs' => $auth{alpha})->status_is(401);
ok(!grep(m{^Mogura/Scanner}, keys %INC), 'Server works without loading scanner code');
done_testing;
