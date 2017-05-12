#!/usr/bin/perl -I../lib -w
use strict;
use Test::More tests => 2;

my $host = $ENV{REMOTE_USE_DEVELOPER};

SKIP: {
  skip "This test only run in the developer machine", 2 unless $host;

  system('rm -fR /tmp/perl5lib/* /home/pp2/perl5lib/*');

  require Remote::Use;
  my $config = -e 't/wgetconfigpm.pm' ? 't/wgetconfigpm.pm' : 'wgetconfigpm.pm';
  Remote::Use->import(config => $config, package => 'wgetconfigpm');


  require Math::Prime::XS;
  Math::Prime::XS->import(qw{:all});

  is_deeply([ primes(9) ], [2, 3, 5, 7], 'Math::Prime::XS imported and working');

  is_deeply([ primes(4, 9) ], [ 5, 7], 'Math::Prime::XS::primes imported and working');
}
