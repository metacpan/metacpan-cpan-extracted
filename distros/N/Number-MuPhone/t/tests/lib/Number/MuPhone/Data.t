use strictures 2;
use Test::More;

use Number::MuPhone::Data;

ok( %Number::MuPhone::Data::idd_codes );
ok( %Number::MuPhone::Data::NANP_areas);

foreach my $key (keys %Number::MuPhone::Data::idd_codes) {
  like($key,qr/^\d+$/,'Valid Key');
  like( $Number::MuPhone::Data::idd_codes{$key}, qr/^[A-Za-z]{2,}$/,"Valid Value for key $key");
}

foreach my $key (keys %Number::MuPhone::Data::NANP_areas) {
  like($key,qr/^\d{3}$/,'Valid Key');
  like( $Number::MuPhone::Data::NANP_areas{$key}, qr/^[A-Z]{2}$/,"Valid Value for key $key");
}

done_testing();
