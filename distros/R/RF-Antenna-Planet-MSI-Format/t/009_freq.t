use strict;
use warnings;
use Test::More tests => 27;
use Path::Class qw{dir file};
BEGIN { use_ok('RF::Antenna::Planet::MSI::Format') };

{
  my $antenna = RF::Antenna::Planet::MSI::Format->new;
  $antenna->frequency('140');
  is($antenna->frequency, "140");
  is($antenna->frequency_mhz, "140");
  is($antenna->frequency_mhz_lower, "140");
  is($antenna->frequency_mhz_upper, "140");
}

{
  my $antenna = RF::Antenna::Planet::MSI::Format->new;
  $antenna->frequency('140-146');
  is($antenna->frequency, "140-146");
  is($antenna->frequency_mhz, (140+146)/2);
  is($antenna->frequency_mhz_lower, "140");
  is($antenna->frequency_mhz_upper, "146");
}

{
  my $file = "$0.msi";
  my $antenna = RF::Antenna::Planet::MSI::Format->new;
  $antenna->read($file);
  my $freq = "5.15\2265.87 GHz";
  is($antenna->frequency, $freq);
  is($antenna->frequency_mhz, (5.15+5.87)*1000/2);
  is($antenna->frequency_mhz_lower, "5150");
  is($antenna->frequency_mhz_upper, "5870");
  is($antenna->frequency_ghz, (5.15+5.87)/2);
  is($antenna->frequency_ghz_lower, 5.15);
  is($antenna->frequency_ghz_upper, 5.87);
}

{
  my $file = "$0.msi";
  my $antenna = RF::Antenna::Planet::MSI::Format->new;
  my $freq = "5 7 GHz";
  $antenna->frequency($freq);
  is($antenna->frequency, $freq);
  is($antenna->frequency_mhz, 6000);
  is($antenna->frequency_mhz_lower, "5000");
  is($antenna->frequency_mhz_upper, "7000");
  is($antenna->frequency_ghz, 6);
  is($antenna->frequency_ghz_lower, 5);
  is($antenna->frequency_ghz_upper, 7);
}

{
  my $antenna = RF::Antenna::Planet::MSI::Format->new;
  $antenna->frequency('140-146 khz');
  is($antenna->frequency, "140-146 khz");
  is($antenna->frequency_mhz, .143);
  is($antenna->frequency_mhz_lower, .140);
  is($antenna->frequency_mhz_upper, .146);
}

