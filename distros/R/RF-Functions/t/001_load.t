use strict;
use warnings;
use Test::More tests => 12;
use Test::Number::Delta;
use RF::Functions qw{db_ratio ratio2db ratio_db db2ratio fsl_mhz_km fsl_ghz_km fsl_hz_m fsl_mhz_mi};

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
