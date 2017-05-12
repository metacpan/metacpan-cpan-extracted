package Chemistry::Elements;

use strict;
use warnings;
no warnings;

use Carp qw(croak carp);
use Scalar::Util qw(blessed);

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD
             $debug %names %elements $maximum_Z
             %names_to_Z $Default_language %Languages
            );

require Exporter;

@ISA       = qw(Exporter);
@EXPORT_OK = qw(get_Z get_symbol get_name);
@EXPORT    = qw();
$VERSION   = '1.07';

use subs qw(
	_get_name_by_Z
	_get_symbol_by_Z
	_get_name_by_symbol
	_get_Z_by_symbol
	_get_symbol_by_name
	_get_Z_by_name
	_is_Z
	_is_name
	_is_symbol
	_format_name
	_format_symbol
	);

BEGIN {
my @class_methods  = qw(can isa);
my @object_methods = qw(new Z name symbol can);
my %class_methods  = map { $_, 1 } @class_methods;
my %object_methods = map { $_, 1 } @object_methods;

sub can
	{
	my $thingy = shift;
	my @methods = @_;

	my $method_hash = blessed $thingy ? \%object_methods : \%class_methods ;
	
	foreach my $method ( @methods )
		{
		return unless exists $method_hash->{ $method };
		}
		
	return 1;
	}
	
sub _add_object_method # everyone gets it
	{
	$object_methods{ $_[1] } = 1;
	}
}

$debug = 0;

%Languages = (
	'Pig Latin' => 0,
	'English'   => 1,
	);

