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
    $SIG{__DIE__} = sub {};
    die "meh";
};

my $wrapped = Plack::Middleware::StackTrace::RethrowFriendly->wrap(
    $app,
    no_print_errors => 1,
);

test_psgi $wrapped, sub {
    my $cb = shift;

    my $req = GET "/";
    my $res = $cb->($req);

    is $res->code, 500;
    like $res->content, qr/The application raised/;
};

my $twice_died_app = sub {
    eval { die "hmm" };
    $SIG{__DIE__} = sub {};
    die "meh";
};

my $twice_died_wrapped = Plack::Middleware::StackTrace::RethrowFriendly->wrap(
    $twice_died_app,
    no_print_errors => 1,
);

test_psgi $twice_died_wrapped, sub {
    my $cb = shift;

    my $req = GET "/";
    my $res = $cb->($req);

    is $res->code, 500;
    like $res->content, qr/The application raised/;
};

done_testing;
