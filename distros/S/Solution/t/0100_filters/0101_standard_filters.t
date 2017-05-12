use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Solution;
sub X { Solution::Template->parse(shift)->render(shift) }
$|++;

# date
SKIP: {
    skip 'Cannot load DateTime module', 1 unless eval { require DateTime };
    is(X('{{date|date:"%Y"}}', {date => DateTime->from_epoch(epoch => 0)}),
        1970, '{{date|date:"%Y"}} => 1970 (DateTime)');
}
SKIP: {
    skip 'Cannot load DateTimeX::Tiny module', 1
        unless eval {
        require DateTimeX::Tiny;
        require require DateTimeX::Lite::Strftime;
        };
    is( X( '{{date|date:"%Y"}}',
           {date => DateTimeX::Tiny->from_epoch(epoch => 0)}
        ),
        1970,
        '{{date|date:"%Y"}} => 2009 (DateTimeX::Tiny)'
    );
}
is(X('{{date|date:"%Y"}}', {date => gmtime(0)}),
    1970, '{{date|date:"%Y"}} => 1970 (int)');
is( X(q[{{ 'now'|date:"%Y"}}], {}),
    1900 + [localtime()]->[5],
    q[{{ 'now'|date:"%Y"}}]
);
is( X(q[{{ 'TODAY'|date:"%Y"}}], {}),
    1900 + [localtime()]->[5],
    q[{{ 'TODAY'|date:"%Y"}}]
);

# string/char case
is(X(q[{{'this is a QUICK test.'|capitalize}}]),
    'This is a quick test.',
    q[{{'this is a QUICK test.'|capitalize}} => This is a quick test.]);
is(X(q[{{'This is a QUICK test.'|downcase }}]),
    'this is a quick test.',
    q[{{'This is a QUICK test.'|downcase }} => this is a quick test.]);
is(X(q[{{'This is a QUICK test.'|upcase }}]),
    'THIS IS A QUICK TEST.',
    q[{{'This is a QUICK test.'|upcase }} => THIS IS A QUICK TEST.]);

# array/lists
note 'For these next few tests, C<array> is defined as C<[1 .. 6]>';
is(X(q[{{array | first}}], {array => [1 .. 6]}),
    '1', '{{array | first}} => 1');
is(X(q[{{array | last}}], {array => [1 .. 6]}), '6',
    '{{array | last }} => 6');
is(X(q[{{array | join}}], {array => [1 .. 6]}),
    '1 2 3 4 5 6', '{{array | join }} => 1 2 3 4 5 6');
is(X(q[{{array | join:', '}}], {array => [1 .. 6]}),
    '1, 2, 3, 4, 5, 6',
    q[{{array | join:', ' }} => 1, 2, 3, 4, 5, 6]);
note 'For this next test, C<array> is defined as C<[10,62,14,257,65,32]>';
is(X(q[{{array | sort}}], {array => [10, 62, 14, 257, 65, 32]}),
    '1014326265257', '{{array | sort}} => 1014326265257');
note
    q[This next test works on strings (C<'This is a test'>) , hashes (C<{Beatles=>'Apple',Nirvana=>'SubPop'}>) , and arrays (C<[0..10]>)];
is(X(q[{{'This is a test' | size}}]),
    '14', q[{{'This is a test' | size}} => 14]);
is(X(q[{{array | size}}], {array => [0 .. 10]}),
    '11', '{{array | size}} => 11');
is( X( q[{{hash | size}}], {hash => {Beatles => 'Apple', Nirvana => 'SubPop'}}
    ),
    '2',
    q[{{hash | size}} => 2 (counts keys)]
);

# split
is(X(q[{{ values | split: ',' | last }}], {values => 'foo,bar,baz'}),
    'baz', q[{{ values | split: ',' | last}}]);

# html/web (including the RubyLiquid bugs... ((sigh)))
is( X(q[{{ '<div>Hello, <em id="whom">world!</em></div>' | strip_html}}]),
    'Hello, world!',
    q[{{'<div>Hello, <em id="whom">world!</em></div>'|strip_html}} => Hello, world!]
);
is( X(q['{{ '<IMG SRC = "foo.gif" ALT = "A > B">' | strip_html}}']),
    q[' B">'],
    q['{{ '<IMG SRC = "foo.gif" ALT = "A > B">'|strip_html }}' => ' B">']
);
is(X(q['{{ '<!-- <A comment> -->' | strip_html }}']),
    q[' -->'], q['{{ '<!-- <A comment> -->'| strip_html }}' => ' -->']);

# simple replacements
note
    'The next few filters handle text where C<multiline> is defined as C<qq[This\n is\n a\n test.]>';
is( X( '{{multiline|strip_newlines}}',
       {multiline => qq[This\n is\n a\n test.]}
    ),
    'This is a test.',
    q[{{multiline|strip_newlines}} => 'This is a test.']
);
is( X( '{{multiline|newline_to_br}}', {multiline => qq[This\n is\n a\n test.]}
    ),
    qq[This<br />\n is<br />\n a<br />\n test.],
    qq[{{multiline|newline_to_br}} => This<br />\n is<br />\n a<br />\n test.]
);

