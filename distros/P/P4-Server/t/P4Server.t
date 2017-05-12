use Test::Unit::HarnessUnit;
use lib qw(t/tlib);

my $r = Test::Unit::HarnessUnit->new();

$r->start( 'P4::Server::Test::Server' );
