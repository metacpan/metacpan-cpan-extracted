#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Test::LeakTrace };
    plan skip_all => 'Test::LeakTrace required' if $@;
}
use Test::LeakTrace;

use Object::Proto;

# Define singleton test classes
Object::Proto::define('LeakSingleton1', 'config:Str', 'count:Int:default(0)');
Object::Proto::singleton('LeakSingleton1');

Object::Proto::define('LeakSingleton2', 'name:Str:default(default)', 'value:Int:default(0)');
Object::Proto::singleton('LeakSingleton2');

Object::Proto::define('LeakSingletonTyped',
    'setting:Str:default(default_setting)',
    'cache:HashRef:default({})',
);
Object::Proto::singleton('LeakSingletonTyped');

# Warmup - initialize singletons
for (1..10) {
    my $s1 = LeakSingleton1->instance(config => 'warmup', count => 0);
    my $s2 = LeakSingleton2->instance();
    my $s3 = LeakSingletonTyped->instance(setting => 'init');
    $s1->count;
    $s2->value;
    $s3->setting;
}

subtest 'singleton instance no leak' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $s = LeakSingleton1->instance();
        }
    } 'singleton instance no leak';
};

subtest 'singleton instance with args no leak' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $s = LeakSingleton2->instance(name => 'test', value => 42);
        }
    } 'singleton instance args no leak';
};

subtest 'singleton accessor get no leak' => sub {
    my $s = LeakSingleton1->instance();
    no_leaks_ok {
        for (1..1000) {
            my $cfg = $s->config;
            my $cnt = $s->count;
        }
    } 'singleton accessor get no leak';
};

subtest 'singleton accessor set no leak' => sub {
    my $s = LeakSingleton1->instance();
    no_leaks_ok {
        for (1..1000) {
            $s->config('updated');
            $s->count(42);
        }
    } 'singleton accessor set no leak';
};

subtest 'singleton state increment no leak' => sub {
    my $s = LeakSingleton1->instance();
    $s->count(0);
    no_leaks_ok {
        for (1..1000) {
            my $c = $s->count;
            $s->count($c + 1);
        }
    } 'singleton increment no leak';
};

subtest 'singleton hash manipulation no leak' => sub {
    my $s = LeakSingletonTyped->instance(setting => 'test');
    no_leaks_ok {
        for (1..500) {
            $s->cache->{key} = 'value';
            my $v = $s->cache->{key};
            delete $s->cache->{key};
        }
    } 'singleton hash no leak';
};

subtest 'singleton multiple classes no leak' => sub {
    no_leaks_ok {
        for (1..500) {
            my $s1 = LeakSingleton1->instance();
            my $s2 = LeakSingleton2->instance();
            my $c = $s1->config;
            my $n = $s2->name;
        }
    } 'singleton multi-class no leak';
};

subtest 'singleton same instance check no leak' => sub {
    no_leaks_ok {
        for (1..500) {
            my $a = LeakSingleton1->instance();
            my $b = LeakSingleton1->instance();
            my $same = ($a == $b);
        }
    } 'singleton same instance no leak';
};

done_testing;