$Default_language = $Languages{'English'};

	
%names =
(
  1 => [ qw( Ydrogenhai Hydrogen ) ],
  2 => [ qw( Eliumhai Helium ) ],
  3 => [ qw( Ithiumlai Lithium ) ],
  4 => [ qw( Erylliumbai Beryllium ) ],
  5 => [ qw( Oronbai Boron ) ],
  6 => [ qw( Arboncai Carbon ) ],
  7 => [ qw( Itrogennai Nitrogen ) ],
  8 => [ qw( Xygenoai Oxygen ) ],
  9 => [ qw( Luorinefai Fluorine ) ],
 10 => [ qw( Eonnai Neon ) ],
 11 => [ qw( Odiumsai Sodium ) ],
 12 => [ qw( Agnesiummai Magnesium ) ],
 13 => [ qw( Luminiumaai Aluminium ) ],
 14 => [ qw( Iliconsai Silicon ) ],
 15 => [ qw( Hosphoruspai Phosphorus ) ],
 16 => [ qw( Ulfursai Sulfur ) ],
 17 => [ qw( Hlorinecai Chlorine ) ],
 18 => [ qw( Rgonaai Argon ) ],
 19 => [ qw( Otassiumpai Potassium ) ],
 20 => [ qw( Alciumcai Calcium ) ],
 21 => [ qw( Candiumsai Scandium ) ],
 22 => [ qw( Itaniumtai Titanium ) ],
 23 => [ qw( Anadiumvai Vanadium ) ],
 24 => [ qw( Hromiumcai Chromium ) ],
 25 => [ qw( Anganesemai Manganese ) ],
 26 => [ qw( Roniai Iron ) ],
 27 => [ qw( Obaltcai Cobalt ) ],
 28 => [ qw( Ickelnai Nickel ) ],
 29 => [ qw( Oppercai Copper ) ],
 30 => [ qw( Inczai Zinc ) ],
 31 => [ qw( Alliumgai Gallium ) ],
 32 => [ qw( Ermaniumgai Germanium ) ],
 33 => [ qw( Rsenicaai Arsenic ) ],
 34 => [ qw( Eleniumsai Selenium ) ],
 35 => [ qw( Rominebai Bromine ) ],
 36 => [ qw( Ryptonkai Krypton ) ],
 37 => [ qw( Ubidiumrai Rubidium ) ],
 38 => [ qw( Trontiumsai Strontium ) ],
 39 => [ qw( Ttriumyai Yttrium ) ],
 40 => [ qw( Irconiumzai Zirconium ) ],
 41 => [ qw( Iobiumnai Niobium ) ],
 42 => [ qw( Olybdenummai Molybdenum ) ],
 43 => [ qw( Echnetiumtai Technetium ) ],
 44 => [ qw( Utheniumrai Ruthenium ) ],
 45 => [ qw( Hodiumrai Rhodium ) ],
 46 => [ qw( Alladiumpai Palladium ) ],
 47 => [ qw( Ilversai Silver ) ],
 48 => [ qw( Admiumcai Cadmium ) ],
 49 => [ qw( Ndiumiai Indium ) ],
 50 => [ qw( Intai Tin ) ],
 51 => [ qw( Ntimonyaai Antimony ) ],
 52 => [ qw( Elluriumtai Tellurium ) ],
 53 => [ qw( Odineiai Iodine ) ],
 54 => [ qw( Enonxai Xenon ) ],
 55 => [ qw( Esiumcai Cesium ) ],
 56 => [ qw( Ariumbai Barium ) ],
 57 => [ qw( Anthanumlai Lanthanum ) ],
 58 => [ qw( Eriumcai Cerium ) ],
 59 => [ qw( Raesodymiumpai Praesodymium ) ],
 60 => [ qw( Eodymiumnai Neodymium ) ],
 61 => [ qw( Romethiumpai Promethium ) ],
 62 => [ qw( Amariumsai Samarium ) ],
 63 => [ qw( Uropiumeai Europium ) ],
 64 => [ qw( Adoliniumgai Gadolinium ) ],
 65 => [ qw( Erbiumtai Terbium ) ],
 66 => [ qw( Ysprosiumdai Dysprosium ) ],
 67 => [ qw( Olmiumhai Holmium ) ],
 68 => [ qw( Rbiumeai Erbium ) ],
 69 => [ qw( Huliumtai Thulium ) ],
 70 => [ qw( Tterbiumyai Ytterbium ) ],
 71 => [ qw( Utetiumlai Lutetium ) ],
 72 => [ qw( Afniumhai Hafnium ) ],
 73 => [ qw( Antalumtai Tantalum ) ],
 74 => [ qw( Ungstentai Tungsten ) ],
 75 => [ qw( Heniumrai Rhenium ) ],
 76 => [ qw( Smiumoai Osmium ) ],
 77 => [ qw( Ridiumiai Iridium ) ],
 78 => [ qw( Latinumpai Platinum ) ],
 79 => [ qw( Oldgai Gold ) ],
 80 => [ qw( Ercurymai Mercury ) ],
 81 => [ qw( Halliumtai Thallium ) ],
 82 => [ qw( Eadlai Lead ) ],
 83 => [ qw( Ismuthbai Bismuth ) ],
 84 => [ qw( Oloniumpai Polonium ) ],
 85 => [ qw( Statineaai Astatine ) ],
 86 => [ qw( Adonrai Radon ) ],
 87 => [ qw( Ranciumfai Francium ) ],
 88 => [ qw( Adiumrai Radium ) ],
 89 => [ qw( Ctiniumaai Actinium ) ],
 90 => [ qw( Horiumtai Thorium ) ],
 91 => [ qw( Rotactiniumpai Protactinium ) ],
 92 => [ qw( Raniumuai Uranium ) ],
 93 => [ qw( Eptuniumnai Neptunium ) ],
 94 => [ qw( Lutoniumpai Plutonium ) ],
 95 => [ qw( Mericiumaai Americium ) ],
 96 => [ qw( Uriumcai Curium ) ],
 97 => [ qw( Erkeliumbai Berkelium ) ],
 98 => [ qw( Aliforniumcai Californium ) ],
 99 => [ qw( Insteiniumeai Einsteinium ) ],
100 => [ qw( Ermiumfai Fermium ) ],
101 => [ qw( Endeleviummai Mendelevium ) ],
102 => [ qw( Obeliumnai Nobelium ) ],
103 => [ qw( Awerenciumlai Lawerencium ) ],
104 => [ qw( Utherfordiumrai Rutherfordium ) ],
105 => [ qw( Ubniumdai Dubnium ) ],
106 => [ qw( Eaborgiumsai Seaborgium ) ],
107 => [ qw( Ohriumbai Bohrium ) ],
108 => [ qw( Assiumhai Hassium ) ],
109 => [ qw( Eitneriummai Meitnerium ) ]
);

