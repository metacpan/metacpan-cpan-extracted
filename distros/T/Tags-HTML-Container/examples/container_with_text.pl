#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Tags::HTML::Container;
use Tags::Output::Indent;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new;
my $obj = Tags::HTML::Container->new(
        'css' => $css,
        'tags' => $tags,
);

# Process container with text.
$obj->process(sub {
        my $self = shift;
        $self->{'tags'}->put(
                ['d', 'Hello World!'],
        );
        return;
});
$obj->process_css;

# Print out.
print $tags->flush;
print "\n\n";
print $css->flush;

# Output:
# <div class="container">
#   <div class="inner">
#     Hello World!
#   </div>
# </div>
# 
# .container {
#         display: flex;
#         align-items: center;
#         justify-content: center;
#         height: 100vh;
# }