#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use JSON 'decode_json';
no warnings 'once';

use FindBin;
use File::Copy;

use Test::More tests => 6;

use lib "$FindBin::Bin/lib";

use_ok 'Mojolicious::Command::generate::lexicont';

my $conf_file = "$FindBin::Bin/lexicont.test.conf";
my $l = new_ok 'Mojolicious::Command::generate::lexicont', [conf_file=>$conf_file];

$l->quiet(1);
$l->app(sub { Mojo::Server->new->build_app('Lexemes') });

$l->run("ja", "en");

my $file = "$FindBin::Bin/public/ja.json";

my $data = decode_json(_get_content($file));

is ($data->{key1} , "日本語" , "ja json key1");
is ($data->{key2} , "英語" , "ja json key2");

$file = "$FindBin::Bin/public/en.json";

$data = decode_json(_get_content($file));

is ($data->{key1} , "Japanese" , "en json key1");
is ($data->{key2} , "English" , "en json key2");

unlink "$FindBin::Bin/lib/Lexemes/I18N/en.pm";
#unlink "$FindBin::Bin/oublic/ja.json";
#unlink "$FindBin::Bin/oublic/en.json";

sub _get_content {
  my $file = shift;

  open my $fh, '<', $file
    or die "Can't open file \"$file\": $!";
  
  my $content = do { local $/; <$fh> };
 
  close $fh;

  return $content;
}