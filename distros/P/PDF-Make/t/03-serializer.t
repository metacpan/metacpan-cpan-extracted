#!perl
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('PDF::Make::Writer') }

# Test constructor
{
    my $writer = PDF::Make::Writer->new;
    ok($writer, 'new() creates a writer');
    isa_ok($writer, 'PDF::Make::Writer');
    is($writer->len, 0, 'new writer has zero length');
}

# Test write with undef (null)
{
    my $writer = PDF::Make::Writer->new;
    my $result = $writer->write(undef);
    is($result, $writer, 'write() returns self for chaining');
    my $bytes = $writer->to_bytes;
    is($bytes, 'null', 'undef serializes to "null"');
}

# Test write with integers
{
    my $writer = PDF::Make::Writer->new;
    $writer->write(42);
    is($writer->to_bytes, '42', 'integer 42 serializes correctly');
}

{
    my $writer = PDF::Make::Writer->new;
    $writer->write(0);
    is($writer->to_bytes, '0', 'integer 0 serializes correctly');
}

{
    my $writer = PDF::Make::Writer->new;
    $writer->write(-123);
    is($writer->to_bytes, '-123', 'negative integer serializes correctly');
}

# Test write with floats
{
    my $writer = PDF::Make::Writer->new;
    $writer->write(1.5);
    my $bytes = $writer->to_bytes;
    like($bytes, qr/^1\.5?0*$/, 'float 1.5 serializes correctly');
}

{
    my $writer = PDF::Make::Writer->new;
    $writer->write(42.0);
    my $bytes = $writer->to_bytes;
    is($bytes, '42', 'integer-valued float serializes without decimal');
}

# Test method chaining
{
    my $writer = PDF::Make::Writer->new;
    $writer->write(1)->write(2)->write(3);
    is($writer->to_bytes, '123', 'method chaining works');
}

# Test to_bytes resets buffer
{
    my $writer = PDF::Make::Writer->new;
    $writer->write(42);
    my $bytes1 = $writer->to_bytes;
    is($bytes1, '42', 'first to_bytes returns content');
    is($writer->len, 0, 'buffer is reset after to_bytes');
    
    $writer->write(99);
    my $bytes2 = $writer->to_bytes;
    is($bytes2, '99', 'writer can be reused after to_bytes');
}

# Test len accessor
{
    my $writer = PDF::Make::Writer->new;
    is($writer->len, 0, 'initial length is 0');
    
    $writer->write(12345);
    is($writer->len, 5, 'length after writing "12345" is 5');
    
    $writer->write(6789);
    is($writer->len, 9, 'length after adding "6789" is 9');
}

# Test buf accessor (basic)
{
    my $writer = PDF::Make::Writer->new;
    my $ptr = $writer->buf;
    ok(defined $ptr, 'buf() returns a defined value');
}

# Test DESTROY (implicit via scope)
{
    my $writer = PDF::Make::Writer->new;
    $writer->write(42);
    # Writer goes out of scope here; should not crash
}
pass('DESTROY does not crash');

# Test multiple writes
{
    my $writer = PDF::Make::Writer->new;
    for my $i (1..100) {
        $writer->write($i);
    }
    my $bytes = $writer->to_bytes;
    ok(length($bytes) > 100, 'multiple writes accumulate');
    like($bytes, qr/^1/, 'starts with 1');
    like($bytes, qr/100$/, 'ends with 100');
}

done_testing();
