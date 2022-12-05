use strict;
use warnings;
use Test::More tests => 23;
use Test::Number::Delta;
use RF::Functions qw{db_ratio ratio2db ratio_db db2ratio fsl_mhz_km fsl_ghz_km fsl_hz_m fsl_mhz_mi dbi_dbd dbd_dbi dbd2dbi dbi2dbd dipole_gain};

delta_within(db_ratio(2),    3.0103, 1e-4, 'db_ratio');
delta_within(db_ratio(1/2), -3.0103, 1e-4, 'db_ratio');
delta_within(ratio2db(2),    3.0103, 1e-4, 'ratio2db');
delta_within(ratio2db(1/2), -3.0103, 1e-4, 'ratio2db');

delta_within(ratio_db(3),    2, 1e-2, 'ratio_db');
delta_within(ratio_db(-3),  1/2, 1e-2, 'ratio_db');
delta_within(db2ratio(3),    2, 1e-2, 'db2ratio');
delta_within(db2ratio(-3),  1/2, 1e-2, 'db2ratio');

delta_within(fsl_mhz_km(2400, 5), 114.03, 1e-2, 'fsl_mhz_km');
delta_within(fsl_ghz_km(2.400, 5), 114.03, 1e-2, 'fsl_ghz_km');
delta_within(fsl_hz_m(2400e6, 5e3), 114.03, 1e-2, 'fsl_hz_m');
delta_within(fsl_mhz_mi(2400, 5 * 0.621371), 114.03, 1e-2, 'fsl_mhz_mi');

is(dipole_gain(), 2.15, 'dipole_gain');
is(dbi_dbd(0), 2.15, 'dbi_dbd');
is(dbd_dbi(2.15), 0, 'dbd_dbi');
is(dbd2dbi(0), 2.15, 'dbi_dbd');
is(dbi2dbd(2.15), 0, 'dbd_dbi');


{
  local $@;
  eval{fsl_mhz_km(0,100)};
  my $error = $@;
  ok($error);
  like($error, qr/must be positive/);
}

{
  local $@;
  eval{fsl_mhz_km(1000,-1)};
  my $error = $@;
  ok($error);
  like($error, qr/must be non-negative/);
}

{
  local $@;
  eval{RF::Functions::_fsl_constant(1000,1000)};
  my $error = $@;
  ok($error);
  like($error, qr/required/);
}

