use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Refcount;
use Ryu::Source;

subtest 'emit next item' => sub {
    my $src = new_ok('Ryu::Source');
    my $f;
    is(exception {
        isa_ok($f = $src->next, qw(Future));
    }, undef, 'no exception when calling ->next');
    ok(!$f->is_ready, 'Future not yet ready');
    is(exception {
        $src->emit('xyz');
    }, undef, 'can ->emit without exception');
    ok( $f->is_done, 'Future now done') or die 'unexpected state, Future should be done';
    is(exception {
        is( $f->get, qw(xyz), 'Future had correct value');
    }, undef, 'can retrieve value');
    is(exception {
        $src->emit('abc');
        $src->finish;
    }, undef, 'can ->emit and finish without exception');
    is_oneref($f, 'and with only our Future ref left');
    is_oneref($src, 'and with only our Ryu::Source ref left');
    done_testing;
};

subtest 'cancel before complete' => sub {
    my $src = new_ok('Ryu::Source');
    my $f;
    is(exception {
        isa_ok($f = $src->next, qw(Future));
    }, undef, 'no exception when calling ->next');
    ok(!$f->is_ready, 'Future not yet ready');
    is(exception {
        $f->cancel;
    }, undef, 'can ->cancel Future without exception');
    ok( $f->is_cancelled, 'Future now cancelled') or die 'unexpected state, Future should be done';
    is(exception {
        $src->emit('abc');
        $src->finish;
    }, undef, 'can ->emit and finish without exception');
    is_oneref($f, 'and with only our Future ref left');
    is_oneref($src, 'and with only our Ryu::Source ref left');
    done_testing;
};

subtest 'empty stream' => sub {
    my $src = new_ok('Ryu::Source');
    my $f;
    is(exception {
        isa_ok($f = $src->next, qw(Future));
    }, undef, 'no exception when calling ->next');
    ok(!$f->is_ready, 'Future not yet ready');
    is(exception {
        $src->finish;
    }, undef, 'can finish without exception');
    ok( $f->is_cancelled, 'Future was cancelled');
    is_oneref($f, 'and with only our Future ref left');
    is_oneref($src, 'and with only our Ryu::Source ref left');
    done_testing;
};

done_testing;
