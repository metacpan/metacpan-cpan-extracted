#
# Tests for nested lists
#

use strict;
use warnings;

use Test::More tests => 12;
use Template::Flute;

my ($spec, $html, $flute, $out, $attributes);

$spec = q{<specification>
<list name="attributes" iterator="attributes">
<param name="value" field="title"/>
<list name="values" class="values" iterator="attribute_values">
<param name="value" class="attribute_value"/>
<param name="title" class="attribute_title"/>
</list>
</list>
</specification>
};

$html = q{<html>
<ul><li class="attributes"><span class="value">Name</span>
<ul><li class="values"><span class="attribute_title">Title</span></li>
</li></ul>
</html>
};

$attributes = [{name => 'color', title => 'Color',
                attribute_values =>
                [{value => 'red', title => 'Red'},
                 {value => 'white', title => 'White'},
                 {value => 'yellow', title => 'Yellow'},
                ]},
               {name => 'size', title => 'Size',
                attribute_values =>
                [{value => 'small', title => 'S'},
                 {value => 'large', title => 'L'},
                ]},
               ];

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {attributes => $attributes},
                              );

$out = $flute->process;

# match attributes
my @attr_matches = ($out =~ m%<li class="attributes"><span class="value">(\w+)</span>%g);

ok (@attr_matches == 2, "Number of toplevel elements")
    || diag "Matches: ", scalar(@attr_matches);

ok ($attr_matches[0] eq 'Color' && $attr_matches[1] eq 'Size',
    "Title of toplevel elements")
    || diag "Matches: $attr_matches[0] $attr_matches[1]";

# match attribute values
my @attr_value_matches = ($out =~ m%<li class="values"><span class="attribute_title">(\w+)</span></li>%g);

ok (@attr_value_matches == 5, "Number of second level elements")
    || diag "Matches: ", scalar(@attr_value_matches);

is_deeply(\@attr_value_matches, ['Red', 'White', 'Yellow', 'S', 'L'],
          "Title of second level elements")
    || diag "Matches: $attr_matches[0] $attr_matches[1]";

# different HTML
$html = q{<html>
<ul><li class="attributes"><span class="value">Name</span>
<ul><li class="values attribute_title">Title</li>
</li></ul>
</html>
};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {attributes => $attributes},
                              );

$out = $flute->process;

# match attributes
@attr_matches = ($out =~ m%<li class="attributes"><span class="value">(\w+)</span>%g);

ok (@attr_matches == 2, "Number of toplevel elements")
    || diag "Matches: ", scalar(@attr_matches);

ok ($attr_matches[0] eq 'Color' && $attr_matches[1] eq 'Size',
    "Title of toplevel elements")
    || diag "Matches: $attr_matches[0] $attr_matches[1]";

# match attribute values
@attr_value_matches = ($out =~ m%<li class="values attribute_title">(\w+)</li>%g);

ok (@attr_value_matches == 5, "Number of second level elements")
    || diag "Matches: ", scalar(@attr_value_matches);

is_deeply(\@attr_value_matches, ['Red', 'White', 'Yellow', 'S', 'L'],
          "Title of second level elements")
    || diag "Matches: $attr_matches[0] $attr_matches[1]";

$spec = q{<specification>
<list name="attributes" iterator="attributes">
<param name="value" field="title"/>
<list name="values" class="values" iterator="attribute_values">
<param name="values" class="attributes-value" field="value" target="value"/>
<param name="attributes-value" field="title"/>
</list>
</list>
</specification>
};

$html = q{<html><ul class="product-attributes-list">
<li class="attributes">
  <span class="value">Attribute</span>
  <ul>
    <li>
      <select>
        <option class="values attributes-value">Value</option>
      </select>
    </li>
  </ul>
</li>
</ul>
</html>
};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {attributes => $attributes},
                              );

$out = $flute->process;


# match attributes
@attr_matches = ($out =~ m%<li class="attributes"><span class="value">(\w+)</span>%g);

ok (@attr_matches == 2, "Number of toplevel elements")
    || diag "Matches: ", scalar(@attr_matches);

ok ($attr_matches[0] eq 'Color' && $attr_matches[1] eq 'Size',
    "Title of toplevel elements")
    || diag "Matches: $attr_matches[0] $attr_matches[1]";

# match attribute values
@attr_value_matches = ($out =~ m%<option class="values attributes-value" value="(\w+)">(\w+)</option>%g);

ok (@attr_value_matches == 10, "Number of second level elements")
    || diag "Matches: ", scalar(@attr_value_matches);

is_deeply(\@attr_value_matches, ['red' => 'Red',
                                 'white' => 'White',
                                 'yellow' => 'Yellow',
                                 'small' => 'S',
                                 'large' => 'L',
                             ],
          "Title of second level elements")
    || diag "Matches: $attr_matches[0] $attr_matches[1]";
