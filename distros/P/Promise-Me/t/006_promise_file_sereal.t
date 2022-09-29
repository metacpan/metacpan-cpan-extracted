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
    use Module::Generic::File qw( file );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    # our $DESTROY_SHARED_MEM = 0;
};

use strict;
use warnings;
# use warnings 'Promise::Me';
$Test::Promise::Me::DEBUG = $DEBUG;

eval "use Sereal 4.020;";
plan( skip_all => "Sereal 4.020 required for testing promise serialisation with Sereal" ) if( $@ );

my $medium     = 'file';
my $serialiser = 'sereal';
my $tmpdir = file(__FILE__)->parent;
subtest "Promise using $medium and $serialiser serialiser" => sub
{
    &Test::Promise::Me::runtest( $medium, $serialiser, { tmpdir => $tmpdir } );
};

done_testing();

__END__