# advanced replacements
is(X(q[{{'foofoo'|replace:'foo', 'bar'}}]),
    'barbar', q[{{'foofoo'|replace:'foo', 'bar'}} => barbar]);
note q[This next method uses C<this> which is defined as C<'that'>];
is( X(q[{{'Replace that with this'|replace:this,'this'}}], {this => 'that'}),
    'Replace this with this',
    q[{{'Replace that with this|replace:this,'this'}} => Replace this with this]
);
is(X(q[{{'I have a listhp.'|replace:'th'}}]),
    'I have a lisp.',
    q[{{'I have a listhp.'|replace:'th'}} => I have a lisp.]);
is(X(q[{{ 'barbar' | replace_first:'bar','foo' }}]),
    'foobar', q[{{ 'barbar' | replace_first:'bar','foo' }} => foobar]);
is(X(q[{{ 'foobarfoobar' | remove:'foo' }}]),
    'barbar', q[{{ 'foobarfoobar' | remove:'foo' }} => barbar]);
is(X(q[{{ 'barbar' | remove_first:'bar' }}]),
    'bar', q[{{ 'barbar' | remove_first:'bar' }} => bar]);

# truncation
is(X(q[{{ 'Running the halls!!!' | truncate:19 }}]),
    'Running the hall...',
    q[{{ 'Running the halls!!!' | truncate:19 }} => Running the hall...]);
note q[This next method uses C<blah> which is defined as C<'STOP!'>];
is( X(q[{{ 'Any Colour You Like' | truncate:10,blah }}], {blah => 'STOP!'}),
    'Any CSTOP!',
    q[{{ 'Any Colour You Like' | truncate:10,blah }} => Any CSTOP!]
);
is(X(q[{{ 'bar' | prepend:'foo' }}]),
    'foobar', q[ {{ 'bar' | prepend:'foo' }} => 'foobar']);
is(X(q[{{ 'bar' | prepend:'foo' }}]),
    'foobar', q[ {{ 'bar' | prepend:'foo' }} => 'foobar']);
is(X(q[{{ 'bar' | prepend:'foo' }}]),
    'foobar', q[ {{ 'bar' | prepend:'foo' }} => 'foobar']);
is(X(q[{{ 'bar' | prepend:'foo' }}]),
    'foobar', q[ {{ 'bar' | prepend:'foo' }} => 'foobar']);
is(X(q[{{ 'bar' | prepend:'foo' }}]),
    'foobar', q[ {{ 'bar' | prepend:'foo' }} => 'foobar']);
is(X(q[{{ 'bar' | prepend:'foo' }}]),
    'foobar', q[ {{ 'bar' | prepend:'foo' }} => 'foobar']);
is(X(q[{{ 'bar' | prepend:'foo' }}]),
    'foobar', q[ {{ 'bar' | prepend:'foo' }} => 'foobar']);
is(X(q[{{ 'bar' | prepend:'foo' }}]),
    'foobar', q[ {{ 'bar' | prepend:'foo' }} => 'foobar']);

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
is( X( q[{{'This is a very quick test of truncating a number of words'|truncatewords:5,'...'}}]
    ),
    'This is a very quick...',
    q[ {{ ... | truncatewords:5,'...' }} => 'This is a very quick...']
);
is( X( q[{{'This is a very quick test of truncating a number of words where the limit is fifteen by default'|truncatewords}}]
    ),
    'This is a very quick test of truncating a number of words where the limit...',
    q[ {{ ... | truncatewords }} => 'This is a very quick [...] limit...']
);

# string concatenation
is(X(q[{{ 'bar' | prepend:'foo' }}]),
    'foobar', q[{{ 'bar' | prepend:'foo' }} => 'foobar']);
is(X(q[{{ 'foo' | append:'bar' }}]),
    'foobar', q[{{ 'foo' | append:'bar' }} => 'foobar']);

# subtraction
is(X(q[{{ 4|minus:2 }}]),      '2', q[{{ 4|minus:2 }} => 2]);
is(X(q[{{ 'Test'|minus:2 }}]), '',  q[{{ 'Test'|minus:2 }} => ]);

# concatenation or simple addition
is(X(q[{{ 154| plus:1183 }}]), '1337', q[{{ 154| plus:1183 }} => 1337]);
is(X(q[{{ 'W'| plus:'TF' }}]), 'WTF',  q[{{ 'W'| plus:'TF' }} => WTF]);

# multiplication or string repetion
is(X(q[{{ 'foo'| times:4 }}]),
    'foofoofoofoo', q[{{ 'foo'|times:4 }} => foofoofoofoo]);
is(X(q[{{ 5|times:4 }}]), '20', q[{{ 5|times:4 }} => 20]);

# division
is(X(q[{{ 10 | divided_by:2 }}]), '5', q[{{ 10 | divided_by:2 }} => 5]);

# modulo
is(X(q[{{ 95 | modulo:6 }}]),   '5', q[{{ 95 | modulo:6 }} => 5]);
is(X(q[{{ 95 | modulo:6.4 }}]), '5', q[{{ 95 | modulo:6.4 }} => 5]);
is(X(q[{{ 95.6 | modulo:6 }}]), '5', q[{{ 95.6 | modulo:6 }} => 5]);

# I'm finished
done_testing();
