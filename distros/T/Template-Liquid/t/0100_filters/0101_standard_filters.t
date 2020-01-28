use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Template::Liquid;
$|++;

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
    skip 'Cannot load DateTimeX::Tiny module', 1
        unless eval {
        require DateTimeX::Tiny;
        require require DateTimeX::Lite::Strftime;
        };
    is( Template::Liquid->parse(
                               '{{date|date:"%Y"}}',
                               date => DateTimeX::Tiny->from_epoch(epoch => 0)
        ),
        1970,
        '{{date|date:"%Y"}} => 2009 (DateTimeX::Tiny)'
    );
}
is( Template::Liquid->parse('{{date|date:"%Y"}}')->render(date => gmtime(0)),
    1970,
    '{{date|date:"%Y"}} => 1970 (int)'
);
is(Template::Liquid->parse(q[{{ 'now'|date:"%Y"}}])->render(),
    1900 + [localtime()]->[5],
    q[{{ 'now'|date:"%Y"}}]);
is(Template::Liquid->parse(q[{{ 'TODAY'|date:"%Y"}}])->render(),
    1900 + [localtime()]->[5],
    q[{{ 'TODAY'|date:"%Y"}}]);

# string/char case
is( Template::Liquid->parse(q[{{'this is a QUICK test.'|capitalize}}])
        ->render(),
    'This is a quick test.',
    q[{{'this is a QUICK test.'|capitalize}} => This is a quick test.]
);
is( Template::Liquid->parse(q[{{'This is a QUICK test.'|downcase }}])
        ->render(),
    'this is a quick test.',
    q[{{'This is a QUICK test.'|downcase }} => this is a quick test.]
);
is( Template::Liquid->parse(q[{{'This is a QUICK test.'|upcase }}])->render(),
    'THIS IS A QUICK TEST.',
    q[{{'This is a QUICK test.'|upcase }} => THIS IS A QUICK TEST.]
);

# string last
is(Template::Liquid->parse(q[{{ str | last}}])->render(str => 'string'),
    'g', '{{ str | last }} => g');

# array/lists
note 'For these next few tests, C<array> is defined as C<[1 .. 6]>';
is( Template::Liquid->parse(q[{{array | first}}])->render(array => [1 .. 6]),
    '1',
    '{{array | first}} => 1'
);
is(Template::Liquid->parse(q[{{array | last}}])->render(array => [1 .. 6]),
    '6', '{{array | last }} => 6');
is(Template::Liquid->parse(q[{{array | join}}])->render(array => [1 .. 6]),
    '1 2 3 4 5 6', '{{array | join }} => 1 2 3 4 5 6');
is( Template::Liquid->parse(q[{{array | join:', '}}])
        ->render(array => [1 .. 6]),
    '1, 2, 3, 4, 5, 6',
    q[{{array | join:', ' }} => 1, 2, 3, 4, 5, 6]
);
note 'For this next test, C<array> is defined as C<[10,62,14,257,65,32]>';
is( Template::Liquid->parse(q[{{array | sort}}])
        ->render(array => [10, 62, 14, 257, 65, 32]),
    '1014326265257',
    '{{array | sort}} => 1014326265257'
);
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

# split
is( Template::Liquid->parse(q[{{ values | split: ',' | last }}])
        ->render(values => 'foo,bar,baz'),
    'baz',
    q[{{ values | split: ',' | last}}]
);

# html/web (including the RubyLiquid bugs... ((sigh)))
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

# simple replacements
note
    'The next few filters handle text where C<multiline> is defined as C<qq[This\n is\n a\n test.]>';
is( Template::Liquid->parse('{{multiline|strip_newlines}}')
        ->render(multiline => qq[This\n is\n a\n test.]),
    'This is a test.',
    q[{{multiline|strip_newlines}} => 'This is a test.']
);
is( Template::Liquid->parse('{{multiline|newline_to_br}}')
        ->render(multiline => qq[This\n is\n a\n test.]),
    qq[This<br />\n is<br />\n a<br />\n test.],
    qq[{{multiline|newline_to_br}} => This<br />\n is<br />\n a<br />\n test.]
);

