use strict;
use warnings;

use File::Slurp;
use FindBin qw($Bin);
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;
use Test::More;

my $json = read_file("$Bin/../example/publication.json");;

my $app = builder {
    enable "Plack::Middleware::Signposting::JSON", fix => "$Bin/../example/signposting.fix";

    sub { [ '200', ['Content-Type' => 'application/json'], [$json] ] };
};

test_psgi app => $app, client => sub {
    my $cb = shift;

    {
        my $req = GET "http://localhost/";
        my $res = $cb->($req);

        like $res->header('Link'), qr/\<https*:\/\/orcid.org\/0000-0002-7635-3473\>; rel="author"/, 'ORCID in Link header';
        like $res->header('Link'), qr/\<https*:\/\/schema.org\/ScholarlyArticle\>; rel="type"/, 'schema.org in Link header';
    }
};

done_testing;
