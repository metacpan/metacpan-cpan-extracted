#!/usr/bin/perl

use strict;
use warnings;

use parent qw(Test::Class);

use Test::More;

use IO::Handle;
use Net::ZooKeeper qw(:node_flags :acls :log_levels);
use Net::ZooKeeper::Lock;

use POSIX qw(:sys_wait_h);
use Time::HiRes qw(sleep);

{
    # I don't know why SKIP_CLASS calls 2 times.
    my $skip;
    sub SKIP_CLASS {
        return $skip if (defined($skip));

        eval {
            my $zkh = Net::ZooKeeper->new(_get_host());
            my $path = $zkh->create(_path() . "2", '0',
                acl   => ZOO_OPEN_ACL_UNSAFE,
                flags => ZOO_EPHEMERAL,
            );
            die "" unless($path);
        };

        if ($@) {
            $skip = "Can't connect to ZooKeeper, ".
                    "it should be \$ENV{ZOOKEEPER_HOST} or 'localhost:2181'";
        } else {
            $skip = 0;
        }

        return $skip;
    }
}

sub setup : Test(setup) {
    my $self = shift;

    $self->{zkh} = _get_zkh();
    unless ($self->{zkh}->exists(_path())) {
        $self->_create(_path());
    }
    if ($self->{zkh}->exists(_path2())) {
        $self->_delete(_path2());
    }
}

sub teardown : Test(teardown) {
    my $self = shift;
    $self->_delete(_path());
    $self->_delete(_path2());
    delete $self->{zkh};
}

sub nonblocking_lock : Test(2) {
    my $self = shift;

    my $lock_name = 'nb1';
    $self->_create(_path($lock_name));

    my $lock_params = {
        zkh         => $self->{zkh},
        lock_prefix => _path($lock_name),
        lock_name   => $lock_name,
        blocking    => 0,
        create_prefix => 0,
    };

    my $lock1 = Net::ZooKeeper::Lock->new($lock_params);
    isa_ok($lock1, 'Net::ZooKeeper::Lock');

    my $lock2 = Net::ZooKeeper::Lock->new($lock_params);
    ok(!defined($lock2), 'nonblocking lock is undef if lock already taken');
}

sub blocking_lock : Test(5) {
    my $self = shift;

    my $lock_name = 'b1';
    $self->_create(_path($lock_name));

    my $lock_params = {
        zkh         => $self->{zkh},
        lock_prefix => _path($lock_name),
        lock_name   => $lock_name,
        blocking    => 1,
        create_prefix => 0,
    };

    my $child_write;
    my $pid = open($child_write, "-|");
    $child_write->blocking(0);
    if (!defined($pid)) {
        die "Can't fork";
    }

    if ($pid) {
        my $lock1 = Net::ZooKeeper::Lock->new($lock_params);
        ok($lock1, 'parent process initially holds the lock');
        sleep(0.3);

        my $get_child_resp = sub {
            my $child_resp;
            while (1) {
                my $buff;
                my $res = read($child_write, $buff, 100);
                if (defined($res) && $res > 0) {
                    $child_resp .= $buff;
                } else {
                    last;
                }
            }
            return $child_resp;
        };

        my $resp1 = $get_child_resp->();
        is($resp1, "before getting lock\n",
           'forked process tries to get lock');

        $lock1->unlock;
        sleep(0.5);

        # use nonblocking lock to know, that forked process really holds the lock
        my $lock2 = Net::ZooKeeper::Lock->new({ %$lock_params, blocking => 0 });
        ok(!defined($lock2), 'forked process really holds the lock');

        my $resp2 = $get_child_resp->();
        is($resp2, "holding lock\n", 'child says that it holds lock');

        kill(9, $pid);
        close($child_write);

        my $lock3 = Net::ZooKeeper::Lock->new($lock_params);
        ok($lock3, 'lock returned to parent process');
    } else {
        sleep(0.1);
        $lock_params->{zkh} = _get_zkh();
        print "before getting lock\n";
        my $ch_lock1 = eval { Net::ZooKeeper::Lock->new($lock_params); };
        if ($@ || !$ch_lock1) {
            print "can't get lock: $@\n";
            exit(1);
        } else {
            print "holding lock\n";
            while (1) {}
        }
    }
}

sub data : Test {
    my $self = shift;

    my $lock_name = 'nb2';
    my $data = $$;

    my $lock_params = {
        zkh         => $self->{zkh},
        lock_name   => $lock_name,
        blocking    => 0,
        data        => $data,
    };

    my $lock1 = Net::ZooKeeper::Lock->new($lock_params);

    is($self->{zkh}->get($lock1->lock_path), $data, 'data works');
}

sub create_prefix : Test {
    my $self = shift;

    my $lock_name = 'nb2';

    my $lock_params = {
        zkh         => $self->{zkh},
        lock_prefix => _path2($lock_name),
        lock_name   => $lock_name,
        blocking    => 0,
        create_prefix => 1,
    };

    my $lock1 = Net::ZooKeeper::Lock->new($lock_params);
    ok($lock1, 'create_prefix works');
}

sub unlock : Test(3) {
    my $self = shift;

    my $lock_name = 'nb3';
    $self->_create(_path($lock_name));

    my $lock_params = {
        zkh         => $self->{zkh},
        lock_prefix => _path($lock_name),
        lock_name   => $lock_name,
        blocking    => 0,
        create_prefix => 0,
    };

    {
        my $lock1 = Net::ZooKeeper::Lock->new($lock_params);
        $lock1->unlock;
        my $lock2 = Net::ZooKeeper::Lock->new($lock_params);
        ok($lock2, 'unlock()');
    }
    {
        my $lock1 = Net::ZooKeeper::Lock->new($lock_params);
        undef $lock1;
        my $lock2 = Net::ZooKeeper::Lock->new($lock_params);
        ok($lock2, 'undef $lock releases lock');
    }
    {
        {
            my $lock1 = Net::ZooKeeper::Lock->new($lock_params);
        }
        my $lock2 = Net::ZooKeeper::Lock->new($lock_params);
        ok($lock2, 'out of scope releases lock');
    }
}

sub _path {
    my $p = shift || '';
    my $version = shift;
    $p = "/" . $p if ($p !~ m{^/} && $p ne '');
    my $prefix = "/wbRsXNuHw5";
    $prefix .= ".$version" if defined($version);
    return $prefix . $p;
}

sub _path2 {
    my $p = shift;
    return _path($p, 2);
}

sub _create {
    my ($self, $path) = @_;

    $self->{zkh}->create($path, '0',
        acl => ZOO_OPEN_ACL_UNSAFE,
    );
}

sub _delete {
    my ($self, $path) = @_;
    my @children = $self->{zkh}->get_children($path);
    if (@children) {
        foreach my $child (@children) {
            $self->{zkh}->delete("$path/$child");
            $self->{zkh}->delete($path);
        }
    } else {
        $self->{zkh}->delete($path);
    }
}

sub _get_host {
    return $ENV{ZOOKEEPER_HOST} || 'localhost:2181';
}

sub _get_zkh {
    return Net::ZooKeeper->new(
        _get_host(),
        session_timeout => 100,
    );
}

__PACKAGE__->new->runtests;
