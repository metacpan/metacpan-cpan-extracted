@objects = (
  bless( {
    annotation => 'm',
    basic_authority => 'ISO 1000',
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'm',
    description => 'The metre is the length equal to 1 650 763.73 wavelengths in vacuum of the radiation corresponding to the transition between the levels 2p10 and 5d5 of the krypton-86 atom.',
    id => 'm',
    is_base => 1,
    name => 'metre',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'rad',
    basic_authority => 'ISO 1000',
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'rad',
    description => 'The radian is the plane angle between two radii of a circle that cut of, on the circumference, an arc equal in length to the radius.',
    id => 'rad',
    is_base => 1,
    name => 'radian',
    quantity_type => 'angle'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'Euc',
    basic_authority => 'POSC',
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'Euc',
    description => 'Unity is also called a Euclid. It is the base dimensionless quanity.',
    id => 'unity',
    is_base => 1,
    name => 'unity',
    quantity_type => 'dimensionless'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.3048',
    C => 1,
    D => 0,
    annotation => 'ft',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ft',
    id => 'ft',
    name => 'foot',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '12',
    C => 0,
    D => '39.37',
    annotation => 'US ft',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftUS',
    display => 'ftUS',
    id => 'ftUS',
    name => 'US survey foot',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.304797265',
    C => 1,
    D => 0,
    annotation => 'ft(Cla)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftCla',
    display => 'ftCla',
    id => 'ftCla',
    name => 'Clarke\'s foot',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.8288',
    C => 1,
    D => 0,
    annotation => 'fathom',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'f',
    id => 'fathom',
    name => 'fathom',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1852',
    C => 1,
    D => 0,
    annotation => 'NM',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'NM',
    display => 'minaut',
    id => 'nmi',
    name => 'Nautical Mile',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.000013597',
    C => 1,
    D => 0,
    annotation => 'M Ger',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'GLM',
    display => 'mGer',
    id => 'glm',
    name => 'German Legal Metre',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '792',
    C => 0,
    D => '39.37',
    annotation => 'ch',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'chUS',
    display => 'chUS',
    id => 'chUS',
    name => 'US Survey Chain',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '7.92',
    C => 0,
    D => '39.37',
    annotation => 'lk',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'lkUS',
    display => 'lkUS',
    id => 'lkUS',
    name => 'US Survey Link',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '63360',
    C => 0,
    D => '39.37',
    annotation => 'mi',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'miUS',
    display => 'miUS',
    id => 'miUS',
    name => 'US Survey Mile',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'km',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'km',
    id => 'km',
    name => 'kilometre',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.914391795',
    C => 1,
    D => 0,
    annotation => 'yd(Cla)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ydCla',
    display => 'ydCla',
    id => 'ydCla',
    name => 'Clarke\'s yard',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '20.11661949',
    C => 1,
    D => 0,
    annotation => 'ch(Cla)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'chCla',
    display => 'chCla',
    id => 'chCla',
    name => 'Clarke\'s chain',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.2011661949',
    C => 1,
    D => 0,
    annotation => 'lk(Cla)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'lkCla',
    display => 'lkCla',
    id => 'lkCla',
    name => 'Clarke\'s link',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '36',
    C => 0,
    D => '39.370147',
    annotation => 'yd(Se)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ydSe',
    display => 'ydSe',
    id => 'ydSe',
    name => 'British yard (Sears 1922)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '12',
    C => 0,
    D => '39.370147',
    annotation => 'ft(Se)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftSe',
    display => 'ftSe',
    id => 'ftSe',
    name => 'British foot (Sears 1922)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '792',
    C => 0,
    D => '39.370147',
    annotation => 'ch(Se)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'chSe',
    display => 'chSe',
    id => 'chSe',
    name => 'British chain (Sears 1922)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '7.92',
    C => 0,
    D => '39.370147',
    annotation => 'lk(Se)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'lkSe',
    display => 'lkSe',
    id => 'lkSe',
    name => 'British link (Sears 1922)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.9143992',
    C => 1,
    D => 0,
    annotation => 'yd(BnA)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ydBnA',
    display => 'ydBnA',
    id => 'ydBnA',
    name => 'British yard (Benoit 1895 A)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.9143992',
    C => 0,
    D => '3',
    annotation => 'ft(BnA)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftBnA',
    display => 'ftBnA',
    id => 'ftBnA',
    name => 'British foot (Benoit 1895 A)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '20.1167824',
    C => 1,
    D => 0,
    annotation => 'ch(BnA)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'chBnA',
    display => 'chBnA',
    id => 'chBnA',
    name => 'British chain (Benoit 1895 A)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.201167824',
    C => 1,
    D => 0,
    annotation => 'lk(BnA)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'lkBnA',
    display => 'lkBnA',
    id => 'lkBnA',
    name => 'British link (Benoit 1895 A)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '36',
    C => 0,
    D => '39.370113',
    annotation => 'yd(BnB)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ydBnB',
    display => 'ydBnB',
    id => 'ydBnB',
    name => 'British yard (Benoit 1895 B)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '12',
    C => 0,
    D => '39.370113',
    annotation => 'ft(BnB)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftBnB',
    display => 'ftBnB',
    id => 'ftBnB',
    name => 'British foot (Benoit 1895 B)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '792',
    C => 0,
    D => '39.370113',
    annotation => 'ch(BnB)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'chBnB',
    display => 'chBnB',
    id => 'chBnB',
    name => 'British chain (Benoit 1895 B)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '7.92',
    C => 0,
    D => '39.370113',
    annotation => 'lk(BnB)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'lkBnB',
    display => 'lkBnB',
    id => 'lkBnB',
    name => 'British link (Benoit 1895 B)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.9144025',
    C => 0,
    D => '3',
    annotation => 'ftBr(65)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftBr(65)',
    display => 'ftBr65',
    id => 'ftBr65',
    name => 'British foot (1865)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '12',
    C => 0,
    D => '39.370142',
    annotation => 'ft(Ind)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftInd',
    display => 'ftInd',
    id => 'ftInd',
    name => 'Indian foot',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.30479841',
    C => 1,
    D => 0,
    annotation => 'ft(Ind37)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftInd(37)',
    display => 'ftInd37',
    id => 'ftInd37',
    name => 'Indian foot (1937)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.3047996',
    C => 1,
    D => 0,
    annotation => 'ft(Ind62)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftInd(62)',
    display => 'ftInd62',
    id => 'ftInd62',
    name => 'Indian foot (1962)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.3047995',
    C => 1,
    D => 0,
    annotation => 'ft(Ind75)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftInd(75)',
    display => 'ftInd75',
    id => 'ftInd75',
    name => 'Indian foot (1975)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '36',
    C => 0,
    D => '39.370142',
    annotation => 'yd(Ind)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ydInd',
    display => 'ydInd',
    id => 'ydInd',
    name => 'Indian yard',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.91439523',
    C => 1,
    D => 0,
    annotation => 'yd(Ind37)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ydInd(37)',
    display => 'ydInd37',
    id => 'ydInd37',
    name => 'Indian yard (1937)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.9143988',
    C => 1,
    D => 0,
    annotation => 'yd(Ind62)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ydInd(62)',
    display => 'ydInd62',
    id => 'ydInd62',
    name => 'Indian yard (1962)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.9143985',
    C => 1,
    D => 0,
    annotation => 'yd(Ind75)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ydInd(75)',
    display => 'ydInd75',
    id => 'ydInd75',
    name => 'Indian yard (1975)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1609.344',
    C => 1,
    D => 0,
    annotation => 'mi',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'mi',
    id => 'mi',
    name => 'Statute Mile',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '6378300',
    C => 0,
    D => '20926201',
    annotation => 'ft(GC)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftGC',
    display => 'ftGC',
    id => 'ftGC',
    name => 'Gold Coast foot',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.14159265358979',
    C => 0,
    D => '180',
    annotation => 'deg',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'deg',
    id => 'deg',
    name => 'degree',
    quantity_type => 'angle'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.14159265358979',
    C => 0,
    D => '10800',
    annotation => 'min',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'min',
    id => 'min',
    name => 'arc-minute',
    quantity_type => 'angle'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.14159265358979',
    C => 0,
    D => '648000',
    annotation => 'sec',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'sec',
    id => 'sec',
    name => 'arc-second',
    quantity_type => 'angle'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.14159265358979',
    C => 0,
    D => '200',
    annotation => 'gr',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'gr',
    id => 'grad',
    name => 'grad',
    quantity_type => 'angle'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.14159265358979',
    C => 0,
    D => '200',
    annotation => 'gon',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'g',
    id => 'gon',
    name => 'gon',
    quantity_type => 'angle'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.0',
    C => 0,
    D => '1000000',
    annotation => 'urad',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'urad',
    display => 'X03BCrad',
    id => 'urad',
    name => 'microradian',
    quantity_type => 'angle'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.14159265358979',
    C => 0,
    D => '20000',
    annotation => 'c',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'c',
    id => 'cmin',
    name => 'centesimal minute',
    quantity_type => 'angle'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.14159265358979',
    C => 0,
    D => '2000000',
    annotation => 'cc',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'cc',
    id => 'csec',
    name => 'centesimal second',
    quantity_type => 'angle'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.14159265358979',
    C => 0,
    D => '3200',
    annotation => 'mil',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'mil',
    id => 'mil6400',
    name => 'mil 6400',
    quantity_type => 'angle'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.0',
    C => 0,
    D => '1000000',
    annotation => 'ppm',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'Euc',
    id => 'ppm',
    name => 'parts per million',
    quantity_type => 'dimensionless'
  }, 'Petrophysics::Units' )
);
$objects[3]{base_unit} = $objects[0];
$objects[4]{base_unit} = $objects[0];
$objects[5]{base_unit} = $objects[0];
$objects[6]{base_unit} = $objects[0];
$objects[7]{base_unit} = $objects[0];
$objects[8]{base_unit} = $objects[0];
$objects[9]{base_unit} = $objects[0];
$objects[10]{base_unit} = $objects[0];
$objects[11]{base_unit} = $objects[0];
$objects[12]{base_unit} = $objects[0];
$objects[13]{base_unit} = $objects[0];
$objects[14]{base_unit} = $objects[0];
$objects[15]{base_unit} = $objects[0];
$objects[16]{base_unit} = $objects[0];
$objects[17]{base_unit} = $objects[0];
$objects[18]{base_unit} = $objects[0];
$objects[19]{base_unit} = $objects[0];
$objects[20]{base_unit} = $objects[0];
$objects[21]{base_unit} = $objects[0];
$objects[22]{base_unit} = $objects[0];
$objects[23]{base_unit} = $objects[0];
$objects[24]{base_unit} = $objects[0];
$objects[25]{base_unit} = $objects[0];
$objects[26]{base_unit} = $objects[0];
$objects[27]{base_unit} = $objects[0];
$objects[28]{base_unit} = $objects[0];
$objects[29]{base_unit} = $objects[0];
$objects[30]{base_unit} = $objects[0];
$objects[31]{base_unit} = $objects[0];
$objects[32]{base_unit} = $objects[0];
$objects[33]{base_unit} = $objects[0];
$objects[34]{base_unit} = $objects[0];
$objects[35]{base_unit} = $objects[0];
$objects[36]{base_unit} = $objects[0];
$objects[37]{base_unit} = $objects[0];
$objects[38]{base_unit} = $objects[0];
$objects[39]{base_unit} = $objects[1];
$objects[40]{base_unit} = $objects[1];
$objects[41]{base_unit} = $objects[1];
$objects[42]{base_unit} = $objects[1];
$objects[43]{base_unit} = $objects[1];
$objects[44]{base_unit} = $objects[1];
$objects[45]{base_unit} = $objects[1];
$objects[46]{base_unit} = $objects[1];
$objects[47]{base_unit} = $objects[1];
$objects[48]{base_unit} = $objects[2];
@objects = (
  bless( {
    annotation => 'm',
    basic_authority => 'ISO 1000',
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'm',
    description => 'The metre is the length equal to 1 650 763.73 wavelengths in vacuum of the radiation corresponding to the transition between the levels 2p10 and 5d5 of the krypton-86 atom.',
    id => 'm',
    is_base => 1,
    name => 'metre',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'rad',
    basic_authority => 'ISO 1000',
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'rad',
    description => 'The radian is the plane angle between two radii of a circle that cut of, on the circumference, an arc equal in length to the radius.',
    id => 'rad',
    is_base => 1,
    name => 'radian',
    quantity_type => 'angle'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'Euc',
    basic_authority => 'POSC',
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'Euc',
    description => 'Unity is also called a Euclid. It is the base dimensionless quanity.',
    id => 'unity',
    is_base => 1,
    name => 'unity',
    quantity_type => 'dimensionless'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.3048',
    C => 1,
    D => 0,
    annotation => 'ft',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ft',
    id => 'ft',
    name => 'foot',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '12',
    C => 0,
    D => '39.37',
    annotation => 'US ft',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftUS',
    display => 'ftUS',
    id => 'ftUS',
    name => 'US survey foot',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.304797265',
    C => 1,
    D => 0,
    annotation => 'ft(Cla)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftCla',
    display => 'ftCla',
    id => 'ftCla',
    name => 'Clarke\'s foot',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.8288',
    C => 1,
    D => 0,
    annotation => 'fathom',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'f',
    id => 'fathom',
    name => 'fathom',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1852',
    C => 1,
    D => 0,
    annotation => 'NM',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'NM',
    display => 'minaut',
    id => 'nmi',
    name => 'Nautical Mile',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.000013597',
    C => 1,
    D => 0,
    annotation => 'M Ger',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'GLM',
    display => 'mGer',
    id => 'glm',
    name => 'German Legal Metre',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '792',
    C => 0,
    D => '39.37',
    annotation => 'ch',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'chUS',
    display => 'chUS',
    id => 'chUS',
    name => 'US Survey Chain',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '7.92',
    C => 0,
    D => '39.37',
    annotation => 'lk',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'lkUS',
    display => 'lkUS',
    id => 'lkUS',
    name => 'US Survey Link',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '63360',
    C => 0,
    D => '39.37',
    annotation => 'mi',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'miUS',
    display => 'miUS',
    id => 'miUS',
    name => 'US Survey Mile',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'km',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'km',
    id => 'km',
    name => 'kilometre',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.914391795',
    C => 1,
    D => 0,
    annotation => 'yd(Cla)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ydCla',
    display => 'ydCla',
    id => 'ydCla',
    name => 'Clarke\'s yard',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '20.11661949',
    C => 1,
    D => 0,
    annotation => 'ch(Cla)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'chCla',
    display => 'chCla',
    id => 'chCla',
    name => 'Clarke\'s chain',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.2011661949',
    C => 1,
    D => 0,
    annotation => 'lk(Cla)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'lkCla',
    display => 'lkCla',
    id => 'lkCla',
    name => 'Clarke\'s link',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '36',
    C => 0,
    D => '39.370147',
    annotation => 'yd(Se)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ydSe',
    display => 'ydSe',
    id => 'ydSe',
    name => 'British yard (Sears 1922)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '12',
    C => 0,
    D => '39.370147',
    annotation => 'ft(Se)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftSe',
    display => 'ftSe',
    id => 'ftSe',
    name => 'British foot (Sears 1922)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '792',
    C => 0,
    D => '39.370147',
    annotation => 'ch(Se)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'chSe',
    display => 'chSe',
    id => 'chSe',
    name => 'British chain (Sears 1922)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '7.92',
    C => 0,
    D => '39.370147',
    annotation => 'lk(Se)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'lkSe',
    display => 'lkSe',
    id => 'lkSe',
    name => 'British link (Sears 1922)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.9143992',
    C => 1,
    D => 0,
    annotation => 'yd(BnA)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ydBnA',
    display => 'ydBnA',
    id => 'ydBnA',
    name => 'British yard (Benoit 1895 A)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.9143992',
    C => 0,
    D => '3',
    annotation => 'ft(BnA)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftBnA',
    display => 'ftBnA',
    id => 'ftBnA',
    name => 'British foot (Benoit 1895 A)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '20.1167824',
    C => 1,
    D => 0,
    annotation => 'ch(BnA)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'chBnA',
    display => 'chBnA',
    id => 'chBnA',
    name => 'British chain (Benoit 1895 A)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.201167824',
    C => 1,
    D => 0,
    annotation => 'lk(BnA)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'lkBnA',
    display => 'lkBnA',
    id => 'lkBnA',
    name => 'British link (Benoit 1895 A)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '36',
    C => 0,
    D => '39.370113',
    annotation => 'yd(BnB)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ydBnB',
    display => 'ydBnB',
    id => 'ydBnB',
    name => 'British yard (Benoit 1895 B)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '12',
    C => 0,
    D => '39.370113',
    annotation => 'ft(BnB)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftBnB',
    display => 'ftBnB',
    id => 'ftBnB',
    name => 'British foot (Benoit 1895 B)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '792',
    C => 0,
    D => '39.370113',
    annotation => 'ch(BnB)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'chBnB',
    display => 'chBnB',
    id => 'chBnB',
    name => 'British chain (Benoit 1895 B)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '7.92',
    C => 0,
    D => '39.370113',
    annotation => 'lk(BnB)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'lkBnB',
    display => 'lkBnB',
    id => 'lkBnB',
    name => 'British link (Benoit 1895 B)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.9144025',
    C => 0,
    D => '3',
    annotation => 'ftBr(65)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftBr(65)',
    display => 'ftBr65',
    id => 'ftBr65',
    name => 'British foot (1865)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '12',
    C => 0,
    D => '39.370142',
    annotation => 'ft(Ind)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftInd',
    display => 'ftInd',
    id => 'ftInd',
    name => 'Indian foot',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.30479841',
    C => 1,
    D => 0,
    annotation => 'ft(Ind37)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftInd(37)',
    display => 'ftInd37',
    id => 'ftInd37',
    name => 'Indian foot (1937)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.3047996',
    C => 1,
    D => 0,
    annotation => 'ft(Ind62)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftInd(62)',
    display => 'ftInd62',
    id => 'ftInd62',
    name => 'Indian foot (1962)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.3047995',
    C => 1,
    D => 0,
    annotation => 'ft(Ind75)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftInd(75)',
    display => 'ftInd75',
    id => 'ftInd75',
    name => 'Indian foot (1975)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '36',
    C => 0,
    D => '39.370142',
    annotation => 'yd(Ind)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ydInd',
    display => 'ydInd',
    id => 'ydInd',
    name => 'Indian yard',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.91439523',
    C => 1,
    D => 0,
    annotation => 'yd(Ind37)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ydInd(37)',
    display => 'ydInd37',
    id => 'ydInd37',
    name => 'Indian yard (1937)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.9143988',
    C => 1,
    D => 0,
    annotation => 'yd(Ind62)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ydInd(62)',
    display => 'ydInd62',
    id => 'ydInd62',
    name => 'Indian yard (1962)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.9143985',
    C => 1,
    D => 0,
    annotation => 'yd(Ind75)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ydInd(75)',
    display => 'ydInd75',
    id => 'ydInd75',
    name => 'Indian yard (1975)',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1609.344',
    C => 1,
    D => 0,
    annotation => 'mi',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'mi',
    id => 'mi',
    name => 'Statute Mile',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '6378300',
    C => 0,
    D => '20926201',
    annotation => 'ft(GC)',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'ftGC',
    display => 'ftGC',
    id => 'ftGC',
    name => 'Gold Coast foot',
    quantity_type => 'length'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.14159265358979',
    C => 0,
    D => '180',
    annotation => 'deg',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'deg',
    id => 'deg',
    name => 'degree',
    quantity_type => 'angle'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.14159265358979',
    C => 0,
    D => '10800',
    annotation => 'min',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'min',
    id => 'min',
    name => 'arc-minute',
    quantity_type => 'angle'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.14159265358979',
    C => 0,
    D => '648000',
    annotation => 'sec',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'sec',
    id => 'sec',
    name => 'arc-second',
    quantity_type => 'angle'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.14159265358979',
    C => 0,
    D => '200',
    annotation => 'gr',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'gr',
    id => 'grad',
    name => 'grad',
    quantity_type => 'angle'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.14159265358979',
    C => 0,
    D => '200',
    annotation => 'gon',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'g',
    id => 'gon',
    name => 'gon',
    quantity_type => 'angle'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.0',
    C => 0,
    D => '1000000',
    annotation => 'urad',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'urad',
    display => 'X03BCrad',
    id => 'urad',
    name => 'microradian',
    quantity_type => 'angle'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.14159265358979',
    C => 0,
    D => '20000',
    annotation => 'c',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'c',
    id => 'cmin',
    name => 'centesimal minute',
    quantity_type => 'angle'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.14159265358979',
    C => 0,
    D => '2000000',
    annotation => 'cc',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'cc',
    id => 'csec',
    name => 'centesimal second',
    quantity_type => 'angle'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.14159265358979',
    C => 0,
    D => '3200',
    annotation => 'mil',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'mil',
    id => 'mil6400',
    name => 'mil 6400',
    quantity_type => 'angle'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.0',
    C => 0,
    D => '1000000',
    annotation => 'ppm',
    base_unit => {},
    catalog_name => 'EPSG abbreviation',
    catalog_symbol => 'Euc',
    id => 'ppm',
    name => 'parts per million',
    quantity_type => 'dimensionless'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'kg',
    basic_authority => 'ISO 1000',
    catalog_name => 'POSC',
    catalog_symbol => 'kg',
    description => 'The kilogram is the unit of mass (not force); it is equal to the mass of the international prototype of the kilogram.',
    id => 'kg',
    is_base => 1,
    name => 'kilogram'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 's',
    basic_authority => 'ISO 1000',
    catalog_name => 'POSC',
    catalog_symbol => 's',
    description => 'The second is the duration of 9 192 631 770 periods of the radiation corresponding to the transition between the two hyperfine levels of the ground state of the cesium-133 atom.',
    id => 's',
    is_base => 1,
    name => 'second'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'A',
    basic_authority => 'ISO 1000',
    catalog_name => 'POSC',
    catalog_symbol => 'A',
    description => 'The ampere is that constant current which, if maintained in two straight parallel conductors of infinite length, of negligible circular cross section, and placed 1 metre apart in vacuum, would produce between these conductors a force equal to 2 x 10**-7 newton per metre of length.',
    id => 'A',
    is_base => 1,
    name => 'ampere'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'K',
    basic_authority => 'ISO 1000',
    catalog_name => 'POSC',
    catalog_symbol => 'K',
    description => 'The kelvin, unit of thermodynamic temperature, is the fraction 1/273.16 of the thermodynamic temperature of the triple point of water.',
    id => 'K',
    is_base => 1,
    name => 'kelvin'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'mol',
    basic_authority => 'ISO 1000',
    catalog_name => 'POSC',
    catalog_symbol => 'mol',
    description => 'The mole is the amount of substance of a system that contains as many elementary entities as there are atoms in 0.012 kilogram of carbon-12. When the mole is used, the elementary entities must be specified and may be atoms, molecules, ions, electrons, other particles, or specified groups of such particles.',
    id => 'mol',
    is_base => 1,
    name => 'mole'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'cd',
    basic_authority => 'ISO 1000',
    catalog_name => 'POSC',
    catalog_symbol => 'cd',
    description => 'The candela is the luminous intensity, in a given direction, of a source that emits monochromatic radiation of frequency 540 X 10**12 hertz and that has a radian intensity in that direction of 1/683 watt per steradian.',
    id => 'cd',
    is_base => 1,
    name => 'candela'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'sr',
    basic_authority => 'ISO 1000',
    catalog_name => 'POSC',
    catalog_symbol => 'sr',
    description => 'The steradian is the solid angle that, having its vertex in the center of a circle, cuts of an area of the surface of the sphere equal to that of a square with sides of length equal to the radius of the sphere.',
    id => 'sr',
    is_base => 1,
    name => 'steradian'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'B',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'B',
    description => 'A unit of intensity. A bel is the base 10 logarithm of an intensity ratio.',
    id => 'B',
    is_base => 1,
    name => 'bel'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'byte',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'byte',
    description => 'The capacity, in bytes, of a storage device or an information system, is one eighth of the base two logarithm of the number of possible states of the device or system.',
    id => 'byte',
    is_base => 1,
    name => 'byte'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'O',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'O',
    description => 'The number of octaves between two positive values is the base two logarithm of their ratio.',
    id => 'O',
    is_base => 1,
    name => 'octave'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'scm(0C)',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'scm(0C)',
    description => 'A unit of standard volume. The number of scm(0C) of a flid is the volume the flid will occupy (in cubic metres) when the flid is reduced to standard conditions of 1 atm., 0 degrees Celsius.',
    id => 'scm(0C)',
    is_base => 1,
    name => 'standard cubic metres at 0 deg Celsius'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'scm(15C)',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'scm(15C)',
    description => 'A unit of standard volume. The number of scm(15C) of a flid is the volume the flid will occupy (in cubic metres) when the flid is reduced to standard conditions of 1 atm., 15 degrees Celsius.',
    id => 'scm(15C)',
    is_base => 1,
    name => 'standard cubic metres at 15 deg Celsius'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'gAPI',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'gAPI',
    description => 'A unit defined by the American Petroleum Institute for gamma ray log measurements.',
    id => 'gAPI',
    is_base => 1,
    name => 'API gamma ray units'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'nAPI',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'nAPI',
    description => 'A unit defined by the American Petroleum Institute for neutron log measurements.',
    id => 'nAPI',
    is_base => 1,
    name => 'API neutron units'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'Euc',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'Euc',
    description => 'A unit to describe unitless quantities such as ratios.',
    id => 'Euc',
    is_base => 1,
    name => 'euclid'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => '1/H',
    basic_authority => 'ISO 1000',
    catalog_name => 'POSC',
    catalog_symbol => '1/H',
    description => 'A unit of reluctance',
    id => '1PH',
    is_base => 1,
    name => 'inverse henry'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => '1/kg',
    basic_authority => 'ISO 1000',
    catalog_name => 'POSC',
    catalog_symbol => '1/kg',
    description => '',
    id => '1Pkg',
    is_base => 1,
    name => 'per kilogram'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => '1/K',
    basic_authority => 'ISO 1000',
    catalog_name => 'POSC',
    catalog_symbol => '1/K',
    description => 'A unit of volumetric thermal expansion',
    id => '1PK',
    is_base => 1,
    name => 'per Kelvin'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => '1/m',
    basic_authority => 'ISO 1000',
    catalog_name => 'POSC',
    catalog_symbol => '1/m',
    description => 'A unit for volume fraction per length; capture unit; wavenumber; and per length',
    id => '1Pm',
    is_base => 1,
    name => 'per metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => '1/m2',
    basic_authority => 'ISO 1000',
    catalog_name => 'POSC',
    catalog_symbol => '1/m2',
    description => 'A unit of per area; length per volume',
    id => '1Pm2',
    is_base => 1,
    name => 'per square metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => '1/m3',
    basic_authority => 'ISO 1000',
    catalog_name => 'POSC',
    catalog_symbol => '1/m3',
    description => 'A unit of per volume',
    id => '1Pm3',
    is_base => 1,
    name => 'per cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => '1/Pa',
    basic_authority => 'ISO 1000',
    catalog_name => 'POSC',
    catalog_symbol => '1/Pa',
    description => 'A unit for compressibility',
    id => '1PPa',
    is_base => 1,
    name => 'per Pascal'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => '1/s',
    basic_authority => 'ISO 1000',
    catalog_name => 'POSC',
    catalog_symbol => '1/s',
    description => 'A unit for shear rate',
    id => '1Ps',
    is_base => 1,
    name => 'per second'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => '1/V',
    basic_authority => 'ISO 1000',
    catalog_name => 'POSC',
    catalog_symbol => '1/V',
    description => '',
    id => '1PV',
    is_base => 1,
    name => 'per Volt'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'A.m2',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'A.m2',
    description => 'A unit of magnetic and electromagnetic moment',
    id => 'ATm2',
    is_base => 1,
    name => 'amperes metres squared'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'A/m',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'A/m',
    description => 'A unit of magnetization, current density linear, and magnetic field strength',
    id => 'APm',
    is_base => 1,
    name => 'amperes/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'A/m2',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'A/m2',
    description => 'A unit of current density',
    id => 'APm2',
    is_base => 1,
    name => 'amperes/square metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'B/m',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'B/m',
    description => 'A unit for attenuation per unit length',
    id => 'BPm',
    is_base => 1,
    name => 'bels/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'B/O',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'B/O',
    description => 'A unit for the drop-off rate of amplitude or power',
    id => 'BPO',
    is_base => 1,
    name => 'bels/octave'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'Bd',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'Bd',
    description => 'The baud rate is a unit of signaling speed equal to one byte per second. The signaling speed in bauds is equal to the reciprocal of the byte length in seconds.',
    id => 'Bd',
    is_base => 1,
    name => 'baud'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'Bq',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'Bq',
    description => 'An activity (of radionuclides) whose units are 1/s.',
    id => 'Bq',
    is_base => 1,
    name => 'becquerel'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'C',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'C',
    description => 'A quantity of electricity which is equal to 1 A.s.',
    id => 'C',
    is_base => 1,
    name => 'coulomb'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'C.m',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'C.m',
    description => 'Electric dipole moment',
    id => 'CTm',
    is_base => 1,
    name => 'coulomb metres'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'C/m2',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'C/m2',
    description => 'A unit of density of charge and electric polarization',
    id => 'CPm2',
    is_base => 1,
    name => 'coulombs/square metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'C/m3',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'C/m3',
    description => 'A unit of surface density of charge and charge density.',
    id => 'CPm3',
    is_base => 1,
    name => 'coulombs/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'cd/m2',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'cd/m2',
    description => 'A unit of luminance',
    id => 'cdPm2',
    is_base => 1,
    name => 'candelas/square metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'F',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'F',
    description => 'Electric capacitance which is equal to 1 A.s/V.',
    id => 'F',
    is_base => 1,
    name => 'farad'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'F/m',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'F/m',
    description => 'A unit of permittivity',
    id => 'FPm',
    is_base => 1,
    name => 'farads/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'Gy',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'Gy',
    description => 'Absorbed dose which is equal to J/kg.',
    id => 'Gy',
    is_base => 1,
    name => 'gray'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'H',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'H',
    description => 'Inductance which is equal to 1 V.s/A.',
    id => 'H',
    is_base => 1,
    name => 'henry'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'H/m',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'H/m',
    description => 'A unit of magnetic permeability',
    id => 'HPm',
    is_base => 1,
    name => 'henries/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'J',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'J',
    description => 'Work, energy which is equal to 1 N.m. Also a unit of torque.',
    id => 'J',
    is_base => 1,
    name => 'joule'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'J/kg',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'J/kg',
    description => 'A unit for calorific value, mass basis; latent heat; and energy per mass',
    id => 'JPkg',
    is_base => 1,
    name => 'joules/kilogram'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'J/kg.K',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'J/kg.K',
    description => 'A unit for specific heat capacity and specific entropy',
    id => 'JPkgTK',
    is_base => 1,
    name => 'joules/kilogram degree kelvin'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'J/m3',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'J/m3',
    description => 'A unit for calorific value gas volume; and energy per volume',
    id => 'JPm3',
    is_base => 1,
    name => 'joules/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'J/mol',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'J/mol',
    description => 'A unit for calorific value mole basis',
    id => 'JPmol',
    is_base => 1,
    name => 'joules/mole'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'J/mol.K',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'J/mol.K',
    description => 'A unit for the specific heat capacity, mole.',
    id => 'JPmolTK',
    is_base => 1,
    name => 'joules/mole degree kelvin'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'K.m2/W',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'K.m2/W',
    description => 'A unit of thermal resistance',
    id => 'KTm2PW',
    is_base => 1,
    name => 'kelvin metres squared/watt'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'K/m',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'K/m',
    description => 'A unit for temperature per length',
    id => 'KPm',
    is_base => 1,
    name => 'degrees kelvin/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'kg.m/s',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'kg.m/s',
    description => 'A unit of momentum',
    id => 'kgTmPs',
    is_base => 1,
    name => 'kilogram metres/second'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'kg.m2',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'kg.m2',
    description => 'A unit for moment of inertia',
    id => 'kgTm2',
    is_base => 1,
    name => 'kilogram metres squared'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'kg/J',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'kg/J',
    description => 'A unit for specific fuel consumption mass',
    id => 'kgPJ',
    is_base => 1,
    name => 'kilograms/joule'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'kg/m',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'kg/m',
    description => 'Mass per length',
    id => 'kgPm',
    is_base => 1,
    name => 'kilograms/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'kg/m.s',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'kg/m.s',
    description => 'flow rate per length, mass basis',
    id => 'kgPmTs',
    is_base => 1,
    name => 'kilograms/metre second'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'kg/m2',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'kg/m2',
    description => 'Mass per area',
    id => 'kgPm2',
    is_base => 1,
    name => 'kilograms/square metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'kg/m2.s',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'kg/m2.s',
    description => 'A unit of acoustic impedance; and flow rate per area, mass basis.',
    id => 'kgPm2Ts',
    is_base => 1,
    name => 'kilograms/square metre seconds'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'kg/m3',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'kg/m3',
    description => 'A unit for density and concentration mass per volume, yield',
    id => 'kgPm3',
    is_base => 1,
    name => 'kilograms/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'kg/m4',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'kg/m4',
    description => 'A unit for density gradient. Note. This is equivalent to Pa.s2/m3, which is Darcy flow coefficient.',
    id => 'kgPm4',
    is_base => 1,
    name => 'kilogram/metre fourth'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'kg/s',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'kg/s',
    description => 'A unit for flow rate, mass basis',
    id => 'kgPs',
    is_base => 1,
    name => 'kilograms/second'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'lm',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'lm',
    description => 'Luminous flux which is equal to 1 cd.sr.',
    id => 'lm',
    is_base => 1,
    name => 'lumen'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'lm.s',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'lm.s',
    description => 'A unit of quantity of light',
    id => 'lmTs',
    is_base => 1,
    name => 'lumen second'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'lm/W',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'lm/W',
    description => 'A unit of luminous efficacy',
    id => 'lmPW',
    is_base => 1,
    name => 'lumens/watt'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'lx',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'lx',
    description => 'Illuminance which is equal to 1 lm/m2.',
    id => 'lx',
    is_base => 1,
    name => 'lux'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'lx.s',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'lx.s',
    description => 'A unit of light exposure',
    id => 'lxTs',
    is_base => 1,
    name => 'lux seconds'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'm/K',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'm/K',
    description => 'A unit for length per temperature',
    id => 'mPK',
    is_base => 1,
    name => 'metres/degree kelvin'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'm/s',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'm/s',
    description => 'A unit of velocity',
    id => 'mPs',
    is_base => 1,
    name => 'metres/second'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'm/s2',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'm/s2',
    description => 'A unit of linear acceleration',
    id => 'mPs2',
    is_base => 1,
    name => 'metres/second squared'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'm2',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'm2',
    description => 'A unit of area and permeability',
    id => 'm2',
    is_base => 1,
    name => 'square metres'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'm2/kg',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'm2/kg',
    description => 'A unit for area per mass',
    id => 'm2Pkg',
    is_base => 1,
    name => 'square metres/kilogram'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'm2/mol',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'm2/mol',
    description => 'A unit of cross-section absorption',
    id => 'm2Pmol',
    is_base => 1,
    name => 'square metres/mol'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'm2/Pa.s',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'm2/Pa.s',
    description => 'A unit for specific productivity index and mobility',
    id => 'm2PPaTs',
    is_base => 1,
    name => 'square metres/second Pascal'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'm2/s',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'm2/s',
    description => 'A unit of kinematic viscosity, diffusivity, and flow rate per length, volume basis.',
    id => 'm2Ps',
    is_base => 1,
    name => 'square metres/second'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'm3',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'm3',
    description => 'A unit of volume and permeability length',
    id => 'm3',
    is_base => 1,
    name => 'cubic metres'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'm3/J',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'm3/J',
    description => 'A unit for specific fuel consumption, volume.',
    id => 'm3PJ',
    is_base => 1,
    name => 'cubic metres/joule'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'm3/kg',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'm3/kg',
    description => 'A unit for specific volume clay yield and specific volume mass liqid and solid',
    id => 'm3Pkg',
    is_base => 1,
    name => 'cubic metres/kilogram'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'm3/mol',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'm3/mol',
    description => 'A unit for concentration volume per mole',
    id => 'm3Pmol',
    is_base => 1,
    name => 'cubic metres/mole'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'm3/Pa.s',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'm3/Pa.s',
    description => 'A unit for productivity index',
    id => 'm3PPaTs',
    is_base => 1,
    name => 'cubic metres/second pascal'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'm3/Pa2.s2',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'm3/Pa2.s2',
    description => '',
    id => 'm3PPa2Ts2',
    is_base => 1,
    name => 'cubic metres/pascal second squared'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'm3/s',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'm3/s',
    description => 'A unit for the flow rate, volume basis',
    id => 'm3Ps',
    is_base => 1,
    name => 'cubic metres/second'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'm3/s2',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'm3/s2',
    description => 'A unit for volume flow rate per unit time',
    id => 'm3Ps2',
    is_base => 1,
    name => 'cubic metres/seconds squared'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'm3/scm(0C)',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'm3/scm(0C)',
    description => 'A unit of volume per standard volume',
    id => 'm3Pscm(0C)',
    is_base => 1,
    name => 'cubic metres/std cubic metres, 0 deg C'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'm3/scm(15C)',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'm3/scm(15C)',
    description => 'A unit of volume per standard volume',
    id => 'm3Pscm(15C)',
    is_base => 1,
    name => 'cubic metres/std cubic metres, 15 deg C'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'm4',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'm4',
    description => 'A unit for moment of section',
    id => 'm4',
    is_base => 1,
    name => 'metres fourth'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'm4/s',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'm4/s',
    description => '',
    id => 'm4Ps',
    is_base => 1,
    name => 'metres fourth/second'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'mol/m2',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'mol/m2',
    description => 'A unit for standard volume per area',
    id => 'molPm2',
    is_base => 1,
    name => 'moles/square metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'mol/m2.s',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'mol/m2.s',
    description => 'A unit for standard volume flow per area',
    id => 'molPm2Ts',
    is_base => 1,
    name => 'moles/square metre second'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'mol/m3',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'mol/m3',
    description => 'A unit for concentration mole per volume, and standard volume per volume',
    id => 'molPm3',
    is_base => 1,
    name => 'moles/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'mol/s',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'mol/s',
    description => 'A unit for the flow rate, mole basis',
    id => 'molPs',
    is_base => 1,
    name => 'moles/second'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'N',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'N',
    description => 'Force which is equal to 1 kg.m/s2.',
    id => 'N',
    is_base => 1,
    name => 'newton'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'N.m2',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'N.m2',
    description => 'A unit for force area',
    id => 'NTm2',
    is_base => 1,
    name => 'newton square metres'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'N/m',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'N/m',
    description => 'A unit for force per length; and surface tension',
    id => 'NPm',
    is_base => 1,
    name => 'newtons/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'N/m3',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'N/m3',
    description => '',
    id => 'NPm3',
    is_base => 1,
    name => 'newtons/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'N4/kg.m7',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'N4/kg.m7',
    description => 'A unit for the quantity parachor',
    id => 'N4PkgTm7',
    is_base => 1,
    name => 'newtons fourth metres/kilogram'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'ohm',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'ohm',
    description => 'Electric resistance which is equal to1 V/A.',
    id => 'ohm',
    is_base => 1,
    name => 'ohm'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'ohm.m',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'ohm.m',
    description => 'A unit of electrical resistivity',
    id => 'ohmTm',
    is_base => 1,
    name => 'ohm metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'Pa',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'Pa',
    description => 'Pressure which is equal to 1 N/m2.',
    id => 'Pa',
    is_base => 1,
    name => 'pascal'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'Pa2',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'Pa2',
    description => '',
    id => 'Pa2',
    is_base => 1,
    name => 'pascal squared'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'Pa.s',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'Pa.s',
    description => 'A unit of dynamic viscosity. Also a unit of flow rate per length, mass basis.',
    id => 'PaTs',
    is_base => 1,
    name => 'pascal seconds'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'Pa.s/m3',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'Pa.s/m3',
    description => 'A unit for inflow performance ratio',
    id => 'PaTsPm3',
    is_base => 1,
    name => 'pascal seconds/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'Pa.s/m6',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'Pa.s/m6',
    description => 'A unit of nonDarcy flow coefficient.',
    id => 'PaTsPm6',
    is_base => 1,
    name => 'pascal second /cubic metre squared'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'Pa/m',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'Pa/m',
    description => 'A unit of pressure drop',
    id => 'PaPm',
    is_base => 1,
    name => 'pascals/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'Pa/m3',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'Pa/m3',
    description => 'A unit for Darcy flow coefficient',
    id => 'PaPm3',
    is_base => 1,
    name => 'pascals/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'Pa/s',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'Pa/s',
    description => 'A unit of pseudopressure',
    id => 'PaPs',
    is_base => 1,
    name => 'pascal/ second'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'rad/m',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'rad/m',
    description => 'A unit of angle per length',
    id => 'radPm',
    is_base => 1,
    name => 'radians/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'rad/s',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'rad/s',
    description => 'A unit or rotational frequency and angular velocity',
    id => 'radPs',
    is_base => 1,
    name => 'radians/second'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'rad/s2',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'rad/s2',
    description => 'A unit of rotaional acceleration',
    id => 'radPs2',
    is_base => 1,
    name => 'radians/second squared'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'S',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'S',
    description => 'Electrical conductance which is equal to 1 A/V.',
    id => 'S',
    is_base => 1,
    name => 'siemens'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'S/m',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'S/m',
    description => 'A unit of conductivity',
    id => 'SPm',
    is_base => 1,
    name => 'siemens/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 's/m',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 's/m',
    description => 'A unit of interval transit time; and slowness',
    id => 'sPm',
    is_base => 1,
    name => 'seconds/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 's/m3',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 's/m3',
    description => 'A unit for the turbulence coefficient',
    id => 'sPm3',
    is_base => 1,
    name => 'seconds/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'scm(0C)/m2',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'scm(0C)/m2',
    description => 'A unit of standard volume per area',
    id => 'scm(0C)Pm2',
    is_base => 1,
    name => 'std cubic metres, 0 deg C/square metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'scm(0C)/m3',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'scm(0C)/m3',
    description => 'A unit of standard volume per volume',
    id => 'scm(0C)Pm3',
    is_base => 1,
    name => 'std cubic metres, 0 deg C/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'scm(15C)/m2',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'scm(15C)/m2',
    description => 'A unit of standard volume per area',
    id => 'scm(15C)Pm2',
    is_base => 1,
    name => 'std cubic metres, 15 deg C/square metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'scm(15C)/m3',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'scm(15C)/m3',
    description => 'A unit of standard volume per volume',
    id => 'scm(15C)Pm3',
    is_base => 1,
    name => 'std cubic metres, 15 deg C/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'scm(15C)/s',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'scm(15C)/s',
    description => 'A unit of production rate',
    id => 'scm(15C)Ps',
    is_base => 1,
    name => 'std cubic metres, 15 deg C/second'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'T',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'T',
    description => 'Magnetic flux density which is equal to 1 Wb/m2.',
    id => 'T',
    is_base => 1,
    name => 'tesla'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'V',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'V',
    description => 'Electric potential which is equal to 1 W/A.',
    id => 'V',
    is_base => 1,
    name => 'volt'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'V/B',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'V/B',
    description => '',
    id => 'VPB',
    is_base => 1,
    name => 'volts/Bel'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'V/m',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'V/m',
    description => 'A unit of electric field strength',
    id => 'VPm',
    is_base => 1,
    name => 'volts/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'W',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'W',
    description => 'Power which is equal to 1 J/s.',
    id => 'W',
    is_base => 1,
    name => 'watt'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'W/m.K',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'W/m.K',
    description => 'A unit of thermal conductivity',
    id => 'WPmTK',
    is_base => 1,
    name => 'watts/metre kelvin'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'W/m2',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'W/m2',
    description => 'A unit of acoustic intensity; heat flux; heat flow; and power per unit area.',
    id => 'WPm2',
    is_base => 1,
    name => 'watts/square metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'W/m2.K',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'W/m2.K',
    description => 'A unit for th heat transfer coefficient',
    id => 'WPm2TK',
    is_base => 1,
    name => 'watts/square metre kelvin'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'W/m2.sr',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'W/m2.sr',
    description => 'A unit of radiance',
    id => 'WPm2Tsr',
    is_base => 1,
    name => 'watts/square metre steradian'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'W/m3',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'W/m3',
    description => 'Heat generation unit and heat release rate',
    id => 'WPm3',
    is_base => 1,
    name => 'watts/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'W/m3.K',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'W/m3.K',
    description => 'A unit for the volumetric heat transfer coeeficient',
    id => 'WPm3TK',
    is_base => 1,
    name => 'watts/cubic metre kelvin'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'W/sr',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'W/sr',
    description => 'A unit of radiant intensity',
    id => 'WPsr',
    is_base => 1,
    name => 'watts/steradian'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'Wb',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'Wb',
    description => 'Magnetic flux which is equal to 1 V.s.',
    id => 'Wb',
    is_base => 1,
    name => 'weber'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'Wb.m',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'Wb.m',
    description => 'Magnetic dipole moment',
    id => 'WbTm',
    is_base => 1,
    name => 'weber metres'
  }, 'Petrophysics::Units' ),
  bless( {
    annotation => 'Wb/m',
    basic_authority => 'POSC',
    catalog_name => 'POSC',
    catalog_symbol => 'Wb/m',
    description => 'A unit of magnetic vector potential',
    id => 'WbPm',
    is_base => 1,
    name => 'webers/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.01',
    C => 1,
    D => 0,
    annotation => '%',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '%',
    id => 'percent',
    name => 'percent'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '31558150',
    annotation => '1/a',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/a',
    id => '1Pa',
    name => 'per annum'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '10000000000.',
    C => 1,
    D => 0,
    annotation => '1/angstrom',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/angstrom',
    id => '1Pangstrom',
    name => 'per angstrom'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '86400',
    annotation => '1/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/d',
    id => '1Pd',
    name => 'per day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '0.3048',
    annotation => '1/ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/ft',
    id => '1Pft',
    name => 'per foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '100',
    C => 1,
    D => 0,
    annotation => '1/cm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/cm',
    id => '1Pcm',
    name => 'per centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => '1/degC',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/degC',
    id => '1PdegC',
    name => 'per degree Celsius'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9',
    C => 0,
    D => '5',
    annotation => '1/degR',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/degR',
    id => '1PdegR',
    name => 'per degree Rankine'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9',
    C => 0,
    D => '5',
    annotation => '1/degF',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/degF',
    id => '1PdegF',
    name => 'per degree Fahrenheit'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '.09290304',
    annotation => '1/ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/ft2',
    id => '1Pft2',
    name => 'per square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '1000000.',
    annotation => '1/km2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/km2',
    id => '1Pkm2',
    name => 'per square kilometre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '2589988.11',
    annotation => '1/mi2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/mi2',
    id => '1Pmi2',
    name => 'per square mile'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => '1/g',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/g',
    id => '1Pg',
    name => 'per gram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '3600',
    annotation => '1/h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/h',
    id => '1Ph',
    name => 'per hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => '1/mm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/mm',
    id => '1Pmm',
    name => 'per millimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000000.',
    C => 1,
    D => 0,
    annotation => '1/nm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/nm',
    id => '1Pnm',
    name => 'per nanometre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '60',
    annotation => '1/min',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/min',
    id => '1Pmin',
    name => 'per minute'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '1609.344',
    annotation => '1/mi',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/mi',
    id => '1Pmi',
    name => 'per mile'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '0.9144',
    annotation => '1/yd',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/yd',
    id => '1Pyd',
    name => 'per yard'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '0.0254',
    annotation => '1/in',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/in',
    id => '1Pin',
    name => 'per inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => '1/kPa',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/kPa',
    id => '1PkPa',
    name => 'per kilopascal'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '6894.757',
    annotation => '1/psi',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/psi',
    id => '1Ppsi',
    name => 'per pounds/square inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000',
    C => 1,
    D => 0,
    annotation => '1/uV',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/uV',
    id => '1PuV',
    name => 'per microvolt'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '604800',
    annotation => '1/wk',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '1/wk',
    id => '1Pwk',
    name => 'per week'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '31558150',
    C => 1,
    D => 0,
    annotation => 'a',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'a',
    id => 'a',
    name => 'annum'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3600',
    C => 1,
    D => 0,
    annotation => 'A.h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'A.h',
    id => 'ATh',
    name => 'Ampere hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'A/mm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'A/mm',
    id => 'APmm',
    name => 'Ampere/millimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000',
    C => 1,
    D => 0,
    annotation => 'A/mm2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'A/mm2',
    id => 'APmm2',
    name => 'Ampere/square millimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4046.873',
    C => 1,
    D => 0,
    annotation => 'acre',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'acre',
    id => 'acre',
    name => 'acre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1233.489',
    C => 1,
    D => 0,
    annotation => 'acre.ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'acre.ft',
    id => 'acreTft',
    name => 'acre foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0000000001',
    C => 1,
    D => 0,
    annotation => 'angstrom',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'angstrom',
    id => 'angstrom',
    name => 'Angstrom'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '98066.5',
    C => 1,
    D => 0,
    annotation => 'at',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'at',
    id => 'at',
    name => 'Technical atmosphere'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '101325',
    C => 1,
    D => 0,
    annotation => 'atm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'atm',
    id => 'atm',
    name => 'Atmosphere'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '101325',
    C => 1,
    D => 0,
    annotation => 'atm/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'atm/m',
    id => 'atmPm',
    name => 'Atmospheres/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '8',
    annotation => 'bit',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bit',
    id => 'bit',
    name => 'bit'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '100000',
    C => 1,
    D => 0,
    annotation => 'bar',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bar',
    id => 'bar',
    name => 'bar'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.00E+28',
    C => 1,
    D => 0,
    annotation => 'b',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'b',
    id => 'b',
    name => 'barn'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.00E+34',
    C => 1,
    D => 0,
    annotation => 'b/cm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'b/cm3',
    id => 'bPcm3',
    name => 'barns/cubic centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '6.023E-5',
    C => 1,
    D => 0,
    annotation => 'b/elec',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'b/elec',
    id => 'bPelec',
    name => 'barns/electron'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1589873',
    C => 1,
    D => 0,
    annotation => 'bbl',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bbl',
    id => 'bbl',
    name => 'barrel'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1589873',
    C => 0,
    D => '4046.879',
    annotation => 'bbl/acre',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bbl/acre',
    id => 'bblPacre',
    name => 'barrels/acre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1589873',
    C => 0,
    D => '1233.489',
    annotation => 'bbl/acre.ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bbl/acre.ft',
    id => 'bblPacreTft',
    name => 'barrel/acre foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'bbl/bbl',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bbl/bbl',
    id => 'bblPbbl',
    name => 'barrel/barrel'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1589873',
    C => 0,
    D => '595707.0',
    annotation => 'bbl/cP.d.psi',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bbl/cP.d.psi',
    id => 'bblPcPTdTpsi',
    name => 'barrels/centiPoise day psi'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1589873',
    C => 0,
    D => '86400',
    annotation => 'bbl/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bbl/d',
    id => 'bblPd',
    name => 'barrel/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '2.12978E-11',
    C => 1,
    D => 0,
    annotation => 'bbl/d2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bbl/d2',
    id => 'bblPd2',
    name => 'barrels/day per day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1589873',
    C => 0,
    D => '26334.72',
    annotation => 'bbl/d.ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bbl/d.ft',
    id => 'bblPdTft',
    name => 'barrels/day foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1589873',
    C => 0,
    D => '106573450',
    annotation => 'bbl/d.acre.ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bbl/d.acre.ft',
    id => 'bblPdTacreTft',
    name => 'barrels/day acre foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '2.66888418E-10',
    C => 1,
    D => 0,
    annotation => 'bbl/d.psi',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bbl/d.psi',
    id => 'bblPdTpsi',
    name => 'barrel/day pounds/square inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '2.66888418E-10',
    C => 0,
    D => '0.3048',
    annotation => 'bbl/d.ft.psi',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bbl/d.ft.psi',
    id => 'bblPdTftTpsi',
    name => 'barrels/day foot pounds/sq in'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1589873',
    C => 0,
    D => '0.3048',
    annotation => 'bbl/ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bbl/ft',
    id => 'bblPft',
    name => 'barrel/foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1589873',
    C => 0,
    D => '3600',
    annotation => 'bbl/hr',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bbl/hr',
    id => 'bblPhr',
    name => 'barrel/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1589873',
    C => 0,
    D => '12960000',
    annotation => 'bbl/hr2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bbl/hr2',
    id => 'bblPhr2',
    name => 'barrels/hour/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1589873',
    C => 0,
    D => '0.0254',
    annotation => 'bbl/in',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bbl/in',
    id => 'bblPin',
    name => 'barrel/inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1589873',
    C => 0,
    D => '1609.344',
    annotation => 'bbl/mi',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bbl/mi',
    id => 'bblPmi',
    name => 'barrel/mile'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1589873',
    C => 0,
    D => '28262.357',
    annotation => 'bbl/MMscf(60F)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bbl/MMscf(60F)',
    id => 'bblPMMscf(60F)',
    name => 'barrels/million std cubic feet, 60 degF'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '156.4763',
    C => 1,
    D => 0,
    annotation => 'bbl/tonUK',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bbl/tonUK',
    id => 'bblPtonUK',
    name => 'barrel per U.K. ton'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '175.2535',
    C => 1,
    D => 0,
    annotation => 'bbl/tonUS',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bbl/tonUS',
    id => 'bblPtonUS',
    name => 'barrel per U.S. ton'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1055.056',
    C => 1,
    D => 0,
    annotation => 'Btu',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu',
    id => 'Btu',
    name => 'British thermal unit'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '293071.1',
    C => 1,
    D => 0,
    annotation => 'Btu(million)/hr',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu(million)/hr',
    id => 'Btu(million)Phr',
    name => 'million Btus/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1442279',
    C => 1,
    D => 0,
    annotation => 'Btu.in/hr.ft2.F',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu.in/hr.ft2.F',
    id => 'BtuTinPhrTft2TF',
    name => 'Btus/hour foot squared deg F per inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1055.056',
    C => 0,
    D => '0.1589873',
    annotation => 'Btu/bbl',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/bbl',
    id => 'BtuPbbl',
    name => 'British thermal units/barrel'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0003930148',
    C => 1,
    D => 0,
    annotation => 'Btu/bhp.hr',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/bhp.hr',
    id => 'BtuPbhpThr',
    name => 'Btus/brake-horsepower hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '37258.95',
    C => 1,
    D => 0,
    annotation => 'Btu/ft3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/ft3',
    id => 'BtuPft3',
    name => 'British thermal units/cubic foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '232080',
    C => 1,
    D => 0,
    annotation => 'Btu/galUK',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/galUK',
    id => 'BtuPgalUK',
    name => 'British thermal units/U.K. gallon'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '278716.3',
    C => 1,
    D => 0,
    annotation => 'Btu/galUS',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/galUS',
    id => 'BtuPgalUS',
    name => 'British thermal units/U.S. gallon'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.2930711',
    C => 1,
    D => 0,
    annotation => 'Btu/hr',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/hr',
    id => 'BtuPhr',
    name => 'British thermal unit/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.730735',
    C => 1,
    D => 0,
    annotation => 'Btu/hr.ft.degF',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/hr.ft.degF',
    id => 'BtuPhrTftTdegF',
    name => 'British thermal units/hour foot deg F'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.154591',
    C => 1,
    D => 0,
    annotation => 'Btu/hr.ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/hr.ft2',
    id => 'BtuPhrTft2',
    name => 'Btus/hour per square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '5.678263',
    C => 1,
    D => 0,
    annotation => 'Btu/hr.ft2.degF',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/hr.ft2.degF',
    id => 'BtuPhrTft2TdegF',
    name => 'Btus/hour foot squared deg F'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '5.678263',
    C => 1,
    D => 0,
    annotation => 'Btu/hr.ft2.degR',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/hr.ft2.degR',
    id => 'BtuPhrTft2TdegR',
    name => 'Btus/hour foot squared deg R'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '10.34971',
    C => 1,
    D => 0,
    annotation => 'Btu/hr.ft3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/hr.ft3',
    id => 'BtuPhrTft3',
    name => 'British thermal units/hour cubic foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '18.62947',
    C => 1,
    D => 0,
    annotation => 'Btu/hr.ft3.degF',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/hr.ft3.degF',
    id => 'BtuPhrTft3TdegF',
    name => 'Btus/hour foot cubed deg F'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.2930711',
    C => 1,
    D => 0,
    annotation => 'Btu/hr.m2.degC',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/hr.m2.degC',
    id => 'BtuPhrTm2TdegC',
    name => 'Btus/hour metre squared deg C'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '2326',
    C => 1,
    D => 0,
    annotation => 'Btu/lbm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/lbm',
    id => 'BtuPlbm',
    name => 'British thermal units/pound mass'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4186.8',
    C => 1,
    D => 0,
    annotation => 'Btu/lbm.degF',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/lbm.degF',
    id => 'BtuPlbmTdegF',
    name => 'British thermal units/pound mass deg F'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4186.8',
    C => 1,
    D => 0,
    annotation => 'Btu/lbm.degR',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/lbm.degR',
    id => 'BtuPlbmTdegR',
    name => 'British thermal units/pound mass deg R'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '17.58427',
    C => 1,
    D => 0,
    annotation => 'Btu/min',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/min',
    id => 'BtuPmin',
    name => 'British thermal units/minute'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '2326',
    C => 1,
    D => 0,
    annotation => 'Btu/mol(lbm)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/mol(lbm)',
    id => 'BtuPmol(lbm)',
    name => 'British thermal units/pound mass mol'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4186.8',
    C => 1,
    D => 0,
    annotation => 'Btu/mol(lbm).F',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/mol(lbm).F',
    id => 'BtuPmol(lbm)TF',
    name => 'Btus/pound mass mol deg F'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1055.056',
    C => 1,
    D => 0,
    annotation => 'Btu/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/s',
    id => 'BtuPs',
    name => 'British thermal units/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '11356.53',
    C => 1,
    D => 0,
    annotation => 'Btu/s.ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/s.ft2',
    id => 'BtuPsTft2',
    name => 'British thermal units/second square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '20441.75',
    C => 1,
    D => 0,
    annotation => 'Btu/s.ft2.degF',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/s.ft2.degF',
    id => 'BtuPsTft2TdegF',
    name => 'Btus/second per square foot deg F'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '37258.95',
    C => 1,
    D => 0,
    annotation => 'Btu/s.ft3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/s.ft3',
    id => 'BtuPsTft3',
    name => 'Btus/second per cubic foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '67066.11',
    C => 1,
    D => 0,
    annotation => 'Btu/s.ft3.degF',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Btu/s.ft3.degF',
    id => 'BtuPsTft3TdegF',
    name => 'Btus/second per cubic foot deg F'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '0.0001',
    annotation => 'C/cm2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'C/cm2',
    id => 'CPcm2',
    name => 'Coulombs/square centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '0.000001',
    annotation => 'C/mm2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'C/mm2',
    id => 'CPmm2',
    name => 'Coulombs/square millimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '0.000000001',
    annotation => 'C/mm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'C/mm3',
    id => 'CPmm3',
    name => 'Coulombs/cubic millimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4.184',
    C => 1,
    D => 0,
    annotation => 'cal',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cal',
    id => 'cal',
    name => 'calorie'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4.184',
    C => 0,
    D => '0.000001',
    annotation => 'cal/cm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cal/cm3',
    id => 'calPcm3',
    name => 'calories/cubic centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4.184',
    C => 0,
    D => '0.000000001',
    annotation => 'cal/mm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cal/mm3',
    id => 'calPmm3',
    name => 'calories/cubic millimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4184',
    C => 1,
    D => 0,
    annotation => 'cal/g',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cal/g',
    id => 'calPg',
    name => 'calories/gram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4184',
    C => 1,
    D => 0,
    annotation => 'cal/g.K',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cal/g.K',
    id => 'calPgTK',
    name => 'calories/gram degree Kelvin'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '11.62222',
    C => 1,
    D => 0,
    annotation => 'cal/h.cm2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cal/h.cm2',
    id => 'calPhTcm2',
    name => 'calories/hour centimetre squared'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1162222',
    C => 1,
    D => 0,
    annotation => 'cal/h.cm.degC',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cal/h.cm.degC',
    id => 'calPhTcmTdegC',
    name => 'calories/hour centimetre degree Celsius'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '11.62222',
    C => 1,
    D => 0,
    annotation => 'cal/h.cm2.degC',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cal/h.cm2.degC',
    id => 'calPhTcm2TdegC',
    name => 'calories/hour square centimetre deg C'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1162.222',
    C => 1,
    D => 0,
    annotation => 'cal/h.cm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cal/h.cm3',
    id => 'calPhTcm3',
    name => 'calories/hour cubic centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4.184',
    C => 1,
    D => 0,
    annotation => 'cal/kg',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cal/kg',
    id => 'calPkg',
    name => 'calories/kilogram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9.224141',
    C => 1,
    D => 0,
    annotation => 'cal/lbm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cal/lbm',
    id => 'calPlbm',
    name => 'calories/pound mass'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4184000',
    C => 1,
    D => 0,
    annotation => 'cal/mL',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cal/mL',
    id => 'calPmL',
    name => 'calories/milliliter'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4184',
    C => 1,
    D => 0,
    annotation => 'cal/mol(g).degC',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cal/mol(g).degC',
    id => 'calPmol(g)TdegC',
    name => 'calories/gram mol degree celsius'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '418.4',
    C => 1,
    D => 0,
    annotation => 'cal/s.cm.degC',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cal/s.cm.degC',
    id => 'calPsTcmTdegC',
    name => 'calories/second centimetre deg C'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '41840',
    C => 1,
    D => 0,
    annotation => 'cal/s.cm2.degC',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cal/s.cm2.degC',
    id => 'calPsTcm2TdegC',
    name => 'calories/second square centimetre deg C'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4184000',
    C => 1,
    D => 0,
    annotation => 'cal/s.cm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cal/s.cm3',
    id => 'calPsTcm3',
    name => 'calories/second cubic centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.01',
    C => 1,
    D => 0,
    annotation => 'cEuc',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cEuc',
    id => 'cEuc',
    name => 'centiEuclid'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.1415926535898',
    C => 0,
    D => '20000',
    annotation => 'cgr',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cgr',
    id => 'cgr',
    name => 'centesimal minute'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.1415926535898',
    C => 0,
    D => '2000000',
    annotation => 'ccgr',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ccgr',
    id => 'ccgr',
    name => 'centesimal second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '735.499',
    C => 1,
    D => 0,
    annotation => 'ch',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ch',
    id => 'ch',
    name => 'ch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '2647796',
    C => 1,
    D => 0,
    annotation => 'ch.h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ch.h',
    id => 'chTh',
    name => 'ch hours'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1899.101',
    C => 1,
    D => 0,
    annotation => 'Chu',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Chu',
    id => 'Chu',
    name => 'chus'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.01',
    C => 1,
    D => 0,
    annotation => 'cm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cm',
    id => 'cm',
    name => 'centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.1',
    C => 1,
    D => 0,
    annotation => 'cu',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cu',
    id => 'cu',
    name => 'capture unit'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.01',
    C => 1,
    D => 0,
    annotation => 'cm/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cm/s',
    id => 'cmPs',
    name => 'centimetre/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.01',
    C => 1,
    D => 0,
    annotation => 'cm/s2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cm/s2',
    id => 'cmPs2',
    name => 'centimetre/second squared'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0001',
    C => 1,
    D => 0,
    annotation => 'cm2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cm2',
    id => 'cm2',
    name => 'square centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1',
    C => 1,
    D => 0,
    annotation => 'cm2/g',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cm2/g',
    id => 'cm2Pg',
    name => 'centimetres squared/gram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0001',
    C => 1,
    D => 0,
    annotation => 'cm2/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cm2/s',
    id => 'cm2Ps',
    name => 'centimetres squared/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'cm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cm3',
    id => 'cm3',
    name => 'cubic centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'cm3/g',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cm3/g',
    id => 'cm3Pg',
    name => 'cubic centimetres/gram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'cm3/m3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cm3/m3',
    id => 'cm3Pm3',
    name => 'cubic centimetre/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.00000001',
    C => 1,
    D => 0,
    annotation => 'cm4',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cm4',
    id => 'cm4',
    name => 'centimetres fourth'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '98.0638',
    C => 1,
    D => 0,
    annotation => 'cmH2O(4degC)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cmH2O(4degC)',
    id => 'cmH2O(4degC)',
    name => 'cm of water at 4 degC.'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'cP',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cP',
    id => 'cP',
    name => 'centipoise'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'cSt',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cSt',
    id => 'cSt',
    name => 'centiStoke'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.02831685',
    C => 1,
    D => 0,
    annotation => 'cu ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cu ft',
    id => 'cu_ft',
    name => 'cubic feet'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.00001638706',
    C => 1,
    D => 0,
    annotation => 'cu in',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cu in',
    id => 'cu_in',
    name => 'cubic inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.7645549',
    C => 1,
    D => 0,
    annotation => 'cu yd',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cu yd',
    id => 'cu_yd',
    name => 'cubic yard'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4168182000.',
    C => 1,
    D => 0,
    annotation => 'cubem',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cubem',
    id => 'cubem',
    name => 'cubem'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '37000000000.',
    C => 1,
    D => 0,
    annotation => 'curie',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'curie',
    id => 'curie',
    name => 'curie'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '735.499',
    C => 1,
    D => 0,
    annotation => 'CV',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'CV',
    id => 'CV',
    name => 'CV'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '2647796',
    C => 1,
    D => 0,
    annotation => 'CV.h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'CV.h',
    id => 'CVTh',
    name => 'CV hours'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '50.80235',
    C => 1,
    D => 0,
    annotation => 'cwtUK',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cwtUK',
    id => 'cwtUK',
    name => 'UK hundredweight'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '45.35924',
    C => 1,
    D => 0,
    annotation => 'cwtUS',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'cwtUS',
    id => 'cwtUS',
    name => 'US hundredweight'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '6.283185307',
    C => 1,
    D => 0,
    annotation => 'c',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'c',
    id => 'c',
    name => 'cycle'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '6.283185307',
    C => 1,
    D => 0,
    annotation => 'c/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'c/s',
    id => 'cPs',
    name => 'cycles/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '86400',
    C => 1,
    D => 0,
    annotation => 'd',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'd',
    id => 'd',
    name => 'day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '86400',
    C => 0,
    D => '0.02831685',
    annotation => 'd/ft3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'd/ft3',
    id => 'dPft3',
    name => 'days/cubic foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '86400',
    C => 1,
    D => 0,
    annotation => 'd/m3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'd/m3',
    id => 'dPm3',
    name => 'days/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9.86923E-13',
    C => 1,
    D => 0,
    annotation => 'D',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'D',
    id => 'D',
    name => 'darcy'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.008141E-13',
    C => 1,
    D => 0,
    annotation => 'D.ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'D.ft',
    id => 'DTft',
    name => 'darcy foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9.86923E-13',
    C => 1,
    D => 0,
    annotation => 'D.m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'D.m',
    id => 'DTm',
    name => 'darcy metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1',
    C => 1,
    D => 0,
    annotation => 'dB',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dB',
    id => 'dB',
    name => 'decibel'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1',
    C => 0,
    D => '0.3048',
    annotation => 'dB/ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dB/ft',
    id => 'dBPft',
    name => 'decibels/foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1',
    C => 1,
    D => 0,
    annotation => 'dB/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dB/m',
    id => 'dBPm',
    name => 'decibels/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1',
    C => 1,
    D => 0,
    annotation => 'dB/O',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dB/O',
    id => 'dBPO',
    name => 'decibels/octave'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'ddegC',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ddegC',
    id => 'ddegC',
    name => 'change in degrees Celsius'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'ddegK',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ddegK',
    id => 'ddegK',
    name => 'change in degrees Kelvin'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '5',
    C => 0,
    D => '9',
    annotation => 'ddegF',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ddegF',
    id => 'ddegF',
    name => 'change in degrees Fahrenheit'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '5',
    C => 0,
    D => '9',
    annotation => 'ddegR',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ddegR',
    id => 'ddegR',
    name => 'change in degrees Rankine'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.01745329',
    C => 1,
    D => 0,
    annotation => 'dega',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dega',
    id => 'dega',
    name => 'degree of an angle'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.01745329',
    C => 0,
    D => '0.3048',
    annotation => 'dega/ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dega/ft',
    id => 'degaPft',
    name => 'degrees of an angle/foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.01745329',
    C => 0,
    D => '30.48',
    annotation => 'dega/ft(100)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dega/ft(100)',
    id => 'degaPft(100)',
    name => 'degrees of an angle/100 feet'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.01745329',
    C => 0,
    D => '30.0',
    annotation => 'dega/m(30)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dega/m(30)',
    id => 'degaPm(30)',
    name => 'degrees of an angle/30 metres'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.01745329',
    C => 1,
    D => 0,
    annotation => 'dega/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dega/m',
    id => 'degaPm',
    name => 'degrees of an angle/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.01745329',
    C => 0,
    D => '60',
    annotation => 'dega/min',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dega/min',
    id => 'degaPmin',
    name => 'degrees of an angle/minute'
  }, 'Petrophysics::Units' ),
  bless( {
    A => '141500',
    B => '0',
    C => '131.5',
    D => '1',
    annotation => 'dAPI',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dAPI',
    id => 'dAPI',
    name => 'API gravity'
  }, 'Petrophysics::Units' ),
  bless( {
    A => '273.15',
    B => '1',
    C => '1',
    D => 0,
    annotation => 'degC',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'degC',
    id => 'degC',
    name => 'degrees Celsius'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.00E-03',
    C => 1,
    D => 0,
    annotation => 'degC/km',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'degC/km',
    id => 'degCPkm',
    name => 'degrees Celsius/kilometre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'degC/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'degC/m',
    id => 'degCPm',
    name => 'degrees Celsius/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.8604208',
    C => 1,
    D => 0,
    annotation => 'degC.m2.h/kcal',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'degC.m2.h/kcal',
    id => 'degCTm2ThPkcal',
    name => 'degrees C square metres hours/kilocal'
  }, 'Petrophysics::Units' ),
  bless( {
    A => '2298.35',
    B => '5.',
    C => '9.',
    D => 0,
    annotation => 'degF',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'degF',
    id => 'degF',
    name => 'degree Fahrenheit'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1761102',
    C => 1,
    D => 0,
    annotation => 'degF.ft2.h/Btu',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'degF.ft2.h/Btu',
    id => 'degFTft2ThPBtu',
    name => 'degrees F square feet hours/Btu'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0001822689',
    C => 1,
    D => 0,
    annotation => 'degF/ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'degF/ft',
    id => 'degFPft',
    name => 'degrees Fahrenheit/foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.01822689',
    C => 1,
    D => 0,
    annotation => 'degF/ft(100)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'degF/ft(100)',
    id => 'degFPft(100)',
    name => 'degrees Fahrenheit/100 feet.'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '5',
    C => 0,
    D => '9',
    annotation => 'degR',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'degR',
    id => 'degR',
    name => 'degrees Rankine'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.1',
    C => 1,
    D => 0,
    annotation => 'dm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dm',
    id => 'dm',
    name => 'decimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'dm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dm3',
    id => 'dm3',
    name => 'cubic decimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'dm3/kg',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dm3/kg',
    id => 'dm3Pkg',
    name => 'cubic decimetres/kilogram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.00000001',
    C => 1,
    D => 0,
    annotation => 'dm3/km(100)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dm3/km(100)',
    id => 'dm3Pkm(100)',
    name => 'cubic decimetres/100 kilometres'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '2.777778E-10',
    C => 1,
    D => 0,
    annotation => 'dm3/kW.h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dm3/kW.h',
    id => 'dm3PkWTh',
    name => 'cubic decimetres/kilowatt hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'dm3/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dm3/m',
    id => 'dm3Pm',
    name => 'cubic decimetres/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'dm3/m3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dm3/m3',
    id => 'dm3Pm3',
    name => 'cubic decimetres/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000000001',
    C => 1,
    D => 0,
    annotation => 'dm3/MJ',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dm3/MJ',
    id => 'dm3PMJ',
    name => 'cubic decimetres/megajoule'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'dm3/mol(kg)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dm3/mol(kg)',
    id => 'dm3Pmol(kg)',
    name => 'cubic decimetres/kilogram mole'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'dm3/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dm3/s',
    id => 'dm3Ps',
    name => 'cubic decimetres/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'dm3/s2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dm3/s2',
    id => 'dm3Ps2',
    name => 'cubic decimetres/second/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'dm3/t',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dm3/t',
    id => 'dm3Pt',
    name => 'cubic decimetres/ton'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.00001',
    C => 1,
    D => 0,
    annotation => 'dyne',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dyne',
    id => 'dyne',
    name => 'dynes'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000000001',
    C => 1,
    D => 0,
    annotation => 'dyne.cm2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dyne.cm2',
    id => 'dyneTcm2',
    name => 'dyne centimetre squared'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1',
    C => 1,
    D => 0,
    annotation => 'dyne.s/cm2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dyne.s/cm2',
    id => 'dyneTsPcm2',
    name => 'dyne seconds/square centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'dyne/cm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dyne/cm',
    id => 'dynePcm',
    name => 'dynes/centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1',
    C => 1,
    D => 0,
    annotation => 'dyne/cm2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'dyne/cm2',
    id => 'dynePcm2',
    name => 'dynes/square centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => '(dyne/cm)4/gcm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '(dyne/cm)4/gcm3',
    id => '(dynePcm)4Pgcm3',
    name => 'dynes/centimetre fourth/gram cm cubed'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.00E+18',
    C => 1,
    D => 0,
    annotation => 'EJ',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'EJ',
    id => 'EJ',
    name => 'exajoule'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '31687540000.',
    C => 1,
    D => 0,
    annotation => 'EJ/a',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'EJ/a',
    id => 'EJPa',
    name => 'exajoules/year'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.0',
    C => 1,
    D => 0,
    annotation => 'eq',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'eq',
    id => 'eq',
    name => 'equivalent'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.0',
    C => 1,
    D => 0,
    annotation => 'eq/kg',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'eq/kg',
    id => 'eqPkg',
    name => 'equivalents/ kilogram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000.0',
    C => 1,
    D => 0,
    annotation => 'eq/L',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'eq/L',
    id => 'eqPL',
    name => 'equivalents/ Liter'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.0',
    C => 1,
    D => 0,
    annotation => 'eq/m3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'eq/m3',
    id => 'eqPm3',
    name => 'equivalent/ cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0000001',
    C => 1,
    D => 0,
    annotation => 'erg',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'erg',
    id => 'erg',
    name => 'ergs'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0000001',
    C => 0,
    D => '31558150',
    annotation => 'erg/a',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'erg/a',
    id => 'ergPa',
    name => 'ergs/year'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'erg/cm2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'erg/cm2',
    id => 'ergPcm2',
    name => 'ergs/square centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1',
    C => 1,
    D => 0,
    annotation => 'erg/cm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'erg/cm3',
    id => 'ergPcm3',
    name => 'ergs/cubic centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0001',
    C => 1,
    D => 0,
    annotation => 'erg/g',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'erg/g',
    id => 'ergPg',
    name => 'ergs/gram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0000001',
    C => 1,
    D => 0,
    annotation => 'erg/kg',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'erg/kg',
    id => 'ergPkg',
    name => 'ergs/kilogram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0000001',
    C => 1,
    D => 0,
    annotation => 'erg/m3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'erg/m3',
    id => 'ergPm3',
    name => 'ergs/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.602190E-19',
    C => 1,
    D => 0,
    annotation => 'eV',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'eV',
    id => 'eV',
    name => 'electron volts'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.E-15',
    C => 1,
    D => 0,
    annotation => 'fC',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'fC',
    id => 'fC',
    name => 'femtocoulomb'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.00002841308',
    C => 1,
    D => 0,
    annotation => 'fl ozUK',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'fl ozUK',
    id => 'fl_ozUK',
    name => 'UK flid ounce'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.00002957353',
    C => 1,
    D => 0,
    annotation => 'fl ozUS',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'fl ozUS',
    id => 'fl_ozUS',
    name => 'US flid ounces'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'flops',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'flops',
    id => 'flops',
    name => 'flops'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '10.76391',
    C => 1,
    D => 0,
    annotation => 'footcandle',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'footcandle',
    id => 'footcandle',
    name => 'footcandles'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '10.76391',
    C => 1,
    D => 0,
    annotation => 'footcandle.s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'footcandle.s',
    id => 'footcandleTs',
    name => 'footcandle seconds'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.355818',
    C => 1,
    D => 0,
    annotation => 'ft.lbf',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft.lbf',
    id => 'ftTlbf',
    name => 'foot pounds force'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.355818',
    C => 0,
    D => '0.1589873',
    annotation => 'ft.lbf/bbl',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft.lbf/bbl',
    id => 'ftTlbfPbbl',
    name => 'foot pounds force/barrel'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '358.1692',
    C => 1,
    D => 0,
    annotation => 'ft.lbf/galUS',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft.lbf/galUS',
    id => 'ftTlbfPgalUS',
    name => 'foot pounds force/US gallon'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.355818',
    C => 0,
    D => '0.4535924',
    annotation => 'ft.lbf/lbm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft.lbf/lbm',
    id => 'ftTlbfPlbm',
    name => 'foot pounds force/pound mass'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.02259697',
    C => 1,
    D => 0,
    annotation => 'ft.lbf/min',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft.lbf/min',
    id => 'ftTlbfPmin',
    name => 'foot pounds force/minute'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.355818',
    C => 1,
    D => 0,
    annotation => 'ft.lbf/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft.lbf/s',
    id => 'ftTlbfPs',
    name => 'foot pounds force/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.917134',
    C => 1,
    D => 0,
    annotation => 'ft/bbl',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft/bbl',
    id => 'ftPbbl',
    name => 'feet/barrel'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.3048',
    C => 0,
    D => '86400',
    annotation => 'ft/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft/d',
    id => 'ftPd',
    name => 'feet/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.54864',
    C => 1,
    D => 0,
    annotation => 'ft/degF',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft/degF',
    id => 'ftPdegF',
    name => 'feet/degree Fahrenheit'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '10.76391',
    C => 1,
    D => 0,
    annotation => 'ft/ft3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft/ft3',
    id => 'ftPft3',
    name => 'feet/cubic foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '80.51964',
    C => 1,
    D => 0,
    annotation => 'ft/galUS',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft/galUS',
    id => 'ftPgalUS',
    name => 'feet/US gallon'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.3048',
    C => 0,
    D => '3600',
    annotation => 'ft/h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft/h',
    id => 'ftPh',
    name => 'feet/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '12.',
    C => 1,
    D => 0,
    annotation => 'ft/in',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft/in',
    id => 'ftPin',
    name => 'feet/inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.3048',
    C => 1,
    D => 0,
    annotation => 'ft/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft/m',
    id => 'ftPm',
    name => 'feet/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '5280',
    annotation => 'ft/mi',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft/mi',
    id => 'ftPmi',
    name => 'feet/mile'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.3048',
    C => 0,
    D => '60',
    annotation => 'ft/min',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft/min',
    id => 'ftPmin',
    name => 'feet/minute'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.3048',
    C => 1,
    D => 0,
    annotation => 'ft/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft/s',
    id => 'ftPs',
    name => 'feet/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.3048',
    C => 1,
    D => 0,
    annotation => 'ft/s2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft/s2',
    id => 'ftPs2',
    name => 'feet/second squared'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.09290304',
    C => 1,
    D => 0,
    annotation => 'ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft2',
    id => 'ft2',
    name => 'square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.09290304',
    C => 0,
    D => '3600',
    annotation => 'ft2/h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft2/h',
    id => 'ft2Ph',
    name => 'square feet/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '5669.291',
    C => 1,
    D => 0,
    annotation => 'ft2/in3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft2/in3',
    id => 'ft2Pin3',
    name => 'square feet/cubic inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.09290304',
    C => 1,
    D => 0,
    annotation => 'ft2/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft2/s',
    id => 'ft2Ps',
    name => 'square feet/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.02831685',
    C => 1,
    D => 0,
    annotation => 'ft3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft3',
    id => 'ft3',
    name => 'cubic feet'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.02831685',
    C => 0,
    D => '0.1589873',
    annotation => 'ft3/bbl',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft3/bbl',
    id => 'ft3Pbbl',
    name => 'cubic feet/barrel'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.02831685',
    C => 0,
    D => '86400',
    annotation => 'ft3/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft3/d',
    id => 'ft3Pd',
    name => 'cubic feet/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.09290304',
    C => 0,
    D => '595707005.',
    annotation => 'ft3/d.ft.psi',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft3/d.ft.psi',
    id => 'ft3PdTftTpsi',
    name => 'cubic feet/day foot psi'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.02831685',
    C => 0,
    D => '7464960000.',
    annotation => 'ft3/d2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft3/d2',
    id => 'ft3Pd2',
    name => 'cubic feet/day/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.09290304',
    C => 1,
    D => 0,
    annotation => 'ft3/ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft3/ft',
    id => 'ft3Pft',
    name => 'cubic feet/foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'ft3/ft3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft3/ft3',
    id => 'ft3Pft3',
    name => 'cubic feet/cubic foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.02831685',
    C => 0,
    D => '3600',
    annotation => 'ft3/h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft3/h',
    id => 'ft3Ph',
    name => 'cubic feet/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.02831685',
    C => 0,
    D => '12960000',
    annotation => 'ft3/h2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft3/h2',
    id => 'ft3Ph2',
    name => 'cubic feet/hour/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.06242796',
    C => 1,
    D => 0,
    annotation => 'ft3/lbm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft3/lbm',
    id => 'ft3Plbm',
    name => 'cubic feet/pound mass'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.02831685',
    C => 0,
    D => '60',
    annotation => 'ft3/min',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft3/min',
    id => 'ft3Pmin',
    name => 'cubic feet/minute'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.02831685',
    C => 0,
    D => '3600',
    annotation => 'ft3/min2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft3/min2',
    id => 'ft3Pmin2',
    name => 'cubic feet/minute/minute'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.3048',
    C => 0,
    D => '60',
    annotation => 'ft3/min.ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft3/min.ft2',
    id => 'ft3PminTft2',
    name => 'cubic feet/min square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.06242796',
    C => 1,
    D => 0,
    annotation => 'ft3/mol(lbm)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft3/mol(lbm)',
    id => 'ft3Pmol(lbm)',
    name => 'cubic feet/mole (pound mass)'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.02831685',
    C => 1,
    D => 0,
    annotation => 'ft3/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft3/s',
    id => 'ft3Ps',
    name => 'cubic feet/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.02831685',
    C => 1,
    D => 0,
    annotation => 'ft3/s2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft3/s2',
    id => 'ft3Ps2',
    name => 'cubic feet/second/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.3048',
    C => 1,
    D => 0,
    annotation => 'ft3/s.ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft3/s.ft2',
    id => 'ft3PsTft2',
    name => 'cubic feet/second square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'ft3/scf(60F)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft3/scf(60F)',
    id => 'ft3Pscf(60F)',
    name => 'cubic feet/std cubic foot, 60 deg F'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0011953',
    C => 1,
    D => 0,
    annotation => 'ft3(std,60F)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ft3(std,60F)',
    id => 'ft3(std,60F)',
    name => 'cubic feet at standard conditions'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.304812253',
    C => 1,
    D => 0,
    annotation => 'ftMA',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ftMA',
    id => 'ftMA',
    name => 'Modified American Foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.9144025',
    C => 0,
    D => '3',
    annotation => 'ftBr(65)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ftBr(65)',
    id => 'ftBr(65)',
    name => 'British Foot 1865'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.30479841',
    C => 1,
    D => 0,
    annotation => 'ftInd(37)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ftInd(37)',
    id => 'ftInd(37)',
    name => 'Indian Foot, 1937'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.3047996',
    C => 1,
    D => 0,
    annotation => 'ftInd(62)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ftInd(62)',
    id => 'ftInd(62)',
    name => 'Indian Foot, 1962'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.3047995',
    C => 1,
    D => 0,
    annotation => 'ftInd(75)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ftInd(75)',
    id => 'ftInd(75)',
    name => 'Indian Foot, 1975'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.015707963268',
    C => 1,
    D => 0,
    annotation => 'gr',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'gr',
    id => 'gr',
    name => 'grad'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'g',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'g',
    id => 'g',
    name => 'gram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0003048',
    C => 0,
    D => '0.000001',
    annotation => 'g.ft/cm3.s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'g.ft/cm3.s',
    id => 'gTftPcm3Ts',
    name => 'gram feet/cubic centimetre second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'g/cm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'g/cm3',
    id => 'gPcm3',
    name => 'grams/cubic centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '100000',
    C => 1,
    D => 0,
    annotation => 'g/cm4',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'g/cm4',
    id => 'gPcm4',
    name => 'grams/centimetre fourth'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'g/dm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'g/dm3',
    id => 'gPdm3',
    name => 'grams/cubic decimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.2199692',
    C => 1,
    D => 0,
    annotation => 'g/galUK',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'g/galUK',
    id => 'gPgalUK',
    name => 'grams/UK gallon'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.264172',
    C => 1,
    D => 0,
    annotation => 'g/galUS',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'g/galUS',
    id => 'gPgalUS',
    name => 'grams/US gallon'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'g/kg',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'g/kg',
    id => 'gPkg',
    name => 'grams/kilogram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'g/L',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'g/L',
    id => 'gPL',
    name => 'grams/litre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'g/m3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'g/m3',
    id => 'gPm3',
    name => 'grams/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'g/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'g/s',
    id => 'gPs',
    name => 'grams/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.155815E+16',
    C => 1,
    D => 0,
    annotation => 'Ga',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Ga',
    id => 'Ga',
    name => 'gigayears'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.01',
    C => 1,
    D => 0,
    annotation => 'Gal',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Gal',
    id => 'Gal',
    name => 'galileo'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.004546092',
    C => 1,
    D => 0,
    annotation => 'galUK',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUK',
    id => 'galUK',
    name => 'UK gallon'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1605437',
    C => 1,
    D => 0,
    annotation => 'galUK/ft3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUK/ft3',
    id => 'galUKPft3',
    name => 'UK gallons/cubic foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.004546092',
    C => 0,
    D => '3600',
    annotation => 'galUK/hr',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUK/hr',
    id => 'galUKPhr',
    name => 'UK gallons/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.004546092',
    C => 0,
    D => '12960000',
    annotation => 'galUK/hr2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUK/hr2',
    id => 'galUKPhr2',
    name => 'UK gallons/hour/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000004143055',
    C => 1,
    D => 0,
    annotation => 'galUK/hr.ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUK/hr.ft',
    id => 'galUKPhrTft',
    name => 'UK gallons/hour foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0000135927',
    C => 1,
    D => 0,
    annotation => 'galUK/hr.ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUK/hr.ft2',
    id => 'galUKPhrTft2',
    name => 'UK gallons/hour square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.00004971667',
    C => 1,
    D => 0,
    annotation => 'galUK/hr.in',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUK/hr.in',
    id => 'galUKPhrTin',
    name => 'UK gallons/hour inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001957349',
    C => 1,
    D => 0,
    annotation => 'galUK/hr.in2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUK/hr.in2',
    id => 'galUKPhrTin2',
    name => 'UK gallons/hour square inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.01002242',
    C => 1,
    D => 0,
    annotation => 'galUK/lbm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUK/lbm',
    id => 'galUKPlbm',
    name => 'UK gallons/pound mass'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.00002859406',
    C => 1,
    D => 0,
    annotation => 'galUK/Mbbl',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUK/Mbbl',
    id => 'galUKPMbbl',
    name => 'UK gallons/1000 barrels'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.004546092',
    C => 0,
    D => '1609.344',
    annotation => 'galUK/mi',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUK/mi',
    id => 'galUKPmi',
    name => 'UK gallons/mile'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.004546092',
    C => 0,
    D => '60',
    annotation => 'galUK/min',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUK/min',
    id => 'galUKPmin',
    name => 'UK gallons/minute'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.004546092',
    C => 0,
    D => '3600',
    annotation => 'galUK/min2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUK/min2',
    id => 'galUKPmin2',
    name => 'UK gallons/minute/minute'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0002485333',
    C => 1,
    D => 0,
    annotation => 'galUK/min.ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUK/min.ft',
    id => 'galUKPminTft',
    name => 'UK gallons/minute foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0008155621',
    C => 1,
    D => 0,
    annotation => 'galUK/min.ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUK/min.ft2',
    id => 'galUKPminTft2',
    name => 'UK gallons/minute square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.003785412',
    C => 1,
    D => 0,
    annotation => 'galUS',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUS',
    id => 'galUS',
    name => 'US gallons'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.003785412',
    C => 0,
    D => '0.3048',
    annotation => 'galUS/ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUS/ft',
    id => 'galUSPft',
    name => 'US gallons/foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1336806',
    C => 1,
    D => 0,
    annotation => 'galUS/ft3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUS/ft3',
    id => 'galUSPft3',
    name => 'US gallons/cubic foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.003785412',
    C => 0,
    D => '3600',
    annotation => 'galUS/hr',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUS/hr',
    id => 'galUSPhr',
    name => 'US gallons/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.003785412',
    C => 0,
    D => '12960000',
    annotation => 'galUS/hr2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUS/hr2',
    id => 'galUSPhr2',
    name => 'US gallons/hour/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000003449814',
    C => 1,
    D => 0,
    annotation => 'galUS/hr.ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUS/hr.ft',
    id => 'galUSPhrTft',
    name => 'US gallons/foot hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.00001131829',
    C => 1,
    D => 0,
    annotation => 'galUS/hr.ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUS/hr.ft2',
    id => 'galUSPhrTft2',
    name => 'US gallons/hour square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.00004139776',
    C => 1,
    D => 0,
    annotation => 'galUS/hr.in',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUS/hr.in',
    id => 'galUSPhrTin',
    name => 'US gallons/hour inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001629833',
    C => 1,
    D => 0,
    annotation => 'galUS/hr.in2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUS/hr.in2',
    id => 'galUSPhrTin2',
    name => 'US gallons/hour square inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.003785412',
    C => 0,
    D => '28.262357',
    annotation => 'galUS/Mscf(60F)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUS/Mscf(60F)',
    id => 'galUSPMscf(60F)',
    name => 'US gals/1000 std cubic feet, 60 deg F'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.008345404',
    C => 1,
    D => 0,
    annotation => 'galUS/lbm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUS/lbm',
    id => 'galUSPlbm',
    name => 'US gallons/pound mass'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.00002380952',
    C => 1,
    D => 0,
    annotation => 'galUS/Mbbl',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUS/Mbbl',
    id => 'galUSPMbbl',
    name => 'US gallons/1000 barrels'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.003785412',
    C => 0,
    D => '1609.344',
    annotation => 'galUS/mi',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUS/mi',
    id => 'galUSPmi',
    name => 'US gallons/mile'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.003785412',
    C => 0,
    D => '60',
    annotation => 'galUS/min',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUS/min',
    id => 'galUSPmin',
    name => 'US gallons/minute'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.003785412',
    C => 0,
    D => '3600',
    annotation => 'galUS/min2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUS/min2',
    id => 'galUSPmin2',
    name => 'US gallons/minute/minute'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0002069888',
    C => 1,
    D => 0,
    annotation => 'galUS/min.ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUS/min.ft',
    id => 'galUSPminTft',
    name => 'US gallons/minute foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0006790972',
    C => 1,
    D => 0,
    annotation => 'galUS/min.ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUS/min.ft2',
    id => 'galUSPminTft2',
    name => 'US gallons/minute square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000003725627',
    C => 1,
    D => 0,
    annotation => 'galUS/tonUK',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUS/tonUK',
    id => 'galUSPtonUK',
    name => 'US gallons/UK ton'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000004172702',
    C => 1,
    D => 0,
    annotation => 'galUS/tonUS',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'galUS/tonUS',
    id => 'galUSPtonUS',
    name => 'US gallons/US ton'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.003785412',
    C => 0,
    D => '42.63769',
    annotation => 'gal/sack',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'gal/sack',
    id => 'galPsack',
    name => 'US gallons/94 lb sack'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0007957747',
    C => 1,
    D => 0,
    annotation => 'gamma',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'gamma',
    id => 'gamma',
    name => 'gamma'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0001',
    C => 1,
    D => 0,
    annotation => 'gauss',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'gauss',
    id => 'gauss',
    name => 'gauss'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000000000160219',
    C => 1,
    D => 0,
    annotation => 'GeV',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'GeV',
    id => 'GeV',
    name => 'billions of electron volts'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9.80665',
    C => 1,
    D => 0,
    annotation => 'gn',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'gn',
    id => 'gn',
    name => 'earth gravity multiple'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000000.',
    C => 1,
    D => 0,
    annotation => 'GPa',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'GPa',
    id => 'GPa',
    name => 'gigapascal'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.00006479891',
    C => 1,
    D => 0,
    annotation => 'grain',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'grain',
    id => 'grain',
    name => 'grain'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.002288352',
    C => 1,
    D => 0,
    annotation => 'grain/ft3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'grain/ft3',
    id => 'grainPft3',
    name => 'grains/cubic foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.00002288352',
    C => 1,
    D => 0,
    annotation => 'grain/ft3(100)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'grain/ft3(100)',
    id => 'grainPft3(100)',
    name => 'grains/100 cubic feet'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.01711806',
    C => 1,
    D => 0,
    annotation => 'grain/galUS',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'grain/galUS',
    id => 'grainPgalUS',
    name => 'grains/US gallon'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000000.',
    C => 1,
    D => 0,
    annotation => 'Gsm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Gsm3',
    id => 'Gsm3',
    name => 'giga standard cubic metres 15C'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000000.',
    C => 1,
    D => 0,
    annotation => 'GW',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'GW',
    id => 'GW',
    name => 'gigawatt'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3600000000000.',
    C => 1,
    D => 0,
    annotation => 'GW.h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'GW.h',
    id => 'GWTh',
    name => 'gigawatt hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3600',
    C => 1,
    D => 0,
    annotation => 'h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'h',
    id => 'h',
    name => 'hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3600',
    C => 0,
    D => '0.02831685',
    annotation => 'h/ft3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'h/ft3',
    id => 'hPft3',
    name => 'hours/cubic foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '10000',
    C => 1,
    D => 0,
    annotation => 'ha',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ha',
    id => 'ha',
    name => 'hectare'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '10000',
    C => 1,
    D => 0,
    annotation => 'ha.m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ha.m',
    id => 'haTm',
    name => 'hectare metres'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '746.043',
    C => 1,
    D => 0,
    annotation => 'hhp',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'hhp',
    id => 'hhp',
    name => 'hydraulic horsepower'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '745.6999',
    C => 1,
    D => 0,
    annotation => 'hp',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'hp',
    id => 'hp',
    name => 'horsepower'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '746',
    C => 1,
    D => 0,
    annotation => 'ehp',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ehp',
    id => 'ehp',
    name => 'electric horsepower'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '2684520',
    C => 1,
    D => 0,
    annotation => 'hp.hr',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'hp.hr',
    id => 'hpThr',
    name => 'horsepower hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '2684520',
    C => 0,
    D => '0.1589873',
    annotation => 'hp.hr/bbl',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'hp.hr/bbl',
    id => 'hpThrPbbl',
    name => 'horsepower hours/barrel'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '2684520',
    C => 0,
    D => '0.4535924',
    annotation => 'hp.hr/lbm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'hp.hr/lbm',
    id => 'hpThrPlbm',
    name => 'horsepower hours/pound mass'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '26334.14',
    C => 1,
    D => 0,
    annotation => 'hp/ft3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'hp/ft3',
    id => 'hpPft3',
    name => 'horsepower/cubic foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '6.283185307',
    C => 1,
    D => 0,
    annotation => 'Hz',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Hz',
    id => 'Hz',
    name => 'Hertz'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0254',
    C => 1,
    D => 0,
    annotation => 'in',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'in',
    id => 'in',
    name => 'inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.8',
    C => 1,
    D => 0,
    annotation => 'in/in.degF',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'in/in.degF',
    id => 'inPinTdegF',
    name => 'inches/inch degree Fahrenheit'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0254',
    C => 0,
    D => '60',
    annotation => 'in/min',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'in/min',
    id => 'inPmin',
    name => 'inches/minute'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0254',
    C => 1,
    D => 0,
    annotation => 'in/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'in/s',
    id => 'inPs',
    name => 'inches/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0254',
    C => 0,
    D => '31558150',
    annotation => 'in/a',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'in/a',
    id => 'inPa',
    name => 'inches/year'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.00064516',
    C => 1,
    D => 0,
    annotation => 'in2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'in2',
    id => 'in2',
    name => 'square inches'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '144',
    annotation => 'in2/ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'in2/ft2',
    id => 'in2Pft2',
    name => 'square inches/square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'in2/in2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'in2/in2',
    id => 'in2Pin2',
    name => 'square inches/square inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '6.4516E-04',
    C => 1,
    D => 0,
    annotation => 'in2/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'in2/s',
    id => 'in2Ps',
    name => 'square inches/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.00001638706',
    C => 1,
    D => 0,
    annotation => 'in3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'in3',
    id => 'in3',
    name => 'cubic inches'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0000004162314',
    C => 1,
    D => 0,
    annotation => 'in4',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'in4',
    id => 'in4',
    name => 'inches to the fourth'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '249.082',
    C => 1,
    D => 0,
    annotation => 'inH2O(39.2F)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'inH2O(39.2F)',
    id => 'inH2O(39T2F)',
    name => 'inches of water at 39.2 deg F'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '248.84',
    C => 1,
    D => 0,
    annotation => 'inH2O(60F)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'inH2O(60F)',
    id => 'inH2O(60F)',
    name => 'inches of water at 60 deg F'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3386.38',
    C => 1,
    D => 0,
    annotation => 'inHg(32F)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'inHg(32F)',
    id => 'inHg(32F)',
    name => 'inches of mercury at 32 deg F'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3376.85',
    C => 1,
    D => 0,
    annotation => 'inHg(60F)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'inHg(60F)',
    id => 'inHg(60F)',
    name => 'inches of mercury at 60 deg F'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '10000',
    C => 1,
    D => 0,
    annotation => 'J/cm2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'J/cm2',
    id => 'JPcm2',
    name => 'joules/square centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'J/dm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'J/dm3',
    id => 'JPdm3',
    name => 'joules/cubic decimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'J/g',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'J/g',
    id => 'JPg',
    name => 'joules/gram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'J/g.K',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'J/g.K',
    id => 'JPgTK',
    name => 'joules/gram degree Kelvin'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'J/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'J/m',
    id => 'JPm',
    name => 'joules/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'J/m2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'J/m2',
    id => 'JPm2',
    name => 'joules/square metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'J/s.m2.degC',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'J/s.m2.degC',
    id => 'JPsTm2TdegC',
    name => 'joules/second square metre deg C'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'K.m2/kW',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'K.m2/kW',
    id => 'KTm2PkW',
    name => 'degrees Kelvin square metres/kilowatt'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1024',
    C => 1,
    D => 0,
    annotation => 'kbyte',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kbyte',
    id => 'kbyte',
    name => 'kilobyte'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'kC',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kC',
    id => 'kC',
    name => 'kilocoulombs'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4184',
    C => 1,
    D => 0,
    annotation => 'kcal',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kcal',
    id => 'kcal',
    name => 'kilocalories'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4184',
    C => 0,
    D => '0.0001',
    annotation => 'kcal.m/cm2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kcal.m/cm2',
    id => 'kcalTmPcm2',
    name => 'kilocalorie metres/square centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4184',
    C => 0,
    D => '0.000001',
    annotation => 'kcal/cm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kcal/cm3',
    id => 'kcalPcm3',
    name => 'kilocalories/cubic centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4184',
    C => 0,
    D => '0.001',
    annotation => 'kcal/g',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kcal/g',
    id => 'kcalPg',
    name => 'kilocalories/gram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.162222',
    C => 1,
    D => 0,
    annotation => 'kcal/h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kcal/h',
    id => 'kcalPh',
    name => 'kilocalories/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.162222',
    C => 1,
    D => 0,
    annotation => 'kcal/h.m.degC',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kcal/h.m.degC',
    id => 'kcalPhTmTdegC',
    name => 'kilocalories/hour metre degree Celsius'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.162222',
    C => 1,
    D => 0,
    annotation => 'kcal/h.m2.degC',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kcal/h.m2.degC',
    id => 'kcalPhTm2TdegC',
    name => 'kilocalorie/hour square metre deg C'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4184',
    C => 1,
    D => 0,
    annotation => 'kcal/kg',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kcal/kg',
    id => 'kcalPkg',
    name => 'kilocalories/kilogram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4184',
    C => 1,
    D => 0,
    annotation => 'kcal/kg.degC',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kcal/kg.degC',
    id => 'kcalPkgTdegC',
    name => 'kilocalories/kilogram degree Celsius'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4184',
    C => 1,
    D => 0,
    annotation => 'kcal/m3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kcal/m3',
    id => 'kcalPm3',
    name => 'kilocalroies/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4184000',
    C => 1,
    D => 0,
    annotation => 'kcal/mol(g)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kcal/mol(g)',
    id => 'kcalPmol(g)',
    name => 'kilocalories/mole (gram)'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.60219E-16',
    C => 1,
    D => 0,
    annotation => 'keV',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'keV',
    id => 'keV',
    name => 'kiloelectron volts'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'kg/dm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kg/dm3',
    id => 'kgPdm3',
    name => 'kilograms/cubic decimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '10000',
    C => 1,
    D => 0,
    annotation => 'kg/dm4',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kg/dm4',
    id => 'kgPdm4',
    name => 'kilograms/decimetre fourth'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '10000',
    C => 1,
    D => 0,
    annotation => 'kg.m/cm2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kg.m/cm2',
    id => 'kgTmPcm2',
    name => 'kilogram metres/square centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '3600',
    annotation => 'kg/h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kg/h',
    id => 'kgPh',
    name => 'kilograms/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'kg/kg',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kg/kg',
    id => 'kgPkg',
    name => 'kilograms/kilogram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '3600000',
    annotation => 'kg/kW.h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kg/kW.h',
    id => 'kgPkWTh',
    name => 'kilograms/kilowatt hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'kg/MJ',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kg/MJ',
    id => 'kgPMJ',
    name => 'kilograms/megajoule'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9.80665',
    C => 1,
    D => 0,
    annotation => 'kgf',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kgf',
    id => 'kgf',
    name => 'kilogram force'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9.80665',
    C => 1,
    D => 0,
    annotation => 'kgf.m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kgf.m',
    id => 'kgfTm',
    name => 'kilogram force metres'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9.80665',
    C => 1,
    D => 0,
    annotation => 'kgf.m2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kgf.m2',
    id => 'kgfTm2',
    name => 'kilogram force metres squared'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '98066.5',
    C => 1,
    D => 0,
    annotation => 'kgf.m/cm2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kgf.m/cm2',
    id => 'kgfTmPcm2',
    name => 'kilogram force metres/square centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9.80665',
    C => 1,
    D => 0,
    annotation => 'kgf.m/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kgf.m/m',
    id => 'kgfTmPm',
    name => 'kilograms force metres/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9.80665',
    C => 1,
    D => 0,
    annotation => 'kgf.s/m2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kgf.s/m2',
    id => 'kgfTsPm2',
    name => 'kilograms force seconds/square metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9.80665',
    C => 0,
    D => '0.01',
    annotation => 'kgf/cm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kgf/cm',
    id => 'kgfPcm',
    name => 'kilograms force/centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9.80665',
    C => 0,
    D => '0.000001',
    annotation => 'kgf/mm2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kgf/mm2',
    id => 'kgfPmm2',
    name => 'kilogram force/square millimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '6283.185307',
    C => 1,
    D => 0,
    annotation => 'kHz',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kHz',
    id => 'kHz',
    name => 'kilohertz'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'kJ',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kJ',
    id => 'kJ',
    name => 'kilojoules'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '3.6',
    annotation => 'kJ.m/h.m2.K',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kJ.m/h.m2.K',
    id => 'kJTmPhTm2TK',
    name => 'kilojoule metres/hour sq metre deg K'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000',
    C => 1,
    D => 0,
    annotation => 'kJ/dm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kJ/dm3',
    id => 'kJPdm3',
    name => 'kilojoules/cubic decimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 0,
    D => '3600',
    annotation => 'kJ/h.m2.K',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kJ/h.m2.K',
    id => 'kJPhTm2TK',
    name => 'kilojoules/hour square metre deg K'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'kJ/kg',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kJ/kg',
    id => 'kJPkg',
    name => 'kilojoule/kilogram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'kJ/kg.K',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kJ/kg.K',
    id => 'kJPkgTK',
    name => 'kilojoules/kilogram degree Kelvin'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'kJ/m3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kJ/m3',
    id => 'kJPm3',
    name => 'kilojoule/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'kJ/mol(kg)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kJ/mol(kg)',
    id => 'kJPmol(kg)',
    name => 'kilojoule/mole (kilogram)'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'kJ/mol(kg).K',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kJ/mol(kg).K',
    id => 'kJPmol(kg)TK',
    name => 'kilojoules/mole (kilogram) deg K'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '100000.',
    C => 1,
    D => 0,
    annotation => 'km/cm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'km/cm',
    id => 'kmPcm',
    name => 'kilometre/ centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000',
    C => 1,
    D => 0,
    annotation => 'km/dm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'km/dm3',
    id => 'kmPdm3',
    name => 'kilometres/cubic decimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '3.6',
    annotation => 'km/h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'km/h',
    id => 'kmPh',
    name => 'kilometres/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000',
    C => 1,
    D => 0,
    annotation => 'km/L',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'km/L',
    id => 'kmPL',
    name => 'kilometres/litre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000',
    C => 1,
    D => 0,
    annotation => 'km2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'km2',
    id => 'km2',
    name => 'square kilometres'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000000.',
    C => 1,
    D => 0,
    annotation => 'km3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'km3',
    id => 'km3',
    name => 'cubic kilometres'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'kN',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kN',
    id => 'kN',
    name => 'kilonewtons'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'kN.m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kN.m',
    id => 'kNTm',
    name => 'kilonewton metres'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'kN.m2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kN.m2',
    id => 'kNTm2',
    name => 'kilonewton metres squared'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'kN/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kN/m',
    id => 'kNPm',
    name => 'kilonewtons/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1852',
    C => 0,
    D => '3600.',
    annotation => 'knot',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'knot',
    id => 'knot',
    name => 'knots'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'kPa',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kPa',
    id => 'kPa',
    name => 'kilopascals'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'kPa.s/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kPa.s/m',
    id => 'kPaTsPm',
    name => 'kilopascal seconds/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'kPa/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kPa/m',
    id => 'kPaPm',
    name => 'kilopascals/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000.',
    C => 1,
    D => 0,
    annotation => 'ksm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ksm3',
    id => 'ksm3',
    name => 'kilo standard cubic metres 15C'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000.',
    C => 1,
    D => 0,
    annotation => 'ksm3/sm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ksm3/sm3',
    id => 'ksm3Psm3',
    name => '1000 std cubic metres/ std cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000.',
    C => 0,
    D => '86400.',
    annotation => 'ksm3/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ksm3/d',
    id => 'ksm3Pd',
    name => 'thousand std cubic metres/ day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'kV',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kV',
    id => 'kV',
    name => 'kilovolt'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'kW',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kW',
    id => 'kW',
    name => 'kilowatts'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3600000',
    C => 1,
    D => 0,
    annotation => 'kW.h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kW.h',
    id => 'kWTh',
    name => 'kilowatt hours'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3600000',
    C => 0,
    D => '0.001',
    annotation => 'kW.h/dm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kW.h/dm3',
    id => 'kWThPdm3',
    name => 'kilowatt hours/decimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3600000',
    C => 1,
    D => 0,
    annotation => 'kW.h/kg',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kW.h/kg',
    id => 'kWThPkg',
    name => 'kilowatt hours/kilogram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3600000',
    C => 1,
    D => 0,
    annotation => 'kW.h/kg.degC',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kW.h/kg.degC',
    id => 'kWThPkgTdegC',
    name => 'kilowatt hours/kilogram degree C'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3600000',
    C => 1,
    D => 0,
    annotation => 'kW.h/m3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kW.h/m3',
    id => 'kWThPm3',
    name => 'kilowatt hours/cubic metres'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'kW/m2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kW/m2',
    id => 'kWPm2',
    name => 'kilowatts/square metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'kW/m2.K',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kW/m2.K',
    id => 'kWPm2TK',
    name => 'kilowatts/square metre degree Kelvin'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'kW/m3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kW/m3',
    id => 'kWPm3',
    name => 'kilowatts/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'kW/m3.K',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'kW/m3.K',
    id => 'kWPm3TK',
    name => 'killowatts/cubic metre degree Kelvin'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'L',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'L',
    id => 'L',
    name => 'litre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 0,
    D => '100000',
    annotation => 'L/km(100)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'L/km(100)',
    id => 'LPkm(100)',
    name => 'litres/100 kilometres'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'L/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'L/m',
    id => 'LPm',
    name => 'litres/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'L/m3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'L/m3',
    id => 'LPm3',
    name => 'litres/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'L/mol(g)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'L/mol(g)',
    id => 'LPmol(g)',
    name => 'litres/mole (gram)'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'L/mol(kg)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'L/mol(kg)',
    id => 'LPmol(kg)',
    name => 'litres/mole (kilogram)'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'L/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'L/s',
    id => 'LPs',
    name => 'litres/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'L/s2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'L/s2',
    id => 'LPs2',
    name => 'litres/second/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'L/t',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'L/t',
    id => 'LPt',
    name => 'litres/tonne'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4.448222',
    C => 1,
    D => 0,
    annotation => 'lbf',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbf',
    id => 'lbf',
    name => 'pounds force'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.355818',
    C => 1,
    D => 0,
    annotation => 'lbf.ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbf.ft',
    id => 'lbfTft',
    name => 'foot pounds force'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.355818',
    C => 0,
    D => '0.1589873',
    annotation => 'lbf.ft/bbl',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbf.ft/bbl',
    id => 'lbfTftPbbl',
    name => 'foot pounds force/barrel'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.355818',
    C => 0,
    D => '0.0254',
    annotation => 'lbf.ft/in',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbf.ft/in',
    id => 'lbfTftPin',
    name => 'pounds force feet/inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '2101.522',
    C => 1,
    D => 0,
    annotation => 'lbf.ft/in2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbf.ft/in2',
    id => 'lbfTftPin2',
    name => 'foot pounds force/square inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.355818',
    C => 0,
    D => '0.4535924',
    annotation => 'lbf.ft/lbm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbf.ft/lbm',
    id => 'lbfTftPlbm',
    name => 'foot pounds force/pound mass'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1129848',
    C => 1,
    D => 0,
    annotation => 'lbf.in',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbf.in',
    id => 'lbfTin',
    name => 'inch pounds force'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.002869815',
    C => 1,
    D => 0,
    annotation => 'lbf.in2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbf.in2',
    id => 'lbfTin2',
    name => 'pounds force inches squared'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4.448222',
    C => 1,
    D => 0,
    annotation => 'lbf.in/in',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbf.in/in',
    id => 'lbfTinPin',
    name => 'pounds force inches/inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4.448222',
    C => 0,
    D => '0.0254',
    annotation => 'lbf/in',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbf/in',
    id => 'lbfPin',
    name => 'pounds force/inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '47.88026',
    C => 1,
    D => 0,
    annotation => 'lbf.s/ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbf.s/ft2',
    id => 'lbfTsPft2',
    name => 'pounds force seconds/square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '6894.757',
    C => 1,
    D => 0,
    annotation => 'lbf.s/in2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbf.s/in2',
    id => 'lbfTsPin2',
    name => 'pounds force seconds/square inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '47.88026',
    C => 1,
    D => 0,
    annotation => 'lbf/ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbf/ft2',
    id => 'lbfPft2',
    name => 'pounds force/square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.4788026',
    C => 1,
    D => 0,
    annotation => 'lbf/ft2(100)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbf/ft2(100)',
    id => 'lbfPft2(100)',
    name => 'pounds force/100 square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4.448222',
    C => 0,
    D => '0.02831685',
    annotation => 'lbf/ft3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbf/ft3',
    id => 'lbfPft3',
    name => 'pounds force/cubic foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '6894.757',
    C => 1,
    D => 0,
    annotation => 'lbf/in2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbf/in2',
    id => 'lbfPin2',
    name => 'pounds force/square inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4.448222',
    C => 0,
    D => '0.003785412',
    annotation => 'lbf/galUS',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbf/galUS',
    id => 'lbfPgalUS',
    name => 'pounds force/US gallon'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.4535924',
    C => 1,
    D => 0,
    annotation => 'lbm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm',
    id => 'lbm',
    name => 'pounds mass'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '453592.4',
    C => 0,
    D => '31558150',
    annotation => 'lbm(million)/yr',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm(million)/yr',
    id => 'lbm(million)Pyr',
    name => 'million pounds mass/year'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.138255',
    C => 1,
    D => 0,
    annotation => 'lbm.ft/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm.ft/s',
    id => 'lbmTftPs',
    name => 'foot pounds mass/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.04214011',
    C => 1,
    D => 0,
    annotation => 'lbm.ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm.ft2',
    id => 'lbmTft2',
    name => 'pounds mass square feet'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.04214011',
    C => 1,
    D => 0,
    annotation => 'lbm.ft2/s2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm.ft2/s2',
    id => 'lbmTft2Ps2',
    name => 'pounds mass square feet/second squared'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4.882428',
    C => 1,
    D => 0,
    annotation => 'lbm/s.ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/s.ft2',
    id => 'lbmPsTft2',
    name => 'pounds mass/second square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '2.85301',
    C => 1,
    D => 0,
    annotation => 'lbm/bbl',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/bbl',
    id => 'lbmPbbl',
    name => 'pounds mass/barrel'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.488164',
    C => 1,
    D => 0,
    annotation => 'lbm/ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/ft',
    id => 'lbmPft',
    name => 'pounds mass/foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0004133789',
    C => 1,
    D => 0,
    annotation => 'lbm/ft.h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/ft.h',
    id => 'lbmPftTh',
    name => 'pounds mass/foot hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.488164',
    C => 1,
    D => 0,
    annotation => 'lbm/ft.s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/ft.s',
    id => 'lbmPftTs',
    name => 'pounds mass/foot second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4.882428',
    C => 1,
    D => 0,
    annotation => 'lbm/ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/ft2',
    id => 'lbmPft2',
    name => 'pounds mass/square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '16.01846',
    C => 1,
    D => 0,
    annotation => 'lbm/ft3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/ft3',
    id => 'lbmPft3',
    name => 'pounds mass/cubic foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '16.01846',
    C => 0,
    D => '0.3048',
    annotation => 'lbm/ft4',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/ft4',
    id => 'lbmPft4',
    name => 'pounds mass/foot fourth'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '99.77633',
    C => 1,
    D => 0,
    annotation => 'lbm/galUK',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/galUK',
    id => 'lbmPgalUK',
    name => 'pounds mass/UK gallon'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '99.77633',
    C => 0,
    D => '1000',
    annotation => 'lbm/galUK(1000)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/galUK(1000)',
    id => 'lbmPgalUK(1000)',
    name => 'pounds mass/1000 UK gallons'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '99.77633',
    C => 0,
    D => '0.3048',
    annotation => 'lbm/galUK.ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/galUK.ft',
    id => 'lbmPgalUKTft',
    name => 'pounds mass/UK gallon foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '119.8264',
    C => 1,
    D => 0,
    annotation => 'lbm/galUS',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/galUS',
    id => 'lbmPgalUS',
    name => 'pounds mass/US gallon'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '119.8264',
    C => 0,
    D => '1000',
    annotation => 'lbm/galUS(1000)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/galUS(1000)',
    id => 'lbmPgalUS(1000)',
    name => 'pounds mass/1000 US gallons'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '119.8264',
    C => 0,
    D => '0.3048',
    annotation => 'lbm/galUS.ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/galUS.ft',
    id => 'lbmPgalUSTft',
    name => 'pounds mass/US gallon foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0000001689659',
    C => 1,
    D => 0,
    annotation => 'lbm/hp.h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/hp.h',
    id => 'lbmPhpTh',
    name => 'pounds mass/horsepower hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.4535924',
    C => 0,
    D => '3600',
    annotation => 'lbm/h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/h',
    id => 'lbmPh',
    name => 'pounds mass/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0004133789',
    C => 1,
    D => 0,
    annotation => 'lbm/h.ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/h.ft',
    id => 'lbmPhTft',
    name => 'pounds mass/hour foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.00135623',
    C => 1,
    D => 0,
    annotation => 'lbm/h.ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/h.ft2',
    id => 'lbmPhTft2',
    name => 'pounds mass/hour square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.00285301',
    C => 1,
    D => 0,
    annotation => 'lbm/Mbbl',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/Mbbl',
    id => 'lbmPMbbl',
    name => 'pounds mass/1000 barrels'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.007559873',
    C => 1,
    D => 0,
    annotation => 'lbm/min',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/min',
    id => 'lbmPmin',
    name => 'pounds mass/minute'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.4535924',
    C => 1,
    D => 0,
    annotation => 'lbm/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/s',
    id => 'lbmPs',
    name => 'pounds mass/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.488164',
    C => 1,
    D => 0,
    annotation => 'lbm/s.ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lbm/s.ft',
    id => 'lbmPsTft',
    name => 'pounds mass/second foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'lm/m2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'lm/m2',
    id => 'lmPm2',
    name => 'lumens/square metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.000014',
    C => 1,
    D => 0,
    annotation => 'mGer',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mGer',
    id => 'mGer',
    name => 'German legal metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '86400',
    annotation => 'm/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm/d',
    id => 'mPd',
    name => 'metres/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '3600',
    annotation => 'm/h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm/h',
    id => 'mPh',
    name => 'metres/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '100.',
    C => 1,
    D => 0,
    annotation => 'm/cm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm/cm',
    id => 'mPcm',
    name => 'metres/ centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'm/km',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm/km',
    id => 'mPkm',
    name => 'metres/kilometre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'm/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm/m',
    id => 'mPm',
    name => 'metres/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'm/m.K',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm/m.K',
    id => 'mPmTK',
    name => 'metres/metre Kelvin'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'm/m3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm/m3',
    id => 'mPm3',
    name => 'metres/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'm/ms',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm/ms',
    id => 'mPms',
    name => 'metres/millisecond'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000',
    C => 1,
    D => 0,
    annotation => 'm2/cm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm2/cm3',
    id => 'm2Pcm3',
    name => 'square metres/cubic centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '86400000',
    annotation => 'm2/d.kPa',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm2/d.kPa',
    id => 'm2PdTkPa',
    name => 'square metres/day kiloPascal'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'm2/g',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm2/g',
    id => 'm2Pg',
    name => 'square metres/gram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '3600',
    annotation => 'm2/h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm2/h',
    id => 'm2Ph',
    name => 'square metres/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'm2/m2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm2/m2',
    id => 'm2Pm2',
    name => 'square metres/square metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'm2/m3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm2/m3',
    id => 'm2Pm3',
    name => 'square metres/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0446158',
    C => 1,
    D => 0,
    annotation => 'm3(std,0C)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm3(std,0C)',
    id => 'm3(std,0C)',
    name => 'cubic metres at std condition (0 deg C)'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0422932',
    C => 1,
    D => 0,
    annotation => 'm3(std,15C)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm3(std,15C)',
    id => 'm3(std,15C)',
    name => 'cubic metres at std condition (15 deg C)'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000.',
    C => 1,
    D => 0,
    annotation => 'm3/cP.Pa.s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm3/cP.Pa.s',
    id => 'm3PcPTPaTs',
    name => 'cubic metres/centiPoise Pascal second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '86400',
    annotation => 'm3/cP.d.kPa',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm3/cP.d.kPa',
    id => 'm3PcPTdTkPa',
    name => 'cubic metres/centiPoise day kiloPascal'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '86400',
    annotation => 'm3/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm3/d',
    id => 'm3Pd',
    name => 'cubic metres/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '7464960000.',
    annotation => 'm3/d2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm3/d2',
    id => 'm3Pd2',
    name => 'cubic metres/day/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '86400000',
    annotation => 'm3/d.kPa',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm3/d.kPa',
    id => 'm3PdTkPa',
    name => 'cubic metres/day kilopascal'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'm3/g',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm3/g',
    id => 'm3Pg',
    name => 'cubic metres/gram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '3600',
    annotation => 'm3/h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm3/h',
    id => 'm3Ph',
    name => 'cubic metres/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0001',
    C => 1,
    D => 0,
    annotation => 'm3/ha.m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm3/ha.m',
    id => 'm3PhaTm',
    name => 'cubic metres/hectare metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'm3/km',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm3/km',
    id => 'm3Pkm',
    name => 'cubic metres/kilometre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '3600000',
    annotation => 'm3/kW.h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm3/kW.h',
    id => 'm3PkWTh',
    name => 'cubic metres/kilowatt hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'm3/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm3/m',
    id => 'm3Pm',
    name => 'cubic metres/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'm3/m3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm3/m3',
    id => 'm3Pm3',
    name => 'cubic metres/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'm3/mol(kg)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm3/mol(kg)',
    id => 'm3Pmol(kg)',
    name => 'cubic metres/mole (kilogram)'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'm3/s.m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm3/s.m',
    id => 'm3PsTm',
    name => 'cubic metres/second metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'm3/s.m2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm3/s.m2',
    id => 'm3PsTm2',
    name => 'cubic metres/second square metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'm3/t',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'm3/t',
    id => 'm3Pt',
    name => 'cubic metres/tonne'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.001',
    C => 1,
    D => 0,
    annotation => 'mA',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mA',
    id => 'mA',
    name => 'milliamp'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '31558150000000.',
    C => 1,
    D => 0,
    annotation => 'Ma',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Ma',
    id => 'Ma',
    name => 'megayears'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '158.9873',
    C => 1,
    D => 0,
    annotation => 'Mbbl',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Mbbl',
    id => 'Mbbl',
    name => 'thousand barrels'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '158.9873',
    C => 0,
    D => '86400',
    annotation => 'Mbbl/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Mbbl/d',
    id => 'MbblPd',
    name => 'thousand barrels/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '48.45933',
    C => 0,
    D => '86400',
    annotation => 'Mbbl.ft/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Mbbl.ft/d',
    id => 'MbblTftPd',
    name => 'thousand barrel feet/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1048576',
    C => 1,
    D => 0,
    annotation => 'Mbyte',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Mbyte',
    id => 'Mbyte',
    name => 'megabyte'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.001',
    C => 1,
    D => 0,
    annotation => 'mC',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mC',
    id => 'mC',
    name => 'millicoulomb'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'mC/m2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mC/m2',
    id => 'mCPm2',
    name => 'millicoulombs/square metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9.86932E-16',
    C => 1,
    D => 0,
    annotation => 'mD',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mD',
    id => 'mD',
    name => 'millidarcies'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.008141E-16',
    C => 1,
    D => 0,
    annotation => 'mD.ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mD.ft',
    id => 'mDTft',
    name => 'millidarcy foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9.86932E-16',
    C => 1,
    D => 0,
    annotation => 'mD/Pa.s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mD/Pa.s',
    id => 'mDPPaTs',
    name => 'millidarcies/Pascal second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9.86932E-16',
    C => 0,
    D => '47.88026',
    annotation => 'mD.ft2/lbf.s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mD.ft2/lbf.s',
    id => 'mDTft2PlbfTs',
    name => 'millidarcy sq feet/pound force second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9.86932E-16',
    C => 0,
    D => '6894.757',
    annotation => 'mD.in2/lbf.s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mD.in2/lbf.s',
    id => 'mDTin2PlbfTs',
    name => 'millidarcy sq inches/pound force second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9.86932E-16',
    C => 1,
    D => 0,
    annotation => 'mD.m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mD.m',
    id => 'mDTm',
    name => 'millidarcy metres'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9.86932E-16',
    C => 0,
    D => '0.001',
    annotation => 'mD/cP',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mD/cP',
    id => 'mDPcP',
    name => 'millidarcies/centipoise'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'mEuc',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mEuc',
    id => 'mEuc',
    name => 'milliEuclid'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'meq',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'meq',
    id => 'meq',
    name => 'milliequivalent'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.0',
    C => 1,
    D => 0,
    annotation => 'meq/g',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'meq/g',
    id => 'meqPg',
    name => 'milliequivalents/ gram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '100.',
    C => 1,
    D => 0,
    annotation => 'meq/hg',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'meq/hg',
    id => 'meqPhg',
    name => 'milliequivalents/ hectogram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000.',
    C => 1,
    D => 0,
    annotation => 'meq/cm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'meq/cm3',
    id => 'meqPcm3',
    name => 'milliequivalents/ cubic centimeter'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.60219E-13',
    C => 1,
    D => 0,
    annotation => 'MeV',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MeV',
    id => 'MeV',
    name => 'millions of electron volts'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000',
    C => 1,
    D => 0,
    annotation => 'Mflops',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Mflops',
    id => 'Mflops',
    name => 'megaflops'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'Mg',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Mg',
    id => 'Mg',
    name => 'megagram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'mg',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mg',
    id => 'mg',
    name => 'milligram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 0,
    D => '31558150.',
    annotation => 'Mg/a',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Mg/a',
    id => 'MgPa',
    name => 'megagrams/year'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 0,
    D => '86400',
    annotation => 'Mg/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Mg/d',
    id => 'MgPd',
    name => 'megagrams/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'mg/dm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mg/dm3',
    id => 'mgPdm3',
    name => 'milligrams/cubic decimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000264172',
    C => 1,
    D => 0,
    annotation => 'mg/galUS',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mg/galUS',
    id => 'mgPgalUS',
    name => 'milligrams/US gallon'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '3.6',
    annotation => 'Mg/h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Mg/h',
    id => 'MgPh',
    name => 'megagrams/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'mg/J',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mg/J',
    id => 'mgPJ',
    name => 'milligrams/joule'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'mg/kg',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mg/kg',
    id => 'mgPkg',
    name => 'milligrams/kilogram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'Mg/m2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Mg/m2',
    id => 'MgPm2',
    name => 'megagrams/square metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'mg/m3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mg/m3',
    id => 'mgPm3',
    name => 'milligrams/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.00001',
    C => 1,
    D => 0,
    annotation => 'mGal',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mGal',
    id => 'mGal',
    name => 'milligal'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'mH',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mH',
    id => 'mH',
    name => 'millihenries'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'mho',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mho',
    id => 'mho',
    name => 'mhos'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'mho/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mho/m',
    id => 'mhoPm',
    name => 'mhos/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '6283185.307',
    C => 1,
    D => 0,
    annotation => 'MHz',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MHz',
    id => 'MHz',
    name => 'megahertz'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0000254',
    C => 1,
    D => 0,
    annotation => 'mil',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mil',
    id => 'mil',
    name => 'mil'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.1415926535898',
    C => 0,
    D => '3200',
    annotation => 'mila',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mila',
    id => 'mila',
    name => 'mil_6400'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0000254',
    C => 0,
    D => '31558150',
    annotation => 'mil/yr',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mil/yr',
    id => 'milPyr',
    name => 'mils/year'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '2589988',
    C => 1,
    D => 0,
    annotation => 'mi2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mi2',
    id => 'mi2',
    name => 'square miles'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '2589998',
    C => 1,
    D => 0,
    annotation => 'miUS2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'miUS2',
    id => 'miUS2',
    name => 'U.S. Survey square mile'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '63360',
    C => 1,
    D => 0,
    annotation => 'mi/in',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mi/in',
    id => 'miPin',
    name => 'miles/inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1609.344',
    C => 0,
    D => '0.004546092',
    annotation => 'mi/galUK',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mi/galUK',
    id => 'miPgalUK',
    name => 'miles/UK gallon'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1609.344',
    C => 0,
    D => '0.003785412',
    annotation => 'mi/galUS',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mi/galUS',
    id => 'miPgalUS',
    name => 'miles/US gallon'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1609.344',
    C => 0,
    D => '3600',
    annotation => 'mi/h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mi/h',
    id => 'miPh',
    name => 'miles/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.00029088821',
    C => 1,
    D => 0,
    annotation => 'mina',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mina',
    id => 'mina',
    name => 'minutes angular'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000',
    C => 1,
    D => 0,
    annotation => 'MJ',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MJ',
    id => 'MJ',
    name => 'megajoules'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000',
    C => 0,
    D => '31558150',
    annotation => 'MJ/a',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MJ/a',
    id => 'MJPa',
    name => 'megajoules/year'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '10',
    C => 1,
    D => 0,
    annotation => 'mJ/cm2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mJ/cm2',
    id => 'mJPcm2',
    name => 'millijoules/square centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000',
    C => 1,
    D => 0,
    annotation => 'MJ/kg',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MJ/kg',
    id => 'MJPkg',
    name => 'megajoules/kilogram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000',
    C => 1,
    D => 0,
    annotation => 'MJ/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MJ/m',
    id => 'MJPm',
    name => 'megajoules/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'mJ/m2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mJ/m2',
    id => 'mJPm2',
    name => 'millijoules/square metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000',
    C => 1,
    D => 0,
    annotation => 'MJ/m3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MJ/m3',
    id => 'MJPm3',
    name => 'megajoules/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000',
    C => 1,
    D => 0,
    annotation => 'MJ/mol(kg)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MJ/mol(kg)',
    id => 'MJPmol(kg)',
    name => 'megajoules/mole (kilogram)'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'mK/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mK/m',
    id => 'mKPm',
    name => 'millidegrees Kelvin/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'mL',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mL',
    id => 'mL',
    name => 'millilitre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0002199692',
    C => 1,
    D => 0,
    annotation => 'mL/galUK',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mL/galUK',
    id => 'mLPgalUK',
    name => 'millilitres/UK gallon'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000264172',
    C => 1,
    D => 0,
    annotation => 'mL/galUS',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mL/galUS',
    id => 'mLPgalUS',
    name => 'millilitres/US gallon'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'mm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mm',
    id => 'mm',
    name => 'millimetres'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 0,
    D => '31558150',
    annotation => 'mm/a',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mm/a',
    id => 'mmPa',
    name => 'millimetres/year'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'mm/mm.K',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mm/mm.K',
    id => 'mmPmmTK',
    name => 'millimetres/millimetre degree Kelvin'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'mm/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mm/s',
    id => 'mmPs',
    name => 'millimetres/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'mm2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mm2',
    id => 'mm2',
    name => 'square millimetres'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'mm2/mm2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mm2/mm2',
    id => 'mm2Pmm2',
    name => 'square millimetres/square millimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'mm2/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mm2/s',
    id => 'mm2Ps',
    name => 'square millimetres/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000000001',
    C => 1,
    D => 0,
    annotation => 'mm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mm3',
    id => 'mm3',
    name => 'cubic millimetres'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000000001',
    C => 1,
    D => 0,
    annotation => 'mm3/J',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mm3/J',
    id => 'mm3PJ',
    name => 'cubic millimetres/joule'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '158987.3',
    C => 1,
    D => 0,
    annotation => 'MMbbl',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MMbbl',
    id => 'MMbbl',
    name => 'million barrels'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '158987.3',
    C => 0,
    D => '1233.489',
    annotation => 'MMbbl/acre.ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MMbbl/acre.ft',
    id => 'MMbblPacreTft',
    name => 'million barrels/acre foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '133.3224',
    C => 1,
    D => 0,
    annotation => 'mmHg(0C)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mmHg(0C)',
    id => 'mmHg(0C)',
    name => 'millimetres of Mercury at 0 deg C'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'mmho/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mmho/m',
    id => 'mmhoPm',
    name => 'millimhos/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'mN',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mN',
    id => 'mN',
    name => 'millinewtons'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'mN.m2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mN.m2',
    id => 'mNTm2',
    name => 'millinewton metres squared'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'mN/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mN/m',
    id => 'mNPm',
    name => 'millinewtons/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'mN/km',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mN/km',
    id => 'mNPkm',
    name => 'millinewtons/kilometre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'mol(g)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mol(g)',
    id => 'mol(g)',
    name => 'mole (gram)'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'mol(kg)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mol(kg)',
    id => 'mol(kg)',
    name => 'mole (kilogram)'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '3600',
    annotation => 'mol(kg)/h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mol(kg)/h',
    id => 'mol(kg)Ph',
    name => 'moles (kilogram)/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'mol(kg)/m3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mol(kg)/m3',
    id => 'mol(kg)Pm3',
    name => 'moles (kilogram)/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'mol(kg)/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mol(kg)/s',
    id => 'mol(kg)Ps',
    name => 'moles (kilogram)/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.4535924',
    C => 1,
    D => 0,
    annotation => 'mol(lbm)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mol(lbm)',
    id => 'mol(lbm)',
    name => 'moles (pounds mass)'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '16.01846',
    C => 1,
    D => 0,
    annotation => 'mol(lbm)/ft3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mol(lbm)/ft3',
    id => 'mol(lbm)Pft3',
    name => 'moles (pounds mass)/cubic foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '99.77633',
    C => 1,
    D => 0,
    annotation => 'mol(lbm)/galUK',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mol(lbm)/galUK',
    id => 'mol(lbm)PgalUK',
    name => 'moles (pounds mass)/UK gallon'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '119.8264',
    C => 1,
    D => 0,
    annotation => 'mol(lbm)/galUS',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mol(lbm)/galUS',
    id => 'mol(lbm)PgalUS',
    name => 'moles (pounds mass)/US gallon'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.4535924',
    C => 0,
    D => '3600',
    annotation => 'mol(lbm)/h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mol(lbm)/h',
    id => 'mol(lbm)Ph',
    name => 'moles (pounds mass)/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.4535924',
    C => 1,
    D => 0,
    annotation => 'mol(lbm)/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mol(lbm)/s',
    id => 'mol(lbm)Ps',
    name => 'moles (pounds mass)/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.4535924',
    C => 0,
    D => '0.09290304',
    annotation => 'mol(lbm)/s.ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mol(lbm)/s.ft2',
    id => 'mol(lbm)PsTft2',
    name => 'moles (pounds mass)/second square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.4535924',
    C => 0,
    D => '334.450944',
    annotation => 'mol(lbm)/h.ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mol(lbm)/h.ft2',
    id => 'mol(lbm)PhTft2',
    name => 'moles (pounds mass)/hour square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.001',
    C => 1,
    D => 0,
    annotation => 'mohm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mohm',
    id => 'mohm',
    name => 'milliohm'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000',
    C => 1,
    D => 0,
    annotation => 'MPa',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MPa',
    id => 'MPa',
    name => 'megapascals'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '6894757000.',
    C => 1,
    D => 0,
    annotation => 'Mpsi',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Mpsi',
    id => 'Mpsi',
    name => 'mega pounds per square inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'ms',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ms',
    id => 'ms',
    name => 'milliseconds'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.001',
    C => 1,
    D => 0,
    annotation => 'mS',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mS',
    id => 'mS',
    name => 'millisiemen'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'mS/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mS/m',
    id => 'mSPm',
    name => 'millisiemens/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'ms/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ms/s',
    id => 'msPs',
    name => 'milliseconds/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1',
    C => 1,
    D => 0,
    annotation => 'ms/cm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ms/cm',
    id => 'msPcm',
    name => 'milliseconds/centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.',
    C => 0,
    D => '25.4',
    annotation => 'ms/in',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ms/in',
    id => 'msPin',
    name => 'milliseconds/inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000.',
    C => 1,
    D => 0,
    annotation => 'Msm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Msm3',
    id => 'Msm3',
    name => 'mega standard cubic metres 15C'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'mT',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mT',
    id => 'mT',
    name => 'milliteslas'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'mV',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mV',
    id => 'mV',
    name => 'millivolts'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.001',
    C => 1,
    D => 0,
    annotation => 'mW',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mW',
    id => 'mW',
    name => 'milliwatt'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000',
    C => 1,
    D => 0,
    annotation => 'MW',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MW',
    id => 'MW',
    name => 'megawatts'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3600000000.',
    C => 1,
    D => 0,
    annotation => 'MW.h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MW.h',
    id => 'MWTh',
    name => 'megawatt hours'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3600000000.',
    C => 1,
    D => 0,
    annotation => 'MW.h/kg',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MW.h/kg',
    id => 'MWThPkg',
    name => 'megawatt hours/kilogram'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3600000000.',
    C => 1,
    D => 0,
    annotation => 'MW.h/m3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MW.h/m3',
    id => 'MWThPm3',
    name => 'megawatt hours/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'mW/m2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mW/m2',
    id => 'mWPm2',
    name => 'milliwatts/square metres'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'mWb',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'mWb',
    id => 'mWb',
    name => 'milliwebers'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '31558150000000.',
    C => 1,
    D => 0,
    annotation => 'MY',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MY',
    id => 'MY',
    name => 'megayears'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000',
    C => 1,
    D => 0,
    annotation => 'N/mm2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'N/mm2',
    id => 'NPmm2',
    name => 'newtons/square millimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1852',
    C => 1,
    D => 0,
    annotation => 'nautmi',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'nautmi',
    id => 'nautmi',
    name => 'nautical mile'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000000001',
    C => 1,
    D => 0,
    annotation => 'nC',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'nC',
    id => 'nC',
    name => 'nanocoulomb'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000000001',
    C => 1,
    D => 0,
    annotation => 'nEuc',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'nEuc',
    id => 'nEuc',
    name => 'nanoeuclid'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000000001',
    C => 1,
    D => 0,
    annotation => 'nm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'nm',
    id => 'nm',
    name => 'nanometres'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000000001',
    C => 1,
    D => 0,
    annotation => 'ns',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ns',
    id => 'ns',
    name => 'nanoseconds'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000000001',
    C => 1,
    D => 0,
    annotation => 'ns/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ns/m',
    id => 'nsPm',
    name => 'nanoseconds/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000000001',
    C => 0,
    D => '0.3048',
    annotation => 'ns/ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ns/ft',
    id => 'nsPft',
    name => 'nanoseconds/foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000000001',
    C => 1,
    D => 0,
    annotation => 'nW',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'nW',
    id => 'nW',
    name => 'nanowatts'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'N/m2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'N/m2',
    id => 'NPm2',
    name => 'newtons/square metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'N.m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'N.m',
    id => 'NTm',
    name => 'newton metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'N.m/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'N.m/m',
    id => 'NTmPm',
    name => 'newton metres/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'N.s/m2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'N.s/m2',
    id => 'NTsPm2',
    name => 'newton seconds/metre squared'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => '(N/m)4/kg.m3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => '(N/m)4/kg.m3',
    id => '(NPm)4PkgTm3',
    name => 'newton/metre fourth/kilogram metre cubed'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '79.57747',
    C => 1,
    D => 0,
    annotation => 'Oe',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Oe',
    id => 'Oe',
    name => 'oersted'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.01',
    C => 1,
    D => 0,
    annotation => 'ohm.cm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ohm.cm',
    id => 'ohmTcm',
    name => 'ohm centimetres'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.02834952',
    C => 1,
    D => 0,
    annotation => 'oz(av)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'oz(av)',
    id => 'oz(av)',
    name => 'avoirdupois ounces'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.03110348',
    C => 1,
    D => 0,
    annotation => 'oz(troy)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'oz(troy)',
    id => 'oz(troy)',
    name => 'troy ounces'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.1',
    C => 1,
    D => 0,
    annotation => 'P',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'P',
    id => 'P',
    name => 'poise'
  }, 'Petrophysics::Units' ),
  bless( {
    A => '101325',
    B => '1',
    C => '1',
    D => 0,
    annotation => 'Pa(g)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Pa(g)',
    id => 'Pa(g)',
    name => 'pascal gauge'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'Pa.s2/m3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Pa.s2/m3',
    id => 'PaTs2Pm3',
    name => 'pascal seconds squared/ cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.E-12',
    C => 1,
    D => 0,
    annotation => 'pC',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'pC',
    id => 'pC',
    name => 'picocoulomb'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.138255',
    C => 1,
    D => 0,
    annotation => 'pdl',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'pdl',
    id => 'pdl',
    name => 'poundals'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0000138255',
    C => 1,
    D => 0,
    annotation => 'pdl.cm2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'pdl.cm2',
    id => 'pdlTcm2',
    name => 'poundal centimetre squared'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.04214012',
    C => 1,
    D => 0,
    annotation => 'pdl.ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'pdl.ft',
    id => 'pdlTft',
    name => 'foot poundal'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.138255',
    C => 0,
    D => '0.01',
    annotation => 'pdl/cm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'pdl/cm',
    id => 'pdlPcm',
    name => 'poundals/centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.001',
    C => 1,
    D => 0,
    annotation => 'permil',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'permil',
    id => 'permil',
    name => 'per mille'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.E-12',
    C => 1,
    D => 0,
    annotation => 'pPa',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'pPa',
    id => 'pPa',
    name => 'picopascal'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.001',
    C => 1,
    D => 0,
    annotation => 'ppk',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ppk',
    id => 'ppk',
    name => 'parts per thousand'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '47.88026',
    C => 1,
    D => 0,
    annotation => 'psf',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'psf',
    id => 'psf',
    name => 'pounds/square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '6894.757',
    C => 1,
    D => 0,
    annotation => 'psi',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'psi',
    id => 'psi',
    name => 'pounds/square inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '23.05916',
    annotation => 'psi.d/bbl',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'psi.d/bbl',
    id => 'psiTdPbbl',
    name => 'pounds per square inch days/barrel'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4107255041294',
    C => 0,
    D => '.000028316847',
    annotation => 'psi2.d/cp.ft3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'psi2.d/cp.ft3',
    id => 'psi2TdPcpTft3',
    name => 'psi squared days/ centipoise cubic foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '354866983550000000.',
    C => 0,
    D => '.0000008018438',
    annotation => 'psi2.d2/cp.ft6',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'psi2.d2/cp.ft6',
    id => 'psi2Td2PcpTft6',
    name => '(psi days/cubic foot)squared/centipoise'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '6894.757',
    C => 0,
    D => '0.3048',
    annotation => 'psi/ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'psi/ft',
    id => 'psiPft',
    name => 'pounds/square inch per foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '6894.757',
    C => 0,
    D => '0.003048',
    annotation => 'psi/ft(100)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'psi/ft(100)',
    id => 'psiPft(100)',
    name => 'pounds/square inch per 100 feet'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '6894.757',
    C => 1,
    D => 0,
    annotation => 'psia',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'psia',
    id => 'psia',
    name => 'pounds/square inch absolute'
  }, 'Petrophysics::Units' ),
  bless( {
    A => '101325',
    B => '6894.757',
    C => '1',
    D => 0,
    annotation => 'psig',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'psig',
    id => 'psig',
    name => 'pounds/square inch gauge'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '4753764090.',
    C => 1,
    D => 0,
    annotation => 'psi2/cP',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'psi2/cP',
    id => 'psi2PcP',
    name => 'pounds/square inch squared/ centipoise'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '2.116809E-10',
    C => 1,
    D => 0,
    annotation => 'ptUK/hp.hr',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ptUK/hp.hr',
    id => 'ptUKPhpThr',
    name => 'UK pints/horsepower hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000003574253',
    C => 1,
    D => 0,
    annotation => 'ptUK/Mbbl',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ptUK/Mbbl',
    id => 'ptUKPMbbl',
    name => 'UK pints/1000 barrels'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0004731765',
    C => 1,
    D => 0,
    annotation => 'ptUS',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ptUS',
    id => 'ptUS',
    name => 'US pints'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001136523',
    C => 1,
    D => 0,
    annotation => 'qtUK',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'qtUK',
    id => 'qtUK',
    name => 'UK quarts'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.0009463529',
    C => 1,
    D => 0,
    annotation => 'qtUS',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'qtUS',
    id => 'qtUS',
    name => 'US quarts'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.055056E+18',
    C => 1,
    D => 0,
    annotation => 'quad',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'quad',
    id => 'quad',
    name => 'quads'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.055056E+18',
    C => 0,
    D => '31558150',
    annotation => 'quad/yr',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'quad/yr',
    id => 'quadPyr',
    name => 'quads/year'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.01',
    C => 1,
    D => 0,
    annotation => 'rd',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'rd',
    id => 'rd',
    name => 'rad'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '6.283185307',
    C => 0,
    D => '60',
    annotation => 'rev/min',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'rev/min',
    id => 'revPmin',
    name => 'revolutions/minute'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '6.283185307',
    C => 1,
    D => 0,
    annotation => 'rev/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'rev/s',
    id => 'revPs',
    name => 'revolutions/second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '6.283185307',
    C => 0,
    D => '60',
    annotation => 'rpm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'rpm',
    id => 'rpm',
    name => 'revolutions/minute'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '6.283185307',
    C => 0,
    D => '60',
    annotation => 'rpm/s',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'rpm/s',
    id => 'rpmPs',
    name => 'revolutions/minute per second'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '100',
    C => 1,
    D => 0,
    annotation => 's/cm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 's/cm',
    id => 'sPcm',
    name => 'seconds/centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '0.3048',
    annotation => 's/ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 's/ft',
    id => 'sPft',
    name => 'seconds/foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 0,
    D => '0.0254',
    annotation => 's/in',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 's/in',
    id => 'sPin',
    name => 'seconds/inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '42.63769',
    C => 1,
    D => 0,
    annotation => 'sack94',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'sack94',
    id => 'sack94',
    name => 'sacks'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.028262357',
    C => 1,
    D => 0,
    annotation => 'scf(60F)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'scf(60F)',
    id => 'scf(60F)',
    name => 'std cubic feet at 60 deg F'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.',
    C => 1,
    D => 0,
    annotation => 'sm3/sm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'sm3/sm3',
    id => 'sm3Psm3',
    name => 'std cubic metres/ std cubic metres'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.',
    C => 0,
    D => '1000.',
    annotation => 'sm3/ksm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'sm3/ksm3',
    id => 'sm3Pksm3',
    name => 'std cubic metres/ 1000 std cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '28.31685',
    C => 1,
    D => 0,
    annotation => 'Mcf',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Mcf',
    id => 'Mcf',
    name => 'thousand cubic feet'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '28316.85',
    C => 1,
    D => 0,
    annotation => 'MMcf',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MMcf',
    id => 'MMcf',
    name => 'million cubic feet'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '28316850.',
    C => 1,
    D => 0,
    annotation => 'bcf',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bcf',
    id => 'bcf',
    name => 'billion cubic feet'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '28316850000.',
    C => 1,
    D => 0,
    annotation => 'tcf',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tcf',
    id => 'tcf',
    name => 'trillion cubic feet'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.',
    C => 0,
    D => '86400',
    annotation => 'scm(15C)/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'scm(15C)/d',
    id => 'scm(15C)Pd',
    name => 'std cubic metres at 15 deg C/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '28.262357',
    C => 1,
    D => 0,
    annotation => 'Mscf(60F)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Mscf(60F)',
    id => 'Mscf(60F)',
    name => 'thousand cubic feet at 60 deg F'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '28262.357',
    C => 1,
    D => 0,
    annotation => 'MMscf(60F)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MMscf(60F)',
    id => 'MMscf(60F)',
    name => 'million standard cubic feet at 60 deg F'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.',
    C => 0,
    D => '0.1589873',
    annotation => 'scm15/stb60',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'scm15/stb60',
    id => 'scm15Pstb60',
    name => 'std cubic metres / stock tank barrel'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.028262357',
    C => 0,
    D => '0.09290304',
    annotation => 'scf(60F)/ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'scf(60F)/ft2',
    id => 'scf(60F)Pft2',
    name => 'std cubic feet at 60 deg F/square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.9980757',
    C => 1,
    D => 0,
    annotation => 'scf(60F)/ft3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'scf(60F)/ft3',
    id => 'scf(60F)Pft3',
    name => 'std cubic feet at 60 deg Ft/cubic foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.028262357',
    C => 0,
    D => '0.1589873',
    annotation => 'scf(60F)/bbl',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'scf(60F)/bbl',
    id => 'scf(60F)Pbbl',
    name => 'std cubic feet at 60 deg F/barrel'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000.',
    C => 0,
    D => '86400',
    annotation => 'Mscm(15C)/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Mscm(15C)/d',
    id => 'Mscm(15C)Pd',
    name => 'thousand std cubic metres, 15 degC/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000.',
    C => 0,
    D => '86400',
    annotation => 'MMscm(15C)/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MMscm(15C)/d',
    id => 'MMscm(15C)Pd',
    name => 'million std cubic metres, 15 degC/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.028262357',
    C => 0,
    D => '86400',
    annotation => 'scf(60F)/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'scf(60F)/d',
    id => 'scf(60F)Pd',
    name => 'standard cubic feet/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '28.262357',
    C => 0,
    D => '86400',
    annotation => 'Mscf(60F)/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Mscf(60F)/d',
    id => 'Mscf(60F)Pd',
    name => 'thousand standard cubic feet/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '28262.357',
    C => 0,
    D => '86400',
    annotation => 'MMscf(60F)/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MMscf(60F)/d',
    id => 'MMscf(60F)Pd',
    name => 'million standard cubic feet/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '28.262357',
    C => 0,
    D => '0.1589873',
    annotation => 'Mscf60/stb60',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Mscf60/stb60',
    id => 'Mscf60Pstb60',
    name => 'thousand std cu ft/ stock tank barrel'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '282623.57',
    C => 0,
    D => '0.1589873',
    annotation => 'MMscf60/stb60',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MMscf60/stb60',
    id => 'MMscf60Pstb60',
    name => 'million std cu ft/ stock tank barrel'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1589873',
    C => 1,
    D => 0,
    annotation => 'stb(60F)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'stb(60F)',
    id => 'stb(60F)',
    name => 'stock tank barrel at 60 deg F'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '158.9873',
    C => 1,
    D => 0,
    annotation => 'Mstb(60F)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Mstb(60F)',
    id => 'Mstb(60F)',
    name => 'thousand stock tank barrels 60 F'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '158987.3',
    C => 1,
    D => 0,
    annotation => 'MMstb(60F)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MMstb(60F)',
    id => 'MMstb(60F)',
    name => 'million stock tank barrels 60 deg F'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1589873',
    C => 0,
    D => '4046.873',
    annotation => 'stb(60F)/acre',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'stb(60F)/acre',
    id => 'stb(60F)Pacre',
    name => 'stock tank barrels, 60 deg F/acre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1589873',
    C => 0,
    D => '86400.',
    annotation => 'stb(60F)/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'stb(60F)/d',
    id => 'stb(60F)Pd',
    name => 'stock tank barrels, 60 deg F/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '158.9873',
    C => 0,
    D => '86400.',
    annotation => 'Mstb(60F)/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Mstb(60F)/d',
    id => 'Mstb(60F)Pd',
    name => 'thousand stock tank barrels,60 deg F/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '158987.3',
    C => 0,
    D => '86400.',
    annotation => 'MMstb(60F)/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MMstb(60F)/d',
    id => 'MMstb(60F)Pd',
    name => 'million stock tank barrels, 60 deg F/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1589873',
    C => 1,
    D => 0,
    annotation => 'stb60/scm15',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'stb60/scm15',
    id => 'stb60Pscm15',
    name => 'stock tank barrels/ std cu metres'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1589873',
    C => 0,
    D => '1000.',
    annotation => 'stb60/Mscm15',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'stb60/Mscm15',
    id => 'stb60PMscm15',
    name => 'stock tank barrels/ 1000 std cu metres'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1589873',
    C => 0,
    D => '1000000.',
    annotation => 'stb60/MMscm15',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'stb60/MMscm15',
    id => 'stb60PMMscm15',
    name => 'stock tank barrels/ million std cu mts'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1589873',
    C => 0,
    D => '28.262357',
    annotation => 'stb60/Mscf60',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'stb60/Mscf60',
    id => 'stb60PMscf60',
    name => 'stock tank barrels/ 1000 std cu ft'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1589873',
    C => 0,
    D => '28262.357',
    annotation => 'stb60/MMscf60',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'stb60/MMscf60',
    id => 'stb60PMMscf60',
    name => 'stock tank barrels/ million std cu ft'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '158987.3',
    C => 0,
    D => '4046.873',
    annotation => 'MMstb/acre',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MMstb/acre',
    id => 'MMstbPacre',
    name => 'million stock tank barrels 60 deg F/acre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'stb(60F)/bbl',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'stb(60F)/bbl',
    id => 'stb(60F)Pbbl',
    name => 'stock tank barrels, 60 deg F/barrel'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '158987.3',
    C => 0,
    D => '1233.489',
    annotation => 'MMstb/acre.ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'MMstb/acre.ft',
    id => 'MMstbPacreTft',
    name => 'million stbs, 60 deg F/acre foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'bbl/stb(60F)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'bbl/stb(60F)',
    id => 'bblPstb(60F)',
    name => 'barrels/stock tank barrel, 60 deg F'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1233.489',
    C => 0,
    D => '158987.3',
    annotation => 'acre.ft/MMstb',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'acre.ft/MMstb',
    id => 'acreTftPMMstb',
    name => 'acre feet/million stbs, 60 deg F'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.00000484814',
    C => 1,
    D => 0,
    annotation => 'seca',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'seca',
    id => 'seca',
    name => 'seconds angular'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '2589998',
    C => 1,
    D => 0,
    annotation => 'section',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'section',
    id => 'section',
    name => 'section'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.1',
    C => 1,
    D => 0,
    annotation => 'sigma',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'sigma',
    id => 'sigma',
    name => 'capture unit'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.09290304',
    C => 1,
    D => 0,
    annotation => 'sq ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'sq ft',
    id => 'sq_ft',
    name => 'square feet'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.00064516',
    C => 1,
    D => 0,
    annotation => 'sq in',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'sq in',
    id => 'sq_in',
    name => 'square inches'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '2589988',
    C => 1,
    D => 0,
    annotation => 'sq mi',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'sq mi',
    id => 'sq_mi',
    name => 'square miles'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.8361274',
    C => 1,
    D => 0,
    annotation => 'sq yd',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'sq yd',
    id => 'sq_yd',
    name => 'square yards'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 't',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 't',
    id => 't',
    name => 'tonne'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 0,
    D => '31558150',
    annotation => 't/a',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 't/a',
    id => 'tPa',
    name => 'tonnes/year'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 0,
    D => '86400',
    annotation => 't/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 't/d',
    id => 'tPd',
    name => 'tonnes/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 0,
    D => '3600',
    annotation => 't/h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 't/h',
    id => 'tPh',
    name => 'tonnes/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'talbot',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'talbot',
    id => 'talbot',
    name => 'talbot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '105505600',
    C => 1,
    D => 0,
    annotation => 'therm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'therm',
    id => 'therm',
    name => 'therms'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '105505600.',
    C => 0,
    D => '0.02831685',
    annotation => 'therm/ft3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'therm/ft3',
    id => 'thermPft3',
    name => 'therms/cubic foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '23208000000.',
    C => 1,
    D => 0,
    annotation => 'therm/galUK',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'therm/galUK',
    id => 'thermPgalUK',
    name => 'therms/UK gallon'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '105505600.',
    C => 0,
    D => '0.4535924',
    annotation => 'therm/lbm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'therm/lbm',
    id => 'thermPlbm',
    name => 'therms/pound mass'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000000000.',
    C => 1,
    D => 0,
    annotation => 'TJ',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'TJ',
    id => 'TJ',
    name => 'terajoules'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000000000.',
    C => 0,
    D => '31558150',
    annotation => 'TJ/a',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'TJ/a',
    id => 'TJPa',
    name => 'terajoules/year'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3516.853',
    C => 1,
    D => 0,
    annotation => 'ton of refrig',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ton of refrig',
    id => 'ton_of_refrig',
    name => 'tons of refrigeration'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9964.016',
    C => 1,
    D => 0,
    annotation => 'tonfUK',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonfUK',
    id => 'tonfUK',
    name => 'UK tons force'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '925.6874',
    C => 1,
    D => 0,
    annotation => 'tonfUK.ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonfUK.ft2',
    id => 'tonfUKTft2',
    name => 'UK ton feet squared'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9964.016',
    C => 0,
    D => '0.3048',
    annotation => 'tonfUK/ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonfUK/ft',
    id => 'tonfUKPft',
    name => 'UK tons force/foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '8896.443',
    C => 1,
    D => 0,
    annotation => 'tonfUS',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonfUS',
    id => 'tonfUS',
    name => 'US tons force'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '2711.636',
    C => 1,
    D => 0,
    annotation => 'tonfUS.ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonfUS.ft',
    id => 'tonfUSTft',
    name => 'US tons force feet'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '826.5067',
    C => 1,
    D => 0,
    annotation => 'tonfUS.ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonfUS.ft2',
    id => 'tonfUSTft2',
    name => 'US tons force feet squared'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '14317440',
    C => 1,
    D => 0,
    annotation => 'tonfUS.mi',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonfUS.mi',
    id => 'tonfUSTmi',
    name => 'US tons force/mile'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '14317440',
    C => 0,
    D => '0.1589873',
    annotation => 'tonfUS.mi/bbl',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonfUS.mi/bbl',
    id => 'tonfUSTmiPbbl',
    name => 'US ton force miles/barrel'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '14317440',
    C => 0,
    D => '0.3048',
    annotation => 'tonfUS.mi/ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonfUS.mi/ft',
    id => 'tonfUSTmiPft',
    name => 'US tons force miles/foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '8896.443',
    C => 0,
    D => '0.3048',
    annotation => 'tonfUS/ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonfUS/ft',
    id => 'tonfUSPft',
    name => 'US tons force/foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '95760.52',
    C => 1,
    D => 0,
    annotation => 'tonfUS/ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonfUS/ft2',
    id => 'tonfUSPft2',
    name => 'US tons force/square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '13789510',
    C => 1,
    D => 0,
    annotation => 'tonfUS/in2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonfUS/in2',
    id => 'tonfUSPin2',
    name => 'US tons force/square inch'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1016.047',
    C => 1,
    D => 0,
    annotation => 'tonUK',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonUK',
    id => 'tonUK',
    name => 'UK tons'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1016.047',
    C => 0,
    D => '86400',
    annotation => 'tonUK/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonUK/d',
    id => 'tonUKPd',
    name => 'UK tons/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1016.047',
    C => 0,
    D => '3600',
    annotation => 'tonUK/h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonUK/h',
    id => 'tonUKPh',
    name => 'UK tons/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1016.047',
    C => 0,
    D => '60',
    annotation => 'tonUK/min',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonUK/min',
    id => 'tonUKPmin',
    name => 'UK tons/minute'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1016.047',
    C => 0,
    D => '31558150',
    annotation => 'tonUK/a',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonUK/a',
    id => 'tonUKPa',
    name => 'UK tons/year'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '907.1847',
    C => 1,
    D => 0,
    annotation => 'tonUS',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonUS',
    id => 'tonUS',
    name => 'US tons'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '907.1847',
    C => 0,
    D => '86400',
    annotation => 'tonUS/d',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonUS/d',
    id => 'tonUSPd',
    name => 'US tons/day'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '9764.855',
    C => 1,
    D => 0,
    annotation => 'tonUS/ft2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonUS/ft2',
    id => 'tonUSPft2',
    name => 'US tons/square foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '907.1847',
    C => 0,
    D => '3600',
    annotation => 'tonUS/h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonUS/h',
    id => 'tonUSPh',
    name => 'US tons/hour'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '907.1847',
    C => 0,
    D => '60',
    annotation => 'tonUS/min',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonUS/min',
    id => 'tonUSPmin',
    name => 'US tons/minute'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '907.1847',
    C => 0,
    D => '31558150',
    annotation => 'tonUS/a',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'tonUS/a',
    id => 'tonUSPa',
    name => 'US tons/year'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '133.3224',
    C => 1,
    D => 0,
    annotation => 'torr',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'torr',
    id => 'torr',
    name => 'torr'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000000000000.',
    C => 1,
    D => 0,
    annotation => 'TW',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'TW',
    id => 'TW',
    name => 'terawatts'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3.60E+15',
    C => 1,
    D => 0,
    annotation => 'TW.h',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'TW.h',
    id => 'TWTh',
    name => 'terrawatt hours'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.000001',
    C => 1,
    D => 0,
    annotation => 'uA',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'uA',
    id => 'uA',
    name => 'microampere'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1',
    C => 1,
    D => 0,
    annotation => 'ubar',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ubar',
    id => 'ubar',
    name => 'microbars'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.000001',
    C => 1,
    D => 0,
    annotation => 'uC',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'uC',
    id => 'uC',
    name => 'microcoulomb'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.04184',
    C => 1,
    D => 0,
    annotation => 'ucal/s.cm2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ucal/s.cm2',
    id => 'ucalPsTcm2',
    name => 'microcalories/second square centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'uEuc',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'uEuc',
    id => 'uEuc',
    name => 'microEuclids'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'uF',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'uF',
    id => 'uF',
    name => 'microfarads'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'uF/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'uF/m',
    id => 'uFPm',
    name => 'microfarads/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.00E-09',
    C => 1,
    D => 0,
    annotation => 'ug',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ug',
    id => 'ug',
    name => 'micrograms'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1.00E-03',
    C => 1,
    D => 0,
    annotation => 'ug/cm3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ug/cm3',
    id => 'ugPcm3',
    name => 'micrograms/cubic centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'uH/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'uH/m',
    id => 'uHPm',
    name => 'microhenries/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'um',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'um',
    id => 'um',
    name => 'microns'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000000000001',
    C => 1,
    D => 0,
    annotation => 'um2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'um2',
    id => 'um2',
    name => 'square microns'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000000000001',
    C => 1,
    D => 0,
    annotation => 'um2.m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'um2.m',
    id => 'um2Tm',
    name => 'square micron metres'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.1333224',
    C => 1,
    D => 0,
    annotation => 'umHg(0C)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'umHg(0C)',
    id => 'umHg(0C)',
    name => 'microns of Mercury at 0 deg C'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'unitless',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'unitless',
    id => 'unitless',
    name => 'unitless'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.000001',
    C => 1,
    D => 0,
    annotation => 'uohm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'uohm',
    id => 'uohm',
    name => 'microohm'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '.000001',
    C => 1,
    D => 0,
    annotation => 'uPa',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'uPa',
    id => 'uPa',
    name => 'micropascal'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'us',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'us',
    id => 'us',
    name => 'microsecond'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 0,
    D => '0.3048',
    annotation => 'us/ft',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'us/ft',
    id => 'usPft',
    name => 'microseconds/foot'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'us/m',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'us/m',
    id => 'usPm',
    name => 'microseconds/metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'uV',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'uV',
    id => 'uV',
    name => 'microvolts'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'uW/m3',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'uW/m3',
    id => 'uWPm3',
    name => 'microwatts/cubic metre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '10',
    C => 1,
    D => 0,
    annotation => 'V/dB',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'V/dB',
    id => 'VPdB',
    name => 'volts/decibel'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.01',
    C => 1,
    D => 0,
    annotation => 'volpercent',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'volpercent',
    id => 'volpercent',
    name => 'volume percent'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'volppm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'volppm',
    id => 'volppm',
    name => 'volume parts per million'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '10000',
    C => 1,
    D => 0,
    annotation => 'W/cm2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'W/cm2',
    id => 'WPcm2',
    name => 'watts/square centimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1',
    C => 1,
    D => 0,
    annotation => 'W/W',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'W/W',
    id => 'WPW',
    name => 'watts/watt'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.001',
    C => 1,
    D => 0,
    annotation => 'W/kW',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'W/kW',
    id => 'WPkW',
    name => 'watts/kilowatt'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '1000',
    C => 1,
    D => 0,
    annotation => 'Wb/mm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'Wb/mm',
    id => 'WbPmm',
    name => 'webers/millimetre'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '604800',
    C => 1,
    D => 0,
    annotation => 'wk',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'wk',
    id => 'wk',
    name => 'weeks'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.01',
    C => 1,
    D => 0,
    annotation => 'wtpercent',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'wtpercent',
    id => 'wtpercent',
    name => 'weight percent'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.000001',
    C => 1,
    D => 0,
    annotation => 'wtppm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'wtppm',
    id => 'wtppm',
    name => 'weight parts per million'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.9144',
    C => 1,
    D => 0,
    annotation => 'yd',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'yd',
    id => 'yd',
    name => 'yards'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.914391795',
    C => 1,
    D => 0,
    annotation => 'ydIm',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ydIm',
    id => 'ydIm',
    name => 'imperial yard'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.91439523',
    C => 1,
    D => 0,
    annotation => 'ydInd(37)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ydInd(37)',
    id => 'ydInd(37)',
    name => 'Indian yard (1937)'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.9143988',
    C => 1,
    D => 0,
    annotation => 'ydInd(62)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ydInd(62)',
    id => 'ydInd(62)',
    name => 'Indian yard (1962)'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.9143985',
    C => 1,
    D => 0,
    annotation => 'ydInd(75)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'ydInd(75)',
    id => 'ydInd(75)',
    name => 'Indian yard (1975)'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '0.83612736',
    C => 1,
    D => 0,
    annotation => 'yd2',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'yd2',
    id => 'yd2',
    name => 'square yards'
  }, 'Petrophysics::Units' ),
  bless( {
    A => 0,
    B => '3155815000000.',
    C => 1,
    D => 0,
    annotation => 'yr(100k)',
    base_unit => {},
    catalog_name => 'POSC',
    catalog_symbol => 'yr(100k)',
    id => 'yr(100k)',
    name => '100000 years'
  }, 'Petrophysics::Units' )
);
$objects[3]{base_unit} = $objects[0];
$objects[4]{base_unit} = $objects[0];
$objects[5]{base_unit} = $objects[0];
$objects[6]{base_unit} = $objects[0];
$objects[7]{base_unit} = $objects[0];
$objects[8]{base_unit} = $objects[0];
$objects[9]{base_unit} = $objects[0];
$objects[10]{base_unit} = $objects[0];
$objects[11]{base_unit} = $objects[0];
$objects[12]{base_unit} = $objects[0];
$objects[13]{base_unit} = $objects[0];
$objects[14]{base_unit} = $objects[0];
$objects[15]{base_unit} = $objects[0];
$objects[16]{base_unit} = $objects[0];
$objects[17]{base_unit} = $objects[0];
$objects[18]{base_unit} = $objects[0];
$objects[19]{base_unit} = $objects[0];
$objects[20]{base_unit} = $objects[0];
$objects[21]{base_unit} = $objects[0];
$objects[22]{base_unit} = $objects[0];
$objects[23]{base_unit} = $objects[0];
$objects[24]{base_unit} = $objects[0];
$objects[25]{base_unit} = $objects[0];
$objects[26]{base_unit} = $objects[0];
$objects[27]{base_unit} = $objects[0];
$objects[28]{base_unit} = $objects[0];
$objects[29]{base_unit} = $objects[0];
$objects[30]{base_unit} = $objects[0];
$objects[31]{base_unit} = $objects[0];
$objects[32]{base_unit} = $objects[0];
$objects[33]{base_unit} = $objects[0];
$objects[34]{base_unit} = $objects[0];
$objects[35]{base_unit} = $objects[0];
$objects[36]{base_unit} = $objects[0];
$objects[37]{base_unit} = $objects[0];
$objects[38]{base_unit} = $objects[0];
$objects[39]{base_unit} = $objects[1];
$objects[40]{base_unit} = $objects[1];
$objects[41]{base_unit} = $objects[1];
$objects[42]{base_unit} = $objects[1];
$objects[43]{base_unit} = $objects[1];
$objects[44]{base_unit} = $objects[1];
$objects[45]{base_unit} = $objects[1];
$objects[46]{base_unit} = $objects[1];
$objects[47]{base_unit} = $objects[1];
$objects[48]{base_unit} = $objects[2];
$objects[179]{base_unit} = $objects[63];
$objects[180]{base_unit} = $objects[71];
$objects[181]{base_unit} = $objects[67];
$objects[182]{base_unit} = $objects[71];
$objects[183]{base_unit} = $objects[67];
$objects[184]{base_unit} = $objects[67];
$objects[185]{base_unit} = $objects[66];
$objects[186]{base_unit} = $objects[66];
$objects[187]{base_unit} = $objects[66];
$objects[188]{base_unit} = $objects[68];
$objects[189]{base_unit} = $objects[68];
$objects[190]{base_unit} = $objects[68];
$objects[191]{base_unit} = $objects[65];
$objects[192]{base_unit} = $objects[71];
$objects[193]{base_unit} = $objects[67];
$objects[194]{base_unit} = $objects[67];
$objects[195]{base_unit} = $objects[71];
$objects[196]{base_unit} = $objects[67];
$objects[197]{base_unit} = $objects[67];
$objects[198]{base_unit} = $objects[67];
$objects[199]{base_unit} = $objects[70];
$objects[200]{base_unit} = $objects[70];
$objects[201]{base_unit} = $objects[72];
$objects[202]{base_unit} = $objects[71];
$objects[203]{base_unit} = $objects[50];
$objects[204]{base_unit} = $objects[80];
$objects[205]{base_unit} = $objects[74];
$objects[206]{base_unit} = $objects[75];
$objects[207]{base_unit} = $objects[116];
$objects[208]{base_unit} = $objects[121];
$objects[209]{base_unit} = $objects[0];
$objects[210]{base_unit} = $objects[144];
$objects[211]{base_unit} = $objects[144];
$objects[212]{base_unit} = $objects[149];
$objects[213]{base_unit} = $objects[57];
$objects[214]{base_unit} = $objects[144];
$objects[215]{base_unit} = $objects[116];
$objects[216]{base_unit} = $objects[67];
$objects[217]{base_unit} = $objects[118];
$objects[218]{base_unit} = $objects[121];
$objects[219]{base_unit} = $objects[0];
$objects[220]{base_unit} = $objects[63];
$objects[221]{base_unit} = $objects[63];
$objects[222]{base_unit} = $objects[126];
$objects[223]{base_unit} = $objects[127];
$objects[224]{base_unit} = $objects[128];
$objects[225]{base_unit} = $objects[120];
$objects[226]{base_unit} = $objects[71];
$objects[227]{base_unit} = $objects[125];
$objects[228]{base_unit} = $objects[119];
$objects[229]{base_unit} = $objects[116];
$objects[230]{base_unit} = $objects[127];
$objects[231]{base_unit} = $objects[128];
$objects[232]{base_unit} = $objects[116];
$objects[233]{base_unit} = $objects[116];
$objects[234]{base_unit} = $objects[130];
$objects[235]{base_unit} = $objects[123];
$objects[236]{base_unit} = $objects[123];
$objects[237]{base_unit} = $objects[90];
$objects[238]{base_unit} = $objects[168];
$objects[239]{base_unit} = $objects[169];
$objects[240]{base_unit} = $objects[93];
$objects[241]{base_unit} = $objects[63];
$objects[242]{base_unit} = $objects[93];
$objects[243]{base_unit} = $objects[93];
$objects[244]{base_unit} = $objects[93];
$objects[245]{base_unit} = $objects[168];
$objects[246]{base_unit} = $objects[169];
$objects[247]{base_unit} = $objects[170];
$objects[248]{base_unit} = $objects[171];
$objects[249]{base_unit} = $objects[171];
$objects[250]{base_unit} = $objects[173];
$objects[251]{base_unit} = $objects[174];
$objects[252]{base_unit} = $objects[171];
$objects[253]{base_unit} = $objects[91];
$objects[254]{base_unit} = $objects[92];
$objects[255]{base_unit} = $objects[92];
$objects[256]{base_unit} = $objects[168];
$objects[257]{base_unit} = $objects[94];
$objects[258]{base_unit} = $objects[95];
$objects[259]{base_unit} = $objects[168];
$objects[260]{base_unit} = $objects[170];
$objects[261]{base_unit} = $objects[171];
$objects[262]{base_unit} = $objects[173];
$objects[263]{base_unit} = $objects[174];
$objects[264]{base_unit} = $objects[82];
$objects[265]{base_unit} = $objects[82];
$objects[266]{base_unit} = $objects[83];
$objects[267]{base_unit} = $objects[90];
$objects[268]{base_unit} = $objects[93];
$objects[269]{base_unit} = $objects[93];
$objects[270]{base_unit} = $objects[91];
$objects[271]{base_unit} = $objects[92];
$objects[272]{base_unit} = $objects[170];
$objects[273]{base_unit} = $objects[169];
$objects[274]{base_unit} = $objects[171];
$objects[275]{base_unit} = $objects[173];
$objects[276]{base_unit} = $objects[91];
$objects[277]{base_unit} = $objects[91];
$objects[278]{base_unit} = $objects[93];
$objects[279]{base_unit} = $objects[95];
$objects[280]{base_unit} = $objects[169];
$objects[281]{base_unit} = $objects[171];
$objects[282]{base_unit} = $objects[173];
$objects[283]{base_unit} = $objects[63];
$objects[284]{base_unit} = $objects[1];
$objects[285]{base_unit} = $objects[1];
$objects[286]{base_unit} = $objects[168];
$objects[287]{base_unit} = $objects[90];
$objects[288]{base_unit} = $objects[90];
$objects[289]{base_unit} = $objects[0];
$objects[290]{base_unit} = $objects[67];
$objects[291]{base_unit} = $objects[114];
$objects[292]{base_unit} = $objects[115];
$objects[293]{base_unit} = $objects[116];
$objects[294]{base_unit} = $objects[117];
$objects[295]{base_unit} = $objects[120];
$objects[296]{base_unit} = $objects[121];
$objects[297]{base_unit} = $objects[123];
$objects[298]{base_unit} = $objects[63];
$objects[299]{base_unit} = $objects[131];
$objects[300]{base_unit} = $objects[144];
$objects[301]{base_unit} = $objects[146];
$objects[302]{base_unit} = $objects[120];
$objects[303]{base_unit} = $objects[121];
$objects[304]{base_unit} = $objects[121];
$objects[305]{base_unit} = $objects[121];
$objects[306]{base_unit} = $objects[121];
$objects[307]{base_unit} = $objects[79];
$objects[308]{base_unit} = $objects[168];
$objects[309]{base_unit} = $objects[90];
$objects[310]{base_unit} = $objects[49];
$objects[311]{base_unit} = $objects[49];
$objects[312]{base_unit} = $objects[1];
$objects[313]{base_unit} = $objects[153];
$objects[314]{base_unit} = $objects[50];
$objects[315]{base_unit} = $objects[158];
$objects[316]{base_unit} = $objects[158];
$objects[317]{base_unit} = $objects[116];
$objects[318]{base_unit} = $objects[121];
$objects[319]{base_unit} = $objects[121];
$objects[320]{base_unit} = $objects[56];
$objects[321]{base_unit} = $objects[76];
$objects[322]{base_unit} = $objects[76];
$objects[323]{base_unit} = $objects[77];
$objects[324]{base_unit} = $objects[52];
$objects[325]{base_unit} = $objects[52];
$objects[326]{base_unit} = $objects[52];
$objects[327]{base_unit} = $objects[52];
$objects[328]{base_unit} = $objects[1];
$objects[329]{base_unit} = $objects[152];
$objects[330]{base_unit} = $objects[152];
$objects[331]{base_unit} = $objects[152];
$objects[332]{base_unit} = $objects[152];
$objects[333]{base_unit} = $objects[153];
$objects[334]{base_unit} = $objects[105];
$objects[335]{base_unit} = $objects[52];
$objects[336]{base_unit} = $objects[97];
$objects[337]{base_unit} = $objects[97];
$objects[338]{base_unit} = $objects[96];
$objects[339]{base_unit} = $objects[52];
$objects[340]{base_unit} = $objects[96];
$objects[341]{base_unit} = $objects[97];
$objects[342]{base_unit} = $objects[97];
$objects[343]{base_unit} = $objects[52];
$objects[344]{base_unit} = $objects[0];
$objects[345]{base_unit} = $objects[121];
$objects[346]{base_unit} = $objects[123];
$objects[347]{base_unit} = $objects[116];
$objects[348]{base_unit} = $objects[122];
$objects[349]{base_unit} = $objects[116];
$objects[350]{base_unit} = $objects[63];
$objects[351]{base_unit} = $objects[122];
$objects[352]{base_unit} = $objects[124];
$objects[353]{base_unit} = $objects[127];
$objects[354]{base_unit} = $objects[128];
$objects[355]{base_unit} = $objects[123];
$objects[356]{base_unit} = $objects[137];
$objects[357]{base_unit} = $objects[138];
$objects[358]{base_unit} = $objects[146];
$objects[359]{base_unit} = $objects[139];
$objects[360]{base_unit} = $objects[144];
$objects[361]{base_unit} = $objects[141];
$objects[362]{base_unit} = $objects[90];
$objects[363]{base_unit} = $objects[168];
$objects[364]{base_unit} = $objects[63];
$objects[365]{base_unit} = $objects[65];
$objects[366]{base_unit} = $objects[69];
$objects[367]{base_unit} = $objects[69];
$objects[368]{base_unit} = $objects[90];
$objects[369]{base_unit} = $objects[168];
$objects[370]{base_unit} = $objects[139];
$objects[371]{base_unit} = $objects[93];
$objects[372]{base_unit} = $objects[91];
$objects[373]{base_unit} = $objects[91];
$objects[374]{base_unit} = $objects[93];
$objects[375]{base_unit} = $objects[90];
$objects[376]{base_unit} = $objects[80];
$objects[377]{base_unit} = $objects[121];
$objects[378]{base_unit} = $objects[121];
$objects[379]{base_unit} = $objects[63];
$objects[380]{base_unit} = $objects[111];
$objects[381]{base_unit} = $objects[112];
$objects[382]{base_unit} = $objects[90];
$objects[383]{base_unit} = $objects[93];
$objects[384]{base_unit} = $objects[93];
$objects[385]{base_unit} = $objects[91];
$objects[386]{base_unit} = $objects[168];
$objects[387]{base_unit} = $objects[168];
$objects[388]{base_unit} = $objects[68];
$objects[389]{base_unit} = $objects[114];
$objects[390]{base_unit} = $objects[113];
$objects[391]{base_unit} = $objects[68];
$objects[392]{base_unit} = $objects[68];
$objects[393]{base_unit} = $objects[114];
$objects[394]{base_unit} = $objects[63];
$objects[395]{base_unit} = $objects[63];
$objects[396]{base_unit} = $objects[63];
$objects[397]{base_unit} = $objects[114];
$objects[398]{base_unit} = $objects[114];
$objects[399]{base_unit} = $objects[115];
$objects[400]{base_unit} = $objects[116];
$objects[401]{base_unit} = $objects[120];
$objects[402]{base_unit} = $objects[67];
$objects[403]{base_unit} = $objects[120];
$objects[404]{base_unit} = $objects[121];
$objects[405]{base_unit} = $objects[63];
$objects[406]{base_unit} = $objects[127];
$objects[407]{base_unit} = $objects[119];
$objects[408]{base_unit} = $objects[128];
$objects[409]{base_unit} = $objects[116];
$objects[410]{base_unit} = $objects[63];
$objects[411]{base_unit} = $objects[127];
$objects[412]{base_unit} = $objects[128];
$objects[413]{base_unit} = $objects[123];
$objects[414]{base_unit} = $objects[127];
$objects[415]{base_unit} = $objects[128];
$objects[416]{base_unit} = $objects[114];
$objects[417]{base_unit} = $objects[124];
$objects[418]{base_unit} = $objects[127];
$objects[419]{base_unit} = $objects[128];
$objects[420]{base_unit} = $objects[114];
$objects[421]{base_unit} = $objects[130];
$objects[422]{base_unit} = $objects[53];
$objects[423]{base_unit} = $objects[0];
$objects[424]{base_unit} = $objects[0];
$objects[425]{base_unit} = $objects[0];
$objects[426]{base_unit} = $objects[0];
$objects[427]{base_unit} = $objects[0];
$objects[428]{base_unit} = $objects[1];
$objects[429]{base_unit} = $objects[49];
$objects[430]{base_unit} = $objects[104];
$objects[431]{base_unit} = $objects[105];
$objects[432]{base_unit} = $objects[106];
$objects[433]{base_unit} = $objects[105];
$objects[434]{base_unit} = $objects[105];
$objects[435]{base_unit} = $objects[105];
$objects[436]{base_unit} = $objects[63];
$objects[437]{base_unit} = $objects[105];
$objects[438]{base_unit} = $objects[105];
$objects[439]{base_unit} = $objects[107];
$objects[440]{base_unit} = $objects[50];
$objects[441]{base_unit} = $objects[115];
$objects[442]{base_unit} = $objects[121];
$objects[443]{base_unit} = $objects[63];
$objects[444]{base_unit} = $objects[127];
$objects[445]{base_unit} = $objects[128];
$objects[446]{base_unit} = $objects[120];
$objects[447]{base_unit} = $objects[114];
$objects[448]{base_unit} = $objects[120];
$objects[449]{base_unit} = $objects[114];
$objects[450]{base_unit} = $objects[123];
$objects[451]{base_unit} = $objects[63];
$objects[452]{base_unit} = $objects[116];
$objects[453]{base_unit} = $objects[127];
$objects[454]{base_unit} = $objects[128];
$objects[455]{base_unit} = $objects[120];
$objects[456]{base_unit} = $objects[114];
$objects[457]{base_unit} = $objects[121];
$objects[458]{base_unit} = $objects[116];
$objects[459]{base_unit} = $objects[63];
$objects[460]{base_unit} = $objects[127];
$objects[461]{base_unit} = $objects[128];
$objects[462]{base_unit} = $objects[120];
$objects[463]{base_unit} = $objects[114];
$objects[464]{base_unit} = $objects[120];
$objects[465]{base_unit} = $objects[114];
$objects[466]{base_unit} = $objects[130];
$objects[467]{base_unit} = $objects[123];
$objects[468]{base_unit} = $objects[63];
$objects[469]{base_unit} = $objects[116];
$objects[470]{base_unit} = $objects[127];
$objects[471]{base_unit} = $objects[128];
$objects[472]{base_unit} = $objects[120];
$objects[473]{base_unit} = $objects[114];
$objects[474]{base_unit} = $objects[123];
$objects[475]{base_unit} = $objects[123];
$objects[476]{base_unit} = $objects[123];
$objects[477]{base_unit} = $objects[74];
$objects[478]{base_unit} = $objects[164];
$objects[479]{base_unit} = $objects[90];
$objects[480]{base_unit} = $objects[115];
$objects[481]{base_unit} = $objects[144];
$objects[482]{base_unit} = $objects[49];
$objects[483]{base_unit} = $objects[105];
$objects[484]{base_unit} = $objects[105];
$objects[485]{base_unit} = $objects[105];
$objects[486]{base_unit} = $objects[60];
$objects[487]{base_unit} = $objects[168];
$objects[488]{base_unit} = $objects[90];
$objects[489]{base_unit} = $objects[50];
$objects[490]{base_unit} = $objects[158];
$objects[491]{base_unit} = $objects[116];
$objects[492]{base_unit} = $objects[121];
$objects[493]{base_unit} = $objects[168];
$objects[494]{base_unit} = $objects[168];
$objects[495]{base_unit} = $objects[168];
$objects[496]{base_unit} = $objects[90];
$objects[497]{base_unit} = $objects[93];
$objects[498]{base_unit} = $objects[91];
$objects[499]{base_unit} = $objects[173];
$objects[500]{base_unit} = $objects[153];
$objects[501]{base_unit} = $objects[0];
$objects[502]{base_unit} = $objects[66];
$objects[503]{base_unit} = $objects[114];
$objects[504]{base_unit} = $objects[114];
$objects[505]{base_unit} = $objects[114];
$objects[506]{base_unit} = $objects[116];
$objects[507]{base_unit} = $objects[63];
$objects[508]{base_unit} = $objects[63];
$objects[509]{base_unit} = $objects[120];
$objects[510]{base_unit} = $objects[121];
$objects[511]{base_unit} = $objects[131];
$objects[512]{base_unit} = $objects[144];
$objects[513]{base_unit} = $objects[144];
$objects[514]{base_unit} = $objects[144];
$objects[515]{base_unit} = $objects[144];
$objects[516]{base_unit} = $objects[139];
$objects[517]{base_unit} = $objects[93];
$objects[518]{base_unit} = $objects[91];
$objects[519]{base_unit} = $objects[92];
$objects[520]{base_unit} = $objects[137];
$objects[521]{base_unit} = $objects[139];
$objects[522]{base_unit} = $objects[171];
$objects[523]{base_unit} = $objects[96];
$objects[524]{base_unit} = $objects[57];
$objects[525]{base_unit} = $objects[80];
$objects[526]{base_unit} = $objects[90];
$objects[527]{base_unit} = $objects[137];
$objects[528]{base_unit} = $objects[93];
$objects[529]{base_unit} = $objects[91];
$objects[530]{base_unit} = $objects[168];
$objects[531]{base_unit} = $objects[169];
$objects[532]{base_unit} = $objects[171];
$objects[533]{base_unit} = $objects[91];
$objects[534]{base_unit} = $objects[92];
$objects[535]{base_unit} = $objects[93];
$objects[536]{base_unit} = $objects[94];
$objects[537]{base_unit} = $objects[90];
$objects[538]{base_unit} = $objects[105];
$objects[539]{base_unit} = $objects[106];
$objects[540]{base_unit} = $objects[101];
$objects[541]{base_unit} = $objects[107];
$objects[542]{base_unit} = $objects[63];
$objects[543]{base_unit} = $objects[100];
$objects[544]{base_unit} = $objects[100];
$objects[545]{base_unit} = $objects[137];
$objects[546]{base_unit} = $objects[90];
$objects[547]{base_unit} = $objects[138];
$objects[548]{base_unit} = $objects[139];
$objects[549]{base_unit} = $objects[137];
$objects[550]{base_unit} = $objects[146];
$objects[551]{base_unit} = $objects[139];
$objects[552]{base_unit} = $objects[144];
$objects[553]{base_unit} = $objects[153];
$objects[554]{base_unit} = $objects[90];
$objects[555]{base_unit} = $objects[169];
$objects[556]{base_unit} = $objects[93];
$objects[557]{base_unit} = $objects[171];
$objects[558]{base_unit} = $objects[91];
$objects[559]{base_unit} = $objects[92];
$objects[560]{base_unit} = $objects[93];
$objects[561]{base_unit} = $objects[94];
$objects[562]{base_unit} = $objects[95];
$objects[563]{base_unit} = $objects[63];
$objects[564]{base_unit} = $objects[68];
$objects[565]{base_unit} = $objects[114];
$objects[566]{base_unit} = $objects[68];
$objects[567]{base_unit} = $objects[116];
$objects[568]{base_unit} = $objects[121];
$objects[569]{base_unit} = $objects[137];
$objects[570]{base_unit} = $objects[90];
$objects[571]{base_unit} = $objects[138];
$objects[572]{base_unit} = $objects[139];
$objects[573]{base_unit} = $objects[114];
$objects[574]{base_unit} = $objects[144];
$objects[575]{base_unit} = $objects[104];
$objects[576]{base_unit} = $objects[149];
$objects[577]{base_unit} = $objects[60];
$objects[578]{base_unit} = $objects[63];
$objects[579]{base_unit} = $objects[163];
$objects[580]{base_unit} = $objects[165];
$objects[581]{base_unit} = $objects[168];
$objects[582]{base_unit} = $objects[90];
$objects[583]{base_unit} = $objects[93];
$objects[584]{base_unit} = $objects[91];
$objects[585]{base_unit} = $objects[92];
$objects[586]{base_unit} = $objects[93];
$objects[587]{base_unit} = $objects[170];
$objects[588]{base_unit} = $objects[171];
$objects[589]{base_unit} = $objects[173];
$objects[590]{base_unit} = $objects[174];
$objects[591]{base_unit} = $objects[121];
$objects[592]{base_unit} = $objects[116];
$objects[593]{base_unit} = $objects[116];
$objects[594]{base_unit} = $objects[63];
$objects[595]{base_unit} = $objects[124];
$objects[596]{base_unit} = $objects[124];
$objects[597]{base_unit} = $objects[127];
$objects[598]{base_unit} = $objects[128];
$objects[599]{base_unit} = $objects[123];
$objects[600]{base_unit} = $objects[137];
$objects[601]{base_unit} = $objects[90];
$objects[602]{base_unit} = $objects[93];
$objects[603]{base_unit} = $objects[137];
$objects[604]{base_unit} = $objects[139];
$objects[605]{base_unit} = $objects[91];
$objects[606]{base_unit} = $objects[90];
$objects[607]{base_unit} = $objects[138];
$objects[608]{base_unit} = $objects[137];
$objects[609]{base_unit} = $objects[139];
$objects[610]{base_unit} = $objects[146];
$objects[611]{base_unit} = $objects[146];
$objects[612]{base_unit} = $objects[144];
$objects[613]{base_unit} = $objects[144];
$objects[614]{base_unit} = $objects[140];
$objects[615]{base_unit} = $objects[144];
$objects[616]{base_unit} = $objects[140];
$objects[617]{base_unit} = $objects[49];
$objects[618]{base_unit} = $objects[107];
$objects[619]{base_unit} = $objects[98];
$objects[620]{base_unit} = $objects[99];
$objects[621]{base_unit} = $objects[90];
$objects[622]{base_unit} = $objects[104];
$objects[623]{base_unit} = $objects[105];
$objects[624]{base_unit} = $objects[101];
$objects[625]{base_unit} = $objects[146];
$objects[626]{base_unit} = $objects[146];
$objects[627]{base_unit} = $objects[103];
$objects[628]{base_unit} = $objects[105];
$objects[629]{base_unit} = $objects[106];
$objects[630]{base_unit} = $objects[105];
$objects[631]{base_unit} = $objects[105];
$objects[632]{base_unit} = $objects[106];
$objects[633]{base_unit} = $objects[105];
$objects[634]{base_unit} = $objects[105];
$objects[635]{base_unit} = $objects[106];
$objects[636]{base_unit} = $objects[100];
$objects[637]{base_unit} = $objects[107];
$objects[638]{base_unit} = $objects[146];
$objects[639]{base_unit} = $objects[104];
$objects[640]{base_unit} = $objects[105];
$objects[641]{base_unit} = $objects[107];
$objects[642]{base_unit} = $objects[107];
$objects[643]{base_unit} = $objects[146];
$objects[644]{base_unit} = $objects[111];
$objects[645]{base_unit} = $objects[0];
$objects[646]{base_unit} = $objects[114];
$objects[647]{base_unit} = $objects[114];
$objects[648]{base_unit} = $objects[63];
$objects[649]{base_unit} = $objects[63];
$objects[650]{base_unit} = $objects[63];
$objects[651]{base_unit} = $objects[66];
$objects[652]{base_unit} = $objects[68];
$objects[653]{base_unit} = $objects[114];
$objects[654]{base_unit} = $objects[67];
$objects[655]{base_unit} = $objects[119];
$objects[656]{base_unit} = $objects[117];
$objects[657]{base_unit} = $objects[120];
$objects[658]{base_unit} = $objects[63];
$objects[659]{base_unit} = $objects[67];
$objects[660]{base_unit} = $objects[53];
$objects[661]{base_unit} = $objects[53];
$objects[662]{base_unit} = $objects[126];
$objects[663]{base_unit} = $objects[126];
$objects[664]{base_unit} = $objects[127];
$objects[665]{base_unit} = $objects[128];
$objects[666]{base_unit} = $objects[125];
$objects[667]{base_unit} = $objects[123];
$objects[668]{base_unit} = $objects[127];
$objects[669]{base_unit} = $objects[63];
$objects[670]{base_unit} = $objects[116];
$objects[671]{base_unit} = $objects[122];
$objects[672]{base_unit} = $objects[116];
$objects[673]{base_unit} = $objects[63];
$objects[674]{base_unit} = $objects[124];
$objects[675]{base_unit} = $objects[120];
$objects[676]{base_unit} = $objects[114];
$objects[677]{base_unit} = $objects[123];
$objects[678]{base_unit} = $objects[51];
$objects[679]{base_unit} = $objects[50];
$objects[680]{base_unit} = $objects[121];
$objects[681]{base_unit} = $objects[127];
$objects[682]{base_unit} = $objects[132];
$objects[683]{base_unit} = $objects[57];
$objects[684]{base_unit} = $objects[80];
$objects[685]{base_unit} = $objects[82];
$objects[686]{base_unit} = $objects[116];
$objects[687]{base_unit} = $objects[121];
$objects[688]{base_unit} = $objects[119];
$objects[689]{base_unit} = $objects[119];
$objects[690]{base_unit} = $objects[119];
$objects[691]{base_unit} = $objects[121];
$objects[692]{base_unit} = $objects[119];
$objects[693]{base_unit} = $objects[63];
$objects[694]{base_unit} = $objects[63];
$objects[695]{base_unit} = $objects[65];
$objects[696]{base_unit} = $objects[65];
$objects[697]{base_unit} = $objects[69];
$objects[698]{base_unit} = $objects[90];
$objects[699]{base_unit} = $objects[63];
$objects[700]{base_unit} = $objects[49];
$objects[701]{base_unit} = $objects[49];
$objects[702]{base_unit} = $objects[107];
$objects[703]{base_unit} = $objects[107];
$objects[704]{base_unit} = $objects[105];
$objects[705]{base_unit} = $objects[105];
$objects[706]{base_unit} = $objects[107];
$objects[707]{base_unit} = $objects[100];
$objects[708]{base_unit} = $objects[63];
$objects[709]{base_unit} = $objects[103];
$objects[710]{base_unit} = $objects[105];
$objects[711]{base_unit} = $objects[115];
$objects[712]{base_unit} = $objects[88];
$objects[713]{base_unit} = $objects[155];
$objects[714]{base_unit} = $objects[156];
$objects[715]{base_unit} = $objects[153];
$objects[716]{base_unit} = $objects[0];
$objects[717]{base_unit} = $objects[1];
$objects[718]{base_unit} = $objects[114];
$objects[719]{base_unit} = $objects[116];
$objects[720]{base_unit} = $objects[116];
$objects[721]{base_unit} = $objects[63];
$objects[722]{base_unit} = $objects[68];
$objects[723]{base_unit} = $objects[68];
$objects[724]{base_unit} = $objects[114];
$objects[725]{base_unit} = $objects[1];
$objects[726]{base_unit} = $objects[90];
$objects[727]{base_unit} = $objects[168];
$objects[728]{base_unit} = $objects[139];
$objects[729]{base_unit} = $objects[91];
$objects[730]{base_unit} = $objects[137];
$objects[731]{base_unit} = $objects[139];
$objects[732]{base_unit} = $objects[93];
$objects[733]{base_unit} = $objects[94];
$objects[734]{base_unit} = $objects[97];
$objects[735]{base_unit} = $objects[121];
$objects[736]{base_unit} = $objects[63];
$objects[737]{base_unit} = $objects[63];
$objects[738]{base_unit} = $objects[0];
$objects[739]{base_unit} = $objects[114];
$objects[740]{base_unit} = $objects[66];
$objects[741]{base_unit} = $objects[114];
$objects[742]{base_unit} = $objects[116];
$objects[743]{base_unit} = $objects[63];
$objects[744]{base_unit} = $objects[120];
$objects[745]{base_unit} = $objects[121];
$objects[746]{base_unit} = $objects[122];
$objects[747]{base_unit} = $objects[121];
$objects[748]{base_unit} = $objects[63];
$objects[749]{base_unit} = $objects[144];
$objects[750]{base_unit} = $objects[156];
$objects[751]{base_unit} = $objects[137];
$objects[752]{base_unit} = $objects[138];
$objects[753]{base_unit} = $objects[139];
$objects[754]{base_unit} = $objects[139];
$objects[755]{base_unit} = $objects[53];
$objects[756]{base_unit} = $objects[53];
$objects[757]{base_unit} = $objects[136];
$objects[758]{base_unit} = $objects[135];
$objects[759]{base_unit} = $objects[136];
$objects[760]{base_unit} = $objects[53];
$objects[761]{base_unit} = $objects[135];
$objects[762]{base_unit} = $objects[135];
$objects[763]{base_unit} = $objects[135];
$objects[764]{base_unit} = $objects[136];
$objects[765]{base_unit} = $objects[136];
$objects[766]{base_unit} = $objects[134];
$objects[767]{base_unit} = $objects[134];
$objects[768]{base_unit} = $objects[142];
$objects[769]{base_unit} = $objects[144];
$objects[770]{base_unit} = $objects[144];
$objects[771]{base_unit} = $objects[50];
$objects[772]{base_unit} = $objects[155];
$objects[773]{base_unit} = $objects[156];
$objects[774]{base_unit} = $objects[63];
$objects[775]{base_unit} = $objects[157];
$objects[776]{base_unit} = $objects[157];
$objects[777]{base_unit} = $objects[60];
$objects[778]{base_unit} = $objects[164];
$objects[779]{base_unit} = $objects[165];
$objects[780]{base_unit} = $objects[168];
$objects[781]{base_unit} = $objects[168];
$objects[782]{base_unit} = $objects[90];
$objects[783]{base_unit} = $objects[91];
$objects[784]{base_unit} = $objects[93];
$objects[785]{base_unit} = $objects[170];
$objects[786]{base_unit} = $objects[176];
$objects[787]{base_unit} = $objects[50];
$objects[788]{base_unit} = $objects[144];
$objects[789]{base_unit} = $objects[0];
$objects[790]{base_unit} = $objects[80];
$objects[791]{base_unit} = $objects[63];
$objects[792]{base_unit} = $objects[0];
$objects[793]{base_unit} = $objects[50];
$objects[794]{base_unit} = $objects[157];
$objects[795]{base_unit} = $objects[157];
$objects[796]{base_unit} = $objects[168];
$objects[797]{base_unit} = $objects[144];
$objects[798]{base_unit} = $objects[90];
$objects[799]{base_unit} = $objects[137];
$objects[800]{base_unit} = $objects[146];
$objects[801]{base_unit} = $objects[141];
$objects[802]{base_unit} = $objects[74];
$objects[803]{base_unit} = $objects[143];
$objects[804]{base_unit} = $objects[49];
$objects[805]{base_unit} = $objects[49];
$objects[806]{base_unit} = $objects[146];
$objects[807]{base_unit} = $objects[144];
$objects[808]{base_unit} = $objects[106];
$objects[809]{base_unit} = $objects[80];
$objects[810]{base_unit} = $objects[137];
$objects[811]{base_unit} = $objects[138];
$objects[812]{base_unit} = $objects[90];
$objects[813]{base_unit} = $objects[139];
$objects[814]{base_unit} = $objects[63];
$objects[815]{base_unit} = $objects[144];
$objects[816]{base_unit} = $objects[63];
$objects[817]{base_unit} = $objects[144];
$objects[818]{base_unit} = $objects[144];
$objects[819]{base_unit} = $objects[147];
$objects[820]{base_unit} = $objects[150];
$objects[821]{base_unit} = $objects[148];
$objects[822]{base_unit} = $objects[149];
$objects[823]{base_unit} = $objects[149];
$objects[824]{base_unit} = $objects[144];
$objects[825]{base_unit} = $objects[144];
$objects[826]{base_unit} = $objects[151];
$objects[827]{base_unit} = $objects[122];
$objects[828]{base_unit} = $objects[63];
$objects[829]{base_unit} = $objects[121];
$objects[830]{base_unit} = $objects[121];
$objects[831]{base_unit} = $objects[121];
$objects[832]{base_unit} = $objects[90];
$objects[833]{base_unit} = $objects[168];
$objects[834]{base_unit} = $objects[87];
$objects[835]{base_unit} = $objects[153];
$objects[836]{base_unit} = $objects[153];
$objects[837]{base_unit} = $objects[153];
$objects[838]{base_unit} = $objects[154];
$objects[839]{base_unit} = $objects[157];
$objects[840]{base_unit} = $objects[157];
$objects[841]{base_unit} = $objects[157];
$objects[842]{base_unit} = $objects[49];
$objects[843]{base_unit} = $objects[60];
$objects[844]{base_unit} = $objects[63];
$objects[845]{base_unit} = $objects[63];
$objects[846]{base_unit} = $objects[121];
$objects[847]{base_unit} = $objects[121];
$objects[848]{base_unit} = $objects[121];
$objects[849]{base_unit} = $objects[121];
$objects[850]{base_unit} = $objects[163];
$objects[851]{base_unit} = $objects[60];
$objects[852]{base_unit} = $objects[60];
$objects[853]{base_unit} = $objects[63];
$objects[854]{base_unit} = $objects[161];
$objects[855]{base_unit} = $objects[162];
$objects[856]{base_unit} = $objects[162];
$objects[857]{base_unit} = $objects[163];
$objects[858]{base_unit} = $objects[163];
$objects[859]{base_unit} = $objects[163];
$objects[860]{base_unit} = $objects[163];
$objects[861]{base_unit} = $objects[163];
$objects[862]{base_unit} = $objects[63];
$objects[863]{base_unit} = $objects[63];
$objects[864]{base_unit} = $objects[60];
$objects[865]{base_unit} = $objects[60];
$objects[866]{base_unit} = $objects[60];
$objects[867]{base_unit} = $objects[161];
$objects[868]{base_unit} = $objects[163];
$objects[869]{base_unit} = $objects[163];
$objects[870]{base_unit} = $objects[163];
$objects[871]{base_unit} = $objects[63];
$objects[872]{base_unit} = $objects[63];
$objects[873]{base_unit} = $objects[63];
$objects[874]{base_unit} = $objects[63];
$objects[875]{base_unit} = $objects[63];
$objects[876]{base_unit} = $objects[161];
$objects[877]{base_unit} = $objects[162];
$objects[878]{base_unit} = $objects[162];
$objects[879]{base_unit} = $objects[130];
$objects[880]{base_unit} = $objects[130];
$objects[881]{base_unit} = $objects[1];
$objects[882]{base_unit} = $objects[116];
$objects[883]{base_unit} = $objects[67];
$objects[884]{base_unit} = $objects[116];
$objects[885]{base_unit} = $objects[116];
$objects[886]{base_unit} = $objects[116];
$objects[887]{base_unit} = $objects[116];
$objects[888]{base_unit} = $objects[49];
$objects[889]{base_unit} = $objects[107];
$objects[890]{base_unit} = $objects[107];
$objects[891]{base_unit} = $objects[107];
$objects[892]{base_unit} = $objects[109];
$objects[893]{base_unit} = $objects[90];
$objects[894]{base_unit} = $objects[93];
$objects[895]{base_unit} = $objects[93];
$objects[896]{base_unit} = $objects[91];
$objects[897]{base_unit} = $objects[90];
$objects[898]{base_unit} = $objects[168];
$objects[899]{base_unit} = $objects[168];
$objects[900]{base_unit} = $objects[137];
$objects[901]{base_unit} = $objects[138];
$objects[902]{base_unit} = $objects[139];
$objects[903]{base_unit} = $objects[137];
$objects[904]{base_unit} = $objects[90];
$objects[905]{base_unit} = $objects[138];
$objects[906]{base_unit} = $objects[90];
$objects[907]{base_unit} = $objects[93];
$objects[908]{base_unit} = $objects[137];
$objects[909]{base_unit} = $objects[139];
$objects[910]{base_unit} = $objects[144];
$objects[911]{base_unit} = $objects[144];
$objects[912]{base_unit} = $objects[49];
$objects[913]{base_unit} = $objects[107];
$objects[914]{base_unit} = $objects[107];
$objects[915]{base_unit} = $objects[107];
$objects[916]{base_unit} = $objects[107];
$objects[917]{base_unit} = $objects[49];
$objects[918]{base_unit} = $objects[107];
$objects[919]{base_unit} = $objects[103];
$objects[920]{base_unit} = $objects[107];
$objects[921]{base_unit} = $objects[107];
$objects[922]{base_unit} = $objects[107];
$objects[923]{base_unit} = $objects[144];
$objects[924]{base_unit} = $objects[168];
$objects[925]{base_unit} = $objects[90];
$objects[926]{base_unit} = $objects[51];
$objects[927]{base_unit} = $objects[144];
$objects[928]{base_unit} = $objects[80];
$objects[929]{base_unit} = $objects[170];
$objects[930]{base_unit} = $objects[63];
$objects[931]{base_unit} = $objects[85];
$objects[932]{base_unit} = $objects[86];
$objects[933]{base_unit} = $objects[49];
$objects[934]{base_unit} = $objects[105];
$objects[935]{base_unit} = $objects[89];
$objects[936]{base_unit} = $objects[0];
$objects[937]{base_unit} = $objects[116];
$objects[938]{base_unit} = $objects[121];
$objects[939]{base_unit} = $objects[144];
$objects[940]{base_unit} = $objects[63];
$objects[941]{base_unit} = $objects[142];
$objects[942]{base_unit} = $objects[144];
$objects[943]{base_unit} = $objects[50];
$objects[944]{base_unit} = $objects[157];
$objects[945]{base_unit} = $objects[157];
$objects[946]{base_unit} = $objects[165];
$objects[947]{base_unit} = $objects[173];
$objects[948]{base_unit} = $objects[166];
$objects[949]{base_unit} = $objects[63];
$objects[950]{base_unit} = $objects[63];
$objects[951]{base_unit} = $objects[170];
$objects[952]{base_unit} = $objects[63];
$objects[953]{base_unit} = $objects[63];
$objects[954]{base_unit} = $objects[178];
$objects[955]{base_unit} = $objects[50];
$objects[956]{base_unit} = $objects[63];
$objects[957]{base_unit} = $objects[63];
$objects[958]{base_unit} = $objects[0];
$objects[959]{base_unit} = $objects[0];
$objects[960]{base_unit} = $objects[0];
$objects[961]{base_unit} = $objects[0];
$objects[962]{base_unit} = $objects[0];
$objects[963]{base_unit} = $objects[116];
$objects[964]{base_unit} = $objects[50];
