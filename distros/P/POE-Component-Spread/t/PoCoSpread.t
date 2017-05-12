use strict;
use POE;
use POE::Session;
use POE::Component::Spread;
use Data::Dumper;
use Test::More tests => 2;

my $class;
my @tests = qw( t/PoCoSpread.t );
BEGIN {
    $class = 'POE::Component::Spread';
    use_ok($class)
}

my $f = $class->new( 'test' );
isa_ok( $f, 'POE::Session' );
$poe_kernel->run();
