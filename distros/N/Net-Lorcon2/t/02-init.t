use Test::More;

BEGIN {
  if(!$ENV{LORCON_IF} || !$ENV{LORCON_INJ}) {
    plan skip_all => "Set LORCON_IF and LORCON_INJ to a valid interface and injector name to run these tests";
  } else {
    plan tests => 2
  }
};

use Net::Lorcon2 qw(:subs);

my $cards = lorcon_list_drivers();

my $ok = 0;
if (@$cards > 0) {
   $ok++;
}
$ok ? ok(1) : ok(0);

# Assumes it's safe to call init (which it is with current Lorcon2)
my $lorcon = Net::Lorcon2->new(
   driver    => $ENV{LORCON_INJ},
   interface => $ENV{LORCON_IF},
);

#ok($lorcon->isa("Net::Lorcon2"), "object isa Net::Lorcon2");
