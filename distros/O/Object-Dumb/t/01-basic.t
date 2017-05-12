#!perl

use 5.010001;
use strict;
use warnings;

use Object::Dumb;
use Test::Exception;
use Test::More 0.98;

subtest default => sub {
    my $o = Object::Dumb->new;
    is($o->foo, 0);
    is($o->bar, 0);
};

subtest "opt:methods (array)" => sub {
    my $o = Object::Dumb->new(methods => ['foo', 'bar']);
    lives_ok { $o->foo };
    lives_ok { $o->bar };
    dies_ok { $o->baz };
};

subtest "opt:methods (array)" => sub {
    my $o = Object::Dumb->new(methods => qr/\A(foo|bar.*)\z/);
    lives_ok { $o->foo };
    lives_ok { $o->bar };
    lives_ok { $o->barbie };
    dies_ok { $o->baz };
};

subtest "opt:returns" => sub {
    my $o = Object::Dumb->new(returns => 42);
    is($o->foo, 42);
    is($o->bar, 42);
};

done_testing;
