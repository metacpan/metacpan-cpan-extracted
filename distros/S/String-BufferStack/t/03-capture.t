use warnings;
use strict;

use Test::More tests => 22;

use vars qw/$BUFFER $DEEPER/;

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
$DEEPER = "";
$stack->push(buffer => \$DEEPER);

# Another tacks onto $DEEPER
$stack->append(", and more");
is($stack->buffer, ", and more", "One step down, append doesn't go through");
is($stack->output_buffer, "Some string", "Output is different");
is($DEEPER, ", and more", "Append caught by lower level");
is($BUFFER, "", "Without flush, doesn't output");

# Pop it
$stack->pop;

# Rest of stack unchanged
is($stack->buffer, "Some string", "Back to as it was");
is($stack->output_buffer, "Some string", "As well");

# Push it again
$DEEPER = "";
$stack->push(buffer => \$DEEPER);
$stack->append(", again");
is($DEEPER, ", again", "Append has effect");
$stack->clear_top;
is($stack->output_buffer, "Some string", "Output buffer unchanged");
is($stack->buffer, "", "clear_top only affects top buffer");
is($DEEPER, "", "Referenced buffer is cleared");

# Write and try a flush
$stack->append(", again");
$stack->flush;
is($stack->output_buffer, "Some string", "With depth, flush is just filters");
is($BUFFER, "", "Hence no output seen");
$stack->flush_output;
is($stack->output_buffer, "", "flush_all pushes the output buffer");
is($stack->buffer, ", again", "But not non-output buffers");
is($DEEPER, ", again", "..nor their variables");
is($BUFFER, "Some string", "Output seen");