{
# There might be duplicates keys here, but it should never come out
# with the wrong Z
our %names_to_Z = ();
foreach my $Z ( keys %names )
	{
	my @names = map { lc } @{ $names{$Z} };
#	print STDERR "Got names [@names] for $Z\n";
	@names_to_Z{@names} = ($Z) x @names;
	}
	
#print STDERR Dumper( \%names_to_symbol ); use Data::Dumper;
}

{
my @a = sort {$a <=> $b } keys %names;
$maximum_Z = pop @a;
}

%elements = (
'H'  => '1',      '1' => 'H',
'He' => '2',      '2' => 'He',
'Li' => '3',      '3' => 'Li',
'Be' => '4',      '4' => 'Be',
'B'  => '5',      '5' => 'B',
'C'  => '6',      '6' => 'C',
'N'  => '7',      '7' => 'N',
'O'  => '8',      '8' => 'O',
'F'  => '9',      '9' => 'F',
'Ne' => '10',    '10' => 'Ne',
'Na' => '11',    '11' => 'Na',
'Mg' => '12',    '12' => 'Mg',
'Al' => '13',    '13' => 'Al',
'Si' => '14',    '14' => 'Si',
'P'  => '15',    '15' => 'P',
'S'  => '16',    '16' => 'S',
'Cl' => '17',    '17' => 'Cl',
'Ar' => '18',    '18' => 'Ar',
'K'  => '19',    '19' => 'K',
'Ca' => '20',    '20' => 'Ca',
'Sc' => '21',    '21' => 'Sc',
'Ti' => '22',    '22' => 'Ti',
'V'  => '23',    '23' => 'V',
'Cr' => '24',    '24' => 'Cr',
'Mn' => '25',    '25' => 'Mn',
'Fe' => '26',    '26' => 'Fe',
'Co' => '27',    '27' => 'Co',
'Ni' => '28',    '28' => 'Ni',
'Cu' => '29',    '29' => 'Cu',
'Zn' => '30',    '30' => 'Zn',
'Ga' => '31',    '31' => 'Ga',
'Ge' => '32',    '32' => 'Ge',
'As' => '33',    '33' => 'As',
'Se' => '34',    '34' => 'Se',
'Br' => '35',    '35' => 'Br',
'Kr' => '36',    '36' => 'Kr',
'Rb' => '37',    '37' => 'Rb',
'Sr' => '38',    '38' => 'Sr',
'Y'  => '39',    '39' => 'Y',
'Zr' => '40',    '40' => 'Zr',
'Nb' => '41',    '41' => 'Nb',
'Mo' => '42',    '42' => 'Mo',
'Tc' => '43',    '43' => 'Tc',
'Ru' => '44',    '44' => 'Ru',
'Rh' => '45',    '45' => 'Rh',
'Pd' => '46',    '46' => 'Pd',
'Ag' => '47',    '47' => 'Ag',
'Cd' => '48',    '48' => 'Cd',
'In' => '49',    '49' => 'In',
'Sn' => '50',    '50' => 'Sn',
'Sb' => '51',    '51' => 'Sb',
'Te' => '52',    '52' => 'Te',
'I'  => '53',    '53' => 'I',
'Xe' => '54',    '54' => 'Xe',
'Cs' => '55',    '55' => 'Cs',
'Ba' => '56',    '56' => 'Ba',
'La' => '57',    '57' => 'La',
'Ce' => '58',    '58' => 'Ce',
'Pr' => '59',    '59' => 'Pr',
'Nd' => '60',    '60' => 'Nd',
'Pm' => '61',    '61' => 'Pm',
'Sm' => '62',    '62' => 'Sm',
'Eu' => '63',    '63' => 'Eu',
'Gd' => '64',    '64' => 'Gd',
'Tb' => '65',    '65' => 'Tb',
'Dy' => '66',    '66' => 'Dy',
'Ho' => '67',    '67' => 'Ho',
'Er' => '68',    '68' => 'Er',
'Tm' => '69',    '69' => 'Tm',
'Yb' => '70',    '70' => 'Yb',
'Lu' => '71',    '71' => 'Lu',
'Hf' => '72',    '72' => 'Hf',
'Ta' => '73',    '73' => 'Ta',
'W'  => '74',    '74' => 'W',
'Re' => '75',    '75' => 'Re',
'Os' => '76',    '76' => 'Os',
'Ir' => '77',    '77' => 'Ir',
'Pt' => '78',    '78' => 'Pt',
'Au' => '79',    '79' => 'Au',
'Hg' => '80',    '80' => 'Hg',
'Tl' => '81',    '81' => 'Tl',
'Pb' => '82',    '82' => 'Pb',
'Bi' => '83',    '83' => 'Bi',
'Po' => '84',    '84' => 'Po',
'At' => '85',    '85' => 'At',
'Rn' => '86',    '86' => 'Rn',
'Fr' => '87',    '87' => 'Fr',
'Ra' => '88',    '88' => 'Ra',
'Ac' => '89',    '89' => 'Ac',
'Th' => '90',    '90' => 'Th',
'Pa' => '91',    '91' => 'Pa',
'U'  => '92',    '92' => 'U',
'Np' => '93',    '93' => 'Np',
'Pu' => '94',    '94' => 'Pu',
'Am' => '95',    '95' => 'Am',
'Cm' => '96',    '96' => 'Cm',
'Bk' => '97',    '97' => 'Bk',
'Cf' => '98',    '98' => 'Cf',
'Es' => '99',    '99' => 'Es',
'Fm' => '100',  '100' => 'Fm',
'Md' => '101',  '101' => 'Md',
'No' => '102',  '102' => 'No',
'Lr' => '103',  '103' => 'Lr',
'Rf' => '104',  '104' => 'Rf',
'Ha' => '105',  '105' => 'Ha',
'Sg' => '106',  '106' => 'Sg',
'Bh' => '107',  '107' => 'Bh',
'Hs' => '108',  '108' => 'Hs',
'Mt' => '109',  '109' => 'Mt'
);

