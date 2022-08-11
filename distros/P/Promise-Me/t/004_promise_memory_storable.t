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

eval "use IPC::SharedMem 2.09;";
plan( skip_all => "IPC::SharedMem 2.09 required for testing promise using shared memory" ) if( $@ );

eval "use Storable 3.25;";
plan( skip_all => "Storable 3.25 required for testing promise serialisation with Storable" ) if( $@ );

my $medium     = 'memory';
my $serialiser = 'storable';
subtest "Promise using $medium and $serialiser serialiser" => sub
{
    &Test::Promise::Me::runtest( $medium, $serialiser );
};

done_testing();

__END__

