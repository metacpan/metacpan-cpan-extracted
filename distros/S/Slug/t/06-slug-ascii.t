#!perl
use 5.008003;
use strict;
use warnings;
use utf8;
use Test::More tests => 10;
use Slug qw(slug_ascii);

# Basic transliteration (no slugification)
is(slug_ascii("Hello World"),     "Hello World",     "ASCII passthrough");
is(slug_ascii("Héllo Wörld"),     "Hello Woerld",    "accents transliterated, case preserved");
is(slug_ascii("Café Résumé"),     "Cafe Resume",     "acute accents");
is(slug_ascii("naïve"),           "naive",           "diaeresis");
is(slug_ascii("Straße"),          "Strasse",         "eszett");

# Preserves punctuation and spaces
is(slug_ascii("Hello, World!"),   "Hello, World!",   "punctuation preserved");
is(slug_ascii("foo.bar"),         "foo.bar",         "dot preserved");
is(slug_ascii("UPPER CASE"),      "UPPER CASE",      "case preserved");

# Cyrillic
is(slug_ascii("Привет мир"),      "Privet mir",      "Cyrillic transliterated");

# Greek
is(slug_ascii("Αθήνα"),           "Athina",          "Greek transliterated");