sub new
	{
	my( $class, $data, $language ) = @_;

	my $self = {};
	bless $self, $class;

	if(    _is_Z      $data ) { $self->Z($data) }
	elsif( _is_symbol $data ) { $self->symbol($data) }
	elsif( _is_name   $data ) { $self->name($data) }
	else                      { return }

	return $self;
	}

sub Z
	{
	my $self = shift;
	
	return $self->{'Z'} unless @_;
	my $data = shift;
	
	unless( _is_Z $data )
		{
		$self->error('$data is not a valid proton number');
		return;
		}

	$self->{'Z'}      = $data;
	$self->{'name'}   = _get_name_by_Z $data;
	$self->{'symbol'} = _get_symbol_by_Z $data;

	return $data;
	}

sub name
	{
	my $self = shift;
	
	return $self->{'name'} unless @_;
	my $data = shift;
	
	unless( _is_name $data )
		{
		$self->error('$data is not a valid element name');
		return;
		}

	$self->{'name'}   = _format_name $data;
	$self->{'Z'}      = _get_Z_by_name $data;
	$self->{'symbol'} = _get_symbol_by_Z($self->Z);

	return $data;
	}

sub symbol
	{
	my $self = shift;
	
	return $self->{'symbol'} unless @_;
	my $data = shift;
	
	unless( _is_symbol $data )
		{
		$self->error('$data is not a valid element symbol');
		return;
		}

	$self->{'symbol'} = _format_symbol $data;
	$self->{'Z'}      = _get_Z_by_symbol $data;
	$self->{'name'}   = _get_name_by_Z $self->Z;

	return $data;
	}

