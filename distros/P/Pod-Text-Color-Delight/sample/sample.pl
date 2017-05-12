#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Pod::Text::Color::Delight;

my $parser = Pod::Text::Color::Delight->new;
$parser->parse_from_filehandle("$FindBin::Bin/../lib/Pod/Text/Color/Delight.pm");
