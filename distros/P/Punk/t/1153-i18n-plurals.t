#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();
use Punk ();

# Plurals, by CLDR rule.
#
# The whole point of this file is the numbers a `$count == 1` implementation
# gets wrong. English has two forms and would pass a test written only in
# English, which is why the table below is mostly not English: Polish changes
# form at 2 and again at 22, Arabic has six categories including one for zero
# and one for two, and Japanese has one form for everything.
#
# A plural system that is wrong is wrong INVISIBLY - the sentence is
# grammatical, just not for that number - so these are asserted per number
# rather than spot-checked.

my $dir = File::Temp::tempdir(CLEANUP => 1);
sub cat {
    my ($tag, $json) = @_;
    open my $fh, '>:raw', File::Spec->catfile($dir, "$tag.json") or die $!;
    print $fh $json;
    close $fh;
}

cat(en => '{ "items": { "one": "1 item", "other": "{count} items" } }');
cat(pl => '{ "items": { "one":  "{count} produkt",
                        "few":  "{count} produkty",
                        "many": "{count} produktow",
                        "other":"{count} produktu" } }');
cat(ar => '{ "items": { "zero": "no items",  "one":  "one item",
                        "two":  "two items", "few":  "few {count}",
                        "many": "many {count}", "other":"other {count}" } }');
cat(ru => '{ "items": { "one":  "{count} tovar",
                        "few":  "{count} tovara",
                        "many": "{count} tovarov",
                        "other":"{count} tovara" } }');
cat(fr => '{ "items": { "one": "{count} article", "other": "{count} articles" } }');
cat(ja => '{ "items": { "other": "{count} ko" } }');
cat(cs => '{ "items": { "one": "{count} polozka", "few": "{count} polozky",
                        "other": "{count} polozek" } }');

eval qq{
    package PApp;
    use Punk;
    plugin 'I18n' => { dir => '$dir', default => 'en' };
    get '/n/:count' => sub {
        my \$c = shift;
        \$c->text(\$c->locale('items', count => \$c->param('count')));
    };
    1;
} or die $@;

my $app = PApp->to_app;
sub say_n {
    my ($lang, $n) = @_;
    my $r = $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => "/n/$n",
        QUERY_STRING   => '',
        'psgi.input'   => undef,
        'psgi.errors'  => \*STDERR,
        HTTP_ACCEPT_LANGUAGE => $lang,
    });
    return $r->[2][0];
}

# ---- English: the two-form case that proves nothing on its own ---------------
{
    is(say_n(en => 1), '1 item',   'en 1 is `one`');
    is(say_n(en => 0), '0 items',  'en 0 is `other` - English does not have a zero form');
    is(say_n(en => 2), '2 items',  'en 2 is `other`');
    is(say_n(en => 21), '21 items','and 21 is still `other`, unlike Slavic');
}

# ---- Polish: `few` at 2-4, and again at 22-24 --------------------------------
# The numbers a $count == 1 implementation gets wrong, and the reason this
# plugin encodes rules rather than a branch.
{
    is(say_n(pl => 1),  '1 produkt',      'pl 1 is `one`');
    is(say_n(pl => 2),  '2 produkty',     'pl 2 is `few`');
    is(say_n(pl => 3),  '3 produkty',     'pl 3 is `few`');
    is(say_n(pl => 5),  '5 produktow',    'pl 5 is `many`');
    is(say_n(pl => 12), '12 produktow',
        'pl 12 is `many` - the teens are an exception to the units rule');
    is(say_n(pl => 14), '14 produktow',   'and so is 14');
    is(say_n(pl => 22), '22 produkty',
        'pl 22 is `few` AGAIN - the rule is on the last digit, so it comes '
      . 'back around, which is exactly what a $count == 1 branch cannot do');
    is(say_n(pl => 25), '25 produktow',   'pl 25 is `many`');
    is(say_n(pl => 111),'111 produktow',  'pl 111 is `many` (the 11 exception)');
}

# ---- Russian: same categories, DIFFERENT rule from Polish --------------------
{
    is(say_n(ru => 1),  '1 tovar',    'ru 1 is `one`');
    is(say_n(ru => 21), '21 tovar',
        'ru 21 is `one` - where Polish 21 is `many`. Two Slavic languages '
      . 'with the same category names and different rules is why a family '
      . 'cannot be shared by eye');
    is(say_n(ru => 2),  '2 tovara',   'ru 2 is `few`');
    is(say_n(ru => 5),  '5 tovarov',  'ru 5 is `many`');
    is(say_n(ru => 11), '11 tovarov', 'ru 11 is `many`');
}

