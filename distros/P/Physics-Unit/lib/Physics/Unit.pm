package Physics::Unit;

use strict;
use warnings;
use Carp;
use base qw(Exporter);
use vars qw(
    $VERSION
    @EXPORT_OK
    %EXPORT_TAGS
    $debug
    $number_re
);

$VERSION = '0.54';
$VERSION = eval $VERSION;

@EXPORT_OK = qw(
    $number_re
    GetTypeUnit
    GetUnit
    InitBaseUnit
    InitPrefix
    InitTypes
    InitUnit
    ListTypes
    ListUnits
    NumBases
    DeleteNames
);

%EXPORT_TAGS = ('ALL' => \@EXPORT_OK);

# This is the regular expression used to parse out a number.  It
# is here so that other modules can use it for convenience.

$number_re = '([-+]?((\d+\.?\d*)|(\.\d+))([eE][-+]?((\d+\.?\d*)|(\.\d+)))?)';

# The value of this hash is a string representing the token returned
# when this word is seen

my %reserved_word = (
    per     => 'divide',
    square  => 'square',
    sq      => 'square',
    cubic   => 'cubic',
    squared => 'squared',
    cubed   => 'cubed',
);

# Pre-defined units
my %unit_by_name;

# Values are references to units representing the prefix
my %prefix;

# Known quantity types.  The values of this hash are references to
# unit objects that exemplify these types
my %prototype;

# The number of base units
my $NumBases = 0;

# The names of the base units
my @BaseName;

InitBaseUnit (
    'Distance'    => ['meter', 'm', 'meters', 'metre', 'metres'],
    'Mass'        => ['gram', 'gm', 'grams'],
    'Time'        => ['second', 's', 'sec', 'secs', 'seconds'],
    'Temperature' => ['kelvin', 'k', 'kelvins',
                      'degree-kelvin', 'degrees-kelvin', 'degree-kelvins'],
    'Current'     => ['ampere', 'amp', 'amps', 'amperes'],
    'Substance'   => ['mole', 'mol', 'moles'],
    'Luminosity'  => ['candela', 'cd', 'candelas', 'candle', 'candles'],
    'Money'       => ['us-dollar', 'dollar', 'dollars', 'us-dollars', '$'],
    'Data'        => ['bit', 'bits'],
);

InitPrefix (
    'deka',    1e1,
    'deca',    1e1,
    'hecto',   1e2,
    'kilo',    1e3,
    'mega',    1e6,
    'giga',    1e9,
    'tera',    1e12,
    'peta',    1e15,
    'exa',     1e18,
    'zetta',   1e21,
    'yotta',   1e24,
    'deci',    1e-1,
    'centi',   1e-2,
    'milli',   1e-3,
    'micro',   1e-6,
    'nano',    1e-9,
    'pico',    1e-12,
    'femto',   1e-15,
    'atto',    1e-18,
    'zepto',   1e-21,
    'yocto',   1e-24,

    # binary prefixes
    'kibi',    2**10,
    'mebi',    2**20,
    'gibi',    2**30,
    'tebi',    2**40,
    'pebi',    2**50,
    'exbi',    2**60,

    # others
    'semi',    0.5,
    'demi',    0.5,
);


