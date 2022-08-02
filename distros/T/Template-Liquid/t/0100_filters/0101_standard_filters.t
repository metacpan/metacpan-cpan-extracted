use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Template::Liquid;
use Config;        # issue #9
$|++;

# abs
is(Template::Liquid->parse(q[{{ 4 | abs }} {{ -4 | abs }}])->render(),
    '4 4', q[{{ 4 | abs }} {{ -4 | abs }} => 4 4]);

# append
is( Template::Liquid->parse(q[{{ 'foo' | append:'bar' }}])->render(),
    'foobar',
    q[{{ 'foo' | append:'bar' }} => 'foobar']
);

# at_least - minimums
is(Template::Liquid->parse(q[{{ 4 | at_least: 5 }}])->render(),
    '5', q[{{ 4 | at_least: 5 }} => '5']);
is(Template::Liquid->parse(q[{{ 4 | at_least: 3 }}])->render(),
    '4', q[{{ 4 | at_least: 3 }} => '4']);

# at_most - maximum
is(Template::Liquid->parse(q[{{ 4 | at_most: 5 }}])->render(),
    '4', q[{{ 4 | at_most: 5 }} => '4']);
is(Template::Liquid->parse(q[{{ 4 | at_most: 3 }}])->render(),
    '3', q[{{ 4 | at_mostt: 3 }} => '3']);

# capitalize
is( Template::Liquid->parse(q[{{'this is a QUICK test.'| capitalize}}])
        ->render(),
    'This is a quick test.',
    q[{{'this is a QUICK test.'|capitalize}} => This is a quick test.]
);
is(Template::Liquid->parse(q[{{ "title" | capitalize }}])->render(),
    'Title', q[{{ "title" | capitalize }} => Title]);
is( Template::Liquid->parse(q[{{ "my great title" | capitalize }}])->render(),
    'My great title',
    q[{{ "my great title" | capitalize }} => My great title]
);

# ceil
is(Template::Liquid->parse(q[{{ 1.2 | ceil }}])->render(),
    '2', q[{{ 1.2 | ceil }} => 2]);
is(Template::Liquid->parse(q[{{ 2.0 | ceil }}])->render(),
    '2', q[{{ 2.0 | ceil }} => 2]);
is(Template::Liquid->parse(q[{{ 183.357 | ceil }}])->render(),
    '184', q[{{ 183.357 | ceil }} => 184]);
is(Template::Liquid->parse(q[{{ "3.5" | ceil }}])->render(),
    '4', q[{{ "3.5" | ceil }} => 4]);

# compact
is( Template::Liquid->parse(
        <<'END'
{%- assign site_categories = site.pages | map: "category" | compact -%}
{%- for category in site_categories %}
- {{ category }}
{%- endfor -%}
END
    )->render(    site => {pages => [{category => 'business'},
                                     {category => 'celebrities'},
                                     {},
                                     {category => 'lifestyle'},
                                     {category => 'sports'},
                                     {},
                                     {category => 'technology'}
                           ]
                  }
    ),
    "\n- business\n- celebrities\n- lifestyle\n- sports\n- technology",
    '{% assign all_categories = site.pages | map: "category" | compact %} where site.pages is a hash with missing values'
);

# concat
is( Template::Liquid->parse(
                <<'IN')->render(), <<'OUT', q[concat one array onto another]);
{%- assign fruits = "apples, oranges, peaches" | split: ", " -%}
{%- assign vegetables = "carrots, turnips, potatoes" | split: ", " -%}

{%- assign everything = fruits | concat: vegetables -%}

{%- for item in everything -%}
- {{ item }}
{% endfor -%}
IN
- apples
- oranges
- peaches
- carrots
- turnips
- potatoes
OUT
is( Template::Liquid->parse(
               <<'IN')->render(), <<'OUT', q[concat multiple arrays at once]);
{%- assign furniture = "chairs, tables, shelves" | split: ", " -%}
{%- assign vegetables = "carrots, turnips, potatoes" | split: ", " -%}
{%- assign fruits = "apples, oranges, peaches" | split: ", " -%}

{%- assign everything = fruits | concat: vegetables | concat: furniture -%}

{%- for item in everything -%}
- {{ item }}
{% endfor -%}
IN
- apples
- oranges
- peaches
- carrots
- turnips
- potatoes
- chairs
- tables
- shelves
OUT

# date
SKIP: {
    skip 'Cannot load DateTime module', 1 unless eval { require DateTime };
    is( Template::Liquid->parse('{{date|date:"%Y"}}')
            ->render(date => DateTime->from_epoch(epoch => 0)),
        1970,
        '{{date|date:"%Y"}} => 1970 (DateTime)'
    );
}
SKIP: {
    skip 'Cannot load DateTimeX::Lite module', 1
        unless eval { require DateTimeX::Lite; };
    is( Template::Liquid->parse(
                               '{{date|date:"%Y"}}',
                               date => DateTimeX::Lite->from_epoch(epoch => 0)
        ),
        1970,
        '{{date|date:"%Y"}} => 2009 (DateTimeX::Lite)'
    );
}
TODO: {
    local $TODO = q[Not important enough to worry about I18N];
    is( Template::Liquid->parse('{{date | date:"%a, %b %d, %Y"}}')
            ->render(date => gmtime(0)),
        'Thu, Jan 01, 1970',
        '{{date | date:"%a, %b %d, %Y"}} => Thu, Jan 01, 1970'
    );
}
is( Template::Liquid->parse('{{date|date:"%Y"}}')->render(date => gmtime(0)),
    1970,
    '{{date|date:"%Y"}} => 1970 (int)'
);
is(Template::Liquid->parse(q[{{ 'now'|date:"%Y"}}])->render(),
    1900 + [localtime()]->[5],
    q[{{ 'now'| date:"%Y"}}]);
