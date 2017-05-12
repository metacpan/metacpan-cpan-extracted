package t::all;
use strict;
use warnings;

use parent qw(Test::Class);
use Test::Fatal qw(exception);
use Test::More;

use AnyEvent;
use Promise::Tiny::AnyEvent;

sub all : Tests {
    my $p1 = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(1);
    });
    my $p2 = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(2);
    });
    my $all = Promise::Tiny::AnyEvent->all([$p1, $p2, 3]);
    is_deeply $all->await, [1,2,3];
}

sub all_async : Tests {
    my $p1 = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        my $w; $w = AnyEvent->timer(
            after => 0.1,
            cb => sub { undef $w; $resolve->(1); }
        );
    });
    my $p2 = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        my $w; $w = AnyEvent->timer(
            after => 0,
            cb => sub { undef $w; $resolve->(2); }
        );
    });
    my $all = Promise::Tiny::AnyEvent->all([$p1, $p2, 3]);
    is_deeply $all->await, [1,2,3];
}

sub all_values : Tests {
    my $all = Promise::Tiny::AnyEvent->all([1, 2]);
    is_deeply $all->await, [1,2];
}

sub all_fail : Tests {
    my $p1 = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(1);
    });
    my $p2 = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        $reject->({ message => 'oh my god' });
    });
    my $all = Promise::Tiny::AnyEvent->all([$p1, $p2]);
    is_deeply exception {
        $all->await;
    }, { message => 'oh my god' };
}

sub all_exception : Tests {
    my $p1 = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(1);
    });
    my $p2 = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        die { message => 'oh my god' };
    });
    my $all = Promise::Tiny::AnyEvent->all([$p1, $p2]);
    is_deeply exception {
        $all->await;
    }, { message => 'oh my god' };
}

__PACKAGE__->runtests;
