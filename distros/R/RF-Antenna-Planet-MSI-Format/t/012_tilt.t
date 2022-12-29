use strict;
use warnings;
use Test::More tests => 59;
BEGIN { use_ok('RF::Antenna::Planet::MSI::Format') };

{
  my $antenna = RF::Antenna::Planet::MSI::Format->new;
  isa_ok($antenna, 'RF::Antenna::Planet::MSI::Format');

  is($antenna->tilt, undef, 'undef');
  is($antenna->electrical_tilt_degrees, undef, 'undef');

  is($antenna->tilt('JUNK'), 'JUNK', 'JUNK');
  is($antenna->electrical_tilt_degrees, undef, 'JUNK');

  is($antenna->tilt('NONE'), 'NONE', 'NONE');
  is($antenna->electrical_tilt_degrees, 0, 'NONE');

  is($antenna->tilt('MECHANICAL'), 'MECHANICAL', 'MECHANICAL');
  is($antenna->electrical_tilt_degrees, 0, 'MECHANICAL');

  is($antenna->tilt('Mechanical'), 'Mechanical', 'Mechanical');
  is($antenna->electrical_tilt_degrees, 0, 'Mechanical');

  is($antenna->tilt('1.25'), '1.25', '1.25');
  is($antenna->electrical_tilt_degrees, 1.25, '1.25');

  is($antenna->tilt('8-Deg Electrical'), '8-Deg Electrical', '8-Deg Electrical');
  is($antenna->electrical_tilt_degrees, 8, '8-Deg Electrical');

  is($antenna->tilt('8-Deg E-Tilt'), '8-Deg E-Tilt', '8-Deg E-Tilt');
  is($antenna->electrical_tilt_degrees, 8, '8-Deg E-Tilt');

  is($antenna->tilt('T1'), 'T1', 'T1');
  is($antenna->electrical_tilt_degrees, 1, 'T1');

  is($antenna->tilt('T10'), 'T10', 'T10');
  is($antenna->electrical_tilt_degrees, 10, 'T10');

  is($antenna->tilt('T100'), 'T100', 'T100'); #>90 should be an invalid downtilt
  is($antenna->electrical_tilt_degrees, undef, 'T100');

  is($antenna->tilt('1T'), '1T', '1T');
  is($antenna->electrical_tilt_degrees, 1, '1T');

  is($antenna->tilt('10T'), '10T', '10T');
  is($antenna->electrical_tilt_degrees, 10, '10T');

  is($antenna->tilt('100T'), '100T', '100T'); #>90 should be an invalid downtilt
  is($antenna->electrical_tilt_degrees, undef, '100T');

  is($antenna->tilt('ELECTRICAL 11'), 'ELECTRICAL 11', 'ELECTRICAL 11');
  is($antenna->electrical_tilt_degrees, 11, 'ELECTRICAL 11');

  is($antenna->tilt('ELECTRICAL 110'), 'ELECTRICAL 110', 'ELECTRICAL 110'); #>90 should be an invalid downtilt
  is($antenna->electrical_tilt_degrees, undef, 'ELECTRICAL 110');

  is($antenna->tilt('ELECTRICAL 11 degrees'), 'ELECTRICAL 11 degrees', 'ELECTRICAL 11 degrees');
  is($antenna->electrical_tilt_degrees, 11, 'ELECTRICAL 11 degrees');

  is($antenna->tilt('ELECTRICAL'), 'ELECTRICAL', 'ELECTRICAL');
  is($antenna->electrical_tilt_degrees, undef, 'ELECTRICAL');

  is($antenna->electrical_tilt('11'), '11', 'ELECTRICAL_TILT 11');
  is($antenna->electrical_tilt_degrees, 11, 'ELECTRICAL_TILT 11');

  is($antenna->electrical_tilt('1.25'), '1.25', 'ELECTRICAL_TILT 1.25');
  is($antenna->electrical_tilt_degrees, 1.25, 'ELECTRICAL_TILT 1.25');

  is($antenna->electrical_tilt('11 degrees'), '11 degrees', 'ELECTRICAL_TILT 11 degrees');
  is($antenna->electrical_tilt_degrees, 11, 'ELECTRICAL_TILT 11 degrees');

  is($antenna->electrical_tilt('111 degrees'), '111 degrees', 'ELECTRICAL_TILT 111 degrees');
  is($antenna->electrical_tilt_degrees, undef, 'ELECTRICAL_TILT 111 degrees');

}
{
  my $antenna = RF::Antenna::Planet::MSI::Format->new;
  isa_ok($antenna, 'RF::Antenna::Planet::MSI::Format');
  is($antenna->tilt('ELECTRICAL'), 'ELECTRICAL', 'ELECTRICAL');
  is($antenna->electrical_tilt_degrees, undef, 'comment empty');

  is($antenna->comment('ELECTRICAL_TILT 8'), 'ELECTRICAL_TILT 8', 'COMMENT ELECTRICAL_TILT 8');
  is($antenna->electrical_tilt_degrees, 8, 'COMMENT ELECTRICAL_TILT 8');

  is($antenna->comment('ELECTRICAL_TILT 8 degrees'), 'ELECTRICAL_TILT 8 degrees', 'COMMENT ELECTRICAL_TILT 8 degrees');
  is($antenna->electrical_tilt_degrees, 8, 'COMMENT ELECTRICAL_TILT 8 degrees');

  is($antenna->comment('E-TILT 8 degrees'), 'E-TILT 8 degrees', 'COMMENT E-TILT 8 degrees');
  is($antenna->electrical_tilt_degrees, 8, 'COMMENT E-TILT 8 degrees');

  is($antenna->comment('E-TILT 8'), 'E-TILT 8', 'COMMENT E-TILT 8');
  is($antenna->electrical_tilt_degrees, 8, 'COMMENT E-TILT 8');

  is($antenna->comment('ETilt -2 deg'), 'ETilt -2 deg', 'COMMENT ETilt -2 deg');
  is($antenna->electrical_tilt_degrees, 2, 'COMMENT ETilt -2 deg');
}
