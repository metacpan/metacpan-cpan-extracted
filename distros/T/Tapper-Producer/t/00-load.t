#!perl -T

use Test::More;

BEGIN {
    use_ok( 'Tapper::Producer' );
    use_ok( 'Tapper::Producer::DummyProducer' );
    use_ok( 'Tapper::Producer::Kernel' );
    use_ok( 'Tapper::Producer::NewestPackage' );
    use_ok( 'Tapper::Producer::SimnowKernel' );
    use_ok( 'Tapper::Producer::Temare' );
}

done_testing;
