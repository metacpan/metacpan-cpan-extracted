use Mojo::Base -strict;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;

plan skip_all => <<'' unless $ENV{TEST_HYPNOTOAD} or $ENV{TEST_HYPNOTOAD_PATH};
set TEST_HYPNOTOAD or TEST_HYPNOTOAD_PATH to enable this test (developer only!)

use Config;
use File::Spec::Functions qw(catdir catfile);
use File::Temp 'tempdir';
use FindBin;
use IO::Socket::INET;
use Mojo::IOLoop::Server;
use Mojo::Server::Hypnotoad;
use Mojo::UserAgent;
use Mojo::Util qw(slurp spurt);

require Mojolicious::Plugin::SizeLimit;

my ($total, $shared) = Mojolicious::Plugin::SizeLimit::check_size();

unless (ok $total, "OS ($^O) is supported") {
    done_testing();
    exit 0;
}

# Prepare script
my $perl = $Config{perlpath};
my $hypnotoad = $ENV{TEST_HYPNOTOAD_PATH} || catfile $Config{bin}, 'hypnotoad';

plan skip_all => <<"" unless -e $hypnotoad;
No hypnotoad found at $hypnotoad. Set TEST_HYPNOTOAD_PATH to correct path.

my $dir = tempdir CLEANUP => 1;
my $script = catdir $dir, 'myapp.pl';
my $log    = catdir $dir, 'mojo.log';
my $port   = Mojo::IOLoop::Server->generate_port;

my $tmpl = <<EOF;
use Mojolicious::Lite;

app->log->path('$log');

plugin Config => {
    default => {
        hypnotoad => {
            inactivity_timeout => 3,
            listen => ['http://127.0.0.1:$port'],
            workers => 1
        }
    }
};

app->log->level('debug');

plugin 'SizeLimit', {%s};

get '/pid' => sub { shift->render(text => \$\$) };

my \@buffer;
get '/size' => sub {
    my \$c = shift;
    my \$inc = \$c->req->param('inc');
    push(\@buffer, ('0') x \$inc)
        if \$inc and \$inc =~ /^\\d+\$/;
    my \@s = Mojolicious::Plugin::SizeLimit::check_size();
    \$c->render(text => "\@s");
};

app->start;
EOF

spurt sprintf($tmpl, ''), $script;

# Start
open my $start, '-|', $perl, $hypnotoad, $script;
sleep 3;
sleep 1 while !_port($port);
my $mpid1 = _pid();

# Application is alive
my $ua = Mojo::UserAgent->new;
my $tx = $ua->get("http://127.0.0.1:$port/pid");
ok $tx->is_finished, 'transaction is finished';
ok $tx->keep_alive,  'connection will be kept alive';
ok !$tx->kept_alive, 'connection was not kept alive';
is $tx->res->code, 200, 'right status';
my $wpid1 = $tx->res->body;
like $wpid1, qr/^\d+$/, 'right content';

# Same result
$tx = $ua->get("http://127.0.0.1:$port/pid");
ok $tx->is_finished, 'transaction is finished';
ok $tx->keep_alive,  'connection will be kept alive';
ok $tx->kept_alive,  'connection was kept alive';
is $tx->res->code, 200, 'right status';
is $tx->res->body, $wpid1, 'right content';

# Get process size
$tx = $ua->get("http://127.0.0.1:$port/size");
ok $tx->is_finished, 'transaction is finished';
ok $tx->keep_alive,  'connection will be kept alive';
ok $tx->kept_alive,  'connection was kept alive';
is $tx->res->code, 200, 'right status';
my ($size1, $shared1) = split ' ', $tx->res->body;
like $size1, qr/^\d+$/, 'size is a non-negative integer';
like $shared1, qr/^\d+$/, 'shared is a non-negative integer';

