use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Plack::App::unAPI;
use Plack::Request;

sub lookup_object {
    my $id = shift;
    return ($id =~ /^[a-z]+:/ ? "found $id" : undef);
}

my $app1 = sub { 
    my $id = Plack::Request->new(shift)->param('id') // '';

    my $obj = lookup_object( $id ); # look up object

    return $obj
        ? [ 200, [ 'Content-Type' => 'text/plain' ], [ $obj ] ]
        : [ 404, [ 'Content-Type' => 'text/plain' ], [ 'not found' ] ];
};

my $app = unAPI(
    txt => [ $app1 => 'text/plain', always => 1 ],
    foo => wrAPI( \&lookup_object => 'foo/bar' ),
);

test_psgi $app, sub {
    my ($cb, $res) = @_;

    foreach my $format (qw(txt foo)) {
        $res = $cb->(GET "/?format=$format&id=foo");
        is( $res->code, 404, "not found with format=$format" );
        is( $res->content, "not found" );

        $res = $cb->(GET "/?format=$format&id=a:b");
        is( $res->code, 200, "found with format=$format" );
        is( $res->content, "found a:b" );
    }

    $res = $cb->(GET "/?format=txt");
    is( $res->code, 404, 'always on: 404');
    is( $res->content, 'not found' );

    $res = $cb->(GET "/?format=txt&id=");
    is( $res->code, 404, 'always on: 404');
    is( $res->content, 'not found' );

    $res = $cb->(GET "/?format=foo");
    is( $res->code, 300, 'always off: 300');
    like( $res->content, qr{<formats}m, 'format list' );
};

done_testing;
