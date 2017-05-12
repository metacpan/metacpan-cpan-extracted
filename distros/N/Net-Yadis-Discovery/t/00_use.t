use Test::More tests => 4;
BEGIN { use_ok('Net::Yadis::Discovery') };

is (YR_HEAD,0);
is (YR_GET,1);
is (YR_XRDS,2);