use 5.00503;
use strict;
use Test::Simply tests => 6;
use Modern::Open;
use Socket;

my $rc = 0;


$rc = socket(PROTOSOCKET,PF_INET,SOCK_STREAM,getprotobyname('tcp'));
ok($rc, q{socket(PROTOSOCKET,PF_INET,SOCK_STREAM,getprotobyname('tcp'))});

if ($^O =~ /cygwin/) {
    for (2..6) {
        ok(1, "SKIP \$^O=$^O");
    }
    exit;
}
elsif (not CORE::accept(SOCKET,PROTOSOCKET)) {
    for (2..6) {
        ok(1, "SKIP \$^O=$^O");
    }
    exit;
}

$rc = accept(SOCKET,PROTOSOCKET);
ok($rc, q{accept(SOCKET,PROTOSOCKET)});
if ($rc) {
    close(SOCKET);
}

$rc = accept(my $socket1,PROTOSOCKET);
ok($rc, q{accept(my $socket1,PROTOSOCKET)});
if ($rc) {
    close($socket1);
}

local $_ = fileno(PROTOSOCKET);
close(PROTOSOCKET);

$rc = socket(my $protosocket,PF_INET,SOCK_STREAM,getprotobyname('tcp'));
ok($rc, q{socket(my $protosocket,PF_INET,SOCK_STREAM,getprotobyname('tcp'))});

$rc = accept(SOCKET,$protosocket);
ok($rc, q{accept(SOCKET,$protosocket)});
if ($rc) {
    close(SOCKET);
}

$rc = accept(my $socket2,$protosocket);
ok($rc, q{accept(my $socket2,$protosocket)});
if ($rc) {
    close($socket2);
}

close($protosocket);

__END__
