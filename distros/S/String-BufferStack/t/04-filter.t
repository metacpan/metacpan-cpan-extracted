use warnings;
use strict;

use Test::More tests => 54;

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

# Add to the stack a no-op filter
$stack->push(filter => sub {return shift} );

# Without flush_filters, doesn't appear in output
$stack->append(", and more");
is($stack->buffer, "Some string", "Buffer is shared with output, nothing yet");
is($stack->output_buffer, "Some string", "Output is still there");
is($BUFFER, "", "Without flush, doesn't output");

# Flushing filters shoves it into buffer, and output
$stack->flush_filters;
is($stack->buffer, "Some string, and more", "Flushing filters gets to buffer");
is($stack->output_buffer, "Some string, and more", "Which is also output");
is($BUFFER, "", "..but not flushed");

# Pop it
$stack->pop;
is($stack->buffer, "Some string, and more", "Unchanged after pop");
is($stack->output_buffer, "Some string, and more", "Also output is");

# Add a upper-case filter
$stack->push(filter => sub {return uc shift} );
$stack->append(", now!");
is($stack->buffer, "Some string, and more", "Nothing yet");
is($stack->output_buffer, "Some string, and more", "Also nothing in output");
is($BUFFER, "", "Without flush, doesn't output");

# Flushing filters shoves it into buffer, and output
$stack->flush_filters;
is($stack->buffer, "Some string, and more, NOW!", "See upper-case filter output");
is($stack->output_buffer, "Some string, and more, NOW!", "Also in output");

# Popping flushes filters
$stack->append("  Whee!");
$stack->pop;
is($stack->buffer, "Some string, and more, NOW!  WHEE!", "See filter output");
is($stack->output_buffer, "Some string, and more, NOW!  WHEE!", "Also in output");
$stack->clear;

# Test clearing in the middle of everything
$stack->append("First ");
$stack->push(filter => sub {return ">>".shift(@_)."<<"} );
$stack->append("second");
$stack->clear;
is($stack->buffer, "", "Clear emptied it out");
$stack->append("third");
is($stack->buffer, "", "Still empty");
$stack->pop;
is($stack->buffer, ">>third<<", "See last append after clear");
$stack->clear;

# Repeated flushes don't call the filter
$stack->push(filter => sub {return ">>".shift(@_)."<<"} );
$stack->flush_filters;
is($stack->buffer, "", "No input, no output");
$stack->flush_filters;
is($stack->buffer, "", "Still no input, no output");
$stack->append("here");
is($stack->buffer, "", "Input, but not flushed");
$stack->flush_filters;
is($stack->buffer, ">>here<<", "Flushed once, get output");
$stack->flush_filters;
is($stack->buffer, ">>here<<", "Flushed again, no more");
$stack->append("");
is($stack->buffer, ">>here<<", "Appending nothing does nothing");
$stack->append(undef);
is($stack->buffer, ">>here<<", "Appending undef does nothing");
$stack->pop;
$stack->clear;


# Filter nesting!
$stack->push(filter => sub {return ">>".shift(@_)."<<"} );
$stack->append("first");
is($stack->buffer, "", "Nothing yet");
$stack->flush_filters;
is($stack->buffer, ">>first<<", "First filter output");
is($stack->output_buffer, ">>first<<", "Output buffer as well");
$stack->push(filter => sub {$_[0] =~ tr/a-z/b-za/; $_[0]} );
is($stack->buffer, "", "Nothing on the new buffer");
is($stack->output_buffer, ">>first<<", "Nothing more yet");
$stack->append("second");
is($stack->buffer, "", "Nothing on the new buffer");
is($stack->output_buffer, ">>first<<", "Nothing more yet");
$stack->filter;
is($stack->buffer, "tfdpoe", "Pushes output through");
is($stack->output_buffer, ">>first<<", "Output unchanged yet");
$stack->flush_filters;
is($stack->buffer, "", "Flushing all of them clears the buffer");
is($stack->output_buffer, ">>first<<>>tfdpoe<<", "And adds to output");
$stack->pop;
$stack->pop;
is($stack->buffer, ">>first<<>>tfdpoe<<", "Unchanged after pop");
is($stack->output_buffer, ">>first<<>>tfdpoe<<", "Also output");
$stack->append("verbatim");
is($stack->output_buffer, ">>first<<>>tfdpoe<<verbatim", "Top level has no filter");
$stack->filter;
is($stack->output_buffer, ">>first<<>>tfdpoe<<verbatim", "Filter does nothing with no stack");
$stack->clear;

## Modifying filters mid-runtime
$stack->push(filter => sub {return ">>".shift(@_)."<<"});
$stack->append("first");
$stack->flush;
is($stack->buffer, ">>first<<", "First filter output");
$stack->append("second");
is($stack->buffer, ">>first<<", "Without flush, no result yet");

# Unsetting filter
$stack->set_filter(undef);
is($stack->buffer, ">>first<<>>second<<", "Unsetting filter flushes");
$stack->append("third");
is($stack->buffer, ">>first<<>>second<<third", "No flush needed anymore");

# Keep it unset
$stack->set_filter(undef);
is($stack->buffer, ">>first<<>>second<<third", "No flush needed anymore");

# Setting to something else
$stack->set_filter(sub {return uc shift});
$stack->append("hi");
is($stack->buffer, ">>first<<>>second<<third", "No flush, no data");
$stack->set_filter(sub {return "(content)"});
is($stack->buffer, ">>first<<>>second<<thirdHI", "Changing does a flush");
$stack->append("This doesn't matter");
$stack->flush;
is($stack->buffer, ">>first<<>>second<<thirdHI(content)", "See new filter in action");
$stack->pop;
