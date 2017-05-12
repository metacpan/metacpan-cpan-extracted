use Test::More tests => 5;

use lib qw(lib t/test01 ../lib);

use Su::Process base => './t', dir => 'test01';

ok( $Su::Template::TEMPLATE_BASE_DIR, "./t" );
ok( $Su::Template::TEMPLATE_DIR,      "test01" );

my $ret = gen("TestComp01");
is( $ret, "TestComp01" );

$ret = gen("subcomp/TestComp02");

is( $ret, "TestComp02" );

## Test arg.
$ret = comp( "TestComp03", "param" );
is( $ret, "TestComp03 param" );

