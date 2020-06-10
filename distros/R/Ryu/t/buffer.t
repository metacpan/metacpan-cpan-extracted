use strict;
use warnings;

use Test::More;

use Ryu::Buffer;

subtest 'simple write' => sub {
    my $buffer = new_ok('Ryu::Buffer');
    is($buffer->size, 0, 'starts with nothing it in');
    ok($buffer->is_empty, 'which means it is empty');
    ok($buffer->write('test'), 'can write some data');
    ok(!$buffer->is_empty, 'which means it is no longer empty');
    done_testing;
};

subtest 'read_exactly' => sub {
    my $buffer = new_ok('Ryu::Buffer');
    ok($buffer->write('test'), 'can write some data');
    {
        isa_ok(my $f = $buffer->read_exactly(2), 'Future');
        ok($f->is_ready, 'read when data already exists');
        is($f->get, 'te', 'data is correct');
    }
    {
        isa_ok(my $f = $buffer->read_exactly(2), 'Future');
        ok($f->is_ready, 'read when data already exists');
        is($f->get, 'st', 'data is correct');
    }
    {
        isa_ok(my $f = $buffer->read_exactly(2), 'Future');
        ok(!$f->is_ready, 'not ready yet');
        $buffer->write('!');
        ok(!$f->is_ready, 'not ready yet');
        $buffer->write('!');
        ok($f->is_ready, 'read when data already exists');
        is($f->get, '!!', 'data is correct');
    }
    done_testing;
};

subtest 'read_until' => sub {
    my $buffer = new_ok('Ryu::Buffer');
    isa_ok(my $f = $buffer->read_until("\x0D\x0A"), 'Future');
    ok(!$f->is_ready, 'not ready yet');
    $buffer->write('example');
    ok(!$f->is_ready, 'not ready yet');
    $buffer->write(' text');
    ok(!$f->is_ready, 'not ready yet');
    $buffer->write(" here\x0D");
    ok(!$f->is_ready, 'not ready yet');
    $buffer->write("\x0A...");
    ok($f->is_ready, 'read when data already exists');
    is($f->get, "example text here\x0D\x0A", 'data is correct');
    ok(!$buffer->is_empty, 'still not empty');
    ok($buffer->read_atleast(1)->is_done, 'can read the rest');
    ok($buffer->is_empty, 'empty afterwards');
};

subtest 'read_packed' => sub {
    my $buffer = new_ok('Ryu::Buffer');
    {
        isa_ok(my $f = $buffer->read_packed("A4"), 'Future');
        ok(!$f->is_ready, 'not ready yet');
        $buffer->write('A');
        ok(!$f->is_ready, 'not ready yet');
        $buffer->write('B');
        ok(!$f->is_ready, 'not ready yet');
        $buffer->write('C');
        ok(!$f->is_ready, 'not ready yet');
        $buffer->write('D');
        ok($f->is_ready, 'is ready');
        is($f->get, 'ABCD', 'has expected data');
    }
    {
        isa_ok(my $f = $buffer->read_packed("A4"), 'Future');
        ok(!$f->is_ready, 'not ready yet');
        $buffer->write('XX  4321');
        ok($f->is_ready, 'is ready');
        # Spaces should be removed
        is($f->get, 'XX', 'has expected data');
        ok($buffer->read_atleast(1)->is_done, 'can read the rest');
        ok($buffer->is_empty, 'empty afterwards');
    }
    {
        isa_ok(my $f = $buffer->read_packed("n1"), 'Future');
        ok(!$f->is_ready, 'not ready yet');
        $buffer->write("\x12\x344321");
        ok($f->is_ready, 'is ready');
        is($f->get, 0x1234, 'has expected data');
    }
};

done_testing;

