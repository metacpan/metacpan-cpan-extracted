
use strict;
use Test::More;
use File::Spec;
use Net::UPS;

my $upsrc = File::Spec->catfile($ENV{HOME}, ".upsrc");
my $ups = undef;
unless (defined($ups = Net::UPS->new($upsrc)) ) {
    plan(skip_all=>Net::UPS->errstr);
    exit(0);
}

plan(tests=>18);

ok($ups);

use_ok("Net::UPS");
use_ok("Net::UPS::Address");



my $address = Net::UPS::Address->new();
ok(    $address->can("city") 
    && $address->can("postal_code") 
    && $address->can("state") 
    && $address->can("country_code")
    && $address->can("is_residential")
    && $address->can("quality")
);

$address->city("East Lansing");
$address->postal_code("48823");
$address->state("MI");
$address->country_code("US");
$address->is_residential(1);

ok($address->city           eq "East Lansing"   );
ok($address->postal_code    eq "48823"          );
ok($address->state          eq "MI"             );
ok($address->country_code   eq "US"             );
ok($address->is_residential eq "1"              );
ok($address->quality        eq undef            );

my $addresses = $address->validate();
ok( $addresses && ref($addresses) && (ref $addresses eq "ARRAY"));
ok( $addresses->[0]->quality == 1 );
ok( $addresses->[0]->is_residential eq undef);
ok( $addresses->[0]->is_exact_match     );
ok(!$addresses->[0]->is_poor_match      );
ok( $addresses->[0]->is_close_match     );
ok( $addresses->[0]->is_very_close_match);
ok( $addresses->[0]->is_match           );
