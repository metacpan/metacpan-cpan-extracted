#!/usr/bin/perl -I../lib -w
use Test::More;
use strict;

my $config;
BEGIN {
  if ( $ENV{REMOTE_USE_DEVELOPER}) {
    plan tests => 2;
  }
  else {
    plan skip_all => 'This tests only run during development';
  }

  system('rm -fR /tmp/perl5lib/* /home/pp2/perl5lib/*');

  $config = -e 't/wgetwithbinconfig' ? 't/wgetwithbinconfig' : 'wgetwithbinconfig';
}
use Remote::Use config => $config, package => 'wgetwithbinconfig';

use Parse::Eyapp;
use Parse::Eyapp::Treeregexp;

$ENV{PERL5LIB} .= ":/tmp/perl5lib/files";
$ENV{PATH} .= ":/tmp/perl5lib/bin";

ok(-x '/tmp/perl5lib/bin/eyapp', 'use: Executable was transferred and has permits');

my $got = `eyapp -V`;
like($got, qr{version}, 'use: executable executes ok');
