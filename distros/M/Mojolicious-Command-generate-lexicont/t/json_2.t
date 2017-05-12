#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use JSON 'decode_json';
no warnings 'once';

use FindBin;
use File::Copy;

use Test::More tests => 3;

use lib "$FindBin::Bin/lib";

use_ok 'Mojolicious::Command::generate::lexicont';

my $conf_file = "$FindBin::Bin/lexicont.nojson_1.conf";
my $l = new_ok 'Mojolicious::Command::generate::lexicont', [conf_file=>$conf_file];

$l->quiet(1);
$l->app(sub { Mojo::Server->new->build_app('Lexemes') });

$l->run("ja", "en");

my $file = "$FindBin::Bin/public/en.json";

isnt ( -e $file , "not output json");

unlink "$FindBin::Bin/lib/Lexemes/I18N/en.pm";

