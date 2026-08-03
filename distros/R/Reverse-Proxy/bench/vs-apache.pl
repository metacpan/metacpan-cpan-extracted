#!/usr/bin/env perl
# Reverse::Proxy (on Hyperman) vs Apache httpd (mod_proxy_http), both in front
# of the SAME backend, driven by wrk. Prints req/s and latency for: the backend
# direct (ceiling), Apache proxy, and our proxy. Everything is co-resident, so
# the numbers are relative on this box. Run from the dist root after `make`:
#   perl bench/vs-apache.pl [DURATION] [CONNECTIONS] [WRK-THREADS] [WORKERS]
use 5.008003;
use strict;
use warnings;
use FindBin ();
use IO::Socket::INET;

BEGIN {
    for my $mod (qw(Fetch Hyperman)) {
        next if eval "require $mod; 1";
        (my $dir = $mod) =~ s/::/-/g;
        my $sib = "$FindBin::Bin/../../$dir";
        unshift @INC, "$sib/blib/lib", "$sib/blib/arch";
        eval "require $mod; 1" or die "bench needs $mod: $@\n";
    }
}
use Fetch;
use Reverse::Proxy;

my $DUR     = shift || 10;
my $CONN    = shift || 100;
my $THREADS = shift || 4;
my $WORKERS = shift || 4;
my $BODY    = 'x' x 256;

my $WRK  = _which('wrk');
my $HTTPD = -x '/usr/sbin/httpd' ? '/usr/sbin/httpd' : _which('httpd');
die "need wrk on PATH\n"   unless $WRK;
die "need Apache httpd\n"  unless $HTTPD;

my $MODDIR = (grep { -d } qw(/usr/libexec/apache2 /usr/lib/apache2/modules
    /etc/apache2/modules))[0] or die "cannot find Apache modules dir\n";
sub modpath { my $m = shift; my ($f) = grep { -f } map { "$MODDIR/$_" }
    ("mod_$m.so", "$m.so"); return $f; }

my $TMP = "$FindBin::Bin/.vs-apache.$$";
mkdir $TMP or die "mkdir $TMP: $!";

sub free_port {
    my $s = IO::Socket::INET->new(LocalHost=>'127.0.0.1', LocalPort=>0,
        Listen=>1, ReuseAddr=>1) or die $!;
    my $p = $s->sockport; close $s; $p;
}
sub wait_up { my $p = shift; for (1..100){ return 1 if
    IO::Socket::INET->new(PeerAddr=>"127.0.0.1:$p"); select undef,undef,undef,0.1 } 0 }
sub _which { my $n = shift; for (split /:/, $ENV{PATH}||'') { return "$_/$n" if -x "$_/$n" } undef }

# ---- backend: Hyperman, $WORKERS workers, fixed 256-byte body -------------
my $bport = free_port();
my $bpid  = fork // die;
if (!$bpid) { open STDERR,'>','/dev/null';
    Hyperman->run(app => sub { [200, ['Content-Type','text/plain'], [$BODY]] },
        host=>'127.0.0.1', port=>$bport, workers=>$WORKERS); exit }

# ---- our proxy: Hyperman + Reverse::Proxy, $WORKERS workers ---------------
my $rpport = free_port();
my $rppid  = fork // die;
if (!$rppid) { open STDERR,'>','/dev/null';
    my $app = Reverse::Proxy->new(upstream=>"http://127.0.0.1:$bport")->to_app;
    Hyperman->run(app=>$app, host=>'127.0.0.1', port=>$rpport, workers=>$WORKERS); exit }

# ---- Apache reverse proxy (mod_proxy_http) --------------------------------
my $apport = free_port();
my $conf   = "$TMP/httpd.conf";
{
    my @mods = (
        [mpm_event_module => 'mpm_event'], [unixd_module => 'unixd'],
        [authz_core_module => 'authz_core'], [log_config_module => 'log_config'],
        [proxy_module => 'proxy'], [proxy_http_module => 'proxy_http'],
    );
    my $load = '';
    for (@mods) { my $p = modpath($_->[1]) or die "missing Apache module $_->[1]\n";
        $load .= "LoadModule $_->[0] \"$p\"\n"; }
    open my $fh, '>', $conf or die $!;
    print $fh <<"CONF";
ServerRoot "$TMP"
Listen 127.0.0.1:$apport
$load
ServerName 127.0.0.1
PidFile "$TMP/httpd.pid"
ErrorLog "$TMP/error.log"
LogLevel warn
Mutex sem

<IfModule mpm_event_module>
  StartServers        2
  ServerLimit         16
  ThreadsPerChild     64
  ThreadLimit         64
  MaxRequestWorkers   1024
  MaxConnectionsPerChild 0
</IfModule>
KeepAlive On
MaxKeepAliveRequests 0
ProxyRequests Off
<Proxy *>
  Require all granted
</Proxy>
ProxyPass        "/" "http://127.0.0.1:$bport/"
ProxyPassReverse "/" "http://127.0.0.1:$bport/"
CONF
    close $fh;
}
system($HTTPD, '-f', $conf, '-k', 'start') == 0 or warn "httpd start rc=$?\n";

END {
    local $?;
    system($HTTPD, '-f', $conf, '-k', 'stop') if $conf && -f $conf;
    for my $pid ($bpid, $rppid) { next unless $pid; kill 'TERM', $pid; waitpid $pid, 0 }
    system('rm', '-rf', $TMP) if $TMP && -d $TMP;
}

unless (wait_up($bport) && wait_up($rpport) && wait_up($apport)) {
    die "one of backend/our-proxy/apache did not start\n";
}

printf "backend : Hyperman %d workers  :%d\n", $WORKERS, $bport;
printf "apache  : httpd mpm_event (mod_proxy_http)  :%d -> :%d\n", $apport, $bport;
printf "ours    : Hyperman %d workers + Reverse::Proxy%s  :%d -> :%d\n",
    $WORKERS, ($Reverse::Proxy::_HAVE_XS ? ' (XS)' : ' (PP)'), $rpport, $bport;
printf "wrk     : %d threads, %d conns, %ds\n\n", $THREADS, $CONN, $DUR;

sub run_wrk {
    my ($label, $port) = @_;
    my @cmd = ($WRK, "-t$THREADS", "-c$CONN", "-d${DUR}s", "--latency",
               "http://127.0.0.1:$port/");
    my $out = qx{@cmd 2>&1};
    my ($rps) = $out =~ /Requests\/sec:\s+([\d.]+)/;
    my ($p50) = $out =~ /50%\s+([\d.]+\w+)/;
    my ($p99) = $out =~ /99%\s+([\d.]+\w+)/;
    my ($err) = $out =~ /Non-2xx or 3xx responses:\s+(\d+)/;
    printf "%-22s %12s req/s   p50 %-8s p99 %-8s%s\n",
        $label, ($rps // '?'), ($p50 // '-'), ($p99 // '-'),
        ($err ? "   [$err non-2xx]" : '');
}

# warm each a touch, then measure
run_wrk("direct backend",       $bport);
run_wrk("apache mod_proxy",     $apport);
run_wrk("Reverse::Proxy",       $rpport);
print "\n";