InitUnit (
    # Dimensionless
    ['pi',],    '3.1415926535897932385',
    ['e',],     '2.7182818284590452354',

    ['unity', 'one', 'ones',],           '1',
    ['two', 'twos',],                    '2',
    ['three', 'threes',],                '3',
    ['four', 'fours',],                  '4',
    ['five', 'fives',],                  '5',
    ['six', 'sixes',],                   '6',
    ['seven', 'sevens',],                '7',
    ['eight', 'eights',],                '8',
    ['nine', 'nines'],                   '9',
    ['ten', 'tens',],                   '10',
    ['eleven', 'elevens',],             '11',
    ['twelve', 'twelves',],             '12',
    ['thirteen', 'thirteens',],         '13',
    ['fourteen', 'fourteens',],         '14',
    ['fifteen', 'fifteens',],           '15',
    ['sixteen', 'sixteens',],           '16',
    ['seventeen', 'seventeens',],       '17',
    ['eighteen', 'eighteens',],         '18',
    ['nineteen', 'nineteens',],         '19',
    ['twenty', 'twenties',],            '20',
    ['thirty', 'thirties',],            '30',
    ['forty', 'forties',],              '40',
    ['fifty', 'fifties',],              '50',
    ['sixty', 'sixties',],              '60',
    ['seventy', 'seventies',],          '70',
    ['eighty', 'eighties',],            '80',
    ['ninety', 'nineties',],            '90',
    ['hundred', 'hundreds'],           '100',
    ['thousand', 'thousands'],        '1000',
    ['million', 'millions',],          '1e6',
    ['billion', 'billions',],          '1e9',
    ['trillion', 'trillions',],       '1e12',
    ['quadrillion', 'quadrillions',], '1e15',
    ['quintillion', 'quintillions',], '1e18',

    ['half', 'halves',],      '0.5',
    ['third', 'thirds',],     '1/3',
    ['fourth', 'fourths',],  '0.25',
    ['tenth',],               '0.1',
    ['hundredth',],          '0.01',
    ['thousandth',],        '0.001',
    ['millionth',],          '1e-6',
    ['billionth',],          '1e-9',
    ['trillionth',],        '1e-12',
    ['quadrillionth',],     '1e-15',
    ['quintillionth',],     '1e-18',

    ['percent', '%',],      '0.01',
    ['dozen', 'doz',],        '12',
    ['gross',],              '144',

    # Angular
    ['radian', 'radians',],                 '1',
    ['steradian', 'sr', 'steradians',],     '1',
    ['degree', 'deg', 'degrees',],          'pi radians / 180',
    ['arcminute', 'arcmin', 'arcminutes',], 'deg / 60',
    ['arcsecond', 'arcsec', 'arcseconds',], 'arcmin / 60',

    # Distance
    ['foot', 'ft', 'feet',],                    '.3048 m',          # exact
    ['inch', 'in', 'inches',],                  'ft/12',            # exact
    ['mil', 'mils',],                           'in/1000',          # exact
    ['yard', 'yards',],                         '3 ft',             # exact
    ['fathom', 'fathoms',],                     '2 yards',          # exact
    ['rod', 'rods',],                           '5.5 yards',        # exact
    ['pole', 'poles',],                         '1 rod',            # exact
    ['perch', 'perches',],                      '1 rod',            # exact
    ['furlong', 'furlongs',],                   '40 rods',          # exact
    ['mile', 'mi', 'miles',],                   '5280 ft',          # exact

    ['micron', 'microns', 'um',],               '1e-6 m',           # exact
    ['angstrom', 'a', 'angstroms',],            '1e-10 m',          # exact
    ['cm',],                                    'centimeter',       # exact
    ['km',],                                    'kilometer',        # exact
    ['nm',],                                    'nanometer',        # exact
    ['mm',],                                    'millimeter',       # exact

    ['pica',],                                  'in/6',    # exact, but see below
    ['point',],                                 'pica/12',          # exact

    ['nautical-mile', 'nmi', 'nauticalmiles',
     'nauticalmile', 'nautical-miles',],        '1852 m',           # exact
    ['astronomical-unit', 'au',],               '1.49598e11 m',
    ['light-year', 'ly', 'light-years',
     'lightyear', 'lightyears'],                '9.46e15 m',
    ['parsec', 'parsecs',],                     '3.083e16 m',

    # equatorial radius of the reference geoid:
    ['re'],                          '6378388 m',    # exact
    # polar radius of the reference geoid:
    ['rp'],                          '6356912 m',    # exact

    # Acceleration
    ['g0', 'earth-gravity'],                    '9.80665 m/s^2',    # exact

    # Mass
    ['kg',],                                    'kilogram',         # exact
    ['metric-ton', 'metric-tons', 'tonne',
     'tonnes'],                                 '1000 kg',          # exact

    ['grain', 'grains'],                        '.0648 gm',

    ['pound-mass', 'lbm', 'lbms',
     'pounds-mass'],                            '0.45359237 kg',    # exact
    ['ounce', 'oz', 'ounces'],                  'lbm/16',           # exact
    ['stone', 'stones'],                        '14 lbm',           # exact
    ['hundredweight', 'hundredweights'],        '100 lbms',         # exact
    ['ton', 'tons', 'short-ton', 'short-tons'], '2000 lbms',        # exact
    ['long-ton', 'long-tons'],                  '2240 lbms',        # exact

    ['slug', 'slugs'],                          'lbm g0 s^2/ft',    # exact
    ['mg',],                                    'milligram',        # exact
    ['ug',],                                    'microgram',        # exact

    ['dram', 'drams'],                          'ounce / 16',       # exact

    ['troy-pound', 'troy-pounds'],              '0.373 kg',
    ['troy-ounce', 'troy-ounces',
     'ounce-troy', 'ounces-troy'],              '31.103 gm',
    ['pennyweight', 'pennyweights'],            '1.555 gm',
    ['scruple', 'scruples'],                    '1.296 gm',

    ['hg',],                                    'hectogram',        # exact
    ['dag',],                                   'decagram',         # exact
    ['dg',],                                    'decigram',         # exact
    ['cg',],                                    'centigram',        # exact
    ['carat', 'carats', 'karat', 'karats',],    '200 milligrams',   # exact
    ['j-point',],                               '2 carats',         # exact

    ['atomic-mass-unit', 'amu', 'u',
     'atomic-mass-units'],                      '1.6605402e-27 kg',


    # Time
    ['minute', 'min', 'mins', 'minutes'],               '60 s',
    ['hour', 'hr', 'hrs', 'hours'],                     '60 min',
    ['day', 'days'],    '24 hr',
    ['week', 'wk', 'weeks'],                            '7 days',
    ['fortnight', 'fortnights'],                        '2 week',
    ['year', 'yr', 'yrs', 'years'],                     '365.25 days',
    ['month', 'mon', 'mons', 'months'],                 'year / 12',    # an average month
    ['score', 'scores'],                                '20 yr',
    ['century', 'centuries'],                           '100 yr',
    ['millenium', 'millenia',],                         '1000 yr',

    ['ms', 'msec', 'msecs'], 'millisecond',
    ['us', 'usec', 'usecs'], 'microsecond',
    ['ns', 'nsec', 'nsecs'], 'nanosecond',
    ['ps', 'psec', 'psecs'], 'picosecond',

    # Data
    ['byte', 'bytes'], '8 bits',

    # Frequency
    ['hertz', 'hz'],                    '1/sec',
    ['becquerel', 'bq'],                '1 hz',
    ['revolution', 'revolutions',],     '1',
    ['rpm',],                           'revolutions per minute',
    ['cycle', 'cycles',],                '1',

    # Current
    ['abampere', 'abamp', 'abamps', 'abamperes'],         '10 amps',
    ['statampere', 'statamp', 'statamps', 'statamperes'], '3.336e-10 amps',

    ['ma',], 'milliamp',
    ['ua',], 'microamp',

    # Electric_potential
    ['volt', 'v', 'volts'],    'kg m^2 / amp s^3',
    ['mv',],                   'millivolt',
    ['uv',],                   'microvolt',
    ['abvolt', 'abvolts'],     '1e-8 volt',
    ['statvolt', 'statvolts'], '299.8 volt',

    # Resistance
    ['ohm', 'ohms'],         'kg m^2 / amp^2 s^3',
    ['abohm', 'abohms'],     'nano ohm',
    ['statohm', 'statohms'], '8.987e11 ohm',
    ['kilohm', 'kilohms',],  'kilo ohm',
    ['megohm', 'megohms'],   'mega ohm',

    # Conductance
    ['siemens',],    'amp^2 s^3 / kg m^2',
    ['mho', 'mhos'], '1/ohm',

    # Capacitance
    ['farad', 'f', 'farads'],    'amp^2 s^4 / kg m^2',
    ['abfarad', 'abfarads'],     'giga farad',
    ['statfarad', 'statfarads'], '1.113e-12 farad',

    ['uf',], 'microfarad',
    ['pf',], 'picofarads',

    # Inductance
    ['henry', 'henrys'],         'kg m^2 / amp^2 s^2',
    ['abhenry', 'abhenrys'],     'nano henry',
    ['stathenry', 'stathenrys'], '8.987e11 henry',

    ['uh',], 'microhenry',
    ['mh',], 'millihenry',

    # Magnetic_flux
    ['weber', 'wb', 'webers'],      'kg m^2 / amp s^2',
    ['maxwell', 'maxwells'],    '1e-8 weber',

    # Magnetic_field
    ['tesla', 'teslas'],      'kg / amp sec^2',
    ['gauss',],       '1e-4 tesla',

    # Temperature
    ['degree-rankine', 'degrees-rankine'],      '5/9 * kelvin',     # exact

    # Force
    ['pound', 'lb', 'lbs', 'pounds',
     'pound-force', 'lbf',
     'pounds-force', 'pound-weight'],           'slug foot / s^2',  # exact
    ['ounce-force', 'ozf'],                     'pound-force / 16', # exact
    ['newton', 'nt', 'newtons'],                'kg m / s^2',       # exact
    ['dyne', 'dynes'],                          'gm cm / s^2',      # exact
    ['gram-weight', 'gram-force'],              'gm g0',            # exact
    ['kgf',],                                   'kilo gram-force',  # exact

    # Area
    ['are', 'ares'],          '100 square meters',
    ['hectare', 'hectares',], '100 ares',
    ['acre', 'acres'],        '43560 square feet',
    ['barn', 'barns'],        '1e-28 square meters',

    # Volume
    ['liter', 'l', 'liters'],                   'm^3/1000',         # exact
    ['cl',],                                    'centiliter',       # exact
    ['dl',],                                    'deciliter',        # exact
    ['cc', 'ml',],                              'cubic centimeter', # exact

    ['gallon', 'gal', 'gallons'],               '3.785411784 liter',
    ['quart', 'qt', 'quarts'],                  'gallon/4',
    ['peck', 'pecks'],                          '8 quarts',
    ['bushel', 'bushels'],                      '4 pecks',
    ['fifth', 'fifths'],                        'gallon/5',
    ['pint', 'pt', 'pints'],                    'quart/2',
    ['cup', 'cups'],                            'pint/2',
    ['fluid-ounce', 'floz', 'fluidounce',
     'fluidounces', 'fluid-ounces'],            'cup/8',
    ['gill', 'gills'],                          '4 fluid-ounces',
    ['fluidram', 'fluidrams'],                  '3.5516 cc',
    ['minim', 'minims'],                        '0.059194 cc',
    ['tablespoon', 'tbsp', 'tablespoons'],      'fluid-ounce / 2',
    ['teaspoon', 'tsp', 'teaspoons'],           'tablespoon / 3',

    # Power
    ['watt', 'w', 'watts'], 'kg m^2 / s^3',
    ['horsepower', 'hp'],   '550 foot pound-force / s',

    # Energy
    ['joule', 'j', 'joules'],                   'kg m^2 / s^2',    # exact
    ['electron-volt', 'ev', 'electronvolt',
     'electronvolts', 'electron-volts'],        '1.60217733e-19 joule',

    ['mev',], 'mega electron-volt',
    ['gev',], 'giga electron-volt',
    ['tev',], 'tera electron-volt',

    ['calorie', 'cal', 'calories'],                '4.184 joules',  # exact
    ['kcal',],                                     'kilocalorie',   # exact
    ['british-thermal-unit', 'btu', 'btus',
     'britishthermalunit', 'britishthermalunits',
     'british-thermal-units'],                     '1055.056 joule',
    ['erg', 'ergs'],                               '1.0e-7 joule',  # exact
    ['kwh',],                                      'kilowatt hour', # exact

    # Torque
    ['foot-pound', 'ftlb', 'ft-lb',
     'footpound', 'footpounds', 'foot-pounds'], 'foot pound-force',

    # Charge
    ['coulomb', 'coul', 'coulombs'],             'ampere second',
    ['abcoulomb', 'abcoul', 'abcoulombs'],       '10 coulomb',
    ['statcoulomb', 'statcoul', 'statcoulombs'], '3.336e-10 coulomb',
    ['elementary-charge', 'eq'],     '1.6021892e-19 coulomb',

    # Pressure
    ['pascal', 'pa'],      'newton / m^2',
    ['bar', 'bars'],       '1e5 pascal',
    ['torr',],             '(101325 / 760) pascal',
    ['psi',],              'pounds per inch^2',
    ['atmosphere', 'atm'], '101325 pascal',             # exact

    # Speed
    ['mph',],          'mi/hr',
    ['kph',],          'km/hr',
    ['kps',],          'km/s',
    ['fps',],          'ft/s',
    ['knot', 'knots'], 'nm/hr',
    ['mps',],          'meter/s',
    ['speed-of-light', 'c'],         '2.99792458e8 m/sec',

    # Dose of radiation
    ['gray', 'gy'],    'joule / kg',
    ['sievert', 'sv'], 'joule / kg',
    ['rad',],          'gray / 100',
    ['rem',],          'sievert / 100',

    # Other
    ['gravitational-constant', 'g'], '6.6720e-11  m^3 / kg s^2',
    # Planck constant:
    ['h'],                            '6.626196e-34 J/s',
    # Avogadro constant:
    ['na'],                              '6.022169/mol',
);


