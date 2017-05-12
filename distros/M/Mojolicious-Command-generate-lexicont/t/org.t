#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use JSON 'decode_json';
no warnings 'once';

use FindBin;
use File::Copy;

use Test::More tests => 18;

use lib "$FindBin::Bin/lib";

use_ok 'Mojolicious::Command::generate::lexicont';

copy("$FindBin::Bin/lib/Lexemes2/I18N/ja.ori","$FindBin::Bin/lib/Lexemes2/I18N/ja.pm");

my $conf_file = "$FindBin::Bin/lexicont.test.conf";
my $l = new_ok 'Mojolicious::Command::generate::lexicont', [conf_file=>$conf_file];

$l->quiet(1);
$l->app(sub { Mojo::Server->new->build_app('Lexemes2') });

$l->run("ja", "en", "zh" ,"es");

require_ok "$FindBin::Bin/lib/Lexemes2/I18N/ja.pm";

is_deeply \%Lexemes2::I18N::ja::Lexicon,
  {key2 =>'日本語', key3 => '英語'},'correct japanese';

require_ok "$FindBin::Bin/lib/Lexemes2/I18N/en.pm";

is_deeply \%Lexemes2::I18N::en::Lexicon,
  {key2 =>'Japanese', key3 => 'English'},'correct english';

require_ok "$FindBin::Bin/lib/Lexemes2/I18N/es.pm";

is_deeply \%Lexemes2::I18N::es::Lexicon,
  {'key2' => 'japonés', key3 =>'idioma en Inglés'}, 'correct spanish';

require_ok "$FindBin::Bin/lib/Lexemes2/I18N/zh.pm";

is_deeply \%Lexemes2::I18N::zh::Lexicon,
  {'key2' => '日本', key3 =>'英语'}, 'correct chinese';

my $file = "$FindBin::Bin/public/ja.json";

my $data = decode_json(_get_content($file));

is ($data->{key2} , "日本語" , "ja json key1");
is ($data->{key3} , "英語" , "ja json key2");

$file = "$FindBin::Bin/public/en.json";

$data = decode_json(_get_content($file));

is ($data->{key2} , "Japanese" , "en json key1");
is ($data->{key3} , "English" , "en json key2");

$file = "$FindBin::Bin/public/es.json";

$data = decode_json(_get_content($file));

is ($data->{key2} , "japonés" , "es json key1");
is ($data->{key3} , "idioma en Inglés" , "es json key2");

$file = "$FindBin::Bin/public/zh.json";

$data = decode_json(_get_content($file));

is ($data->{key2} , "日本" , "zh json key1");
is ($data->{key3} , "英语" , "zh json key2");

unlink "$FindBin::Bin/lib/Lexemes2/I18N/ja.pm";
unlink "$FindBin::Bin/lib/Lexemes2/I18N/en.pm";
unlink "$FindBin::Bin/lib/Lexemes2/I18N/es.pm";
unlink "$FindBin::Bin/lib/Lexemes2/I18N/zh.pm";
unlink "$FindBin::Bin/oublic/ja.json";
unlink "$FindBin::Bin/oublic/en.json";
unlink "$FindBin::Bin/oublic/es.json";
unlink "$FindBin::Bin/oublic/zh.json";

sub _get_content {
  my $file = shift;

  open my $fh, '<', $file
    or die "Can't open file \"$file\": $!";
  
  my $content = do { local $/; <$fh> };
 
  close $fh;

  return $content;
}