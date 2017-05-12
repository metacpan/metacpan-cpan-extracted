# Dropdown tests for values.

use strict;
use warnings;

use Test::More tests => 5;
use Template::Flute;

my ($spec, $html, @colors, $flute, $out);

$spec = q{<specification>
<value name="test" iterator="colors" iterator_value_key="code" iterator_name_key="name"/>
</specification>
};

$html = q{<html><select class="test"></select></html>};

@colors = ({code => 'red'},
           {code => 'black'});

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              iterators => { colors => \@colors },
                             );

$out = $flute->process();

ok ($out =~ m%<option>red</option><option>black</option>%,
    "Test value with HTML dropdown.")
    || diag "HTML: $out.\n";


$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              iterators => { colors => \@colors },
                              values => { test => 'black' },
                             );

$out = $flute->process();

ok ($out =~ m%<option>red</option><option selected="selected">black</option>%,
    "Test value with HTML dropdown and selected value.")
    || diag "HTML: $out.\n";

@colors = ({code => 'red', name => 'Red'},
           {code => 'black', name => 'Black'},
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


$spec =<<'SPEC';
<specification>
  <value name="color" iterator="colors"
         iterator_value_key="code" iterator_name_key="name"/>
</specification>
SPEC

$html =<<'HTML';
<html>
 <select class="color">
 <option value="example">Example</option>
 </select>
</html>
HTML

@colors = ({code => 'red', name => 'Red'},
           {code => 'black', name => 'Black'},
          );

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              iterators => {colors => \@colors},
                              values => { color => 'black' },
                             );

$out = $flute->process();
my $expected =<<'HTML';
<select class="color">
<option value="red">Red</option>
<option selected="selected" value="black">Black</option>
</select></body>
HTML

$expected =~ s/\n//g;

ok($out =~ m/\Q$expected\E/, "doc example ok") || diag $out;

print $out, "\n";

