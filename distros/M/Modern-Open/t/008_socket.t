use 5.00503;
use strict;
use Test::Simply tests => 2;
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
