use strict;
use warnings;
use Test::More;

use Net::OATH::Server::Lite::Error;

subtest q{default} => sub {
    my $error = Net::OATH::Server::Lite::Error->new;
    ok($error, q{new});
    is($error->code, 400, q{code});
    is($error->error, q{invalid_request}, q{error});
    is($error->description, q{}, q{description});
};

subtest q{custom} => sub {
    my $error = Net::OATH::Server::Lite::Error->new(
        code => 500,
        error => q{custom_error},
        description => q{custom_description},
    );
    ok($error, q{new});
    is($error->code, 500, q{code});
    is($error->error, q{custom_error}, q{error});
    is($error->description, q{custom_description}, q{description});
};

done_testing;