InitTypes (
    'Dimensionless'      => 'unity',
    'Frequency'          => 'hertz',
    'Electric_potential' => 'volt',
    'Resistance'         => 'ohm',
    'Conductance'        => 'siemens',
    'Capacitance'        => 'farad',
    'Inductance'         => 'henry',
    'Magnetic_flux'      => 'weber',
    'Magnetic_field'     => 'tesla',
    'Momentum'           => 'kg m/s',
    'Force'              => 'newton',
    'Area'               => 'are',
    'Volume'             => 'liter',
    'Power'              => 'watt',
    'Energy'             => 'joule',
    'Torque'             => 'kg m^2/s^2',
    'Charge'             => 'coulomb',
    'Pressure'           => 'pascal',
    'Speed'              => 'mps',
    'Dose'               => 'gray',       #  of radiation
    'Acceleration'       => 'm/s^2',
);


GetUnit('joule')->type('Energy');
GetUnit('ev')->type('Energy');
GetUnit('mev')->type('Energy');
GetUnit('gev')->type('Energy');
GetUnit('tev')->type('Energy');
GetUnit('cal')->type('Energy');
GetUnit('kcal')->type('Energy');
GetUnit('btu')->type('Energy');
GetUnit('erg')->type('Energy');
GetUnit('kwh')->type('Energy');
GetUnit('ftlb')->type('Torque');


sub InitBaseUnit {
    while (@_) {
        my ($t, $names) = (shift, shift);
        croak 'Invalid arguments to InitBaseUnit'
            if ref $t || (ref $names ne "ARRAY");

        print "Initializing Base Unit $$names[0]\n" if $debug;

        my $unit = NewOne();
        $unit->AddNames(@$names);
        $unit->{def} = $unit->name();  # def same as name

        # The dimension vector for this Unit has zeros in every place
        # except the last
        $unit->{dim}->[$NumBases] = 1;
        $BaseName[$NumBases] = $unit->abbr();
        $NumBases++;

        $unit->NewType($t);
    }
}

sub InitPrefix {
    while (@_) {
        my ($name, $factor) = (shift, shift);
        croak 'Invalid arguments to InitPrefix'
            if !$name || !$factor || ref $name || ref $factor;

        print "Initializing Prefix $name\n" if $debug;

        my $u = NewOne();
        $u->AddNames($name);
        $u->{factor} = $factor;
        $u->{type} = 'prefix';
        $prefix{$name} = $u;

        $u->{def} = $factor;
    }
}

sub InitUnit {
    while (@_) {
        my ($names, $def) = (shift, shift);

        if (ref $names ne "ARRAY" || !$def) {
            print "InitUnit, second argument is '$def'\n";
            croak 'Invalid arguments to InitUnit';
        }

        print "Initializing Unit $$names[0]\n" if $debug;
        my $u = CreateUnit($def);
        $u->AddNames(@$names);
    }
}

sub InitTypes {
    while (@_) {
        my ($t, $u) = (shift, shift);
        croak 'Invalid arguments to InitTypes'
            if !$t || ref $t || !$u;

        my $unit = GetUnit($u);
        $unit->NewType($t);
    }
}