sub get_symbol
	{
	my $thingy = shift;

	#since we were asked for a name, we'll suppose that we were passed
	#either a chemical symbol or a Z.
	return _get_symbol_by_Z($thingy)      if _is_Z $thingy;
	return _get_symbol_by_name($thingy)   if _is_name $thingy;

	#maybe it's already a symbol...
	return _format_symbol $thingy if _is_symbol $thingy;

	#we were passed something wierd.  pretend we don't know anything.
	return;
	}

sub _get_symbol_by_name
	{
	my $name = lc shift;
	
	return unless _is_name $name;

	my $Z = $names_to_Z{$name};

	$elements{$Z}; 
	}

sub _get_symbol_by_Z
	{
	return unless _is_Z $_[0];

	return $elements{$_[0]};
	}

sub get_name
	{
	my $thingy   = shift;
	my $language = defined $_[0] ? $_[0] : $Default_language;
	
	#since we were asked for a name, we'll suppose that we were passed
	#either a chemical symbol or a Z.
	return _get_name_by_symbol( $thingy, $language ) if _is_symbol $thingy;
	return _get_name_by_Z(      $thingy, $language ) if _is_Z $thingy;

	#maybe it's already a name, might have to translate it
	if( _is_name $thingy )
		{
		my $Z = _get_Z_by_name( $thingy );
		return _get_name_by_Z( $Z, $language );
		}

	#we were passed something wierd.  pretend we don't know anything.
	return;
	}


sub _get_name_by_symbol
	{
	my $symbol   = shift;

	return unless _is_symbol $symbol;
	
	my $language = defined $_[0] ? $_[0] : $Default_language;

	my $Z = _get_Z_by_symbol($symbol);
	
	return _get_name_by_Z( $Z, $language );
	}

sub _get_name_by_Z
	{
	my $Z        = shift;
	my $language = defined $_[0] ? $_[0] : $Default_language;
	
	return unless _is_Z $Z;

	#not much we can do if they don't pass a proper number
	# XXX: check for language?
	return $names{$Z}[$language];
	}

sub get_Z
	{
	my $thingy = shift;

	croak "Can't call get_Z on object. Use Z instead" if ref $thingy;
			
	#since we were asked for a name, we'll suppose that we were passed
	#either a chemical symbol or a Z.
	return _get_Z_by_symbol( $thingy ) if _is_symbol( $thingy );
	return _get_Z_by_name( $thingy )   if _is_name( $thingy );

	#maybe it's already a Z
	return $thingy                     if _is_Z( $thingy );

	return;
	}

# gets the proton number for the name, no matter which language it
# is in
sub _get_Z_by_name
	{
	my $name = lc shift;

	$names_to_Z{$name}; # language agnostic
	}

sub _get_Z_by_symbol
	{
	my $symbol = _format_symbol( shift );

	return $elements{$symbol} if exists $elements{$symbol};

	return;
	}

########################################################################
########################################################################
#
# the _is_* functions do some minimal data checking to help other
# functions guess what sort of input they received

########################################################################
sub _is_name { exists $names_to_Z{ lc shift } ? 1 : 0	}

########################################################################
sub _is_symbol
	{
	my $symbol = _format_symbol( $_[0] );
	
	exists $elements{$symbol} ? 1 : ();
	}

########################################################################
sub _is_Z { $_[0] =~ /^[123456789]\d*\z/ && exists $elements{$_[0]}  }

########################################################################
# _format_symbol
#
# input: a string that is supoosedly a chemical symbol
# output: the string with the first character in uppercase and the
#  rest lowercase
#
# there is no data checking involved.  this function doens't know
# and doesn't care if the data are valid.  it just does its thing.
sub _format_symbol { $_[0] =~ m/^[a-z]/i && ucfirst lc $_[0] }

