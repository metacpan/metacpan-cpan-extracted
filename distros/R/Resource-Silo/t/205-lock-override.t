#!/usr/bin/env perl

=head1 DESCRIPTION

Locked mode & overrides are useful to provide test fixtures or mocks
and avoid affecting real resources in tests.

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;

use Resource::Silo;
resource config     => sub { +{ redis => 'localhost', max_users => 42 } };
resource redis_conn => sub { $_[0]->config->{redis} };
resource max_users  =>
    derived             => 1,
    init                => sub { $_[0]->config->{max_users} };
resource redis      =>
    argument            => sub { 1 }, # anything goes
    derived             => 1,
    init                => sub { return ($_[0]->redis_conn . ":$_[2]") };

silo->ctl->lock->override(
    redis_conn => 'mock',
);

lives_and {
    is silo->redis('foo'), 'mock:foo', 'redis falls through and redis_conn is mocked';
};

throws_ok {
    silo->max_users;
} qr(initialize.*locked mode), 'loading config is prohibited';
like $@, qr('config'), 'we tried to load config, max_users was ok';

silo->ctl->unlock;
lives_and {
    is silo->max_users, 42, "unoverridden resource instantiated after unlock";
};

done_testing;