# advanced replacements
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
is( Template::Liquid->parse(q[{{ 'barbar' | replace_first:'bar','foo' }}])
        ->render(),
    'foobar', q[{{ 'barbar' | replace_first:'bar','foo' }} => foobar]
);
is( Template::Liquid->parse(q[{{ 'foobarfoobar' | remove:'foo' }}])->render(),
    'barbar', q[{{ 'foobarfoobar' | remove:'foo' }} => barbar]
);
is( Template::Liquid->parse(q[{{ 'barbar' | remove_first:'bar' }}])->render(),
    'bar', q[{{ 'barbar' | remove_first:'bar' }} => bar]
);

# truncation
is( Template::Liquid->parse(q[{{ 'Running the halls!!!' | truncate:19 }}])
        ->render(),
    'Running the hall...',
    q[{{ 'Running the halls!!!' | truncate:19 }} => Running the hall...]
);
note q[This next method uses C<blah> which is defined as C<'STOP!'>];
is( Template::Liquid->parse(q[{{ 'Any Colour You Like' | truncate:10,blah }}])
        ->render(blah => 'STOP!'),
    'Any CSTOP!',
    q[{{ 'Any Colour You Like' | truncate:10,blah }} => Any CSTOP!]
);
is( Template::Liquid->parse(q[{{ 'bar' | prepend:'foo' }}])->render(),
    'foobar',
    q[ {{ 'bar' | prepend:'foo' }} => 'foobar']
);
is( Template::Liquid->parse(q[{{ 'bar' | prepend:'foo' }}])->render(),
    'foobar',
    q[ {{ 'bar' | prepend:'foo' }} => 'foobar']
);
is( Template::Liquid->parse(q[{{ 'bar' | prepend:'foo' }}])->render(),
    'foobar',
    q[ {{ 'bar' | prepend:'foo' }} => 'foobar']
);
is( Template::Liquid->parse(q[{{ 'bar' | prepend:'foo' }}])->render(),
    'foobar',
    q[ {{ 'bar' | prepend:'foo' }} => 'foobar']
);
is( Template::Liquid->parse(q[{{ 'bar' | prepend:'foo' }}])->render(),
    'foobar',
    q[ {{ 'bar' | prepend:'foo' }} => 'foobar']
);
is( Template::Liquid->parse(q[{{ 'bar' | prepend:'foo' }}])->render(),
    'foobar',
    q[ {{ 'bar' | prepend:'foo' }} => 'foobar']
);
is( Template::Liquid->parse(q[{{ 'bar' | prepend:'foo' }}])->render(),
    'foobar',
    q[ {{ 'bar' | prepend:'foo' }} => 'foobar']
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

=head2 C<truncate>

Truncate a string down to C<x> characters.

 {{ 'Why are you running away?' | truncate:4,'?' }} => Why?
 {{ 'Ha' | truncate:4 }} => Ha
 {{ 'Ha' | truncate:1,'Laugh' }} => Laugh
 {{ 'Ha' | truncate:1,'...' }} => ...

...and...

 {{ 'This is a long line of text to test the default values for truncate' | truncate }}

...becomes...

 This is a long line of text to test the default...

=cut
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

# string concatenation
is( Template::Liquid->parse(q[{{ 'bar' | prepend:'foo' }}])->render(),
    'foobar',
    q[{{ 'bar' | prepend:'foo' }} => 'foobar']
);
is( Template::Liquid->parse(q[{{ 'foo' | append:'bar' }}])->render(),
    'foobar',
    q[{{ 'foo' | append:'bar' }} => 'foobar']
);

# subtraction
is(Template::Liquid->parse(q[{{ 4|minus:2 }}])->render(),
    '2', q[{{ 4|minus:2 }} => 2]);
is(Template::Liquid->parse(q[{{ 'Test'|minus:2 }}])->render(),
    '', q[{{ 'Test'|minus:2 }} => ]);
is(Template::Liquid->parse(q[{{ 4.3|minus:2.5 }}])->render(),
    '1.8', q[{{ 4.3|minus:2.5 }} => 1.8]);
is(Template::Liquid->parse(q[{{ -4|minus:2 }}])->render(),
    '-6', q[{{ -4|minus:2 }} => -6]);

# concatenation or simple addition
is(Template::Liquid->parse(q[{{ 154| plus:1183 }}])->render(),
    '1337', q[{{ 154| plus:1183 }} => 1337]);
is(Template::Liquid->parse(q[{{ 15.4| plus:11.83 }}])->render(),
    '27.23', q[{{ 15.4| plus:11.83 }} => 27.23]);
is(Template::Liquid->parse(q[{{ 15| plus:-11 }}])->render(),
    '4', q[{{ 15| plus:-11 }} => 4]);
is(Template::Liquid->parse(q[{{ 'W'| plus:'TF' }}])->render(),
    'WTF', q[{{ 'W'| plus:'TF' }} => WTF]);

# multiplication or string repetion
is( Template::Liquid->parse(q[{{ 'foo'| times:4 }}])->render(),
    'foofoofoofoo',
    q[{{ 'foo'|times:4 }} => foofoofoofoo]
);
is(Template::Liquid->parse(q[{{ 5|times:4 }}])->render(),
    '20', q[{{ 5|times:4 }} => 20]);

# division
is(Template::Liquid->parse(q[{{ 10 | divided_by:2 }}])->render(),
    '5', q[{{ 10 | divided_by:2 }} => 5]);

# modulo
is(Template::Liquid->parse(q[{{ 95 | modulo:6 }}])->render(),
    '5', q[{{ 95 | modulo:6 }} => 5]);
is(Template::Liquid->parse(q[{{ 95 | modulo:6.4 }}])->render(),
    '5', q[{{ 95 | modulo:6.4 }} => 5]);
is(Template::Liquid->parse(q[{{ 95.6 | modulo:6 }}])->render(),
    '5', q[{{ 95.6 | modulo:6 }} => 5]);

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

# round
is( Template::Liquid->parse(
               q[{{ 4.6 | round }} {{ 4.3 | round }} {{ 4.5612 | round: 2 }}])
        ->render(),
    '5 4 4.56',
    q[{{ 4.6 | round }} {{ 4.3 | round }} {{ 4.5612 | round: 2 }} => 5 4 4.56]
);

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

# abs
is(Template::Liquid->parse(q[{{ 4 | abs }} {{ -4 | abs }}])->render(),
    '4 4', q[{{ 4 | abs }} {{ -4 | abs }} => 4 4]);

# ceil
is(Template::Liquid->parse(q[{{ 4.6 | ceil }} {{ 4.3 | ceil }}])->render(),
    '5 5', q[{{ 4.6 | ceil }} {{ 4.3 | ceil }} => 5 5]);

# floor
is( Template::Liquid->parse(q[{{ 4.6 | floor }} {{ 4.3 | floor }}])->render(),
    '4 4',
    q[{{ 4.6 | floor }} {{ 4.3 | floor }} => 4 4]
);

# default
is( Template::Liquid->parse(
        q[{{ fun | default:"wow!" }} {{ Key | default:"wow!" }} {{ Zero | default:"empty" }} {{ One | default:"another one" }}]
    )->render(Key => 'Value', Zero => '', One => ' '),
    'wow! Value empty  ',
    q[{{ fun | default:"wow!" }} {{ Key | default:"wow!" }} {{ Zero | default:"empty" }} {{ One | default:"another one" }} => wow! Value empty  ]
);
#
# I'm finished
done_testing();
