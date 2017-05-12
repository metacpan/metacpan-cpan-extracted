use Test::More tests => 67;
use strict; use warnings;

use String::MFN;

binmode STDERR, ":utf8";

# null change tests
is( mfn('foo'),                      'foo');
is( mfn('123'),                      '123');
is( mfn('foo.bar'),                  'foo.bar');
is( mfn('123.456'),                  '123.456');
is( mfn('foo123-bar456_lmn+op.xyz'), 'foo123-bar456_lmn+op.xyz');

# case separation
is( mfn('aB'), 'a_b');
is( mfn('fooBarlmNoP'), 'foo_barlm_no_p');

# brackets, ~ converted to -
is( mfn('a(b'), 'a-b');
is( mfn('a[b'), 'a-b');
is( mfn('a{b'), 'a-b');
is( mfn('a<b'), 'a-b');
is( mfn('a~b'), 'a-b');
is( mfn('a(b)'), 'a-b');
is( mfn('(a)b'), 'a-b');
is( mfn('({[a]})b'), 'a-b');
is( mfn('(a)b~c~[d]ef<{gh}>'), 'a-b-c-d-ef-gh');

# whitespace removal
is( mfn('a b'), 'a_b');
is( mfn('a b '), 'a_b');
is( mfn(' a b'), 'a_b');
is( mfn('a  b'), 'a_b');
is( mfn('a	b'), 'a_b');
is( mfn(' a 	 b '), 'a_b');

# ampersand handler
is( mfn('a&b'), 'a_and_b');
is( mfn('a&&&&b'), 'a_and_b');

# drop non-word chars
is( mfn('foo!@#$%^*abc+=|\/""z,/?:;₫'), 'fooabc+-z');
# is( mfn('abç'), 'abç'); # Test::More mangles the unicode in the left half

# condense -_ sequences
is( mfn('abc-_def'), 'abc-def');
is( mfn('abc-_-_-_-_def'), 'abc-def');

# condense _- sequences
is( mfn('abc_-def'), 'abc-def');
is( mfn('abc_-_-_-_-def'), 'abc-def');


# collapse period-containing dash sequences
is( mfn('a-.b'), 'a.b');
is( mfn('a.-b'), 'a.b');
is( mfn('a_.b'), 'a.b');
is( mfn('a._b'), 'a.b');
is( mfn('a--_----_-_--.._...--_-_._-._._._-.__b'), 'a.b');

# collapse repeating -, _, and .
is( mfn('a-b'), 'a-b');
is( mfn('a--b'), 'a-b');
is( mfn('a---b'), 'a-b');
is( mfn('a----b'), 'a-b');
is( mfn('a_b'), 'a_b');
is( mfn('a__b'), 'a_b');
is( mfn('a___b'), 'a_b');
is( mfn('a____b'), 'a_b');
is( mfn('a.b'), 'a.b');
is( mfn('a..b'), 'a.b');
is( mfn('a...b'), 'a.b');
is( mfn('a....b'), 'a.b');
is( mfn('a---b__c_--_d--_-e...f'), 'a-b_c-d-e.f');

# remove leading -_.
is( mfn('-ab'), 'ab');
is( mfn('_ab'), 'ab');
is( mfn('.ab'), 'ab');
is( mfn('-_-.ab'), 'ab');
is( mfn('-------ab'), 'ab');
is( mfn('-__---__..._ab'), 'ab');

# remove trailing -_.
is( mfn('ab-'), 'ab');
is( mfn('ab_'), 'ab');
is( mfn('ab.'), 'ab');
is( mfn('ab-_-.'), 'ab');
is( mfn('ab-------'), 'ab');
is( mfn('ab-__---__..._'), 'ab');

# collapse repeat extensions
is( mfn('ab.foo'), 'ab.foo');
is( mfn('ab.foo.foo'), 'ab.foo');
is( mfn('ab.foo.bar'), 'ab.foo.bar');
is( mfn('ab.foo.bar.bar.bar'), 'ab.foo.bar');
is( mfn('ab.foo.bar.foo.bar'), 'ab.foo.bar.foo.bar');

# lowercase
is( mfn('AB'), 'ab');

# real-world tests
is( mfn('M.I.L.T.F.(Mothers.Id.Like.to.Fuck).8.[DVDRIP][English].avi.torrent'),
        'm.i.l.t.f.mothers.id.like.to.fuck.8.dvdrip-english.avi.torrent');
is( mfn('Classic - Double Your Pleasure - (1978) - Twin Sisters Brooke & Taylor Young / Samantha Fox / Rikki O\'Neal / Merle Michaels.torrent'),
        'classic-double_your_pleasure-1978-twin_sisters_brooke_and_taylor_young-samantha_fox-rikki_oneal-merle_michaels.torrent');

