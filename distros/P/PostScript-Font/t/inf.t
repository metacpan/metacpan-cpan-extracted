#! perl

use Test::More tests => 7;

use strict;

BEGIN {
    use_ok("PostScript::FontInfo");
}

chdir "t";

my $fontname = "ru______.inf";

my $info = eval { new PostScript::FontInfo($fontname) };
ok($info && !$@, "Loaded: $fontname");
is($info->FontName,         "RussellSquare",  "FontName");
is($info->FullName,         "Russell Square", "FullName");
is($info->FontFamily,       "RussellSquare",  "FontFamily");
is($info->PCFileNamePrefix, "ru___",          "PCFileNamePrefix");
is($info->Version,          "001.001",        "Version");

