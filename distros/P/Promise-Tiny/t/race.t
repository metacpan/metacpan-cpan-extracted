package t::race;
use strict;
use warnings;

use parent qw(Test::Class);
use Test::Fatal qw(exception);
use Test::More;

use AnyEvent;
use Promise::Tiny::AnyEvent;

sub race : Tests {
    my $p1 = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        my $w; $w = AnyEvent->timer(
            after => 1,
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

    my $value = Promise::Tiny::AnyEvent->race([$p1, $p2])->await();
    is $value, 2;
}

sub race_with_value : Tests {
    my $p1 = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        my $w; $w = AnyEvent->timer(
            after => 0,
            cb => sub { undef $w; $resolve->(1); }
        );
    });
    my $p2 = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(2);
    });

    my $value = Promise::Tiny::AnyEvent->race([$p1, $p2])->await();
    is $value, 2, 'got raw value instantly';
}

sub race_success : Tests {
    my $p1 = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        my $w; $w = AnyEvent->timer(
            after => 0,
            cb => sub { undef $w; $resolve->(1); }
        );
    });
    my $p2 = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        my $w; $w = AnyEvent->timer(
            after => 1,
            cb => sub { undef $w; $reject->({ message => 'fail' }); }
        );
    });
    my $value = Promise::Tiny::AnyEvent->race([$p1, $p2])->await();
    is $value, 1;
}

sub race_fail : Tests {
    my $p1 = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        my $w; $w = AnyEvent->timer(
            after => 1,
            cb => sub { undef $w; $resolve->(1); }
        );
    });
    my $p2 = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        my $w; $w = AnyEvent->timer(
            after => 0,
            cb => sub { undef $w; $reject->({ message => 'fail' }); }
        );
    });
    is_deeply exception {
        Promise::Tiny::AnyEvent->race([$p1, $p2])->await
    }, { message => 'fail' };
}

__PACKAGE__->runtests;
