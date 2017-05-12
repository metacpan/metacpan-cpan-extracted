use strict;
use warnings;
use Test::More tests => 2;
use t::useragent;

use_ok('Net::Plazes::Plaze');

my $ua = t::useragent->new({
			    is_success => 1,
			   });

{
  my $p = Net::Plazes::Plaze->new();
  isa_ok($p, 'Net::Plazes::Plaze');
}