sub GetUnit {
    my $u = shift;
    croak 'GetUnit: expected an argument' unless $u;
    return $u if ref $u;

    if ($unit_by_name{$u}) {
        #print "GetUnit, $u yields ", $unit_by_name{$u}->name, "\n";
        return $unit_by_name{$u};
    }

    # Try it as an expression
    return CreateUnit($u);
}

sub ListUnits {
    return sort keys %unit_by_name;
}

sub ListTypes {
    return sort keys %prototype;
}

sub NumBases {
    return $NumBases;
}

sub GetTypeUnit {
    my $t = shift;
    return $prototype{$t};
}

# DeleteNames - argument can be either an array ref, a list of name strings, or
# a unit object
sub DeleteNames {
    my $arg0 = $_[0];
    my $argIsUnit = ref $arg0 && ref $arg0 ne 'ARRAY';
    # Get the list of names to delete
    my $names =
        !ref $arg0
            ? \@_                 # list of names
            : ref $arg0 eq 'ARRAY'
                ? $arg0           # array ref
                : $arg0->{names}; # unit object

    my $u;
    if ($argIsUnit) { $u = $arg0; }
    for my $n (@$names) {
        if (LookName($n) != 2) {
            croak "'$n' is not a unit name.";
        }
        print "deleting '$n'\n" if $debug;
        delete $prefix{$n};
        if (!$argIsUnit) { $u = $unit_by_name{$n}; }
        delete $unit_by_name{$n};
        # Delete the array element matching $n from @{$u->{names}}
        if (!$argIsUnit) {
            $u->{names} = [ grep { $_ ne $n } @{$u->{names}} ];
        }
    }
    if ($argIsUnit) { $u->{names} = []; }
}


sub new {
    my $proto = shift;
    my $class;

    my $self;
    if (ref $proto) {        # object method
        $self = $proto->copy;
    }
    else {                    # class method
        my $r = shift;
        $self = CreateUnit($r);
    }

    $self->AddNames(@_);
    return $self;
}

sub type {
    my $self = shift;

    # See if the user is setting the type
    my $t;
    if ($t = shift) {
        # XXX Maybe we should check that $t is a valid type name, and
        # XXX that it's type really does match.
        return $self->{type} = $t;
    }

    # If the type is known already, return it
    return $self->{type} if $self->{type};

    # See if it is a prefix
    my $name = $self->name();

    return $self->{type} = 'prefix'
        if defined $name && defined $prefix{$name};

    # Collect all matching types
    my @t;
    for (keys %prototype) {
        push @t, $_
            unless CompareDim($self, $prototype{$_});
    }

    # Return value depends on whether we got zero, one, or multiple types
    return undef unless @t;
    return $self->{type} = $t[0] if @t == 1;
    return \@t;
}

sub name {
    my $self = shift;
    my $n = $self->{names};
    return $$n[0];
}

sub abbr {
    my $self = shift;
    my $n = ${$self->{names}}[0];
    return undef unless defined $n;

    for ($self->names()) {
        $n = $_ if length $_ < length $n;
    }
    return $n;
}

sub names {
    my $self = shift;
    return @{$self->{names}};
}

sub def {
    my $self = shift;
    return $self->{def};
}

sub expanded {
    my $self = shift;
    my $s = $self->{factor};
    $s = '' if $s == 1;

    my $i = 0;
    for my $d (@{$self->{dim}}) {
        if ($d) {
            #print "Dimension index $i is $d\n";
            if ($s) { $s .= " "; }
            $s .= $BaseName[$i];
            $s .= "^$d" unless $d == 1;
        }
        $i++;
    }

    $s = 1 if $s eq '';
    return $s;
}

sub ToString {
    my $self = shift;
    return $self->name || $self->def || $self->expanded;
}

sub factor {
    my $self = shift;
    if (@_) {
        $self->CheckChange;
        $self->{factor} = shift;
    }
    return $self->{factor};
}

sub convert {
    my ($self, $other) = @_;
    my $u = GetUnit($other);
    carp "Can't convert ". $self->name() .' to '. $u->name()
        if CompareDim($self, $u);
    return $self->{factor} / $u->{factor};
}

sub times {
    my $self = shift;
    $self->CheckChange;
    my $u = GetUnit(shift);
    $self->{factor} *= $u->{factor};

    for (0 .. $NumBases) {
        my $u_val = defined $u->{dim}[$_] ? $u->{dim}[$_] : 0;
        if (defined $self->{dim}[$_]) {
            $self->{dim}[$_] += $u_val;
        }
        else {
            $self->{dim}[$_] = $u_val;
        }
    }

    $self->{type} = '';
    return $self;
}

sub recip {
    my $self = shift;
    $self->CheckChange;
    $self->{factor} = 1 / $self->{factor};

    for (0 .. $NumBases) {
        if (defined $self->{dim}[$_]) {
            $self->{dim}->[$_] = -$self->{dim}->[$_];
        }
        else {
            $self->{dim}[$_] = 0;
        }
    }

    return $self;
}

sub divide {
    my ($self, $other) = @_;
    my $u = GetUnit($other)->copy;
    $self->times($u->recip);
}

sub power {
    my $self = shift;
    $self->CheckChange;
    my $p = shift;
    die 'Exponentiation to integer values only, please'
        unless $p == int $p;
    $self->{factor} **= $p;

    for (0 .. $NumBases) {
        $self->{dim}[$_] = 0 unless defined $self->{dim}[$_];
        $self->{dim}[$_] *= $p;
    }

    $self->{type} = '';
    return $self;
}

sub add {
    my $self = shift;
    $self->CheckChange;

    my $other = shift;
    my $u = GetUnit($other);

    croak "Can't add ". $u->type .' to a '. $self->type
        if CompareDim($self, $u);
    $self->{factor} += $u->{factor};
    return $self;
}

sub neg {
    my $self = shift;
    $self->CheckChange;
    $self->{factor} = -$self->{factor};
    return $self;
}

sub subtract {
    my ($self, $other) = @_;
    my $u = GetUnit($other)->copy;
    $self->add( $u->neg );
}

sub copy {
    my $self = shift;
    my $n = {
        'factor' => $self->{factor},
        'dim'    => [@{$self->{dim}}],
        'type'   => $self->{type},
        'names'  => [],
        'def'    => $self->{def},
    };

    bless $n, 'Physics::Unit';
    return $n;
}

sub equal {
    my $obj1 = shift;

    # If it was called as a class method, throw away the first
    # argument (the class name)
    $obj1 = shift unless ref $obj1;
    $obj1 = GetUnit($obj1);
    my $obj2 = GetUnit(shift);

    return 0 if CompareDim($obj1, $obj2);
    return 0 unless $obj1->{factor} == $obj2->{factor};
    return 1;
}

sub NewOne {
    my $u = {
        'factor' => 1,
        'dim'    => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        'type'   => undef,
        'names'  => [],
        'def'    => undef,
    };
    bless $u, 'Physics::Unit';
}

