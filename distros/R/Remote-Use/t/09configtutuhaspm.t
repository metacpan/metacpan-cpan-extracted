#!/usr/bin/perl -I../lib -w
use Test::More tests => 1;

my $host = $ENV{REMOTE_USE_DEVELOPER};

SKIP: {
  skip "This test only run in the developer machine", 1 unless $host;

  system('rm -fR /tmp/perl5lib/* /home/pp2/perl5lib/*');

  require Remote::Use;

  my $config = -e 't/tutu/wgetconfigpm.pm' ? 't/tutu/wgetconfigpm.pm' : 'tutu/wgetconfigpm.pm';

  Remote::Use->import(config => 't/tutu/wgetconfigpm.pm', package => 'tutu::wgetconfigpm');
  require Math::Prime::XS;
  Math::Prime::XS->import(qw{:all});

  is_deeply([ primes(9) ], [2, 3, 5, 7], 'Math::Prime::XS imported and working');
}
