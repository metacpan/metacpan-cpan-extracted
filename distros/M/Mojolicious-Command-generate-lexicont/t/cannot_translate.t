#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
no warnings 'once';

use FindBin;
use File::Copy;
use Test::Warn;

use Test::More tests => 3;

use lib "$FindBin::Bin/lib";

use_ok 'Mojolicious::Command::generate::lexicont';

my $conf_file = "$FindBin::Bin/lexicont.test.conf";
my $l = new_ok 'Mojolicious::Command::generate::lexicont', [conf_file=>$conf_file];

$l->quiet(1);
$l->app(sub { Mojo::Server->new->build_app('Lexemes') });

warnings_like { $l->run("ja", "qq") } [qr/Cannot translate/,qr/Cannot translate/], 'cannot translate';