sub AddNames {
    my $self = shift;
    my $n;
    while ($n = shift) {
        croak "Can't use a reference as a name!" if ref $n;
        carp "Name $n is already defined" if LookName($n);
        push @{$self->{names}}, "\L$n";
        $unit_by_name{$n} = $self;
    }
}

sub NewType {
    my ($self, $t) = @_;
#    my $oldtype = $self->type;
#    croak "NewType: the type $t is already defined as $oldtype"
#        if $oldtype ne 'unknown';
    $self->{type} = $t;
    $prototype{$t} = $self;
}

sub CreateUnit {
    my $def = shift;
    # argument was a Unit object
    return $def->new() if ref $def;
    # argument was either a simple name or an expression - doesn't matter
    $def = lc $def;

    my $u = expr($def);
    $u->{def} = $def;
    return $u;
}

sub CompareDim {
    my ($u1, $u2) = @_;
    my $d1 = $u1->{dim};
    my $d2 = $u2->{dim};

    for (0 .. $NumBases) {
        $$d1[$_] = 0 unless defined $$d1[$_];
        $$d2[$_] = 0 unless defined $$d2[$_];
        my $c = ($$d1[$_] <=> $$d2[$_]);
        return $c if $c;
    }
    return 0;
}

sub LookName {
    my $name = shift;
    return 3 if defined $prototype{$name};
    return 2 if defined $unit_by_name{$name};
    return 1 if defined $reserved_word{$name};
    return 0;
}

sub DebugString {
    my $self = shift;
    my $s = $self->{factor};
    $s .= '['. join (', ', @{$self->{dim}}) .']';
    return $s;
}

sub CheckChange {
    my $self = shift;
    carp "You're not allowed to change named units!" if $self->{names}[0];
    $self->{names} = [];
    $self->{type} = $self->{def} = undef;
}

# global variables used for parsing.
my $def;      # string being parsed
my $tok;      # the token type
my $numval;   # the value when the token is a number
my $tokname;  # when it is a name
my $indent;   # used to indent debug messages

# parser
sub expr {
    if (@_) {
        $def = shift;
        get_token();
    }

    print ' ' x $indent, "inside expr\n" if $debug;
    $indent++;
    my $u = term();

    for (;;) {
        if ($tok eq 'times') {
            get_token();
            $u->times(term());
        }
        elsif ($tok eq 'divide') {
            get_token();
            $u->divide(term());
        }
        else {
            print ' ' x $indent, "expr: returning ", $u->DebugString, "\n"
                if $debug;
            $indent--;
            return $u;
        }
    }
}

sub term {
    print ' ' x $indent, "inside term\n" if $debug;
    $indent++;
    my $u = Factor();

    for (;;) {
        print ' ' x $indent, "inside term loop\n" if $debug;
        if ($tok eq 'number' ||
            $tok eq 'name'   ||
            $tok eq 'prefix' ||
            $tok eq 'square' ||
            $tok eq 'cubic')
        {
            $u->times(Factor());
        }
        else {
            print ' ' x $indent, "term: returning ", $u->DebugString, "\n"
                if $debug;
            $indent--;
            return $u;
        }
    }
}

sub Factor {
    print ' ' x $indent, "inside factor\n" if $debug;
    $indent++;

    my $u = prim();

    for (;;) {
        print ' ' x $indent, "inside factor loop\n" if $debug;
        if ($tok eq 'exponent') {
            get_token();
            die 'Exponent must be an integer'
                unless $tok eq 'number';
            $u->power($numval);
            get_token();
        }
        else {
            print ' ' x $indent, "factor: returning ",
            $u->DebugString, "\n" if $debug;
            $indent--;
            return $u;
        }
    }
}

sub prim {
    print ' ' x $indent, "inside prim\n" if $debug;
    $indent++;

    my $u;

    if ($tok eq 'number') {
        print ' ' x $indent, "got number $numval\n" if $debug;
        # Create a new Unit object to represent this number
        $u = NewOne();
        $u->{factor} = $numval;
        get_token();
    }
    elsif ($tok eq 'prefix') {
        print ' ' x $indent, "got a prefix: ", "$tokname\n" if $debug;
        $u = GetUnit($tokname)->copy();
        get_token();
        $u->times(prim());
    }
    elsif ($tok eq 'name') {
        print ' ' x $indent, "got a name: ", "$tokname\n" if $debug;
        $u = GetUnit($tokname)->copy();
        get_token();
    }
    elsif ($tok eq 'lparen') {
        print ' ' x $indent, "got a left paren\n" if $debug;
        get_token();
        $u = expr();
        die 'Missing right parenthesis'
            unless $tok eq 'rparen';
        get_token();
    }
    elsif ($tok eq 'end') {
        print ' ' x $indent, "got end\n" if $debug;
        $u = NewOne();
    }
    elsif ($tok eq 'square') {
        get_token();
        $u = prim()->power(2);
    }
    elsif ($tok eq 'cubic') {
        get_token();
        $u = prim()->power(3);
    }
    else {
        die 'Primary expected';
    }

    print ' ' x $indent, "prim: returning ", $u->DebugString, "\n"
        if $debug;
    $indent--;

    # Before returning, see if the *next* token is 'squared' or 'cubed'
    for(;;) {
        if ($tok eq 'squared') {
            get_token();
            $u->power(2);
        }
        elsif ($tok eq 'cubed') {
            get_token();
            $u->power(3);
        }
        else {
            last;
        }
    }

    return $u;
}

sub get_token {
    print ' ' x $indent, "get_token, looking at '$def'\n" if $debug;

    # First remove whitespace at the begining
    $def =~ s/^\s+//;

    if ($def eq '') {
        $tok = 'end';
        return;
    }

    if ($def =~ s/^\(//) {
        $tok = 'lparen';
    }
    elsif ($def =~ s/^\)//) {
        $tok = 'rparen';
    }
    elsif ($def =~ s/^\*\*// || $def =~ s/^\^//) {
        $tok = 'exponent';
    }
    elsif ($def =~ s/^\*//) {
        $tok = 'times';
    }
    elsif ($def =~ s/^\///) {
        $tok = 'divide';
    }
    elsif ($def =~ s/^$number_re//io) {
        $numval = $1 + 0;  # convert to a number
        $tok = 'number';
    }
    elsif ($def =~ /^([^\ \n\r\t\f\(\)\/\^\*]+)/) {
        my $t = $1;
        my $l = LookName($t);

        if ($l == 1) {
            $tok = $reserved_word{$t};
            $tokname = $t;
            $def = substr $def, length($t);
            return;
        }
        elsif ($l == 2) {
            $tok = 'name';
            $tokname = $t;
            $def = substr $def, length($t);
            return;
        }

        # Couldn't find the name on the first try, look for prefix
        for my $p (keys %prefix) {
            if ($t =~ /^$p/i) {
                $tok = 'prefix';
                $tokname = $p;
                $def = substr $def, length($p);
                return;
            }
        }
        die "Unknown unit: $t\n";
    }
    else {
        die "Illegal token in $def";
    }
}

