#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk ();

# Accept-Language negotiation.
#
# A table, tested directly rather than through twenty forked servers, because
# every interesting case here is a header and an answer. The cases are the
# ones naive matching gets wrong - and the reason this is not simply a call
# into punk_accept.h is that punk_accept.h cannot parse this header at all:
# pa_parse takes a segment only when it finds a slash in it, and a language
# tag has none, so `en-GB,en;q=0.9` comes back as ZERO ranges through it.

my $neg = sub { Punk::Plugin::I18n->_negotiate($_[0], $_[1]) };

# ---- the ordinary cases ------------------------------------------------------
{
    is($neg->('en', ['en']), 'en', 'an exact match');
    is($neg->('fr', ['en', 'fr']), 'fr', 'and it picks the right one');
    is($neg->('en-GB', ['en-GB', 'en']), 'en-gb',
        'the exact match beats the prefix it would fall back to');
}

# ---- prefix fallback, and its asymmetry --------------------------------------
{
    is($neg->('en-GB,en;q=0.9', ['en']), 'en',
        'en-GB falls back to a catalogue holding en');
    is($neg->('zh-Hant-TW', ['zh']), 'zh',
        'and it truncates as far as it needs to: zh-Hant-TW to zh');

    is($neg->('en', ['en-GB']), undef,
        'but the fallback does NOT run the other way - a request for en is '
      . 'not served en-GB, because serving pt-BR to a request for pt gives a '
      . 'Portuguese speaker Brazilian spelling with no way to refuse');

    is($neg->('ens', ['en']), undef,
        'and the truncation is on subtag boundaries, never a byte prefix - '
      . 'ens is not English, which is what a bare strncmp would have said');
}

# ---- q-values ----------------------------------------------------------------
{
    is($neg->('en-GB,en;q=0.9', ['en', 'en-GB']), 'en-gb',
        'a higher q wins');
    is($neg->('fr;q=0.8, en;q=0.9', ['en', 'fr']), 'en',
        'regardless of the order they appear in');
    is($neg->('fr;q=0.9, en;q=0.9', ['en', 'fr']), 'fr',
        'and a tie breaks on the order in the header');
}

# ---- q=0 is an EXCLUSION, not an absence -------------------------------------
# The case naive negotiators miss, and the one that matters: a user who asked
# NOT to have French must not be given French.
{
    is($neg->('en, fr;q=0', ['en', 'fr']), 'en',
        'q=0 excludes that language');
    is($neg->('fr;q=0', ['fr']), undef,
        'even when it is the only catalogue there is - refused is not the '
      . 'same as unmentioned');
    is($neg->('fr;q=0, *', ['en', 'fr']), 'en',
        'and the exclusion survives a wildcard: the most specific match '
      . 'decides the q, so * does not smuggle French back in');
}

# ---- the wildcard ------------------------------------------------------------
{
    ok(defined $neg->('*', ['en', 'fr']),
        '* accepts whatever is there');
    is($neg->('de, *', ['en', 'fr']), $neg->('*', ['en', 'fr']),
        'a named language with no catalogue leaves the wildcard to answer');
}

# ---- case, which a real browser will send ------------------------------------
{
    is($neg->('EN-gb', ['en-GB']), 'en-gb',
        'language tags are case insensitive, and the tag comes back folded');
    is($neg->('en-gb', ['EN-GB']), 'en-gb',
        'on both sides of the comparison');
}

# ---- nothing acceptable ------------------------------------------------------
{
    is($neg->('de', ['en', 'fr']), undef,
        'no match is undef, and the caller falls through to the default');
    is($neg->('', ['en']), undef, 'an empty header matches nothing');
    is($neg->(undef, ['en']), undef, 'and so does no header at all');
}

