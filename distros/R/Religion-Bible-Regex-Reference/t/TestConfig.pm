package t::TestConfig;
use Test::Base 0.51 -Base;
use Religion::Bible::Regex::Config;
use Religion::Bible::Regex::Builder;
use Religion::Bible::Regex::Reference;
use Data::Dumper;

use utf8;
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

#delimiters('===', '+++');

$^W = 0;
