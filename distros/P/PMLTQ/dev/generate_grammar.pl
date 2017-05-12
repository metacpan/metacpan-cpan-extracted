#!/usr/bin/env perl
use strict;
use warnings;

use Parse::RecDescent 1.967009;
use File::Copy;
use FindBin;
use lib "$FindBin::RealBin/../lib";
use PMLTQ::Grammar;

chdir $FindBin::RealBin;

Parse::RecDescent->Precompile(
    { -standalone => 1, },
    PMLTQ::Grammar->grammar(),
    'PMLTQ::_Parser'
);

move("$FindBin::RealBin/_Parser.pm",
     "$FindBin::RealBin/../lib/PMLTQ/_Parser.pm");
