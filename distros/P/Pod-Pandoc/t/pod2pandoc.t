use strict;
use Test::More;
use Capture::Tiny qw(capture);

my ( $out, $err ) = capture {
    system( $^X, '-Ilib', 'script/pod2pandoc', '--version' );
};
like $out, qr{\d+\.\d+\.\d+}, '--version';

done_testing;
