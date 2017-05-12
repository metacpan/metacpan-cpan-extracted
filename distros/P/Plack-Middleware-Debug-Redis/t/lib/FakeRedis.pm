package t::lib::FakeRedis;

# ABSTRACT: fake some redis-server features

use strict;
use warnings;
use Test::MockObject;

my $info = {
    'redis_version'     => '0.1.99',
    'db0'               => 'keys=167,expires=145',
    'db1'               => 'keys=75,expires=0',
    'uptime_in_seconds' => 1591647,
    'role'              => 'master',
    'os'                => 'FreeBSD 9.0-RELEASE-p4 amd64',
    'run_id'            => 'e7c2fdeb9b67f78ab5084e4c3f39c9bd789b4458',
    'used_cpu_sys'      => 5.97,
    'used_cpu_user'     => 7.05,
};

my $db = {
    'coy:knows:pseudonoise:codes'      => [ 'string', 9000 ],
    'six:slimy:snails:sailed:silently' => [ 'list',     35 ],
    'eleven:benevolent:elephants'      => [ 'hash',     17 ],
    'two:tried:and:true:tridents'      => [ 'set',     101 ],
    'tie:twine:to:three:tree:twigs'    => [ 'zset',     66 ],
};

my $fake;

sub run {
    unless (defined $fake) {
        $fake = Test::MockObject->new;
        Test::MockObject->fake_module('Redis', new => sub { $fake }, VERSION => sub { '1.955' });
        $fake
            ->set_true('select', 'quit', 'ping')
            ->mock('info', sub { $info })
            ->mock('keys', sub { keys %$db })
            ->mock('type', sub { exists $db->{$_[1]} ? $db->{$_[1]}->[0] : undef });
        map { $fake->mock($_, sub { &generic_len(@_) }) } qw(strlen hlen llen scard zcard);
    }
    $fake;
}

sub generic_len { exists $db->{$_[1]} ? $db->{$_[1]}->[1] : undef };

1; # End of t::lib::FakeRedis
