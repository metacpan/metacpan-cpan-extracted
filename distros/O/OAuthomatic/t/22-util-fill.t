#!perl

use Test::Most tests => 13;
use Encode;
use utf8;

my $req;
my $outp;

use_ok('OAuthomatic::Internal::Util', qw(fill_httpmsg_form));


sub form_matches {
    my ($given, $expected, $comment) = @_;
    my $sorted_given = join('&', sort split('&', $given));
    my $sorted_expected = join('&', sort split('&', $expected));
    is($sorted_given, $sorted_expected, $comment);
}


$req = HTTP::Request->new("POST" => "http://info.onet.pl");
fill_httpmsg_form($req, {a => 1, b => "x", c => 'trutu'});

# print STDERR "-" x 70, "\n", $req->dump(), "-" x 70, "\n";

form_matches( $req->content, 'a=1&b=x&c=trutu', "form 1 - content");
cmp_deeply( [$req->content_type], ['application/x-www-form-urlencoded', 'charset=utf-8'], "form 1 - content type");
is( $req->uri, 'http://info.onet.pl', 'form 1 - url');
is( $req->method, 'POST', 'form 1 - method');



$req = HTTP::Request->new("POST" => "http://info.onet.pl?x=2");
fill_httpmsg_form($req, {a => 'ą', b => "&", c => '='});

# print STDERR "-" x 70, "\n", $req->dump(), "-" x 70, "\n";

form_matches( $req->content, 'a=%C4%85&b=%26&c=%3D', "form 2 - content");
cmp_deeply( [$req->content_type], ['application/x-www-form-urlencoded', 'charset=utf-8'], "form 2 - content type");
is( $req->uri, 'http://info.onet.pl?x=2', 'form 2 - url');
is( $req->method, 'POST', 'form 2 - method');



$req = HTTP::Request->new("POST" => "http://info.onet.pl?x=2");
fill_httpmsg_form($req, {a => 1, b => "AąćęZ", c => 'A&B=CąD'});

# print STDERR "-" x 70, "\n", $req->dump(), "-" x 70, "\n";

form_matches( $req->content, 'a=1&b=A%C4%85%C4%87%C4%99Z&c=A%26B%3DC%C4%85D', "form 3 - content");
cmp_deeply( [$req->content_type], ['application/x-www-form-urlencoded', 'charset=utf-8'], "form 3 - content type");
is( $req->uri, 'http://info.onet.pl?x=2', 'form 3 - url');
is( $req->method, 'POST', 'form 3 - method');

done_testing;
