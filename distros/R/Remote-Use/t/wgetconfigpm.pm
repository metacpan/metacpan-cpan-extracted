package wgetconfigpm;
use strict;
use warnings;

sub getarg {

  my $cache = -e '.orion.via.web' ? '.orion.via.web' : 't/.orion.via.web';
  return (
    command => 'wget -o /tmp/wget.log',
    commandoptions => '-O',
    host => 'http://orion.pcg.ull.es/~casiano/cpan',
    prefix => '/tmp/perl5lib/',
    ppmdf => $cache,
  );
}

1;
