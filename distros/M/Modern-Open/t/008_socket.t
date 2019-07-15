use 5.00503;
use strict;
BEGIN { $|=1; print "1..2\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Modern::Open;
use Socket;

my $rc = 0;

$rc = socket(SOCKET,PF_INET,SOCK_STREAM,getprotobyname('tcp'));
ok($rc, q{socket(SOCKET,PF_INET,SOCK_STREAM,getprotobyname('tcp'))});
if ($rc) {
    local $_ = fileno(SOCKET);
    close(SOCKET);
}

$rc = socket(my $socket,PF_INET,SOCK_STREAM,getprotobyname('tcp'));
ok($rc, q{socket(my $socket,PF_INET,SOCK_STREAM,getprotobyname('tcp'))});
if ($rc) {
    close($socket);
}

__END__
