use strict;
use warnings;
use Test::More;

use Net::OATH::Server::Lite::Model::User;

subtest q{new} => sub {
    my $user = Net::OATH::Server::Lite::Model::User->new(
                   id => q{id},
                   secret => q{secret},
               );
    ok($user, q{mandatory});
    is($user->id, q{id});
    is($user->type, q{totp});
    is($user->secret, q{secret});
    is($user->algorithm, q{SHA1});
    is($user->digits, 6);
    is($user->counter, 0);
    is($user->period, 30);

    # TOTP
    $user = Net::OATH::Server::Lite::Model::User->new(
                   id        => q{id},
                   type      => q{totp},
                   secret    => q{secret_2},
                   algorithm => q{SHA256},
                   digits    => 8,
                   period    => 60,
               );
    ok($user, q{totp full});
    is($user->id, q{id});
    is($user->type, q{totp});
    is($user->secret, q{secret_2});
    is($user->algorithm, q{SHA256});
    is($user->digits, 8);
    is($user->counter, 0);
    is($user->period, 60);

    # HOTP
    $user = Net::OATH::Server::Lite::Model::User->new(
                   id        => q{id},
                   type      => q{hotp},
                   secret    => q{secret},
                   algorithm => q{SHA256},
                   digits    => 8,
                   counter   => 1,
               );
    ok($user, q{mandatory});
    is($user->id, q{id});
    is($user->type, q{hotp});
    is($user->secret, q{secret});
    is($user->algorithm, q{SHA256});
    is($user->digits, 8);
    is($user->counter, 1);
    is($user->period, 30);
};

subtest q{is_valid} => sub {
    my $user = Net::OATH::Server::Lite::Model::User->new(
                   id => q{id},
                   secret => q{secret},
               );
    ok($user);
    ok($user->is_valid, q{valid user});

    $user->type(q{invalid});
    ok(!$user->is_valid, q{invalid type});

    $user = Net::OATH::Server::Lite::Model::User->new(
                   id => q{id},
                   secret => q{secret},
               );
    $user->algorithm(q{SHA256});
    ok(!$user->is_valid, q{invalid type});
};

done_testing;
