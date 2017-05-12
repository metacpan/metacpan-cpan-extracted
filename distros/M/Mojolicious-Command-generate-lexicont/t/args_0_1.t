#!/usr/bin/env perl

use strict;
use warnings;
no warnings 'once';

use FindBin;
use Test::Exception;

use Test::More tests => 4;

use lib "$FindBin::Bin/lib";

use_ok 'Mojolicious::Command::generate::lexicont';

my $conf_file = "$FindBin::Bin/lexicont.test.conf";
my $l = new_ok 'Mojolicious::Command::generate::lexicont', [conf_file=>$conf_file];

$l->quiet(1);
$l->app(sub { Mojo::Server->new->build_app('Lexemes') });

throws_ok { $l->run() }      qr/usage: APPLICATION generate lexicont src_lang dest_lang .../, 'argument none';
throws_ok { $l->run("en") }  qr/usage: APPLICATION generate lexicont src_lang dest_lang .../, 'argument one';

