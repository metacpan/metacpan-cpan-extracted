#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Data::HTML::Element::Form;
use Tags::HTML::Element::Form;
use Tags::Output::Indent;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new;
my %p = (
        'css' => $css,
        'tags' => $tags,
);
my $obj = Tags::HTML::Element::Form->new(%p);

my $form = Data::HTML::Element::Form->new(
        'css_class' => 'form',
        'data' => [
                ['b', 'p'],
                ['b', 'button'],
                ['a', 'type', 'submit'],
                ['d', 'Save'],
                ['e', 'button'],
                ['e', 'p'],
        ],
        'data_type' => 'tags',
        'label' => 'Form for submit',
);

# Initialize.
$obj->init($form);

# Process form.
$obj->process;
$obj->process_css;

# Print out.
print $tags->flush;
print "\n\n";
print $css->flush;

# Output:
# <form class="form" method="get">
#   <fieldset>
#     <legend>
#       Form for submit
#     </legend>
#     <p>
#       <button type="submit">
#         Save
#       </button>
#     </p>
#   </fieldset>
# </form>
# 
# .form {
#         border-radius: 5px;
#         background-color: #f2f2f2;
#         padding: 20px;
# }
# .form fieldset {
#         padding: 20px;
#         border-radius: 15px;
# }
# .form legend {
#         padding-left: 10px;
#         padding-right: 10px;
# }