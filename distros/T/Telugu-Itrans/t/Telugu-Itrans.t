use strict;
use warnings;
use utf8;

use Test::More tests => 2;
BEGIN { use_ok('Telugu::Itrans') };

my $itrans = Telugu::Itrans->new();
my $name = $itrans->itrans("raajkumaarreDDi");

ok($name eq "రాజ్కుమార్రెడ్డి");
