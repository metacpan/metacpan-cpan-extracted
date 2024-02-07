#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Data::HTML::Element::Button;
use Data::HTML::Element::Input;
use Tags::HTML::Element::Form::Items;
use Tags::Output::Indent;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new;
my $obj = Tags::HTML::Element::Form::Items->new(
        'css' => $css,
        'tags' => $tags,
);

my $input = Data::HTML::Element::Input->new(
        'css_class' => 'input',
        'id' => 'one',
        'label' => 'Input field',
);

my $submit = Data::HTML::Element::Button->new(
        'css_class' => 'submit',
        'data' => ['Save'],
        'type' => 'submit',
);

# Initialize.
$obj->init($input, $submit);

# Process form.
$obj->process;
$obj->process_css;

# Print out.
print $tags->flush;
print "\n\n";
print $css->flush;

# Output:
# TODO