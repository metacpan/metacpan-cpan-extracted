use Test::More tests => 3;

BEGIN { use_ok('SWISH::3') }

ok( my $x = SWISH::3->xml2_version, "libxml2 version" );
diag("libxml2 version $x");

ok( my $s = SWISH::3->version, "swish version" );
diag("libswish3 version $s");
