use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Plack::App::unAPI;
use Plack::Request;

my $app1 = sub { 
    [ 404, [ 'Content-Type' => 'application/xml' ], [ '<xml/>' ] ] 
};

{
    package MyApp;
    use parent 'Plack::Component';

    sub call {
        my $req = Plack::Request->new($_[1]);
        my $id = $req->param('id');
        return [ $id ? 200 : 404, 
            [ 'Content-Type' => 'text/plain' ], [ "ID: $id" ] ];
    }
};

my $app2 = MyApp->new;

my @xml = ( 
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<format name="xml" type="application/xml" />',
    '<format name="txt" type="text/plain" docs="http://example.com?x&amp;y" />',
    '</formats>' );

my $app = unAPI(
    xml  => [ $app1 => 'application/xml' ],
    txt  => [ $app2 => 'text/plain', docs => 'http://example.com?x&y', quality => 0.3 ]
);

test_psgi $app, sub {
    my ($cb, $res) = @_;

    $res = $cb->(GET '/?format=foo&id=bar');
    is( $res->code, 406, "Not Acceptable" );

    foreach ('/','/?format=xml') {
        $res = $cb->(GET $_);
        is( $res->code, 300, "Multiple Choices for $_" );
        is_deeply(
            [sort (split "\n", $res->content)],
            [sort ('<formats>',@xml)], 'list formats without id'
        );
    }

    foreach my $q (qw(id=abc id=abc&format= id=abc&format=_)) {
        $res = $cb->(GET "/?$q");
        is( $res->code, 300, 'Multiple Choices' );
        is_deeply(
            [sort (split "\n", $res->content)],
            [sort ('<formats id="abc">',@xml)], 'list formats with id'
        );
    }

    $res = $cb->(GET "/?id=0&format=xml");
    is( $res->code, 404, 'Not found (via format=xml)' );
    is( $res->content, "<xml/>", "format=xml" );

    $res = $cb->(GET "/?id=abc&format=txt");
    is( $res->code, 200, 'Found (via format=txt)' );
    is( $res->content, "ID: abc", "format=txt" );
};

$app = sub { [200,['Content-Type'=>'text/plain'],[42]] };

$app = unAPI( map { $_ => [ $app => 'text/plain' ] } reverse 'a'..'z' );
test_psgi $app, sub {
    my ($cb, $res) = @_;
    $res = $cb->(GET '/');
    my $expect = join "\n", 
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<formats>',
        (map { "<format name=\"$_\" type=\"text/plain\" />" } 'a'..'z'),
        '</formats>';
    is $res->content, $expect, 'sort formats';
};
 
done_testing;