is(Template::Liquid->parse(q[{{ 'TODAY'|date:"%Y"}}])->render(),
    1900 + [localtime()]->[5],
    q[{{ 'TODAY'| date:"%Y"}}]);
is(Template::Liquid->parse(q[{{ 'today' |date:"%Y"}}])->render(),
    1900 + [localtime()]->[5],
    q[{{ 'today'| date:"%Y"}}]);
TODO: {
    local $TODO = q[Not important enough to worry about I18N];
    is( Template::Liquid->parse(
                     q[{{ "March 14, 2016" | date: "%b %d, %y" }}])->render(),
        'Mar 14, 16',
        q[{{ "March 14, 2016" | date: "%b %d, %y" }}]
    );
}

# default
is( Template::Liquid->parse(
        q[{{ fun | default:"wow!" }} {{ Key | default:"wow!" }} {{ Zero | default:"empty" }} {{ One | default:"another one" }}]
    )->render(Key => 'Value', Zero => '', One => ' '),
    'wow! Value empty  ',
    q[{{ fun | default:"wow!" }} {{ Key | default:"wow!" }} {{ Zero | default:"empty" }} {{ One | default:"another one" }} => wow! Value empty  ]
);
is( Template::Liquid->parse('{{ product_price | default: 2.99 }}')->render(),
    2.99, '{{ product_price | default: 2.99 }}'
);
is( Template::Liquid->parse(
        '{% assign product_price = 4.99 %}{{ product_price | default: 2.99 }}'
    )->render(),
    4.99,
    '{{ 4.99 | default: 2.99 }}'
);
is( Template::Liquid->parse(
         '{% assign product_price = "" %}{{ product_price | default: 2.99 }}')
        ->render(),
    2.99,
    '{{ "" | default: 2.99 }}'
);

# divided_by
is(Template::Liquid->parse(q[{{ 16 | divided_by: 4 }}])->render(),
    4, q[{{ 16 | divided_by: 4 }} => 4]);
is(Template::Liquid->parse(q[{{ 5 | divided_by: 3 }}])->render(),
    1, q[{{ 5 | divided_by: 3 }} => 1]);
is(Template::Liquid->parse(q[{{ 20 | divided_by: 7 }}])->render(),
    2, q[{{ 20 | divided_by: 7 }} => 2]);
is( Template::Liquid->parse(q[{{ 20 | divided_by: 7.0 }}])->render(),
    ($Config{uselongdouble} ? '2.85714285714285714' : 2.85714285714286),
    q[{{ 20 | divided_by: 7.0 }} => 2.85714285714286...]
);
is( Template::Liquid->parse(
              q[{% assign my_integer = 7 %}{{ 20 | divided_by: my_integer }}])
        ->render(),
    2,
    q[{{ 20 | divided_by: my_integer }} => 2]
);
is( Template::Liquid->parse(
        q[{% assign my_integer = 7 %}{% assign my_float = my_integer | times: 1.0 %}{{ 20 | divided_by: my_float }}]
    )->render(),
    ($Config{uselongdouble} ? '2.85714285714285714' : 2.85714285714286),
    q[{{ 20 | divided_by: my_float }} => 2.85714285714286...]
);

# downcase
is( Template::Liquid->parse(q[{{'This is a QUICK test.'|downcase }}])
        ->render(),
    'this is a quick test.',
    q[{{'This is a QUICK test.'|downcase }} => this is a quick test.]
);
is( Template::Liquid->parse(q[{{ "Parker Moore" | downcase }}])->render(),
    'parker moore',
    q[{{ "Parker Moore" | downcase }} => parker moore]
);
is(Template::Liquid->parse(q[{{ "apple" | downcase }}])->render(),
    'apple', q[{{ "apple" | downcase }} => apple]);

# escape
is( Template::Liquid->parse(
                 q[{{ "Have you read 'James & the Giant Peach'?" | escape }}])
        ->render(),
    'Have you read &#39;James &amp; the Giant Peach&#39;?',
    q[{{ "Have you read 'James & the Giant Peach'?" | escape }}]
);
is( Template::Liquid->parse(q[{{ "Tetsuro Takara" | escape }}])->render(),
    'Tetsuro Takara',
    q[{{ "Tetsuro Takara" | escape }} => Tetsuro Takara]
);