########################################################################
# _format_name
#
# input: a string that is supoosedly a chemical element's name
# output: the string with the first character in uppercase and the
#  rest lowercase
#
# there is no data checking involved.  this function doens't know
# and doesn't care if the data are valid.  it just does its thing.
#
# this looks like _format_symbol, but it logically isn't.  someday
# it might do something different than _format_symbol
sub _format_name
	{
	my $data = shift;
	
	$data =~ s/^(.)(.*)/uc($1).lc($2)/e;

	return $data;
	}

########################################################################
sub AUTOLOAD
	{
	my $self = shift;
	my $data = shift;

	return unless ref $self;

	my $method_name = $AUTOLOAD;

	$method_name =~ s/.*:://;

	if( $data )                         
		{ # only add new method if they add data
	   	$self->{$method_name} = $data; 
	   	$self->_add_object_method( $method_name );
	   	}
	elsif( defined $self->{$method_name} ) { return $self->{$method_name}  }
	else                                   { return }

	}

1;

__END__

=head1 NAME

Chemistry::Elements - Perl extension for working with Chemical Elements

=head1 SYNOPSIS

  use Chemistry::Elements qw(get_name get_Z get_symbol);

  # the constructor can use different input
  $element = Chemistry::Elements->new( $atomic_number   );
  $element = Chemistry::Elements->new( $chemical_symbol );
  $element = Chemistry::Elements->new( $element_name    );

  # you can make up your own attributes by specifying
  # a method (which is really AUTOLOAD)
        $element->molar_mass(22.989) #sets the attribute
  $MM = $element->molar_mass         #retrieves the value

=head1 DESCRIPTION

There are two parts to the module:  the object stuff and the exportable
functions for use outside of the object stuff.  The exportable
functions are discussed in EXPORTABLE FUNCTIONS.

Chemistry::Elements provides an easy, object-oriented way to
keep track of your chemical data.  Using either the atomic
number, chemical symbol, or element name you can construct
an Element object.  Once you have an element object, you can
associate your data with the object by making up your own
methods, which the AUTOLOAD function handles.  Since each
chemist is likely to want to use his or her own data, or
data for some unforesee-able property, this module does not
try to be a repository for chemical data.

The Element object constructor tries to be as flexible as possible -
pass it an atomic number, chemical symbol, or element name and it
tries to create the object.

  # the constructor can use different input
  $element = Chemistry::Elements->new( $atomic_number );
  $element = Chemistry::Elements->new( $chemical_symbol );
  $element = Chemistry::Elements->new( $element_name );

once you have the object, you can define your own methods simply
by using them.  Giving the method an argument (others will be
ignored) creates an attribute with the method's name and
the argument's value.

  # you can make up your own attributes by specifying
  # a method (which is really AUTOLOAD)
        $element->molar_mass(22.989) #sets the attribute
  $MM = $element->molar_mass         #retrieves the value

The atomic number, chemical symbol, and element name can be
retrieved in the same way.

   $atomic_number = $element->Z;
   $name          = $element->name;
   $symbol        = $element->symbol;

These methods can also be used to set values, although changing
any of the three affects the other two.

   $element       = Chemistry::Elements->new('Lead');

   $atomic_number = $element->Z;    # $atomic_number is 82

   $element->Z(79);

   $name          = $element->name; # $name is 'Gold'

=head2 Instance methods

=over 4

=item new( Z | SYMBOL | NAME )

Create a new instance from either the atomic number, symbol, or
element name.

=item can( METHOD [, METHOD ... ] )

Returns true if the package or object can respond to METHOD. This
distinguishes between class and instance methods.

=item Z

Return the atomic number of the element.

=item name

Return the name of the element.

=item symbol

Return the symbol of the element.

=back

=head2 Exportable functions

These functions can be exported.  They are not exported by default. At the
moment, only the functional interface supports multi-language names.

=over 4

=item get_symbol( NAME|Z )

