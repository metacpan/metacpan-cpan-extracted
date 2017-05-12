use strict;
use warnings;

# lib
use Plack::Middleware::StackTrace::RethrowFriendly;

# cpan
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

$Plack::Test::Impl = "Server";
local $ENV{PLACK_SERVER} = "HTTP::Server::PSGI";

my $app = sub {
    eval { challenge() };
    die $@ if $@;
};

sub challenge {
    die "oops";
}

my $wrapped = Plack::Middleware::StackTrace::RethrowFriendly->wrap(
    $app,
    no_print_errors => 1,
);

test_psgi $wrapped, sub {
    my $cb = shift;

    my $req = GET "/";
    my $res = $cb->($req);

    is $res->code, 500;
    like $res->content, qr/main::challenge/;
};

done_testing;
