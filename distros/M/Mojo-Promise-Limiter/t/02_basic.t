use strict;
use warnings;
use Test::More;
use Mojo::Promise::Limiter;
use Mojo::Promise;
use Mojo::IOLoop;

my $limiter = Mojo::Promise::Limiter->new(2);

my @event;
for my $event (qw(run remove queue dequeue)) {
    $limiter->on($event => sub { my (undef, $name) = @_; push @event, "$event $name" });
}

my $p1 = $limiter->limit(sub {
    my $p = Mojo::Promise->new;
    Mojo::IOLoop->timer(0.1 => sub { $p->resolve("OK1") });
    return $p;
}, "p1");

my $p2 = $limiter->limit(sub {
    my $p = Mojo::Promise->new;
    Mojo::IOLoop->timer(0.2 => sub { $p->reject("NG2") });
    return $p;
}, "p2");

my $p3 = $limiter->limit(sub {
    my $p = Mojo::Promise->new;
    Mojo::IOLoop->timer(0.3 => sub { $p->reject("NG3") });
    return $p;
}, "p3");

my $p4 = $limiter->limit(sub {
    my $p = Mojo::Promise->new;
    Mojo::IOLoop->timer(0.4 => sub { $p->resolve("OK4") });
    return $p;
}, "p4");

Mojo::Promise->all_settled($p1, $p2, $p3, $p4)->then(sub {
    is_deeply $_[0], { status => 'fulfilled', value  => ['OK1'] };
    is_deeply $_[1], { status => 'rejected',  reason => ['NG2'] };
    is_deeply $_[2], { status => 'rejected',  reason => ['NG3'] };
    is_deeply $_[3], { status => 'fulfilled', value  => ['OK4'] };
})->wait;

is_deeply \@event, [
    "run p1",
    "run p2",
    "queue p3",
    "queue p4",
    "remove p1",
    "dequeue p3",
    "run p3",
    "remove p2",
    "dequeue p4",
    "run p4",
    "remove p3",
    "remove p4",
];

done_testing;