1;
__END__

=begin comment

Style conventions for this module's POD:
  - Names of other classes should be in and
    L<> for a link:  L<Physics::Unit::Scalar|Physics::Unit::Scalar>.
  - Unit names by themselves in the text:  B<sec>
  - Inline unit expressions:  no quotes, B<cubic meters>
  - But if it's a code snippet, then C<$u = "cubic meters">
  - "Unit" in caps, when it refers to an object.
  - "unit library", "unit expression" (lowercase)

=end comment

=head1 NAME

Physics::Unit - Manipulate physics units and dimensions.

=head1 SYNOPSIS

    use Physics::Unit ':ALL';   # exports all util. function names

    # Define your own unit named "ff"
    $ff = new Physics::Unit('furlong / fortnight', 'ff');
    print $ff->type, "\n";         # prints:  Speed

    # Convert to mph; this prints:  One ff is 0.0003720... miles per hour
    print "One ", $ff->name, " is ", $ff->convert('mph'), " miles per hour\n";

    # Get canonical string representation
    print $ff->expanded, "\n";     # prints:  0.0001663... m s^-1

    # More intricate unit expression (using the newly defined unit 'ff'):
    $gonzo = new Physics::Unit "13 square millimeters per ff";
    print $gonzo->expanded, "\n";  # prints:  0.07816... m s

    # Doing arithmetic maintains the types of units
    $m = $ff->copy->times("5 kg");
    print "This ", $m->type, " unit is ", $m->ToString, "\n";
    # prints: This Momentum unit is 0.8315... m gm s^-1

See also the L<Synopsis|Physics::Unit::Scalar/Synopsis> section of
L<Physics::Unit::Scalar|Physics::Unit::Scalar> for more examples.

=head1 DESCRIPTION

These modules provide classes for the representation of physical units and
quantities, as well as a large library of predefined Physics::Unit objects.
New units and quantities can be created with simple human-readable expressions
(for example, C<cubic meters per second>).  The resultant objects can then be
manipulated arithmetically, with the dimensionality correctly maintained.

Physics::Unit objects generally represent standard, named units,
like B<meter> or B<electronvolt>.
L<Physics::Unit::Scalar|Physics::Unit::Scalar> and related classes, on the
other hand, are used to represent various quantities that might occur as the
result of a measurement or a specification, like "5.7 meters" or "7.4
teraelectronvolts".

A Physics::Unit object has a list of names, a dimensionality, and a magnitude.
For example, the SI unit of force is the B<newton>.  In this module, it can be
referred to with any of the names B<newton>, B<nt>, or B<newtons>.  It's dimensionality
is that of a force:  mass X distance / time^2.  It's magnitude is 1000, which
expresses how large it is in terms of the unprefixed base units B<gram>, B<meter>, and B<second>.

Units are created through the use of unit expressions, which allow
you to combine previously defined named units in new and interesting
ways. In the synopsis above, C<furlong / fortnight> is a unit
expression.

Units that have the same dimensionality (for example, B<acres> and B<square kilometers>)
can be compared, and converted from one to the other.

=head1 GUIDE TO DOCUMENTATION

=over

=item Physics::Unit

This page.

=item L<Physics::Unit::Scalar|Physics::Unit::Scalar>

Describes the Scalar class and all of the type-specific classes
that derive from Scalar.

=item L<physics-unit>

Describes the command-line utility that is included with this module.

=item L<Physics::Unit::UnitsByName|Physics::Unit::UnitsByName>

Table of all of the units predefined in the unit library, alphabetically
by name.

=item L<Physics::Unit::UnitsByType|Physics::Unit::UnitsByType>

Tables listing all the units in the unit library, grouped by type.

=item L<Physics::Unit::Implementation|Physics::Unit::Implementation>

Describes some implementation details for the Unit module.

=item L<Physics::Unit::Scalar::Implementation|Physics::Unit::Scalar::Implementation>

Implementation details for the Scalar module.

=back

=head1 TYPES OF UNITS

A Unit can have one or more names associated with it, or it can be
unnamed (anonymous).  Named units are immutable. This ensures that
expressions used to derive other Units will remain consistent.
The values of anonymous Unit objects, however, can change.

Among named Units, there are three types: prefixes (for example,
"kilo", "mega", etc.), base units, and derived units.

A prefix Unit is a special-case dimensionless Unit object that
can be used in expressions attached to other Unit names with no
intervening whitespace. For example, "kilogram" is a unit expression that uses the
prefix B<kilo>.  For more details about the use of prefixes, see
L</"Unit Expressions">, below.

A base unit is one that defines a new base dimension. For example,
the Unit B<meter> is a base unit; it defines the dimension for B<Distance>.
The predefined unit library defines nine base units, for each of nine
fundamental quantities.  See L</InitBaseUnit()> below for a list.

A derived Unit is one that is built up from other named Units, using a
unit expression.  Most Units are derived Units.

The terms base dimension and derived dimension (or derived type) are
sometimes used. B<Distance> is an example of a base dimension. It is not
derived from any other set of dimensional quantities. B<Speed>, however,
is a derived dimension (or derived type), corresponding to
B<Distance> / B<Time>.

=head1 UNIT NAMES

Unit names are not allowed to contain whitespace, or any of the
characters ^, *, /, (, or ). Case is not significant. Also, they may not
begin with any sequence of characters that could be interpreted as a
decimal number. Furthermore, the following reserved words are not allowed as
unit names: B<per>, B<square>, B<sq>, B<cubic>, B<squared>, or B<cubed>. Other than
that, pretty much anything goes.

=head1 UNIT EXPRESSIONS

Unit expressions allow you to create new Unit objects from the set of
existing named Units. Some examples of unit expressions are:

    megaparsec / femtosecond
    kg / feet^2 sec
    square millimeter
    kilogram meters per second squared

The operators allowed in unit expressions are, in order from high to
low precedence:

=over 4

=item prefix

Any prefix that is attached to a Unit name is applied to that Unit
immediately (highest precedence). Note that if there is whitespace
between the prefix and the Unit name, this would be the space
operator, which is not the same (see below).

The unit library comes with a rather complete set of predefined SI prefixes;
see the L<UnitsByType|Physics::Unit::UnitsByType> page.

The prefixes are allowed before units, or by themselves. Thus, these
are equivalent:

    (megameter)
    (mega meter)

But note that when used in expressions, there can be subtle differences, because
the precedence of the prefix operation is higher than the space operator.  So
C<square megameter> is a unit of area, but C<square mega meter> is a unit of
distance (equal to B<10^12 meters>).

=item square, sq, or cubic

Square or cube the next thing on the line

=item squared or cubed

Square or cube the previous thing on the line.

=item C<< ^ >> or C<< ** >>

Exponentiation (must be to an integral power)