# escape_once
is( Template::Liquid->parse(q[{{ "1 < 2 & 3" | escape_once }}])->render(),
    '1 &lt; 2 &amp; 3',
    q[{{ "1 < 2 & 3" | escape_once }} => 1 &lt; 2 &amp; 3]
);
is( Template::Liquid->parse(q[{{ "1 &lt; 2 &amp; 3" | escape_once }}])
        ->render(),
    '1 &lt; 2 &amp; 3',
    q[{{ "1 &lt; 2 &amp; 3" | escape_once }} => 1 &lt; 2 &amp; 3]
);

# first
is( Template::Liquid->parse(
                 q[{{ "Ground control to Major Tom." | split: " " | first }}])
        ->render(),
    'Ground',
    q[{{ "Ground control to Major Tom." | split: " " | first }} => Ground]
);
is( Template::Liquid->parse(
        q[{% assign my_array = "zebra, octopus, giraffe, tiger" | split: ", " %}{{ my_array.first }}]
    )->render(),
    'zebra',
    q[{% assign my_array = "zebra, octopus, giraffe, tiger" | split: ", " %}{{ my_array.first }} => zebra]
);
is(Template::Liquid->parse(q[{{ str | first}}])->render(str => 'string'),
    's', '{{ str | first }} => s');

# floor
is(Template::Liquid->parse(q[{{ 1.2 | floor }}])->render(),
    '1', q[{{ 1.2 | floor }}]);
is(Template::Liquid->parse(q[{{ 2.0 | floor }}])->render(),
    '2', q[{{ 2.0 | floor }}]);
is(Template::Liquid->parse(q[{{ 183.357 | floor }}])->render(),
    '183', q[{{ 183.357 | floor }}]);
is(Template::Liquid->parse(q[{{ "3.5" | floor }}])->render(),
    '3', q[{{ "3.5" | floor }}]);

# join
is( Template::Liquid->parse(
        q[{% assign beatles = "John, Paul, George, Ringo" | split: ", " %}{{ beatles | join: " and " }}]
    )->render(),
    'John and Paul and George and Ringo',
    q[{{ beatles | join: " and " }} => John and Pau and George and Ringo]
);

# last
is( Template::Liquid->parse(
                  q[{{ "Ground control to Major Tom." | split: " " | last }}])
        ->render(),
    'Tom.',
    q[{{ "Ground control to Major Tom." | split: " " | last }} => Tom.]
);
is( Template::Liquid->parse(
        q[{% assign my_array = "zebra, octopus, giraffe, tiger" | split: ", " %}{{ my_array.last }}]
    )->render(),
    'tiger',
    q[{% assign my_array = "zebra, octopus, giraffe, tiger" | split: ", " %}{{ my_array.last }} => tiger]
);
note 'For these next few tests, C<array> is defined as C<[1 .. 6]>';
is( Template::Liquid->parse(q[{{array | first}}])->render(array => [1 .. 6]),
    '1',
    '{{array | first}} => 1'
);

# join
is( Template::Liquid->parse(q[{{array | join: " " }}])
        ->render(array => [1 .. 6]),
    '1 2 3 4 5 6',
    '{{array | join: " " }} => 1 2 3 4 5 6'
);
is( Template::Liquid->parse(q[{{array | join:', '}}])
        ->render(array => [1 .. 6]),
    '1, 2, 3, 4, 5, 6',
    q[{{array | join:', ' }} => 1, 2, 3, 4, 5, 6]
);

# last
is(Template::Liquid->parse(q[{{array | last}}])->render(array => [1 .. 6]),
    '6', '{{array | last }} => 6');
is(Template::Liquid->parse(q[{{ str | last}}])->render(str => 'string'),
    'g', '{{ str | last }} => g');

# lstrip
is( Template::Liquid->parse(
         q[{{ "          So much room for activities!          " | lstrip }}])
        ->render(),
    'So much room for activities!          ',
    q[{{ "          So much room for activities!          " | lstrip }} => So much room for activities!          ]
);

# map
is( Template::Liquid->parse(
        <<'END'
{%- assign site_categories = site.pages | map: "category" -%}
{%- for category in site_categories %}
- {{ category }}
{%- endfor -%}
END
    )->render(    site => {pages => [{category => 'business'},
                                     {category => 'celebrities'},
                                     {category => 'lifestyle'},
                                     {category => 'sports'},
                                     {category => 'technology'}
                           ]
                  }
    ),
    "\n- business\n- celebrities\n- lifestyle\n- sports\n- technology",
    '{% assign all_categories = site.pages | map: "category" %} where site.pages is a hash'
);
is( Template::Liquid->parse(
        <<'END'
{%- assign site_categories = site.pages | map: "category" -%}
{%- for category in site_categories %}
- {{ category }}
{%- endfor -%}
END
    )->render(    site => {pages => [{category => 'business'},
                                     {category => 'celebrities'},
                                     {},
                                     {category => 'lifestyle'},
                                     {category => 'sports'},
                                     {},
                                     {category => 'technology'}
                           ]
                  }
    ),
    "\n- business\n- celebrities\n- \n- lifestyle\n- sports\n- \n- technology",
    '{% assign all_categories = site.pages | map: "category" %} where site.pages is a hash with missing values'
);
is( Template::Liquid->parse(
        <<'END'
{%- assign collection_titles = collections | map: 'title' -%}
{{- collection_titles -}}
END
    )->render(    collections => [{title => 'Spring'},
                                  {title => 'Summer'},
                                  {title => 'Fall'},
                                  {title => 'Winter'}
                  ]
    ),
    "SpringSummerFallWinter",
    '{% assign collection_titles = collections | map: "title" %} => SpringSummerFallWinter'
);

