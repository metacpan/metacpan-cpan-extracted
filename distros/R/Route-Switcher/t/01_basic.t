use Test::More;
use lib 't/lib';
use TestDispatcher::Src;
use TestDispatcher::Dest;

my $src_router = TestDispatcher::Src::router;
my $dest_router = TestDispatcher::Dest::router;


is_deeply($src_router,$dest_router);

done_testing;




