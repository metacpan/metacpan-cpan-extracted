#!/usr/bin/perl -I../lib -Ilib/ -w
use strict;
use Test::More tests => 1;
# Don't run this program from the "t/" directory

my $host = $ENV{REMOTE_USE_DEVELOPER};

SKIP: {
  skip "This test only run in the developer machine", 1 unless $host;

  system('rm -fR /tmp/perl5lib/* /home/pp2/perl5lib/*');

  require Remote::Use;

  my $config = 't/t_rsyncconfig';
  Remote::Use->import(config => $config,);
  require Math::Prime::XS;
  Math::Prime::XS->import(':all');

  is_deeply([ primes(9) ], [2, 3, 5, 7], 'Math::Prime::XS imported and working');
}
