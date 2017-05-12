#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
no warnings 'once';

use FindBin;
use File::Copy;

use Test::More tests => 8;

use lib "$FindBin::Bin/lib";

use_ok 'Mojolicious::Command::generate::lexicont';

my $conf_file = "$FindBin::Bin/lexicont.test.conf";
my $l = new_ok 'Mojolicious::Command::generate::lexicont', [conf_file=>$conf_file];

$l->quiet(1);
$l->app(sub { Mojo::Server->new->build_app('Lexemes') });

$l->run("ja", "en", "zh" ,"es");

require_ok "$FindBin::Bin/lib/Lexemes/I18N/en.pm";

is_deeply \%Lexemes::I18N::en::Lexicon,
  {key1 => 'Japanese', key2 =>'English'},'correct english';

require_ok "$FindBin::Bin/lib/Lexemes/I18N/es.pm";

is_deeply \%Lexemes::I18N::es::Lexicon,
  {'key1' => 'japonés', key2 =>'idioma en Inglés'}, 'correct spanish';

require_ok "$FindBin::Bin/lib/Lexemes/I18N/zh.pm";

is_deeply \%Lexemes::I18N::zh::Lexicon,
  {'key1' => '日本', key2 =>'英语'}, 'correct chinese';

unlink "$FindBin::Bin/lib/Lexemes/I18N/en.pm";
unlink "$FindBin::Bin/lib/Lexemes/I18N/es.pm";
unlink "$FindBin::Bin/lib/Lexemes/I18N/zh.pm";
unlink "$FindBin::Bin/public/en.pm";
unlink "$FindBin::Bin/public/es.pm";
unlink "$FindBin::Bin/public/zh.pm";