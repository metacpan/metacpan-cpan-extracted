use 5.020;
use experimental 'signatures';
use Test2::V0 -no_srand;
use utf8;
use Unicode::Normalize;

binmode STDOUT, ':utf8';

use String::FuzzyMatch;

my $default = String::FuzzyMatch->new();

subtest "Basic mechanics" => sub {
    my $list = ['a',"hätte"];
    is $default->filter( 'a', $list ), ['a','hätte'], "Diacritics on the RHS are ignored by default";
    is $list, ['a',"hätte"], "The original list remains unchanged";
};

my @common_cases = (
  [ 'abc',      ['a/b/c','0/a/b/c/d'], ['a/b/c','0/a/b/c/d'], "arbitrary characters between the search chars" ],
  [ 'a$c',      ['a/$/c','0/a/$/c/d'], ['a/$/c','0/a/$/c/d'], "Regex meta characters are no problem" ],
  [ '\\',       ['foo\\bar',"aa*"],    ['foo\\bar'],          "Regex meta characters are no problem" ],
  [ '\\[]{}*+', ['\\[]{}*+',""] ,      ['\\[]{}*+'],          "Regex meta characters are no problem" ],
  [ 'aBc',      ['a/b/c','0/a/b/c/d'], ['a/b/c','0/a/b/c/d'], "character matches case-insensitively" ],
);

is $default->filter( '', ['a','b','c'] ), ['a','b','c'], "Empty string matches everything";
is $default->filter( 'a', ['a','b','c','ba','bac'] ), ['a','ba','bac'], "Single character matches";
is $default->filter( 'a', ['a',"hätte","b"] ), ['a','hätte'], "Diacritics on the RHS are ignored by default";
is $default->filter( 'ä', ['a',"hätte","b"] ), ['hätte'], "Diacritics on the LHS are respected by default";
is $default->filter( 'aääa', ['aääa',"aaää","aäaä","aäää"] ), ['aääa','aäää'], "Diacritics on the LHS are respected by default";
is $default->filter( 'Ä', ['a',"hätte","b"] ), ['hätte'], "Diacritics on the LHS work case-insensitively";

for my $t (@common_cases) {
    is $default->filter( $t->[0], $t->[1] ), $t->[2], $t->[3];
};

my $ascii = String::FuzzyMatch->new(
    ignore_diacritics_lhs => 1,
);

is $ascii->filter( '', ['a','b','c'] ), ['a','b','c'], "Empty string matches everything";
is $ascii->filter( 'a', ['a','b','c','ba','bac'] ), ['a','ba','bac'], "Single character matches";
is $ascii->filter( 'a', ['a',"hätte",'b'] ), ['a','hätte'], "Diacritics on the RHS are ignored";
is $ascii->filter( 'ä', ['a',"hätte",'b'] ), ['a', 'hätte'], "Diacritics on the LHS are ignored";
is $ascii->filter( 'aääa', ['aääa',"aaää","aäaä","aäää"] ), ['aääa',"aaää","aäaä","aäää"], "Diacritics on the LHS are ignored";
is $ascii->filter( '\\', ['foo\\bar',"aa*"] ), ['foo\\bar'], "Regex meta characters are no problem";
is $ascii->filter( '\\[]{}*+', ['\\[]{}*+',""] ), ['\\[]{}*+'], "Regex meta characters are no problem";

for my $t (@common_cases) {
    is $ascii->filter( $t->[0], $t->[1] ), $t->[2], $t->[3];
};

my @highlight = (
  [ 'z',        'cab',   'cab',      "No match, no highlight" ],
  [ 'ab',       'a/b',   '[a]/[b]',   "highlight highlights elements" ],
  [ 'a$c',      'a/$/c', '[a]/[$]/[c]', "Regex meta characters are no problem" ],
  [ 'a(c',      'a/(/c', '[a]/[(]/[c]', "Regex meta characters are no problem" ],
  [ 'ab',       'ab',    '[ab]',      "adjacent highlight elements get merged" ],
  [ 'aääa',     'aäää',  '[aäää]',     "Diacritics also work" ],
  [ 'a',        'cab',   'c[a]b',      "highlight middle" ],
  [ 'a',        'abc',   '[a]bc',      "highlight start" ],
  [ 'a',        'bca',   'bc[a]',        "highlight end" ],
  [ 'a',        'cäb',   'c[ä]b',      "highlight middle" ],
  [ 'a',        'äbc',   '[ä]bc',      "highlight start" ],
  [ 'a',        'bcä',   'bc[ä]',      "highlight end (nfd)" ],
  [ 'aa',       'bcaa',   'bc[aa]',    "continouus matches" ],
  [ 'aa',       'bcäa',   'bc[äa]',    "continouus matches (nfd)" ],
  [ 'aa',       "bc\N{LATIN SMALL LETTER A WITH DIAERESIS}a",   'bc[äa]',    "continouus matches (nfd)" ],
  [ 'aa',       'abca',   '[a]bc[a]',    "split" ],
);

subtest 'default highlighting' => sub {
    for my $t (@highlight) {
        is NFD($default->highlight( $t->[0], $t->[1] )), NFD($t->[2]), $t->[3];
    };
};

subtest 'html highlight callback' => sub{
    my $html = String::FuzzyMatch->new(
        highlight_start => '<highlight>',
        highlight_end => '</highlight>',
    );
    for my $t (@highlight) {
        my $expected = $t->[2];
        $expected =~ s/\[/<highlight>/g;
        $expected =~ s!\]!</highlight>!g;
        is NFD($html->highlight( $t->[0], $t->[1] )), NFD($expected), $t->[3];
    };
};

subtest 'custom highlight callback' => sub{
    my $custom = String::FuzzyMatch->new(
        highlight_cb => sub( $match ) { return "<<$match>>" },
    );
    for my $t (@highlight) {
        my $expected = $t->[2];
        $expected =~ s/\[/<</g;
        $expected =~ s/\]/>>/g;
        is NFD($custom->highlight( $t->[0], $t->[1] )), NFD($expected), $t->[3];
    };
};

subtest 'match hash-key extraction' => sub {
    my $f = String::FuzzyMatch->new(
        match => 'caption',
    );

    is $f->filter("aa", [ { caption => 'Neu' }, { caption => 'Alle Änderungen' } ]), [{caption => 'Alle Änderungen'}], "String hash-key extraction works";
};

subtest 'match subroutine extraction' => sub {
    my $f = String::FuzzyMatch->new(
        match => sub($o) { $o->{'caption'} },
    );

    is $f->filter("aa", [ { caption => 'Neu' }, { caption => 'Alle Änderungen' } ]), [{caption => 'Alle Änderungen'}], "Callback extraction works";
};

done_testing;
