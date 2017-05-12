use strict;
use warnings;
use v5.10.1;
use Test::More;
use Plack::App::DAIA::Test;
use Plack::Test;
use HTTP::Request::Common;

my $app = Plack::App::DAIA->new( code => sub { return [ ] } );

test_daia_psgi $app, 'some:id' => sub {
    my ($e) = $_->message;
    is( $e->content, "request method did not return a DAIA response" );
};

$app->code( sub { die "!\n" } );
test_daia_psgi $app, 'some:id' => sub {
    my ($e) = $_->message;
    is( $e->content, "request method died: !" );
};

$app->safe(0);
test_psgi $app, sub {
    my $res = shift()->(GET "/?id=some:id&format=json");
    is( $res->content, "!\n", 'unsafe server died' );
};

done_testing;