=item I<whitespace>

Any amount of whitespace between units is considered a multiplication

=item E<42>, /, or per

Multiplication or division

=item I<parentheses>

Can be used to override the precedence of any of the operators.

=back

For the most part, this precedence order lets you write unit expressions
in a natural way.  For example, note that the space operator has higher precedence
than '*', '/', or 'per'.  Thus "C<meters/sec sec>" is a unit of acceleration,
but "C<meters/sec*sec>" is not.  The latter is equivalent to just 'meters'.

=head2 Expression Grammar

This is the approximate grammar used by the parser.

  expr : term
       | term '/' expr
       | term '*' expr
       | term 'per' expr

  term : factor
       | term <whitespace> factor

  factor : primary
         | primary '**' integer

  primary : number
          | word
          | '(' expr ')'
          | 'square' primary
          | 'sq' primary
          | 'cubic' primary
          | primary 'squared'
          | primary 'cubed'

=head1 PREDEFINED UNIT LIBRARY

A rather complete set of units is pre-defined in the unit library, so it
will probably be rare that you'll need to define your own. See the
L<UnitsByName|Physics::Unit::UnitsByName> or
L<UnitsByType|Physics::Unit::UnitsByType> page for a complete list.

A B<pound> is a unit of force. I was very much tempted to make it a unit
of mass, since that is the way it is used in everyday speech, but I just
couldn't do it. The everyday pound, then, is named B<pound-mass>,
B<lbm>, B<lbms>, or B<pounds-mass>.

However, I couldn't bring myself to do the same thing to all the
other American units derived from a B<pound>. Therefore, B<ounce>, B<ton>,
B<long-ton>, and B<hundredweight> are all units of mass.

=head2 Physical Constants

A few physical constants were defined as Unit objects. This list is
very restricted, however. I limited them to physical constants which
really qualify as universal, according to (as much as I know of) the
laws of physics, and a few constants which have been defined by
international agreement. Thus, they are:

=over

=item * c   - the speed of light

=item * G   - the universal gravitational constant

=item * eq  - elementary charge

=item * em  - electron mass

=item * u   - atomic mass unit

=item * g0  - standard gravity

=item * atm - standard atmosphere

=item * re  - equatorial radius of the reference geoid

=item * rp  - polar radius of the reference geoid

=item * h   - Planck constant

=item * Na  - Avogadro constant

=back

=head2 Name Conflicts and Resolutions

A few unit names and abbreviations had to be changed in order to avoid name
conflicts.  These are:

=over

=item * Elementary charge - abbreviated B<eq> instead of B<e>

=item * Earth gravity - abbreviated B<g0> instead of B<g>

=item * B<point> - there are several definitions for this term.  In our library,
we define it to be exactly 1/72 of an inch.

=item * B<minute> is defined as a unit of time.  For the unit of arc, use
B<arcminute>.  Same for B<second> and B<arcsecond>.

=item * B<pound> - As described above, this is defined as a unit of force, with
synonyms B<pound-force>, B<pounds-force>, B<pound-weight>, and B<lbf>.
For the unit of mass, use B<pound-mass>, B<pounds-mass>, or B<lbm>.

=item * B<ounce> - As a unit of mass, use B<ounce>, B<ounce-force>, or B<ozf>.
For the unit of volume, use B<fluid-ounce>, B<floz>, or B<fluidounce>.

=back

=head1 EXPORT OPTIONS

By default, this module exports nothing. You can request all of the
L<functions|/FUNCTIONS> to be exported as follows:

  use Physics::Unit ':ALL';

Or, you can just get specific ones. For example:

  use Physics::Unit qw( GetUnit ListUnits );

=head1 FUNCTIONS

=over

=item InitBaseUnit(I<$type1>, I<$nameList1>, I<$type2>, I<$nameList2>, ...)

This function is used to define any number of new, fundamental,
independent dimensional quantities.  Each such quantity is represented
by a Unit object, which must have at least one name.  From these base
units, all the units in the system are derived.

The library is initialized to know about nine base quantities. These
quantities, and the base units which represent them, are:

=over

=item 1.  Distance - meter

=item 2.  Mass - gram

=item 3.  Time - second

=item 4.  Temperature - kelvin

=item 5.  Current - ampere

=item 6.  Substance - mole

=item 7.  Luminosity - candela

=item 8.  Money - us-dollar

=item 9.  Data - bit

=back

More base quantities can be added at run-time, by calling this
function. The arguments to this function are in pairs. Each pair
consists of a type name followed by a reference to an array. The
array consists of a list of names which can be used to reference the
unit. For example:

  InitBaseUnit('Beauty' => ['sonja', 'sonjas', 'yh']);

This defines a new basic physical type, called B<Beauty>. This also
causes the creation of a single new Unit object, which has three
names: B<sonja>, B<sonjas>, and B<yh>. The type B<Beauty> is refered to as a
base type. The Unit B<sonja> is refered to as the base unit
corresponding to the type B<Beauty>.

After defining a new base Unit and type, you can then create other
Units derived from this Unit, and other types derived from this type.

=item InitPrefix(I<$name1>, I<$number1>, I<$name2>, I<$number2>, ...)

This function defines new prefixes.  For example:

  InitPrefix('gonzo' => 1e100, 'piccolo' => 1e-100);

From then on, you can use those prefixes to define new units, as in:

  $beautification_rate = new Physics::Unit('5 piccolosonjas / hour');

=item InitUnit(I<$nameList1>, I<$unitDef1>, I<$nameList2>, I<$unitDef2>, ...)

This function creates one or more new named Units.  This is called at
compile time to initialize the module with all the predefined units.
It may also be
called by users at runtime, to expand the unit system. For example:

  InitUnit( ['chris', 'cfm'] => '3 piccolosonjas' );

creates another Unit of type B<Beauty> equal to B<3e-100 sonjas>.

Both this utility function and the C<new> class method can be used to
create new, named Unit objects. Units created with
C<InitUnit> must have a name, however, whereas C<new> can be used to create anonymous
Unit objects.

In this function and in others, an argument that specifies a Unit (a "unitDef")
can be given
either as Unit object, a single Unit name, or a unit expression.
So, for example, these are the same:

  InitUnit( ['mycron'], '3600 sec' );
  InitUnit( ['mycron'], 'hour' );
  InitUnit( ['mycron'], GetUnit('hour') );

No forward references are allowed.

=item InitTypes(I<$typeName1>, I<$unit1>, I<$typeName2>, I<$unit2>, ...)

Use this function to define derived types. For example:

  InitTypes( 'Blooming' => 'sonja / year' );

defines a new type that for a rate of change of B<Beauty> with time.

This function associates a type name with a specific dimensionality.
The magnitude of the Unit is not used.

=item GetUnit(I<$unitDef>)

Returns a Unit object associated with the the argument passed in. The
argument can either be a Unit object (in which case it is simply returned),
a unit name (in which case the name is looked up and a reference to the
corresponding Unit is returns), or a unit expression (in which case a new
Unit object is created and a reference to it is returned).

