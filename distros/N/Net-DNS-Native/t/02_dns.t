use strict;
use Test::More;
use Net::DNS::Native;
use Socket;
use IO::Select;

use constant HAS_INET_NTOP => eval { Socket::inet_ntop(AF_INET6, "\0"x16) };

my $ip = inet_aton("google.com");
unless ($ip) {
    plan skip_all => "no DNS access on this computer";
}

# DNS CHECK

my $dns = Net::DNS::Native->new();
my $sel = IO::Select->new();

# inet_aton
for my $host ("google.com", "google.ru", "google.cy") {
    my $fh = $dns->inet_aton($host);
    $sel->add($fh);
}

my $i = 0;

while ($sel->count() > 0) {
    if (++$i > 2) {
        my @timedout = $sel->handles;
        diag(scalar(@timedout) . " are timed out");
        
        for my $sock (@timedout) {
            $dns->timedout($sock);
            $sel->remove($sock);
        }
    }
    else {
        my @ready = $sel->can_read(60);
        ok(scalar @ready, "inet_aton: resolved less then 60 sec");
        
        for my $fh (@ready) {
            $sel->remove($fh);
            my @res = $dns->get_result($fh);
            is(scalar @res, 1, "1 result for inet_aton");
            if ($res[0]) {
                ok(eval{inet_ntoa($res[0])}, "inet_aton: properly packed ip") or diag $@;
            }
        }
    }
}

# inet_pton
# AF_INET6
SKIP: {
    skip 'Socket::inet_ntop() not implemented', 0 unless HAS_INET_NTOP;
    
    for my $host ("google.com", "google.ru", "google.cy") {
        my $fh = $dns->inet_pton(AF_INET6, $host);
        $sel->add($fh);
    }

    while ($sel->count() > 0) {
        my @ready = $sel->can_read(60);
        ok(scalar @ready, "inet_pton: resolved less then 60 sec");
        
        for my $fh (@ready) {
            $sel->remove($fh);
            my @res = $dns->get_result($fh);
            is(scalar @res, 1, "1 result for inet_pton");
            if ($res[0]) {
                ok(eval{Socket::inet_ntop(AF_INET6, $res[0])}, "inet_pton: properly packed ip") or diag $@;
            }
        }
    }
}

# AF_INET
for my $host ("google.com", "google.ru", "google.cy") {
    my $fh = $dns->inet_pton(AF_INET, $host);
    $sel->add($fh);
}

while ($sel->count() > 0) {
    my @ready = $sel->can_read(60);
    ok(scalar @ready, "inet_pton: resolved less then 60 sec");
    
    for my $fh (@ready) {
        $sel->remove($fh);
        my @res = $dns->get_result($fh);
        is(scalar @res, 1, "1 result for inet_pton");
        if ($res[0]) {
            ok(eval{inet_ntoa($res[0])}, "inet_pton: properly packed ip") or diag $@;
        }
    }
}

# gethostbyname
for my $host ("google.com", "google.ru", "google.cy") {
    my $fh = $dns->gethostbyname($host);
    $sel->add($fh);
}

while ($sel->count() > 0) {
    my @ready = $sel->can_read(60);
    ok(scalar @ready, "gethostbyname: resolved less then 60 sec");
    
    for my $fh (@ready) {
        $sel->remove($fh);
        
        if (rand > 0.5) {
            my $ip = $dns->get_result($fh);
            if ($ip) {
                ok(eval{inet_ntoa($ip)}, "gethostbyname: properly packed ip") or diag $@;
            }
        }
        else {
            my @res = $dns->get_result($fh);
            if (@res) {
                ok(scalar @res >= 5, ">=5 return values for gethostbyname() in list context");
                splice @res, 0, 4;
                
                for my $ip (@res) {
                    ok(eval{inet_ntoa($ip)}, "gethostbyname: properly packed ip") or diag $@;
                }
            }
        }
        
        ok(!eval{$dns->get_result($fh)}, "get result when result already got");
    }
}

# getaddrinfo
for my $host ("google.com", "google.ru", "google.cy") {
    my $fh = $dns->getaddrinfo($host);
    $sel->add($fh);
}

while ($sel->count() > 0) {
    my @ready = $sel->can_read(60);
    ok(scalar @ready, "getaddrinfo: resolved less then 60 sec");
    
    for my $fh (@ready) {
        $sel->remove($fh);
        
        my ($err, @res) = $dns->get_result($fh);
        ok(defined $err, "error SV defined");
        if (!$err) {
            ok(@res >= 1, "getaddrinfo: one or more result");
            for my $r (@res) {
                is(ref $r, 'HASH', 'result is hash ref');
                for (qw/family socktype protocol addr canonname/) {
                    ok(exists $r->{$_}, "result hash $_ key");
                }
                
                ok($r->{family} == AF_INET || $r->{family} == AF_INET6, "correct family");
                ok(eval{($r->{family} == AF_INET ? unpack_sockaddr_in($r->{addr}) : Net::DNS::Native::unpack_sockaddr_in6($r->{addr}))[1]}, "has correct address") or diag $@;
            }
        }
    }
}