# minus
is(Template::Liquid->parse(q[{{ 4|minus:2 }}])->render(),
    '2', q[{{ 4|minus:2 }} => 2]);
is(Template::Liquid->parse(q[{{ 16 | minus: 4 }}])->render(),
    '12', q[{{ 16 | minus: 4 }} => 12]);
is( Template::Liquid->parse(q[{{ 183.357 | minus: 12 }}])->render(),
    '171.357',
    q[{{ 183.357 | minus: 12 }} => 171.357]
);
is(Template::Liquid->parse(q[{{ 'Test'|minus:2 }}])->render(),
    '', q[{{ 'Test'|minus:2 }} => ]);
is(Template::Liquid->parse(q[{{ 4.3|minus:2.5 }}])->render(),
    '1.8', q[{{ 4.3|minus:2.5 }} => 1.8]);
is(Template::Liquid->parse(q[{{ -4|minus:2 }}])->render(),
    '-6', q[{{ -4|minus:2 }} => -6]);

# modulo
is(Template::Liquid->parse(q[{{ 3 | modulo: 2 }}])->render(),
    '1', q[{{ 3 | modulo: 2 }} => 1]);
is(Template::Liquid->parse(q[{{ 24 | modulo: 7 }}])->render(),
    '3', q[{{ 24 | modulo: 7 }} => 3]);
is(Template::Liquid->parse(q[{{ 183.357 | modulo: 12 }}])->render(),
    '3.357', q[{{ 183.357 | modulo: 12 }} => 3.357]);

# newline_to_br
is( Template::Liquid->parse(
        <<'IN')->render(), <<'OUT', q[{{ string_with_newlines | newline_to_br }}]);
{% capture string_with_newlines %}
Hello
there
{% endcapture %}

{{ string_with_newlines | newline_to_br }}
IN


<br />
Hello<br />
there<br />

OUT
is( Template::Liquid->parse('{{multiline|newline_to_br}}')
        ->render(multiline => qq[This\n is\n a\n test.]),
    qq[This<br />\n is<br />\n a<br />\n test.],
    qq[{{multiline|newline_to_br}} => This<br />\n is<br />\n a<br />\n test.]
);

# plus
is(Template::Liquid->parse(q[{{ 4 | plus: 2 }}])->render(),
    '6', q[{{ 4 | plus: 2 }} => 1337]);
is(Template::Liquid->parse(q[{{ 16 | plus: 4 }}])->render(),
    '20', q[{{ 16 | plus: 4 }} => 20]);
is(Template::Liquid->parse(q[{{ 183.357 | plus:12 }}])->render(),
    '195.357', q[{{ 183.357 | plus:12 }} => 195.357]);
is(Template::Liquid->parse(q[{{ 154| plus:1183 }}])->render(),
    '1337', q[{{ 154| plus:1183 }} => 1337]);
is(Template::Liquid->parse(q[{{ 15.4| plus:11.83 }}])->render(),
    '27.23', q[{{ 15.4| plus:11.83 }} => 27.23]);
is(Template::Liquid->parse(q[{{ 15| plus:-11 }}])->render(),
    '4', q[{{ 15| plus:-11 }} => 4]);
is(Template::Liquid->parse(q[{{ 'W'| plus:'TF' }}])->render(),
    'WTF', q[{{ 'W'| plus:'TF' }} => WTF]);

# prepend
is( Template::Liquid->parse(
            q[{{ "apples, oranges, and bananas" | prepend: "Some fruit: " }}])
        ->render(),
    'Some fruit: apples, oranges, and bananas',
    q[{{ "apples, oranges, and bananas" | prepend: "Some fruit: " }} => Some fruit: apples, oranges, and bananas]
);
is( Template::Liquid->parse(
        q[{% assign url = "example.com" %}{{ "/index.html" | prepend: url }}])
        ->render(),
    'example.com/index.html',
    q[{% assign url = "example.com" %}{{ "/index.html" | prepend: url }} => example.com/index.html]
);
is( Template::Liquid->parse(q[{{ 'bar' | prepend:'foo' }}])->render(),
    'foobar',
    q[ {{ 'bar' | prepend:'foo' }} => 'foobar']
);
is( Template::Liquid->parse(q[{{ 'bar' | prepend:baz }}])
        ->render(baz => 'foo'),
    'foobar',
    q[ {{ 'bar' | prepend:baz }} => 'foobar']
);
is( Template::Liquid->parse(q[{{ 'bar' | prepend:baz }}])->render(baz => ''),
    'bar',
    q[ {{ 'bar' | prepend:baz }} => 'bar']
);
is( Template::Liquid->parse(q[{{ 'bar' | prepend:baz }}])->render(xxx => ''),
    'bar',
    q[ {{ 'bar' | prepend:baz }} => 'bar']
);
is( Template::Liquid->parse(q[{{ 'bar' | prepend:'baz' }}])
        ->render(baz => 'fun'),
    'bazbar',
    q[ {{ 'bar' | prepend:'baz' }} => 'bazbar']
);

