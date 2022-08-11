#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib qw( ./lib ./t );
    use vars qw( $DEBUG $DESTROY_SHARED_MEM );
    # use Test2::IPC;
    # use Test2::V0;
    use Test::More;
    use Promise::Me qw( :all );
    use Test::Promise::Me;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    # our $DESTROY_SHARED_MEM = 0;
};

use strict;
use warnings;
# use warnings 'Promise::Me';
$Test::Promise::Me::DEBUG = $DEBUG;

eval "use Cache::FastMmap 1.57;";
plan( skip_all => "Cache::FastMmap 1.57 required for testing promise using cache mmap" ) if( $@ );

eval "use CBOR::XS 1.86;";
plan( skip_all => "CBOR::XS 1.86 required for testing promise serialisation with CBOR" ) if( $@ );

my $medium     = 'mmap';
my $serialiser = 'cbor';
subtest "Promise using $medium and $serialiser serialiser" => sub
{
    &Test::Promise::Me::runtest( $medium, $serialiser );
};

done_testing();

__END__

