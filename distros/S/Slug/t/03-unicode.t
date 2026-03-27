#!perl
use 5.008003;
use strict;
use warnings;
use utf8;
use Test::More tests => 25;
use Slug qw(slug);

# Latin-1 Supplement
is(slug("Héllo Wörld"),       "hello-woerld",      "Latin-1 accented vowels");
is(slug("Café"),              "cafe",              "acute accent");
is(slug("Résumé"),            "resume",            "multiple accents");
is(slug("naïve"),             "naive",             "diaeresis");
is(slug("Ångström"),          "angstroem",         "ring above + umlaut");
is(slug("Straße"),            "strasse",           "eszett");

# Latin Extended-A
is(slug("Łódź"),              "lodz",              "Polish stroke L + accents");
is(slug("Česká"),             "ceska",             "Czech caron");
is(slug("Đorđe"),             "dorde",             "Serbian D-stroke");
is(slug("İstanbul"),          "istanbul",          "Turkish dotted I");

# Ligatures
is(slug("Æsop"),              "aesop",             "AE ligature");
is(slug("Œuvre"),             "oeuvre",             "OE ligature");

# Cyrillic
is(slug("Привет"),            "privet",            "Russian hello");
is(slug("Москва"),            "moskva",            "Moscow");
is(slug("Мир"),               "mir",               "Russian mir");

# Greek
is(slug("Αθήνα"),             "athina",            "Athens in Greek");
is(slug("Φιλοσοφία"),         "filosofia",         "Philosophy in Greek");
is(slug("Ωμέγα"),             "omega",             "Omega");

# Vietnamese
is(slug("Hà Nội"),            "ha-noi",            "Hanoi");

# Fullwidth
is(slug("Ｈｅｌｌｏ"),       "hello",             "fullwidth latin");

# Mixed scripts
is(slug("Hello Мир World"),   "hello-mir-world",   "mixed Latin + Cyrillic");

# Currency and symbols from transliteration
is(slug("100€ price"),        "100eur-price",      "euro sign");
is(slug("©2024"),             "c2024",             "copyright at start");

is(slug("®brand"),            "rbrand",            "registered sign");
is(slug("™mark"),             "tmmark",            "trademark");