This function attempts to return the symbol of the chemical element given
either the chemical symbol, element name, or atmoic number.  The
function does its best to interpret inconsistent input data (e.g.
chemcial symbols of mixed and single case).

	use Chemistry::Elements qw(get_symbol);

	$name = get_symbol('Fe');     #$name is 'Fe'
	$name = get_symbol('fe');     #$name is 'Fe'
	$name = get_symbol(26);       #$name is 'Fe'
	$name = get_symbol('Iron');   #$name is 'Fe'
	$name = get_symbol('iron');   #$name is 'Fe'

If no symbol can be found, nothing is returned.

Since this function will return the symbol if it is given a symbol,
you can use it to test whether a string is a chemical symbol
(although you have to play some tricks with case since get_symbol
will try its best despite the case of the input data).

	if( lc($string) eq lc( get_symbol($string) ) )
		{
		#stuff
		}
	
You can modify the symbols (e.g. you work for UCal ;) ) by changing
the data at the end of this module.

=item get_name( SYMBOL|NAME|Z [, LANGUAGE] )

This function attempts to return the name the chemical element given
either the chemical symbol, element name, or atomic number.  The
function does its best to interpret inconsistent input data (e.g.
chemcial symbols of mixed and single case).

	$name = get_name('Fe');     #$name is 'Iron'
	$name = get_name('fe');     #$name is 'Iron'
	$name = get_name(26);       #$name is 'Iron'
	$name = get_name('Iron');   #$name is 'Iron'
	$name = get_name('iron');   #$name is 'Iron'

If there is no Z can be found, nothing is returned.

Since this function will return the name if it is given a name,
you can use it to test whether a string is a chemical element name
(although you have to play some tricks with case since get_name
will try its best despite the case of the input data).

	if( lc($string) eq lc( get_name($string) ) )
		{
		#stuff
		}

You can modify the names (e.g. for different languages) by changing
the data at the end of this module.

=item get_Z( SYMBOL|NAME|Z )

This function attempts to return the atomic number of the chemical
element given either the chemical symbol, element name, or atomic
number.  The function does its best to interpret inconsistent input data
(e.g. chemcial symbols of mixed and single case).

	$name = get_Z('Fe');     #$name is 26
	$name = get_Z('fe');     #$name is 26
	$name = get_Z(26);       #$name is 26
	$name = get_Z('Iron');   #$name is 26
	$name = get_Z('iron');   #$name is 26

If there is no Z can be found, nothing is returned.

Since this function will return the Z if it is given a Z,
you can use it to test whether a string is an atomic number.
You might want to use the string comparison in case the
$string is not a number (in which case the comparison
will be false save for the case when $string is undefined).

	if( $string eq get_Z($string) )
		{
		#stuff
		}

=back

The package constructor automatically finds the largest defined
atomic number (in case you add your own heavy elements).

=head2 AUTOLOADing methods

You can pseudo-define additional methods to associate data with objects.
For instance, if you wanted to add a molar mass attribute, you
simply pretend that there is a molar_mass method:

	$element->molar_mass($MM); #add molar mass datum in $MM to object

Similiarly, you can retrieve previously set values by not specifying
an argument to your pretend method:

	$datum = $element->molar_mass();

	#or without the parentheses
	$datum = $element->molar_mass;

If a value has not been associated with the pretend method and the
object, the pretend method returns nothing.

I had thought about providing basic data for the elements, but
thought that anyone using this module would probably have their
own data.  If there is an interest in canned data, perhaps I can
provide mine :)

=head2 Localization support

XXX: Fill this stuff in later. For now see the test suite

=head1 TO DO

I would like make this module easily localizable so that one could
specify other names or symbols for the elements (i.e. a different
language or a different perspective on the heavy elements).  If
anyone should make changes to the data, i would like to get a copy
so that i can include it in future releases :)

=head1 SOURCE AVAILABILITY

The source for this module is in Github:

	git://github.com/briandfoy/chemistry--elements.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2000-2008 brian d foy. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
