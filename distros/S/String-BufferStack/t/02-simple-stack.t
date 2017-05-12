use warnings;
use strict;

use Test::More tests => 32;

use vars qw/$BUFFER/;

use_ok 'String::BufferStack';

my $stack = String::BufferStack->new( out_method => sub { $BUFFER .= join("", @_) });
ok($stack, "Made an object");
isa_ok($stack, 'String::BufferStack');

# Tests with no buffer stack
$BUFFER = "";
$stack->append("Some string");
is($stack->buffer, "Some string", "No stack, append goes through to output");
is($stack->output_buffer, "Some string", "Same as output buffer");
is($BUFFER, "", "Without flush, doesn't output");

# Add to the stack
is($stack->depth, 0, "Has no depth yet");
$stack->push;
is($stack->depth, 1, "Has a frame");

# Another append does exactly that
$stack->append(", and more");
is($stack->buffer, "Some string, and more", "One step down, append goes through to output");
is($stack->output_buffer, "Some string, and more", "Same as output buffer");
is($BUFFER, "", "Without flush, doesn't output");

# Pop it
is($stack->depth, 1, "Still has a frame");
$stack->pop;
is($stack->depth, 0, "No frames anymore");

# State is unchanged
is($stack->buffer, "Some string, and more", "One step down, append goes through to output");
is($stack->output_buffer, "Some string, and more", "Same as output buffer");
is($BUFFER, "", "Without flush, doesn't output");

# Flush the output
$stack->flush;
is($stack->buffer, "", "Flush clears output");
is($stack->output_buffer, "", "Also output buffer");
is($BUFFER, "Some string, and more", "Flush moved to output");

# Popping again does nothing
is($stack->pop, undef, "Popping again returns undef");
is($stack->depth, 0, "And leaves depth unchanged");
is($stack->buffer, "", "Buffer is still empty");
is($stack->output_buffer, "", "Also output buffer");

# Nested pushes do the right thing
$stack->push;
$stack->push;
$stack->append("Nested");
is($stack->buffer, "Nested", "Nested append");
is($stack->output_buffer, "Nested", "Nested append carried through to output");
is($stack->pop, "Nested", "Popping produces correct content");
is($stack->buffer, "Nested", "Nested append");
is($stack->output_buffer, "Nested", "Nested append carried through to output");
is($stack->pop, "Nested", "Popping produces correct content");
is($stack->buffer, "Nested", "Nested append");
is($stack->output_buffer, "Nested", "Nested append carried through to output");
is($stack->pop, undef, "Too many pops returns undef");
