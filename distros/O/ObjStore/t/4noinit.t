use Test; #-*-perl-*-
BEGIN { plan test => 6 }

use ObjStore::NoInit;

ok !$ObjStore::INITIALIZED;
ok defined *begin{CODE};

my ($name,$sz) = ("3noinit.t", 6 * 1024 * 1024);
$ObjStore::CLIENT_NAME = $name;
$ObjStore::CACHE_SIZE = $sz;

ObjStore::initialize();

ok $ObjStore::INITIALIZED;
ok $ObjStore::CLIENT_NAME, $name;
ok $ObjStore::CACHE_SIZE, $sz;

{
    my $warn;
    local $SIG{__WARN__} = sub { $warn = shift };
    ObjStore::NoInit->import();
    ok $warn =~ m/too late/;
}

