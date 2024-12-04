use strict;
use warnings;
use Test::More;
use PDL::IO::ENVI;
use File::Spec::Functions;

my $hdr = readenvi_hdr(catfile qw(t t.hdr));
is_deeply $hdr, {
  'ENVI' => 1,
  'acquisition_time' => '2020-09-30T16:50:19.024Z',
  'bands' => '1',
  'byte_order' => '0',
  'coordinate_system_string' => [
    'PROJCS["WGS_1984_UTM_Zone_15N"',
    'GEOGCS["GCS_WGS_1984"',
    'DATUM["D_WGS_1984"',
    'SPHEROID["WGS_1984"',
    '6378137.0',
    '298.257223563]]',
    'PRIMEM["Greenwich"',
    '0.0]',
    'UNIT["Degree"',
    '0.0174532925199433]]',
    'PROJECTION["Transverse_Mercator"]',
    'PARAMETER["False_Easting"',
    '500000.0]',
    'PARAMETER["False_Northing"',
    '0.0]',
    'PARAMETER["Central_Meridian"',
    '-93.0]',
    'PARAMETER["Scale_Factor"',
    '0.9996]',
    'PARAMETER["Latitude_Of_Origin"',
    '0.0]',
    'UNIT["Meter"',
    '1.0]]'
  ],
  'data_ignore_value' => '-1.000000e+34',
  'data_type' => '4',
  'file_type' => 'ENVI Standard',
  'header_offset' => '0',
  'interleave' => 'bsq',
  'lines' => '2370',
  'map_info' => [
    'UTM',
    '1.000',
    '1.000',
    '466860.000',
    '3353870.000',
    '1.000000e+01',
    '1.000000e+01',
    '15',
    'North',
    'WGS-84',
    'units=Meters'
  ],
  'samples' => '3409',
  'x_start' => '6691',
  'y_start' => '4616',
} or diag "got=", explain $hdr;

done_testing;