# ---- Arabic: six categories, including zero and two -------------------------
{
    is(say_n(ar => 0),   'no items',    'ar 0 is `zero` - a category English has no use for');
    is(say_n(ar => 1),   'one item',    'ar 1 is `one`');
    is(say_n(ar => 2),   'two items',   'ar 2 is `two`');
    is(say_n(ar => 3),   'few 3',       'ar 3 is `few`');
    is(say_n(ar => 11),  'many 11',     'ar 11 is `many`');
    is(say_n(ar => 100), 'other 100',   'ar 100 is `other`');
}

# ---- French: `one` covers zero ----------------------------------------------
{
    is(say_n(fr => 0), '0 article',  'fr 0 is `one` - French says "0 article"');
    is(say_n(fr => 1), '1 article',  'fr 1 is `one`');
    is(say_n(fr => 2), '2 articles', 'fr 2 is `other`');
}

# ---- Japanese: one form for every number ------------------------------------
{
    is(say_n(ja => 0), '0 ko', 'ja 0');
    is(say_n(ja => 1), '1 ko', 'ja 1 - no separate singular');
    is(say_n(ja => 7), '7 ko', 'ja 7');
}

# ---- a fraction is not a whole number ---------------------------------------
# CLDR's `v = 0` operand: 1 is `one` and 1.0 is not, because "1.0 item" is
# wrong in English.
{
    is(say_n(en => '1.5'), '1.5 items', 'en 1.5 is `other`');
    is(say_n(en => '1.0'), '1.0 items',
        'and so is 1.0 - the rule is `i = 1 and v = 0`, so a visible fraction '
      . 'takes the other branch even when the value is one');
    is(say_n(cs => '1.5'), '1.5 polozek',
        'Czech names the fractional branch itself, and gets it');
}

# ---- a missing category falls back to `other` -------------------------------
{
    my $part = File::Temp::tempdir(CLEANUP => 1);
    open my $fh, '>:raw', File::Spec->catfile($part, 'pl.json') or die $!;
    print $fh '{ "items": { "one": "jeden", "other": "inne" } }';
    close $fh;
    open my $e, '>:raw', File::Spec->catfile($part, 'en.json') or die $!;
    print $e '{ "items": { "one": "1", "other": "n" } }';
    close $e;

    eval qq{
        package PPart;
        use Punk;
        plugin 'I18n' => { dir => '$part', default => 'en' };
        get '/n/:count' => sub {
            my \$c = shift;
            \$c->text(\$c->locale('items', count => \$c->param('count')));
        };
        1;
    } or die $@;
    my $a = PPart->to_app;
    my $hit = sub {
        $a->({ REQUEST_METHOD => 'GET', PATH_INFO => "/n/$_[0]",
               QUERY_STRING => '', 'psgi.input' => undef,
               'psgi.errors' => \*STDERR,
               HTTP_ACCEPT_LANGUAGE => 'pl' })->[2][0];
    };
    is($hit->(2), 'inne',
        'a category the translator did not write falls back to `other` - a '
      . 'partly written plural map is a translation in progress, not a 500');
    is($hit->(1), 'jeden', 'and the ones that are written are used');
}

# ---- a language with no rule is a BOOT error --------------------------------
# Not a fallback to one/other: that is English's grammar applied to a language
# that does not have it, and it would read perfectly well while being wrong.
{
    my $unk = File::Temp::tempdir(CLEANUP => 1);
    open my $fh, '>:raw', File::Spec->catfile($unk, 'en.json') or die $!;
    print $fh '{ "items": { "one": "1", "other": "n" } }';
    close $fh;
    open my $x, '>:raw', File::Spec->catfile($unk, 'xx.json') or die $!;
    print $x '{ "items": { "one": "a", "other": "b" } }';
    close $x;

    eval qq{
        package PUnknown;
        use Punk;
        plugin 'I18n' => { dir => '$unk', default => 'en' };
        1;
    };
    my $err = $@ || '';
    like($err, qr/no plural rule/,
        'a plural map in a language with no rule fails at boot');
    like($err, qr/\bxx\b/, 'and the message names the locale');
}

# ---- a language with no rule and no plurals is fine -------------------------
{
    my $ok = File::Temp::tempdir(CLEANUP => 1);
    open my $fh, '>:raw', File::Spec->catfile($ok, 'en.json') or die $!;
    print $fh '{ "hi": "hello" }';
    close $fh;
    open my $x, '>:raw', File::Spec->catfile($ok, 'xx.json') or die $!;
    print $x '{ "hi": "yo" }';
    close $x;

    my $lived = eval qq{
        package POkUnknown;
        use Punk;
        plugin 'I18n' => { dir => '$ok', default => 'en' };
        1;
    };
    ok($lived,
        'a language with no plural rule is perfectly usable for ordinary '
      . 'strings - the rule is only needed by a catalogue that uses one')
        or diag $@;
}

done_testing;
