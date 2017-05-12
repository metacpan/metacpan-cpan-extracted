use Test::More tests => 2;
use lib qw(lib t/lib);
use BaseClass::Subclass;

sub make_man { BaseClass::Subclass->new( @_ ) }

is( make_man()->max_workers, 20, "Should default to 20 max_workers when no value specified" );
is( make_man( max_workers => 10 )->max_workers, 10, "Should have 10 max_workers when so specified" );

