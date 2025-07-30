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
    use Module::Generic::SharedMemXS v0.1.0 qw( :all );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    # our $DESTROY_SHARED_MEM = 0;
};

use strict;
use warnings;
# use warnings 'Promise::Me';
$Test::Promise::Me::DEBUG = $DEBUG;
$Promise::Me::DEBUG = $DEBUG;

eval "use IPC::SharedMem 2.09;";
plan( skip_all => "IPC::SharedMem 2.09 required for testing promise using shared memory" ) if( $@ );

eval "use CBOR::XS 1.86;";
plan( skip_all => "CBOR::XS 1.86 required for testing promise serialisation with CBOR" ) if( $@ );

my $medium     = 'memory';
my $serialiser = 'cbor';
my $s = Module::Generic::SharedMemXS->new(
{
    create  => 1,
    key     => 'pm_mem_cbor_' . $$,
    mode    => 0666,
    size    => 10240,
}) || do
{
    plan( skip_all => 'This platform does not support shared memory or there is not enough of it.' );
};
my $mem = $s->open || do
{
    plan( skip_all => 'This platform does not support shared memory or there is not enough of it: ' . $s->error );
};
$mem->remove;
my $tmpdir = file(__FILE__)->parent;
subtest "Promise using $medium and $serialiser serialiser" => sub
{
    &Test::Promise::Me::runtest( $medium, $serialiser, { tmpdir => $tmpdir } );
};

done_testing();

__END__