# ---- a malformed header must not be able to error a response -----------------
# It is attacker controlled. The worst it may do is fail to match.
{
    my @junk = (
        ';;;', 'en;;q=', 'q=0.5', ',,,', 'en;q=', 'en;q=abc', '-', '--',
        'en-', '=', "en\tGB", 'en GB', '<script>', "en\0GB", 'a' x 500,
        join(',', ('en') x 200),
    );
    my $lived = 1;
    for my $h (@junk) {
        eval { $neg->($h, ['en', 'fr']); 1 } or do { $lived = 0; diag "died on: $h ($@)" };
    }
    ok($lived, 'no malformed header errors the negotiation');

    is($neg->('a' x 500, ['en']), undef,
        'a tag longer than any real one matches nothing rather than reading '
      . 'past the header');
    is($neg->(join(',', ('de') x 200), ['en']), undef,
        'and a header with two hundred tags is bounded, not unbounded');
}

# ---- the bound ---------------------------------------------------------------
{
    # PL_TAG_MAX_N tags are taken and the rest ignored. The catalogue named
    # only after the bound is therefore not found, which is the documented
    # cost of the bound rather than a bug.
    my $far = join(',', ('de') x 40) . ',fr';
    is($neg->($far, ['fr']), undef,
        'past the tag bound the header is ignored rather than grown - a '
      . 'client cannot make the parser allocate');
}

# ---- the ORDER a language is chosen ------------------------------------------
# Explicit beats implicit. A user who has chosen a language must not have the
# browser override them on the next request, which is what makes a language
# switcher work on the second page rather than only the first.
{
    use File::Temp ();
    use File::Spec ();

    my $dir = File::Temp::tempdir(CLEANUP => 1);
    for my $t (qw(en fr de)) {
        open my $fh, '>:raw', File::Spec->catfile($dir, "$t.json") or die $!;
        print $fh qq({ "hi": "$t" });
        close $fh;
    }

    eval qq{
        package I18nOrder;
        use Punk;
        plugin 'I18n' => { dir => '$dir', default => 'en' };
        get '/hi' => sub { \$_[0]->text(\$_[0]->locale('hi')) };
        1;
    } or die $@;
    my $app = I18nOrder->to_app;

    my $hit = sub {
        my (%o) = @_;
        my $r = $app->({
            REQUEST_METHOD => 'GET',
            PATH_INFO      => '/hi',
            QUERY_STRING   => $o{query} || '',
            'psgi.input'   => undef,
            'psgi.errors'  => \*STDERR,
            ($o{lang}   ? (HTTP_ACCEPT_LANGUAGE => $o{lang})   : ()),
            ($o{cookie} ? (HTTP_COOKIE          => $o{cookie}) : ()),
        });
        return $r->[2][0];
    };

    is($hit->(lang => 'fr'), 'fr', 'Accept-Language alone decides');
    is($hit->(), 'en', 'and with nothing at all, the default does');

    is($hit->(query => 'lang=de', lang => 'fr'), 'de',
        '?lang= beats Accept-Language - an explicit act on THIS request beats '
      . 'what the browser was configured with');

    is($hit->(cookie => 'punk.lang=de', lang => 'fr'), 'de',
        'the stored choice beats Accept-Language too - an explicit act on an '
      . 'earlier request is still explicit, and this is what makes a '
      . 'switcher work on the second page');

    is($hit->(query => 'lang=fr', cookie => 'punk.lang=de'), 'fr',
        'and ?lang= beats the stored choice, because it is more recent');

    is($hit->(query => 'lang=xx', lang => 'fr'), 'fr',
        'a ?lang= naming a locale with no catalogue falls THROUGH rather '
      . 'than failing - it is exactly the parameter people hand-edit, and a '
      . '500 there is a worse answer than a language');

    is($hit->(query => 'lang=en-GB', lang => 'fr'), 'en',
        'an explicit tag gets the same prefix fallback the header gets');

    is($hit->(cookie => 'other=1; punk.lang=de; another=2'), 'de',
        'the stored choice is found beside other cookies');
    is($hit->(cookie => 'punk.langy=de', lang => 'fr'), 'fr',
        'and a cookie whose name merely starts the same is not it');
}

done_testing;
