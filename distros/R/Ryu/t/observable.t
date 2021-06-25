use strict;
use warnings;

use Test::More;
use Test::Warnings qw(:all);
use Test::Refcount;
use Test::Fatal;

use Ryu::Observable;

subtest 'string and number handling' => sub {
    my $v = Ryu::Observable->new(123);
    is(0+$v, 123, 'number looks right');
    is("$v", "123", 'string looks right');
    done_testing;
};

subtest 'subscription' => sub {
    my $v = Ryu::Observable->new(123);
    my $expected = 124;
    my $called;
    $v->subscribe(sub {
        is($_, $_[0], 'value was passed in $_ and @_');
        is(shift, $expected, 'have expected value');
        ++$called;
    });
    ++$v;
    ok($called, 'callback was triggered');
    $v->set($expected = 65);
    is($called, 2, 'callback was triggered again');
    done_testing;
};
subtest 'boolean comparison - numeric' => sub {
    ok(!!Ryu::Observable->new(123), 'true numeric boolean');
    ok(!Ryu::Observable->new(0), 'true numeric boolean');
    done_testing;
};
subtest 'boolean comparison - string' => sub {
    ok(!!Ryu::Observable->new("example"), 'true string boolean');
    ok(!Ryu::Observable->new(""), 'false string boolean');
    ok(!Ryu::Observable->new(undef), 'false string boolean');
    done_testing;
};

subtest 'sources' => sub {
    is(exception {
        my $v = Ryu::Observable->new('example');
        isa_ok(my $src = $v->source, 'Ryu::Source');
        my $count = 0;
        $src->each(sub { ++$count });
        is($count, 0, 'count starts as zero');
        $v->set_string('changed');
        is($count, 1, 'count changes after a value change');
        {
            isa_ok(my $src2 = $v->source, 'Ryu::Source');
            is($src, $src2, 'same source is returned each time from ->source');
        }
        undef $v;
        is($src->completed->state, 'done', 'source is marked as done on completion');
        is_oneref($src, 'source has only a single ref left');
        is($count, 1, 'count unchanged');
    }, undef, 'no exceptions raised');
    done_testing;
};

SKIP: {
    skip 'Sentinel module not installed', 1 unless eval { require Sentinel };
    subtest 'sentinel' => sub {
        is(exception {
            my $v = Ryu::Observable->new("example\n");
            for($v->lvalue_str) {
                chomp;
                is($v->as_string, 'example', 'chomp operation on lvalue_str applied to original instance');
                $_ = 'test';
                is($v->as_string, 'test', 'assignment operation on lvalue_str applied to original instance');
            }
            is("$v", 'test', 'new value retained on lvalue destruction');
            is_oneref($v, 'single ref for our observable');
        }, undef, 'no exceptions raised');

        is(exception {
            my $v = Ryu::Observable->new(123);
            for($v->lvalue_num) {
                $_ *= 2;
                is($v->as_number, 246, 'multiply operation on lvalue_num applied to original instance');
                $_ = 8;
                is($v->as_number, 8, 'assignment operation on lvalue_num applied to original instance');
            }
            is(0 + $v, 8, 'new value retained on lvalue destruction');
            is_oneref($v, 'single ref for our observable');
        }, undef, 'no exceptions raised');
        done_testing;
    };
}

done_testing;