# Grow process and get process size again
$tx = $ua->get("http://127.0.0.1:$port/size?inc=1000000");
ok $tx->is_finished, 'transaction is finished';
ok $tx->keep_alive,  'connection will be kept alive';
ok $tx->kept_alive,  'connection was kept alive';
is $tx->res->code, 200, 'right status';
my ($size2, $shared2) = split ' ', $tx->res->body;
like $size2, qr/^\d+$/, 'size is a non-negative integer';
like $shared2, qr/^\d+$/, 'shared is a non-negative integer';
my $msize = int(($size1 + $size2) / 2 + 1);
my $mshared= int(($shared1 + $shared2) / 2 + 1);
my ($p, $v);

if ($shared1) {
    $p = 'max_unshared_size';
    $v = ($msize - $mshared);
}
else {
    # no information available for shared (Solaris)
    $p = 'max_process_size';
    $v = $msize;
}

# Update script
spurt sprintf($tmpl, "$p => $v, report_level => 'info'"), $script;

open my $hot_deploy1, '-|', $perl, $hypnotoad, $script;

# Connection did not get lost
$tx = $ua->get("http://127.0.0.1:$port/pid");
ok $tx->is_finished, 'transaction is finished';
ok $tx->keep_alive,  'connection will be kept alive';
ok $tx->kept_alive,  'connection was kept alive';
is $tx->res->code, 200, 'right status';
is $tx->res->body, $wpid1, 'right content';

# Remove keep-alive connections
$ua = Mojo::UserAgent->new;

my $mpid2;
# Wait for hot deployment to finish
while (1) {
    sleep 1;
    next unless $mpid2 = _pid();
    last if $mpid2 ne $mpid1;
}

# Application has been reloaded
$tx = $ua->get("http://127.0.0.1:$port/pid");
ok $tx->is_finished, 'transaction is finished';
ok $tx->keep_alive,  'connection will be kept alive';
ok !$tx->kept_alive, 'connection was not kept alive';
is $tx->res->code, 200, 'right status';
my $wpid2 = $tx->res->body;
like $wpid2, qr/^\d+$/, 'right content';
isnt $wpid2, $wpid1, 'worker pid changed';

# Grow process, check that SizeLimit got it
$tx = $ua->get("http://127.0.0.1:$port/size?inc=1000000");
ok $tx->is_finished, 'transaction is finished';
ok !$tx->keep_alive,  'connection will not be kept alive';
ok $tx->kept_alive,  'connection was kept alive';
is $tx->res->code, 200, 'right status';
my ($size3, $shared3) = split ' ', $tx->res->body;
like $size3, qr/^\d+$/, 'size is a non-negative integer';
like $shared3, qr/^\d+$/, 'shared is a non-negative integer';

# This must be a fresh worker process
$tx = $ua->get("http://127.0.0.1:$port/pid");
ok $tx->is_finished, 'transaction is finished';
ok $tx->keep_alive,  'connection will be kept alive';
ok !$tx->kept_alive,  'connection was not kept alive';
is $tx->res->code, 200, 'right status';
my $wpid3 = $tx->res->body;
like $wpid3, qr/^\d+$/, 'right content';
isnt $wpid3, $wpid2, 'worker pid changed again';

# Update script again
spurt sprintf($tmpl, "$p => $v, check_interval => 3, report_level => 'warn'"),
      $script;

open my $hot_deploy2, '-|', $perl, $hypnotoad, $script;

# Remove keep-alive connections
$ua = Mojo::UserAgent->new;

my $mpid3;
# Wait for hot deployment to finish
while (1) {
    sleep 1;
    next unless $mpid3 = _pid();
    last if $mpid3 ne $mpid2;
}

# Application has been reloaded
$tx = $ua->get("http://127.0.0.1:$port/pid");
ok $tx->is_finished, 'transaction is finished';
ok $tx->keep_alive,  'connection will be kept alive';
ok !$tx->kept_alive, 'connection was not kept alive';
is $tx->res->code, 200, 'right status';
my $wpid4 = $tx->res->body;
like $wpid4, qr/^\d+$/, 'right content';
isnt $wpid4, $wpid3, 'worker pid changed';

