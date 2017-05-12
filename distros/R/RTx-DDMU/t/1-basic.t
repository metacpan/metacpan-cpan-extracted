use Test::More tests => 1;

use lib qw(
    /opt/rt3/lib
    /usr/local/rt3/lib
    c:/progra~1/ourinternet/reques~1/rt/lib
);

SKIP: {
    skip("Can't find RT3 path", 1) unless eval { require RT::Record; 1 };
    use_ok('RTx::DDMU');
}

1;
