# These tests need a valid device
# Set LORCON_IF and LORCON_INJ

use Test::More;
BEGIN { 
  if(!$ENV{LORCON_IF} || !$ENV{LORCON_INJ}) {
    plan skip_all => "Set LORCON_IF and LORCON_INJ to a valid interface and injector name to run these tests";
  } else {
    plan tests => 3
  }
};
use Net::Lorcon2 qw(:all);

my $tx = Net::Lorcon2->new($ENV{LORCON_IF}, $ENV{LORCON_INJ});

ok($tx);
# Can't change the value, just check it returns something..
ok($tx->getchannel);
# Ditto..
ok($tx->getmode);