# Grow process, but it's not SizeLimit's turn
$tx = $ua->get("http://127.0.0.1:$port/size?inc=1000000");
ok $tx->is_finished, 'transaction is finished';
ok $tx->keep_alive,  'connection will be kept alive';
ok $tx->kept_alive,  'connection was kept alive';
is $tx->res->code, 200, 'right status';

# Attack SizeLimit!
$tx = $ua->get("http://127.0.0.1:$port/pid");
ok $tx->is_finished, 'transaction is finished';
ok !$tx->keep_alive,  'connection will not be kept alive';
ok $tx->kept_alive,  'connection was kept alive';
is $tx->res->code, 200, 'right status';
my $wpid4a = $tx->res->body;
like $wpid4a, qr/^\d+$/, 'right content';
is $wpid4a, $wpid4, 'worker pid did not change';

# Now we must have a fresh worker
$tx = $ua->get("http://127.0.0.1:$port/pid");
ok $tx->is_finished, 'transaction is finished';
ok $tx->keep_alive,  'connection will be kept alive';
ok !$tx->kept_alive,  'connection was not kept alive';
is $tx->res->code, 200, 'right status';
my $wpid5 = $tx->res->body;
like $wpid5, qr/^\d+$/, 'right content';
isnt $wpid5, $wpid4, 'worker pid changed again';

# Stop
open my $stop, '-|', $perl, $hypnotoad, $script, '-s';
sleep 1 while _port($port);

# Check log
$log = slurp $log;
like $log, qr/
        Manager\s+$mpid1\s+started
        .+
        Worker\s+$wpid1\s+started
        .+
        Starting\s+zero\s+downtime\s+software\s+upgrade
        .+
        Manager\s+$mpid2\s+started
        .+
        Worker\s+$wpid2\s+started
        .+
        Upgrade\s+successful,\s+stopping\s+$mpid1
        .+
        Stopping\s+worker\s+$wpid1\s+gracefully
        .+
        Worker\s+$wpid1\s+stopped
        .+
        \[info\]\s+SizeLimit\:\s+Exceeding\s+limit\s+$p\s+=\s+$v\s+KB\.\s+
            PID\s+=\s+\d+,\s+
            SIZE\s+=\s+\d+\s+KB,\s+
            (?:
                SHARED\s+=\s+\d+\s+KB,\s+
                UNSHARED\s+=\s+\d+\s+KB,\s+
            )?
            REQUESTS\s+=\s+\d+,\s+
            LIFETIME\s+=\s+\d+\.\d+\s+s
        .+
        Worker\s+$wpid2\s+stopped
        .+
        Worker\s+$wpid3\s+started
        .+
        Starting\s+zero\s+downtime\s+software\s+upgrade
        .+
        Manager\s+$mpid3\s+started
        .+
        Worker\s+$wpid4\s+started
        .+
        Upgrade\s+successful,\s+stopping\s+$mpid2
        .+
        Stopping\s+worker\s+$wpid3\s+gracefully
        .+
        Worker\s+$wpid3\s+stopped
        .+
        \[warn\]\s+SizeLimit\:\s+Exceeding\s+limit\s+$p\s+=\s+$v\s+KB\.\s+
            PID\s+=\s+\d+,\s+
            SIZE\s+=\s+\d+\s+KB,\s+
            (?:
                SHARED\s+=\s+\d+\s+KB,\s+
                UNSHARED\s+=\s+\d+\s+KB,\s+
            )?
            REQUESTS\s+=\s+\d+,\s+
            LIFETIME\s+=\s+\d+\.\d+\s+s
        .+
        Worker\s+$wpid4\s+stopped
        .+
        Worker\s+$wpid5\s+started
        .+
        Stopping\s+worker\s+$wpid5\s+gracefully
        .+
        Worker\s+$wpid5\s+stopped
    /sx, 'log is correct';

sub _pid {
    return undef unless open my $file, '<', catdir($dir, 'hypnotoad.pid');
    my $pid = <$file>;
    chomp $pid;
    return $pid;
}

sub _port {
    IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => shift)
}

done_testing();