open my $fh, __FILE__;
ok(!eval{$dns->get_result($fh)}, "get_result for unknow handle");

# POOL CHECK

$dns = Net::DNS::Native->new(pool => 3);
$sel = IO::Select->new();
{
    no warnings 'redefine';
    my $orig = \&Net::DNS::Native::timedout;
    my $timedout = 0;
    local *Net::DNS::Native::timedout = sub {
        my $self = shift;
        $timedout++;
        $self->$orig(@_);
    };
    
    for my $domain ('mail.ru', 'google.com', 'google.ru', 'google.cy', 'mail.com', 'mail.net') {
        my $sock = $dns->gethostbyname($domain);
        if ($domain ne 'mail.ru') {
            $sel->add($sock);
        }
    }
    
    is($timedout, 1, 'right count marked as timed out');
}

while ($sel->count() > 0) {
    my @ready = $sel->can_read(60);
    ok(@ready > 0, 'resolving took less than 60 sec');
    
    for my $sock (@ready) {
        $sel->remove($sock);
        
        if (my $ip = $dns->get_result($sock)) {
            ok(eval{inet_ntoa($ip)}, 'correct ipv4 address');
        }
    }
}

$dns = Net::DNS::Native->new(pool => 1, extra_thread => 1);
$sel = IO::Select->new();

for my $domain ('mail.ru', 'google.com', 'google.ru', 'google.cy', 'mail.com', 'mail.net') {
    my $sock = $dns->gethostbyname($domain);
    if ($domain eq 'mail.ru') {
        $dns->timedout($sock);
    }
    else {
        $sel->add($sock);
    }
}

while ($sel->count() > 0) {
    my @ready = $sel->can_read(60);
    ok(@ready > 0, 'extra_thread: resolving took less than 60 sec');
    
    for my $sock (@ready) {
        $sel->remove($sock);
        
        if (my $ip = $dns->get_result($sock)) {
            ok(eval{inet_ntoa($ip)}, 'extra_thread: correct ipv4 address');
        }
    }
}

# NOTIFY_ON_BEGIN CHECK

$dns = Net::DNS::Native->new(pool => 1, notify_on_begin => 1);
$sel = IO::Select->new();

my %map;
for my $host (qw/google.com google.cy google.ru/) {
    my $sock = $dns->inet_aton($host);
    $sel->add($sock);
    $map{$sock} = 0;
}

while ($sel->count() > 0) {
    my @ready = $sel->can_read(60);
    ok(@ready, "select() took less than 60 sec");
    
    for my $sock (@ready) {
        $map{$sock}++;
        sysread($sock, my $buf, 1);
        is($buf, $map{$sock}, "correct notification value");
        if ($map{$sock} == 2) {
            my $ip = $dns->get_result($sock);
            if ($ip) {
                ok(eval{inet_ntoa($ip)}, "correct ip");
            }
            $sel->remove($sock);
        }
    }
}

# FORK CHECK
SKIP: {
    skip 'No fork() support on this platform', 0 if $^O eq 'MSWin32';
    defined(my $child = fork()) or skip "Can't fork: $!", 0;
    
    # with pool
    if ($child == 0) {
        alarm(60);
        
        for my $host (qw/localhost google.com localhost google.cy localhost google.ru localhost/) {
            my $sock = $dns->getaddrinfo($host);
            $sel->add($sock);
        }
        
        while ($sel->count() > 0) {
            my @ready = $sel->can_read(60) or exit 1;
            
            for my $sock (@ready) {
                sysread($sock, my $buf, 1);
                if ($buf eq '2') {
                    my @res = $dns->get_result($sock) or exit 2;
                    $sel->remove($sock);
                }
            }
        }
        
        exit 0;
    }
    
    wait();
    is($?>>8, 0, 'Child process worked successfully (with pool)');
    
    $dns = Net::DNS::Native->new();
    defined($child = fork()) or skip "Can't fork: $!", 0;
    
    # without pool
    if ($child == 0) {
        alarm(60);
        
        for my $host (qw/localhost google.com localhost google.cy localhost google.ru localhost/) {
            my $sock = $dns->getaddrinfo($host);
            $sel->add($sock);
        }
        
        while ($sel->count() > 0) {
            my @ready = $sel->can_read(60) or exit 1;
            
            for my $sock (@ready) {
                sysread($sock, my $buf, 1);
                my @res = $dns->get_result($sock) or exit 2;
                $sel->remove($sock);
            }
        }
        
        exit 0;
    }
    
    wait();
    is($?>>8, 0, 'Child process worked successfully (without pool)');
}

done_testing;
