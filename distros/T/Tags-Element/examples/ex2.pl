#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Element qw(element);
use Tags::Output::Raw;

# Get example element.
my @tags = element('div', {
        'id' => 'foo',
        'class' => 'bar',
}, 'Foo', 'Bar');

# Serialize by Tags.
my $tags = Tags::Output::Raw->new;
$tags->put(@tags);
print $tags->flush."\n";

# Output.
# <div class="bar" id="foo">FooBar</div>