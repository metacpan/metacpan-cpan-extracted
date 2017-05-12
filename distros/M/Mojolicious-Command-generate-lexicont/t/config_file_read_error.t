#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
no warnings 'once';

use FindBin;
use File::Copy;
use Test::Exception;

use Test::More tests => 3;

use lib "$FindBin::Bin/lib";

use_ok 'Mojolicious::Command::generate::lexicont';

my $l = new_ok 'Mojolicious::Command::generate::lexicont', [conf_file=>"@@@@@"];

$l->quiet(1);
$l->app(sub { Mojo::Server->new->build_app('Lexemes') });

throws_ok { $l->run("ja", "en") } qr/Config file cannot read/, 'config file cannot read';

