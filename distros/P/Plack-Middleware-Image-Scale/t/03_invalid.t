use strict;
use warnings;
use Test::More;
use Plack::Middleware::Static;
use Plack::Builder;
use Plack::Util;
use HTTP::Request::Common;
use HTTP::Response;
use Plack::Test;
use Image::Scale;
use Imager;
use Data::Dumper;

my $handler = builder {
    enable 'Image::Scale';
    sub { [
        404,
        [ 'Content-Type' => 'text/plain', 'Content-Length' => 8 ],
        [ 'not found' ]
    ] };
};

test_psgi $handler, sub {
    my $cb = shift;

    subtest 'Invalid cases' => sub {

        my @invalid = (
           '100x100_x.zip',   # invalid extension
           '100x100_x.',      # missing extension
           '100x100_x',
           '100x100_poo.png', # invalid spec
           '100x100_.png',    # missing spec
           '_x.png',          # missing basename
           '.png',            # missing basename and spec
        );

        for my $filename ( @invalid ) {
            my $res = $cb->(GET "http://localhost/images/$filename");
            is $res->code, 404, "$filename gives 404";
        }

    };
};

done_testing;