=item ListUnits()

Returns a list of all Unit names known, sorted alphabetically.

=item ListTypes()

Returns a list of all the quantity types known to the library, sorted
alphabetically.

=item NumBases()

Returns the number of base dimension units.

=item GetTypeUnit(I<$type>)

Returns the Unit object corresponding to a given type name, or B<undef> if
the type is not recognized.

=item DeleteNames(I<@names>)

=item DeleteNames(I<$unit>)

Deletes the names indicated by the argument, which can either be a list
of names, a reference to array of names, or a Unit object.  If the argument
is a Unit object, then all the names of that Unit are deleted.

This provides a mechanism to override specific definitions in the default
unit library.  Use with this with caution.  If existing Unit objects
had been constructed using these names, the C<def> value of those
Units would be rendered invalid when these names are removed.

=back

=head1 METHODS

=over

=item new Physics::Unit( I<$unit> [, I<$name1>, I<$name2>, ... ] )

=item I<$u>->new( [I<$name1>, I<$name2>, ... ] )

This method creates a new Unit object. The names are optional.
If more than one name is given, the first is the "primary name",
which means it is the one returned by the C<name()> method.

Unit names must be unique. See the L<UnitsByName|Physics::Unit::UnitsByName>
page to see an alphabetical list of all the pre-defined unit names.

If no names are given, then an anonymous Unit is created. Note that
another way of creating new anonymous Units is with the C<GetUnit()>
function.  Unlike GetUnit(), however, the new method always creates
a new object.

Examples:

  # Create a new, named unit:
  $u = new Physics::Unit ('3 pi furlongs', 'gorkon');

=item I<$u>->type([I<$typeName>])

Get or set this Unit's type.

For example:

  print GetUnit('rod')->type, "\n";  # 'Distance'

Usually it will not be necessary to set a Unit's type. The type
is normally determined uniquely from the dimensionality.
However, occasionally, more than one type can match a given Unit's
dimensionality.

For example, B<Torque> and B<Energy> have the same
dimensionality.  In that case, all of the predefined, named Units are explicitly
designated to be one type or the other. For example, the Unit B<newton>
is defined to have the type B<Energy>. See the
L<UnitsByType|Physics::Unit::UnitsByType> page to
see which Units are defined as B<Energy> and which as B<Torque>.

If you create a new Unit object that has this dimensionality, then it will
be necessary to explicitly specify which type that Unit object is.

When this method is called to set the Unit's type, only one type
string argument is allowed, and it must be a predefined type name
(see C<InitTypes> above).

This method returns one of:

=over

=item C<undef>

no type was found to match the unit's dimensionality

=item 'prefix'

in the special case where the unit is a named prefix

=item a type name

the prototype unit for this type name matches the unit's dimensionality

=item an array of type names

more than one type was found to match the unit's dimensionality

=back

Some examples:

  $u1 = new Physics::Unit('kg m^2/s^2');
  $t = $u1->type;       #  ['Energy', 'Torque']

  $u1->type('Energy');  #  This establishes the type once and for all
  $t = $u1->type;       #  'Energy'

  # Create a new copy of a predefined, typed unit:
  $u3 = GetUnit('joule')->new;
  $t = $u3->type;       # 'Energy'

=item I<$u>->name()

Returns the primary name of the Unit. If this Unit has no names, then
C<undef>.

=item I<$u>->abbr()

Returns the shortest name of the Unit. If this Unit has no names,
C<undef>.

=item I<$u>->names()

Returns a list of names that can be used to reference the Unit.
Returns the empty list if the Unit is unnamed.

=item I<$u>->def()

Returns the string that was used to define this Unit.  Note that if
the Unit has been manipulated with any of the arithmetic methods,
then the C<def> method will return C<undef>, since the definition string is
no longer a valid definition of the Unit.

=item I<$u>->expanded()

Produces a string representation of the Unit, in terms of the base
Units.  For example:

  print GetUnit('calorie')->expanded, "\n";  # "4184 m^2 gm s^-2"

=item I<$u>->ToString()

There are several ways to serialize a Unit object to a string.
This method is designed to give you what you usually want, and to always
give something meaningful.

If the object is named, this does the same as the C<name()> method above.
Otherwise, if the object's definition string is still valid, this
does the same as the C<def()> method above. Otherwise, this does the same
thing as the C<expanded()> method.

=item I<$u>->factor([I<$newValue>])

Get or set the Unit's conversion factor (magnitude). If this is used to set a
Unit's factor, then the Unit object must be anonymous.

=item I<$u>->convert(I<$unitDef>)

Returns the number which converts this Unit to another. The types of
the Units must match. For example:

  print GetUnit('mile')->convert('foot'), "\n";  # 5280

=item I<$u>->times(I<$unitDef>)

Multiply this object by the given Unit.  This will, in general, change a
Unit's dimensionality, and hence its type.

=item I<$u>->recip()

Replaced a Unit with its reciprocal.  This will, in general, change a
Unit's dimensionality, and hence its type.

=item I<$u>->divide(I<$unitDef>)

Divide this object by the given Unit.  This will, in general, change a
Unit's dimensionality, and hence its type.

For example:

  $u = new Physics::Unit('36 m^2');
  $u->divide('3 meters');   # now '12 m'
  $u->divide(3);            # now '4 m'
  $u->divide('.5 sec');     # now '8 m/s'

=item I<$u>->power(I<$i>)

Raises a Unit to an integral power.   This will, in general, change its
dimensionality, and hence its type.

=item I<$u>->add(I<$unitDef>)

Add a Unit, which must be of the same type.

=item I<$u>->neg()

Replace a Unit with its arithmetic negative.

=item I<$u>->subtract(I<$unitDef>)

Subtract a Unit, which must be of the same type.

=item I<$u>->copy()

This creates a copy of an existing Unit, without copying the names.
So you are free to modify the copy (while modification of
named Units is verboten).  If the type of the existing Unit is
well-defined, then it, also, is copied.

This is the same as the new method, when new is called as an object
method with no names.

=item I<$u>->equal(I<$unit>)

=item Physics::Unit->equal(I<$unit1>, I<$unit2>);

This returns 1 if the two Unit objects have the same type and the
same magnitude.

=back

=head1 SEE ALSO

Here are some other modules that might fit your needs better than this one:

=over

=item * L<MooseX::Types::NumUnit>

=item * L<Math::Units>

=item * L<Math::Units::PhysicalValue>

=item * L<Petrophysics::Unit>

=item * L<Physics::Udunits2>

=back

=head1 AUTHOR

Written by Chris Maloney <voldrani@gmail.com>

Special thanks for major contributions and encouragement from Joel Berger.
Thanks also to Ben Bullock, and initial help in formatting for distribution
from Gene Boggs <cpan@ology.net>.

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2003 by Chris Maloney

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