# remove
is( Template::Liquid->parse(
        q[{{ "I strained to see the train through the rain" | remove: "rain" }}]
    )->render(),
    'I sted to see the t through the ',
    q[{{ "I strained to see the train through the rain" | remove: "rain" }} => I sted to see the t through the ]
);
is( Template::Liquid->parse(q[{{ 'foobarfoobar' | remove:'foo' }}])->render(),
    'barbar', q[{{ 'foobarfoobar' | remove:'foo' }} => barbar]
);

# remove_first
is( Template::Liquid->parse(
        q[{{ "I strained to see the train through the rain" | remove_first: "rain" }}]
    )->render(),
    'I sted to see the train through the rain',
    q[{{ "I strained to see the train through the rain" | remove_first: "rain" }} => I sted to see the train through the rain]
);
is( Template::Liquid->parse(q[{{ 'barbar' | remove_first:'bar' }}])->render(),
    'bar', q[{{ 'barbar' | remove_first:'bar' }} => bar]
);

# replace
is( Template::Liquid->parse(
        q[{{ "Take my protein pills and put my helmet on" | replace: "my", "your" }}]
    )->render(),
    'Take your protein pills and put your helmet on',
    q[{{ "Take my protein pills and put my helmet on" | replace: "my", "your" }} => Take your protein pills and put your helmet on]
);
is(Template::Liquid->parse(q[{{'foofoo'|replace:'foo', 'bar'}}])->render(),
    'barbar', q[{{'foofoo'|replace:'foo', 'bar'}} => barbar]);
