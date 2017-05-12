use warnings;
use strict;

use Test::More tests => 35;

use vars qw/$BUFFER/;
$BUFFER = "";

use_ok 'String::BufferStack';

# Test printing to STDOUT
my $stack = String::BufferStack->new;
ok($stack, "Made an object");
isa_ok($stack, 'String::BufferStack');
SKIP: {
    skip "Perl 5.6 doesn't support three arg open to a string", 2
        unless $] >= 5.008;
    open my $output, '>>', \$BUFFER;
    local *STDOUT = $output;
    $stack->append("Content");
    is($BUFFER, "", "No output after append");
    $stack->flush;
    is($BUFFER, "Content", "Saw content on STDOUT");
}

# Tests with no buffer stack
$stack = String::BufferStack->new( out_method => sub { $BUFFER .= join("", @_) });
$BUFFER = "";
$stack->append("Some string");
is($stack->buffer, "Some string", "No stack, append goes through to output");
is($stack->output_buffer, "Some string", "Same as output buffer");
is($BUFFER, "", "Without flush, doesn't output");

# Another append does exactly that
$stack->append(", and more");
is($stack->buffer, "Some string, and more", "No stack, append goes through to output");
is($stack->output_buffer, "Some string, and more", "Same as output buffer");
is($BUFFER, "", "Without flush, doesn't output");

# Can inspect and modify the output buffer
isa_ok($stack->output_buffer_ref, "SCALAR", "Output ref is a ref to a scalar");
is(${$stack->output_buffer_ref}, "Some string, and more", "Dereferencing shows content");
${$stack->output_buffer_ref} = "Moose";
is(${$stack->output_buffer_ref}, "Moose", "Altering it changes output ref, deref'd");
is($stack->output_buffer, "Moose", "Altering it changes output itself");
is($stack->buffer, "Moose", "Also top buffer");

# Flush the output
$stack->flush;
is($stack->buffer, "", "Flush clears output");
is($stack->output_buffer, "", "Also output buffer");
is($BUFFER, "Moose", "Flush moved to output");

# Ensure no saved state
$BUFFER = "";
$stack->append("More");
is($stack->buffer, "More", "Append after flush goes through");
is($stack->output_buffer, "More", "Same as output buffer");
is($BUFFER, "", "Without flush, doesn't output");
$stack->flush;
is($stack->buffer, "", "Flush clears output");
is($stack->output_buffer, "", "Also output buffer");
is($BUFFER, "More", "Flush moved to output");

# Clear 
$BUFFER = "";
$stack->append("Never seen");
is($stack->buffer, "Never seen", "See the append");
is($stack->output_buffer, "Never seen", "Same as output buffer");
$stack->clear;
is($stack->buffer, "", "Clear empties the buffers");
is($stack->output_buffer, "", "output buffer as well");
$stack->flush;
is($BUFFER, "", "No buffers, no output after flush");

# Clear top is same, with no capture
$stack->append("Never seen");
is($stack->buffer, "Never seen", "See the append");
is($stack->output_buffer, "Never seen", "Same as output buffer");
$stack->clear_top;
is($stack->buffer, "", "Clear empties the buffers");
is($stack->output_buffer, "", "output buffer as well");
$stack->flush;
is($BUFFER, "", "No buffers, no output after flush");
