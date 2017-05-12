use strictures;

package basic_test;

use Test::InDistDir;
use Test::More;
no warnings qw' once redefine ';

use HTTP::Request::Common qw( GET );

run();
done_testing;
exit;

sub run {
    my @responses = (
        [ 1, { Status => 200 }, map { GET( $_ ), $_ } "http://google.de" ],
        [ 1, { Status => 200 }, map { GET( $_ ), $_ } "http://google.com" ],
        [ undef, {}, map { GET( $_ ), $_ } "http://website.broke" ],
    );

    my @w;
    require AnyEvent::HTTP;
    local *AnyEvent::HTTP::http_request = sub {
        my ( @args ) = @_;
        my $cb = sub {
            my ( $res ) = grep { $_->[3] eq $args[1] } @responses;
            pop( @args )->( @{$res} );
        };
        push @w, AnyEvent->timer( after => rand, cb => $cb );
    };

    require Parallel::Downloader;
    Parallel::Downloader->import( 'async_download' );

    my @results = async_download( requests => [ map { $_->[2] } @responses ] );

    is( $results[$_][1]{Status}, 200 ) for ( 0, 1 );
    is( $results[2][0], undef );

    return;
}
