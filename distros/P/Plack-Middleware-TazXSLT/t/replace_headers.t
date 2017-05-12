use strict;
use warnings;
use Plack::Middleware::TazXSLT;
use Test::More;
use HTTP::Headers;
use HTTP::Request::Common;

my $header = GET( "http://example.com?foo=bar",
    foo   => 'bar',
    waldo => 'fred',
);

*replace_header = \&Plack::Middleware::TazXSLT::replace_header;

is( replace_header( $header, '' ),                           '' );
is( replace_header( $header, 'bar' ),                        "bar" );
is( replace_header( $header, '$HEADER[foo]' ),               "bar" );
is( replace_header( $header, '$HEADER[foo]$HEADER[waldo]' ), "barfred" );
is( replace_header( $header, 'foo$HEADER[foo]foo$HEADER[waldo]waldo' ),
    "foobarfoofredwaldo" );
is( replace_header( $header, '$HEADER[foowaldo]' ), '' );
is( replace_header( $header, '$GET[foo]' ), 'bar' );
is( replace_header( $header, '$GET[quux]' ), '' );

done_testing();

