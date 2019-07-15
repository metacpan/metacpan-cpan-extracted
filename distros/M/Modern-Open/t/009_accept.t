use 5.00503;
use strict;
BEGIN { $|=1; print "1..6\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}

use FindBin;
use lib "$FindBin::Bin/../lib";
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
