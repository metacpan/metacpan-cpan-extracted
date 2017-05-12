use Test::More tests => 2;
use lib qw(lib t/lib);
use BaseClass::Subclass;

sub make_man { BaseClass::Subclass->new( @_ ) }

my $man = make_man(max_workers => 10);

is( make_man( max_workers => 10 )->max_workers, 10, "At construction time, it respected the max_workers param" );

$man->max_workers( 20 );

is( $man->max_workers, 20, "Can reset the max_workers param at run time" );

