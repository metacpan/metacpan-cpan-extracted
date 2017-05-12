use strict;
use warnings;
use Test::More;

use Net::OATH::Server::Lite::DataHandler;

subtest q{new} => sub {
    my $dh = Net::OATH::Server::Lite::DataHandler->new;
    ok($dh, q{new});

    ok($dh->can(q{create_id}),     q{create_id});
    ok($dh->can(q{create_secret}), q{create_secret});

    ok($dh->can(q{insert_user}),   q{insert_user});
    ok($dh->can(q{select_user}),   q{select_user});
    ok($dh->can(q{update_user}),   q{update_user});
    ok($dh->can(q{delete_user}),   q{delete_user});
};

done_testing;