note q[This next method uses C<this> which is defined as C<'that'>];
is( Template::Liquid->parse(
                          q[{{'Replace that with this'|replace:this,'this'}}])
        ->render(this => 'that'),
    'Replace this with this',
    q[{{'Replace that with this|replace:this,'this'}} => Replace this with this]
);
is( Template::Liquid->parse(q[{{'I have a listhp.'|replace:'th'}}])->render(),
    'I have a lisp.',
    q[{{'I have a listhp.'|replace:'th'}} => I have a lisp.]
);

# replace_first
is( Template::Liquid->parse(
        q[{{ "Take my protein pills and put my helmet on" | replace_first: "my", "your" }}]
    )->render(),
    'Take your protein pills and put my helmet on',
    q[{{ "Take my protein pills and put my helmet on" | replace_first: "my", "your" }} => Take your protein pills and put my helmet on]
);
is( Template::Liquid->parse(q[{{ 'barbar' | replace_first:'bar','foo' }}])
        ->render(),
    'foobar', q[{{ 'barbar' | replace_first:'bar','foo' }} => foobar]
);

# reverse
is( Template::Liquid->parse(
        q[{% assign my_array = "apples, oranges, peaches, plums" | split: ", " %}{{ my_array | reverse | join: ", " }}]
    )->render(),
    'plums, peaches, oranges, apples',
    q[{{ my_array | reverse | join: ", " }} => plums, peaches, oranges, apples]
);
is( Template::Liquid->parse(
        q[{{ "Ground control to Major Tom." | split: "" | reverse | join: "" }}]
    )->render(),
    '.moT rojaM ot lortnoc dnuorG',
    q[{{ "Ground control to Major Tom." | split: "" | reverse | join: "" }} => .moT rojaM ot lortnoc dnuorG]
);

# round
is( Template::Liquid->parse(
               q[{{ 4.6 | round }} {{ 4.3 | round }} {{ 4.5612 | round: 2 }}])
        ->render(),
    '5 4 4.56',
    q[{{ 4.6 | round }} {{ 4.3 | round }} {{ 4.5612 | round: 2 }} => 5 4 4.56]
);
is(Template::Liquid->parse(q[{{ 1.2 | round }}])->render(),
    '1', q[{{ 1.2 | round }} => 1]);
is(Template::Liquid->parse(q[{{ 2.7 | round }}])->render(),
    '3', q[{{ 2.7 | round }} => 3]);
is(Template::Liquid->parse(q[{{ 183.357 | round: 2 }}])->render(),
    '183.36', q[{{ 183.357 | round: 2 }} => 183.36]);

# rstrip
is( Template::Liquid->parse(
         q[{{ "          So much room for activities!          " | rstrip }}])
        ->render(),
    '          So much room for activities!',
    q[{{ "          So much room for activities!          " | rstrip }} =>           So much room for activities!]
);

# size
note
    q[This next test works on strings (C<'This is a test'>) , hashes (C<{Beatles=>'Apple',Nirvana=>'SubPop'}>) , and arrays (C<[0..10]>)];
is(Template::Liquid->parse(q[{{'This is a test' | size}}])->render(),
    '14', q[{{'This is a test' | size}} => 14]);
is( Template::Liquid->parse(q[{{array | size}}])->render(array => [0 .. 10]),
    '11',
    '{{array | size}} => 11'
);
is( Template::Liquid->parse(q[{{hash | size}}])
        ->render(hash => {Beatles => 'Apple', Nirvana => 'SubPop'}),
    '2',
    q[{{hash | size}} => 2 (counts keys)]
);
is(Template::Liquid->parse(q[{{nope | size}}])->render(),
    '0', q[{{nope | size}} => 0 (undef)]);
is( Template::Liquid->parse(q[{{ "Ground control to Major Tom." | size }}])
        ->render(),
    '28', q[{{nope | size}} => 28]
);
is( Template::Liquid->parse(
        q[{% assign my_array = "apples, oranges, peaches, plums" | split: ", " %}{{ my_array.size }}]
    )->render(),
    '4',
    q[{{ my_array.size }} => 4]
);

# slice
is(Template::Liquid->parse(q[{{ "Liquid" | slice: 0 }}])->render(),
    'L', q[{{ "Liquid" | slice: 0 }} => L]);
is(Template::Liquid->parse(q[{{ "Liquid" | slice: 2 }}])->render(),
    'q', q[{{ "Liquid" | slice: 2 }} => q]);
is(Template::Liquid->parse(q[{{ "Liquid" | slice: 2, 5 }}])->render(),
    'quid', q[{{ "Liquid" | slice: 2, 5 }} => quid]);
is(Template::Liquid->parse(q[{{ "Liquid" | slice: -3, 2 }}])->render(),
    'ui', q[{{ "Liquid" | slice: -3, 2 }} => ui]);

# sort
note 'For this next test, C<array> is defined as C<[10,62,14,257,65,32]>';
is( Template::Liquid->parse(q[{{array | sort | join: ', ' }}])
        ->render(array => [10, 62, 14, 257, 65, 32]),
    '10, 14, 32, 62, 65, 257',
    q[{{array | sort | join: ', '}} => 10, 14, 32, 62, 65, 257]
);
is( Template::Liquid->parse(
        q[{% assign my_array = "zebra, octopus, giraffe, Sally Snake" | split: ", " %}{{ my_array | sort | join: ", " }}]
    )->render(),
    'Sally Snake, giraffe, octopus, zebra',
    '{% assign my_array = "zebra, octopus, giraffe, Sally Snake" | split: ", " %}{{ my_array | sort | join: ", " }}=> Sally Snake, giraffe, octopus, zebra'
);

# sort_natural
is( Template::Liquid->parse(
        q[{% assign my_array = "zebra, octopus, giraffe, Sally Snake" | split: ", " %}{{ my_array | sort_natural | join: ", " }}]
    )->render(),
    'giraffe, octopus, Sally Snake, zebra',
    '{% assign my_array = "zebra, octopus, giraffe, Sally Snake" | split: ", " %}{{ my_array | sort_natural | join: ", " }}=> giraffe, octopus, Sally Snake, zebra'
);

# split
is( Template::Liquid->parse(q[{{ values | split: ',' | last }}])
        ->render(values => 'foo,bar,baz'),
    'baz',
    q[{{ values | split: ',' | last}}]
);
is(Template::Liquid->parse(<<'END')->render, <<'OUT', q[...split: ', ' ]);
{%- assign beatles = "John, Paul, George, Ringo" | split: ', ' -%}
{%- for member in beatles %} a. {{ member }}
{% endfor -%}
END
 a. John
 a. Paul
 a. George
 a. Ringo
OUT
is(Template::Liquid->parse(<<'END')->render, <<'OUT', q[...split: ", " ]);
{%- assign beatles = "John, Paul, George, Ringo" | split: ", " -%}
{%- for member in beatles %} b. {{ member }}
{% endfor -%}
END
 b. John
 b. Paul
 b. George
 b. Ringo
OUT

# strip
is( Template::Liquid->parse(
          q[{{ "          So much room for activities!          " | strip }}])
        ->render(),
    'So much room for activities!',
    '{{ "          So much room for activities!          " | strip }} => So much room for activities!'
);

# strip_html (including the RubyLiquid bugs... ((sigh)))
is( Template::Liquid->parse(
           q[{{ '<div>Hello, <em id="whom">world!</em></div>' | strip_html}}])
        ->render(),
    'Hello, world!',
    q[{{'<div>Hello, <em id="whom">world!</em></div>'|strip_html}} => Hello, world!]
);
is( Template::Liquid->parse(
                 q['{{ '<IMG SRC = "foo.gif" ALT = "A > B">' | strip_html}}'])
        ->render(),
    q[' B">'],
    q['{{ '<IMG SRC = "foo.gif" ALT = "A > B">'|strip_html }}' => ' B">']
);
is( Template::Liquid->parse(q['{{ '<!-- <A comment> -->' | strip_html }}'])
        ->render(),
    q[' -->'],
    q['{{ '<!-- <A comment> -->'| strip_html }}' => ' -->']
);

# strip_newlines
note
    'The next few filters handle text where C<multiline> is defined as C<qq[This\n is\n a\n test.]>';
is( Template::Liquid->parse('{{ multiline | strip_newlines }}')
        ->render(multiline => qq[This\n is\n a\n test.]),
    'This is a test.',
    q[{{ multiline | strip_newlines }} => 'This is a test.']
);
is( Template::Liquid->parse(
        <<'END')->render, <<'OUT', q[{{ string_with_newlines | strip_newlines }}]);
{% capture string_with_newlines %}
Hello
there
{% endcapture %}

{{ string_with_newlines | strip_newlines }}
END


Hellothere
OUT

# times
is( Template::Liquid->parse(q[{{ 'foo'| times:4 }}])->render(),
    'foofoofoofoo',
    q[{{ 'foo'|times:4 }} => foofoofoofoo]
);
is(Template::Liquid->parse(q[{{ 5 |times:4 }}])->render(),
    '20', q[{{ 5|times:4 }} => 20]);
is(Template::Liquid->parse(q[{{ 3 | times: 2 }}])->render(),
    '6', q[{{ 3 | times: 2 }} => 6]);
is(Template::Liquid->parse(q[{{ 24 | times: 7 }}])->render(),
    '168', q[{{ 24 | times: 7 }} => 168]);
is( Template::Liquid->parse(q[{{ 183.357 | times: 12 }}])->render(),
    '2200.284',
    q[{{ 183.357 | times: 12 }} => 2200.284]
);

# truncate
is( Template::Liquid->parse(q[{{ 'Running the halls!!!' | truncate:19 }}])
        ->render(),
    'Running the hall...',
    q[{{ 'Running the halls!!!' | truncate:19 }} => Running the hall...]
);
note q[This next method uses C<blah> which is defined as C<'STOP!'>];
is( Template::Liquid->parse(
                            q[{{ 'Any Colour You Like' | truncate:10,blah }}])
        ->render(blah => 'STOP!'),
    'Any CSTOP!',
    q[{{ 'Any Colour You Like' | truncate:10,blah }} => Any CSTOP!]
);
is( Template::Liquid->parse(
            q[{{ "Ground control to Major Tom." | truncate: 20 }}])->render(),
    'Ground control to...',
    q[{{ "Ground control to Major Tom." | truncate: 20 }} => Ground control to...]
);
is( Template::Liquid->parse(
        q[{{ "Ground control to Major Tom." | truncate: 25, ", and so on" }}])
        ->render(),
    'Ground control, and so on',
    q[{{ "Ground control to Major Tom." | truncate: 25, ", and so on" }} => Ground control, and so on]
);
is( Template::Liquid->parse(
        q[{{ "Ground control to Major Tom." | truncate: 20, "" }}])->render(),
    'Ground control to Ma',
    q[{{ "Ground control to Major Tom." | truncate: 20, "" }} => Ground control to Ma]
);

# truncatewords
is( Template::Liquid->parse(
        q[{{'This is a very quick test of truncating a number of words'|truncatewords:5,'...'}}]
    )->render(),
    'This is a very quick...',
    q[ {{ ... | truncatewords:5,'...' }} => 'This is a very quick...']
);
is( Template::Liquid->parse(
        q[{{'This is a very quick test of truncating a number of words where the limit is fifteen by default'|truncatewords}}]
    )->render(),
    'This is a very quick test of truncating a number of words where the limit...',
    q[ {{ ... | truncatewords }} => 'This is a very quick [...] limit...']
);
is( Template::Liquid->parse(
        q[{{ "Ground control to Major Tom." | truncatewords: 3 }}])->render(),
    'Ground control to...',
    q[{{ "Ground control to Major Tom." | truncatewords: 3  }} => Ground control to Ma]
);
is( Template::Liquid->parse(
             q[{{ "Ground control to Major Tom." | truncatewords: 3, "--" }}])
        ->render(),
    'Ground control to--',
    q[{{ "Ground control to Major Tom." | truncatewords: 3, "--"  }} => Ground control to--]
);
is( Template::Liquid->parse(
               q[{{ "Ground control to Major Tom." | truncatewords: 3, "" }}])
        ->render(),
    'Ground control to',
    q[{{ "Ground control to Major Tom." | truncatewords: 3, "" }} => Ground control to]
);

# uniq
is( Template::Liquid->parse(
        q[{% assign my_array = "ants, bugs, bees, bugs, ants" | split: ", " %}{{ my_array | uniq | join: ", " }}]
    )->render(),
    'ants, bugs, bees',
    q[{{ my_array | uniq | join: ", " }} => ants, bugs, bees]
);

# upcase
is( Template::Liquid->parse(q[{{'This is a QUICK test.'|upcase }}])->render(),
    'THIS IS A QUICK TEST.',
    q[{{'This is a QUICK test.'|upcase }} => THIS IS A QUICK TEST.]
);
is( Template::Liquid->parse(q[{{ "Parker Moore" | upcase }}])->render(),
    'PARKER MOORE',
    q[{{ 'Parker Moore' | upcase }} => PARKER MOORE]
);
is(Template::Liquid->parse(q[{{"APPLE" | upcase }}])->render(),
    'APPLE', q[{{ "APPLE" | upcase }} => APPLE]);

# url_decode
is( Template::Liquid->parse(q[{{ "%27Stop%21%27+said+Fred" | url_decode }}])
        ->render(),
    q['Stop!' said Fred],
    q[{{ "%27Stop%21%27+said+Fred" | url_decode }} => 'Stop!' said Fred]
);

# url_encode
is( Template::Liquid->parse(q[{{ "john@liquid.com" | url_encode }}])
        ->render(),
    q[john%40liquid.com],
    q[{{ "john@liquid.com" | url_encode }} => john%40liquid.com]
);
is( Template::Liquid->parse(q[{{ "Tetsuro Takara" | url_encode }}])->render(),
    q[Tetsuro+Takara],
    q[{{ "Tetsuro Takara" | url_encode }} => Tetsuro+Takara]
);
is( Template::Liquid->parse(q[{{ "'Stop!' said Fred" | url_encode }}])
        ->render(),
    q[%27Stop%21%27+said+Fred],
    q[{{ "'Stop!' said Fred" | url_encode }} => %27Stop%21%27+said+Fred]
);

# where
{
    my %data = (products => [{title => 'Vacuum',       type => 'carpet',},
                             {title => 'Spatula',      type => 'kitchen'},
                             {title => 'Television',   type => 'den'},
                             {title => 'Garlic press', type => 'kitchen'},
                ]
    );
    is( Template::Liquid->parse(
            <<'END')->render(%data), <<'OUT', q[{% assign kitchen_products = products | where: "type", "kitchen" %}]);
All products:
{% for product in products -%}
- {{ product.title }}
{% endfor -%}

{%- assign kitchen_products = products | where: "type", "kitchen" %}
Kitchen products:
{% for product in kitchen_products -%}
- {{ product.title }}
{% endfor -%}
END
All products:
- Vacuum
- Spatula
- Television
- Garlic press

Kitchen products:
- Spatula
- Garlic press
OUT
}
{
    my %data = (
           products => [{title => 'Coffee mug',               available => 1},
                        {title => 'Limited edition sneakers', available => 0},
                        {title => 'Boring sneakers',          available => 1}
           ]
    );
    is( Template::Liquid->parse(
            <<'END')->render(%data), <<'OUT', q[{% assign available_products = products | where: "available" %}]);
All products:
{% for product in products -%}
- {{ product.title }}
{% endfor -%}

{%- assign available_products = products | where: "available" %}
Available products:
{% for product in available_products -%}
- {{ product.title }}
{% endfor -%}
END
All products:
- Coffee mug
- Limited edition sneakers
- Boring sneakers

Available products:
- Coffee mug
- Boring sneakers
OUT
}
{
    my %data = (
          products => [{title => 'Limited edition sneakers', type => 'shoes'},
                       {title => 'Hawaiian print sweater vest',
                        type  => 'shirt'
                       },
                       {title => 'Tuxedo print tshirt', type => 'shirt'},
                       {title => 'Jorts',               type => 'shorts'}
          ]
    );
    is( Template::Liquid->parse(
            <<'END')->render(%data), <<'OUT', q[{% assign new_shirt = products | where: "type", "shirt" | first %}]);
{%- assign new_shirt = products | where: "type", "shirt" | first -%}
Featured product: {{ new_shirt.title }}
END
Featured product: Hawaiian print sweater vest
OUT
}

# money
is( Template::Liquid->parse(
        q[{{ 4.6 | money }} {{ -4.3 | money }} {{ 4.5612 | money }} {{ 4.6 | money:'€' }}]
    )->render(),
    '$4.60 -$4.30 $4.56 €4.60',
    q[{{ 4.6 | money }} {{ -4.3 | money }} {{ 4.5612 | money }} {{ 4.6 | money:'€' }} => $4.60 -$4.30 $4.56 €4.60]
);

# stock_price
is( Template::Liquid->parse(
        q[{{ 4.6 | stock_price }} {{ .30 | stock_price }} {{ 4.5612 | stock_price }} {{ 4.6 | stock_price:'€' }}]
    )->render(),
    '$4.60 $0.3000 $4.56 €4.60',
    q[{{ 4.6 | stock_price }} {{ .30 | stock_price }} {{ 4.5612 | stock_price }} {{ 4.6 | stock_price:'€' }} => $4.60 $0.3000 $4.56 €4.60]
);

# Bug in ::Variable clobbered filter values
is( Template::Liquid->parse(
           q[{%for row in rows%}{{row.a | minus: row.b}} {%endfor%}])->render(
                                                  rows => [
                                                          {a => 5,  b => 2},
                                                          {a => 13, b => 12},
                                                          {a => 13, b => 112},
                                                          {a => 13, b => -12},
                                                          {a => 115, b => 18}
                                                  ]
           ),
    '3 1 -99 25 97 ',
    q[Bug in ::Variable clobbered filter values]
);
#
# I'm finished
done_testing();
