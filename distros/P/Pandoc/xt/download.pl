use strict;
use warnings;
use Test::More;
use Pandoc::Release;

foreach( Pandoc::Release->list(since => '2.1', verbose => 1) ) {
    isa_ok( $_->download(
        arch => 'amd64', dir => 'xt/deb', verbose => 1, bin => 'xt/bin'
    ), 'Pandoc::Version');
}

done_testing;
