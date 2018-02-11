use strict;
use warnings FATAL => 'all';

use Catmandu;
use HTTP::Request::Common;
use Plack::App::Catmandu::Bag;
use Plack::Builder;
use Plack::Test;
use Test::More;
use Data::Dumper;

my $pkg;
BEGIN {
    $pkg = "Plack::Middleware::Signposting::Catmandu";
    use_ok $pkg;
}
require_ok $pkg;

my $data = {
    _id => '123AX99',
    signs => [
        ["https://orcid.org/i-am-orcid", "author"],
        ["https://orcid.org/987654", "author"],
    ]
};

Catmandu->define_store('library', 'Hash');
Catmandu->store('library')->bag('books')->add($data);

my $app = builder {
    enable "Plack::Middleware::Signposting::Catmandu",
        store => "library",
        bag => "books",
        match_paths => ['record/(\w+)/*', 'publication/(\w+)/*'];
    mount '/publication' => Plack::App::Catmandu::Bag->new(
        store => 'library',
        bag => 'books',
    );
    mount '/record' => Plack::App::Catmandu::Bag->new(
        store => 'library',
        bag => 'books',
    );
    mount '/foo' => Plack::App::Catmandu::Bag->new(
        store => 'library',
        bag => 'books',
    );
};

test_psgi app => $app, client => sub {
    my $cb = shift;

    {
        my $req = GET "http://localhost/publication/123AX99";
        my $res = $cb->($req);

        like $res->header('Link'), qr{\<https*:\/\/orcid.org\/i-am-orcid\>; rel="author"}, "ORCID for /publication/1 in Link header";
        like $res->header('Link'), qr{\<https*:\/\/orcid.org\/987654\>; rel="author"}, "second ORCID for /publication/1 in Link header";
    }

    {
        my $req = GET "http://localhost/record/123AX99";
        my $res = $cb->($req);

        like $res->header('Link'), qr{\<https*:\/\/orcid.org\/i-am-orcid\>; rel="author"}, "ORCID for /record/1 in Link header";
        like $res->header('Link'), qr{\<https*:\/\/orcid.org\/987654\>; rel="author"}, "secibd ORCID for /record/1 in Link header";
    }

    {
        my $req = GET "http://localhost/foo/123AX99";
        my $res = $cb->($req);

        is $res->is_success, 1, "/foo app is fine";
        is $res->header('Link'), undef, "Link header not present for /foo/1";
    }

    # {
    #     my $req = GET "http://localhost/publication/123AX99";
    #     my $res = $cb->($req);
    #
    #     like $res->header('Link'), qr{\<https*:\/\/orcid.org\/i-am-orcid\>; rel="author"}, "ORCID for /publication/1 in Link header";
    #     like $res->header('Link'), qr{\<https*:\/\/orcid.org\/987654\>; rel="author"}, "second ORCID for /publication/1 in Link header";
    # }
};

done_testing;
