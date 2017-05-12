# Dropdown tests for values.

use strict;
use warnings;

use Test::More tests => 4;
use Template::Flute;

my ($spec, $html, @colors, $flute, $out);

$spec = q{<specification>
<value name="test" iterator="colors"/>
</specification>
};

$html = q{<html><select class="test"></select></html>};

@colors = ({value => 'red'}, {value => 'black'});

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              iterators => {colors => \@colors},
                              values => {colors => \@colors},
                             );

$out = $flute->process();

ok ($out =~ m%<option>red</option><option>black</option>%,
    "Test value with HTML dropdown.")
    || diag "HTML: $out.\n";


$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              iterators => {colors => \@colors},
                              values => {colors => \@colors, test => 'black'},
                             );

$out = $flute->process();

ok ($out =~ m%<option>red</option><option selected="selected">black</option>%,
    "Test value with HTML dropdown and selected value.")
    || diag "HTML: $out.\n";

@colors = ({value => 'red', label => 'Red'},
           {value => 'black', label => 'Black'},
          );

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              iterators => {colors => \@colors},
                             );

$out = $flute->process();

ok ($out =~ m%<option value="red">Red</option><option value="black">Black</option>%,
    "Test value with HTML dropdown and labels.")
    || diag "HTML: $out.\n";


$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              iterators => {colors => \@colors},
                              values => {test => 'black'},
                             );

$out = $flute->process();

ok ($out =~ m%<option value="red">Red</option><option selected="selected" value="black">Black</option>%,
    "Test value with HTML dropdown, labels and selected value.")
    || diag "HTML: $out.\n";
