#!/usr/bin/perl -I../lib -w
use Test::More tests => 2;

use strict;

my $host = $ENV{REMOTE_USE_DEVELOPER};

SKIP: {
  skip "This test only run in the developer machine", 2 unless $host;

  system('rm -fR /tmp/perl5lib/* /home/pp2/perl5lib/*');

  my $config = -e 't/wgetwithbinconfig' ? 't/wgetwithbinconfig' : 'wgetwithbinconfig';
  require Remote::Use;
  Remote::Use->import(config => $config, package => 'wgetwithbinconfig');

  require Parse::Eyapp;
  require Parse::Eyapp::Treeregexp;

  $ENV{PERL5LIB} .= ":/tmp/perl5lib/files";
  $ENV{PATH} .= ":/tmp/perl5lib/bin";

  ok(-x '/tmp/perl5lib/bin/eyapp', 'Executable was transferred and has permits');

  my $got = `eyapp -V`;
  like($got, qr{version}, 'executable executes ok');
}
