#! /usr/bin/perl
#---------------------------------------------------------------------

use Test::More tests => 4;

BEGIN {
    use_ok('PostScript::File');
    use_ok('PostScript::File::Functions');
    use_ok('PostScript::File::Metrics');

  SKIP: {
    # RECOMMEND PREREQ: Font::AFM
    eval { require Font::AFM };
    skip "Font::AFM not installed", 1 if $@;

    use_ok('PostScript::File::Metrics::Loader');
  };
}

diag("Testing PostScript::File $PostScript::File::VERSION");
