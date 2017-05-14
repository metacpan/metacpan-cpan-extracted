#================================ Format.pm ==================================
# Filename:  	       Format.pm
# Description:         Page Scan Format Class.
# Original Author:     Dale M. Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-09-24 19:18:03 $ 
# Version:             $Revision: 1.2 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;

package Scanner::Format;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

#=============================================================================
#				CLASS METHODS
#=============================================================================
$Scanner::Format::DEFAULT_UNITS = undef;

sub defaultUnitsAre ($$) {
  my ($class, $units) = @_; 
  defined $units || return 0;
  if (Scanner::Format->_validateUnits ($units)) {
      $Scanner::Format::DEFAULT_UNITS = lc $units;
      return 1;
  }
  return 0;
}

#-----------------------------------------------------------------------------
$Scanner::Format::DEFAULT_FORMAT = undef;

sub defaultFormatIs ($$) {
  my ($class, $format) = @_; 
  defined $format || return 0;
  
  my ($t,$w,$h) = Scanner::Format->_validateFormat ($format);
  $t || return 0;

  $Scanner::Format::DEFAULT_FORMAT = $format;
  return 1;
}

#-----------------------------------------------------------------------------
$Scanner::Format::DEFAULT_CALIBRATOR = 0;

sub setDefaultCalibratorFlag {$Scanner::Format::DEFAULT_CALIBRATOR = 1;}
sub clrDefaultCalibratorFlag {$Scanner::Format::DEFAULT_CALIBRATOR = 0;}

#-----------------------------------------------------------------------------

sub new {
    my $class  = shift;
    my %params = @_;
    my $self   = bless {}, $class;

    $self->_setPaperSpecs  (\%params) || return undef;
    $self->_setCalibrator  (\%params) || return undef;

    return $self;
}

#=============================================================================
#                          INSTANCE METHODS                                 
#=============================================================================

sub info ($$) {
  my ($self,$str) = @_;
  my $u           = $self->{'units'};
  my ($pw,$pl)    = $self->UserDimensions;
  my ($sw,$sl)    = ($self->_unconvertLength ($u,$self->{'width'}),
		     $self->_unconvertLength ($u,$self->_actualHeight));

  printf  "[$str Format]\n" . 
	  "Format string:             %s\n" .
	  "Scan orientation:          %s\n" .
	  "Paper type:                %s\n" .
	  "Scan width:                %6.2f %s\n" .
	  "Scan length:               %6.2f %s\n" .
	  "Calibrator margin:         %s\n" .
	  "Total scan width:          %6.2f %s\n" .
	  "Total scan length:         %6.2f %s\n",
	  $self->{'format'}, 
	  ($self->{'orientation'} eq "P") ? "Scanner top is page top." :
	                                    "Scanner left is page top.",
	  ucfirst $self->{'papertype'},
	  $pw, $self->_unitsPrintString ($pw), 
	  $pl, $self->_unitsPrintString ($pl), 
	  ($self->{'calibrator'})         ? "On"      : "Off",
	  $sw, $self->_unitsPrintString ($sw), 
	  $sl, $self->_unitsPrintString ($sl);

  return $self;
}

#-----------------------------------------------------------------------------

sub ScanDimensions ($) {
  my $self = shift; 
  return ($self->{'width'}, $self->_actualHeight);
}

sub UserDimensions ($) {
  my $self = shift; 
  my $u    = $self->{'units'};
  my $w    = $self->_unconvertLength ($u,$self->{'width'});
  my $h    = $self->_unconvertLength ($u,$self->{'height'});
  return ($w,$h);
}

sub landscape   ($) {shift->{'orientation'} eq "L";}
sub portrait    ($) {shift->{'orientation'} eq "P";}
sub orientation ($) {shift->{'orientation'};}
sub format      ($) {shift->{'format'};}

#=============================================================================
#			INTERNAL CLASS METHODS
#=============================================================================
#                         Orientation    Description
#------------------------------------------------------
$Scanner::Format::Orientation = { "L"   => "Landscape", 
			          "P"   => "Portrait"
			    };
sub _validateOrientation ($$) { 
  shift; my $o = uc shift;
  return exists $Scanner::Format::Orientation->{$o};
}

#-----------------------------------------------------------------------------
#                              Unit     Units per mm
#------------------------------------------------------
$Scanner::Format::PaperUnits = { "mm"       =>  1.0,
			         "mm's"     =>  1.0,
			         "mms"      =>  1.0,
			         "inch"     => 25.4, 
			         "inches"   => 25.4
			       };
sub _validateUnits ($$) { 
  shift; my $u = lc shift;
  return exists $Scanner::Format::PaperUnits->{$u};
}


#-----------------------------------------------------------------------------
# It returns a list (type,width,height), which may all be undef.
#
#                               Type         width(mm)  height(mm)
#-----------------------------------------------------------------
$Scanner::Format::PaperSpecs = { "a4"       => [8.5*25.4, 12.0*25.4], 
			         "letter"   => [8.5*25.4, 11.0*25.4],
			         "legal"    => [8.5*25.4, 13.0*25.4]
			       };

sub _validatePaperSpecs ($$) {
    shift; my $p = lc shift;
    return exists $Scanner::Format::PaperSpecs->{$p};
}

sub _paperSpecs ($$) {
    shift; my $p = lc shift;
    return ($p, @{ $Scanner::Format::PaperSpecs->{$p} });
}

#-----------------------------------------------------------------------------

sub _validateFormat ($$) {
    my ($self, $format) = @_;

    my ($o,$w,$l) = split /[:x]/, $format, 3;

    $self->_validateOrientation(uc $o) || (return (undef,undef,undef));
    
    if ($w =~ /^[[:digit:].]*$/) { 
      return (undef,undef,undef) if ($w  <= 0.0);
      return (undef,undef,undef) if ($l  <= 0.0);
      return (undef,undef,undef) if ($l !~ /^[[:digit:].]*$/);
    }
    else {
      return (undef,undef,undef) if (!$self->_validatePaperSpecs ($w));
    }      
    return ($o,$w,$l);
}

#-----------------------------------------------------------------------------
# Convert a length from the current unit into the internally used mm. The unit
# type is used to look up a conversion factor in the unit's hash.

sub _convertLength ($$$) {
    my ($s,$u,$l) = @_;
    return $Scanner::Format::PaperUnits->{$u} * $l;
}

#-----------------------------------------------------------------------------

sub _unconvertLength ($$$) {
    my ($s,$u,$l) = @_;
    return $l / $Scanner::Format::PaperUnits->{$u};
}

#-----------------------------------------------------------------------------

my $UnitSingular = { "mm"       =>  "mm",
		     "mm's"     =>  "mm",
		     "mms"      =>  "mm",
		     "inch"     =>  "inch", 
		     "inches"   =>  "inch"
		   };
		      
my $UnitPlural  = { "mm"       =>  "mm's",
		    "mm's"     =>  "mm's",
		    "mms"      =>  "mm's",
		    "inch"     =>  "inches", 
		    "inches"   =>  "inches"
		  };

sub _unitsPrintString ($$) {
  my ($s,$l) = @_;
  my $u      = $s->{'units'};
  return ($l eq 1) ? $UnitSingular->{$u} : $UnitPlural->{$u};
}

#=============================================================================
#			INTERNAL OBJECT METHODS
#=============================================================================
# Convert a length into the current unit. The unit type is used to look up
# a conversion factor in the unit's hash. It returns the height to be scanned
# which includes extra inch if calibrator is true.

sub _actualHeight ($) {
    my $self = shift; 
    return $self->{'height'} + (($self->{'calibrator'}) ? 25.4 : 0.0);
}

#-----------------------------------------------------------------------------

sub _setPaperSpecs ($$) {
    my ($self, $params) = @_;
    my ($u,$p,$o,$w,$l);

    $u = (defined $params->{'units'}) ? 
      lc $params->{'units'} : $Scanner::Format::DEFAULT_UNITS;
    return 0 if (!$self->_validateUnits($u));

    my $format = (defined $params->{'format'}) ? 
      $self->{'format'} = $params->{'format'} :
	$Scanner::Format::DEFAULT_FORMAT;

    ($o,$w,$l) = $self->_validateFormat($format);
    return 0 if (!defined $o);

    # Convert external units to internally used mm.
    if ($w =~ /^[[:digit:].]*$/) { 
      ($p,$w,$l) = ("undefined",
		    $self->_convertLength ($u, $w),
		    $self->_convertLength ($u, $l));
    }
    # Internal units are already in mm.
    else {
      ($p,$w,$l) = $self->_paperSpecs ($w);
    }      

    @$self{'format','units','orientation','papertype','width','height'} = 
      ($format, lc $u, uc $o,$p,$w,$l);
    return 1;
}

#-----------------------------------------------------------------------------

sub _setCalibrator ($$) {
    my ($self, $params) = @_;

    my $calibrator = (defined $params->{'calibrator'}) ?
	$params->{'calibrator'} : $Scanner::Format::DEFAULT_CALIBRATOR;
    $self->{'calibrator'} = ($calibrator) ? 1 : 0;
    return 1;
}

#=============================================================================
#			Set Class Runtime Defaults
#=============================================================================

Scanner::Format->defaultUnitsAre ("mm");
Scanner::Format->clrDefaultCalibratorFlag;
Scanner::Format->defaultFormatIs ("P:A4");

#=============================================================================
#                          POD DOCUMENTATION                                
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 Scanner::Format - Page Scan format class.

=head1 SYNOPSIS

 use Scanner::Format;

 $obj  = Scanner::Format->new ( list of named arguments );
         Scanner::Format->setDefaultCalibratorFlag;
         Scanner::Format->clrDefaultCalibratorFlag;
 $bool = Scanner::Format->defaultUnitsAre ( $myunits );
 $bool = Scanner::Format->defaultFormatIs ( $myformat );

 ($width, $height) = $obj->ScanDimensions;
 ($width, $height) = $obj->UserDimensions;
 $flg              = $obj->landscape;
 $flg              = $obj->portrait;
 $str              = $obj->orientation;
 $str              = $obj->format;
 $obj              = $obj->info ($str);

=head1 Inheritance

 UNIVERSAL

=head1 Description

This class is a representation of a format of a page.

=head1 Examples

 use Scanner::Format;

 my $flg = Scanner::Format->defaultUnitsAre ( "Inches" );
    $flg = Scanner::Format->defaultFormatIs ( "P:Letter" );
           Scanner::Format->setDefaultCalibratorFlag;

 my $obj    = Scanner::Format->new ('format' => "P:8.5x13.0");
 my ($x,$y) = $obj->ScanDimensions;

 if ($obj->landscape) {print "It is a landscape format.\n";}
 if ($obj->portrait ) {print "It is a portrait  format.\n";}

=head1 Class Variables

 DEFAULT_UNITS              Assume arguments to every new are in 
                            this unit. Default is mm.
 DEFAULT_FORMAT             If a new method does not specify a format
                            assume this format. Default is a Portrait
                            A4 page, ie 215.9 x 304.8 mm.
 DEFAULT_CALIBRATOR         Flag whether an extra inch or 25.4 mm
                            should be added to the bottom to allow for
                            calibration tools below the page. Default is 
                            off.

=head1 Instance Variables

 format         page format string
 calibrator     Flag  indicating whether extra space is left at the bottom.
 orientation    L for landscape and P for Portrait.
 height         Height of the page in default units, usually mm.
 width          Width of the page in default units, usually mm.
 papertype      a4, letter, etc. May be undefined.

=head1 Class Methods

=over 4

=item B<$obj = Scanner::Format-E<gt>new ( named argument list )>

This is the Class method for creating new Scanner::Format objects. It may have
many different arguments. They are in short:

		format     -> string          {OPT: default is "P:A4"]
		calibrator -> boolean         [OPT: default is 1]
		units      -> mm|inches       [OPT: default is "mm"]

'calibrator' => <boolean>

If set, add an extra inch below the page. The default value is false.

'units' => <units>

Sets the unit of measure to be used when interpreting the width and height
parameters. Current choices are "mm" and "inches". The default value is "mm"
since that is what the 'scanimage' program uses.

'format'     => <formatstring>

A format string has two or 3 fields:

  <formatstring> := <orientation>:<papertype> | 
                    <orientation>:<scanwidth>x<scanheight>

where:

 <orientation>: is the page placement on the scanner, either L for landscape or 
                P for portrait.

 <papertype>:   allowed values at present are a4, letter and legal (case is ignored).

 <scanwidth>:   scan width of the page in the current units of measure and must be 
                greater than zero.

 <scanheight>:  scan height of the page in the current units of measure and must be 
                greater than zero.

All fields are case insensitive.

The default value is a portrait oritentation of an a4 paper type. The size is 
8.5 inch * 25.4 mm/inch across the width of the scanner and 12.5 inch * 25.4 mm/inch down 
the length of the scanner.

'date' => <date string>

A date to be included as the first part of the page name, where a  single date
is represented as:

	yyyymmdd
	yyyymmddhhmmss

and mm and dd may be 00 to represent 'the whole month' or the  'whole year' as
in a monthly magazine or a yearly report, or to  represent uncertainty, 'it
was from sometime in that year'. there may optionally be two dates, so as to
represent a period  of time associated with the page:

	date1-date2

=item B<Scanner::Format-E<gt>setDefaultCalibratorFlag>

Setting this will make every object created add an extra inch below each page
unless specifically overridden by 'calibrator' => 0 when a new object is
created.

The intent of this option is to leave space for placement of a 
size/color/aspect-ratio calibration devices in the scan field of view. Common
image calibration devices are small color wheels, rulers, little  square
things like you see in photos by field Geologists, or perhaps a round coin to
show aspect ratios. Such calibrators act are a permanent means of mapping an
image to its real world original.

The feature is turned off by default. It may either be set on by default with
this Class method, or turned on explicitly for particular page objects.

=item B<Scanner::Format-E<gt>clrDefaultCalibratorFlag>

The converse of the above. Since this is the default condition of the Class,
you will only need to run this if you have executed a setDefaultCalibratorFlag
somewhere in your code.

=item B<$bool = Scanner::Format-E<gt>defaultUnitsAre ( $units )>

Set the default units for height and width input values. Legal inputs are "mm"
and "inches". Case is ignored. Any other value causes a false return.

If you do nothing, the class default is "mm" because the scanimage program
assumes metric.

Returns true on success; false if no arg or it wasn't one of the two valid
options.

=item B<$bool = Scanner::Format-E<gt>defaultPaperTypeIs ( $papertype )>

Set the default paper type. Legal values are "a4", "letter" or  "legal". Case
is ignored. Any other value causes a false return.

If you do nothing, the class default is "a4". Why? Because we used metric for
the units default. Consistency is next to godliness I always say.

=back 4

=head1 Instance Methods

=over 4

=item B<$str = $obj-E<gt>format>

Return the current page scan format string.

=item B<$flg = $obj-E<gt>info ($str)>

Print a block of informational text to stdout:

    [$str Format]
    Format:		        P:8.5x12
    Scan Orientation:		P
    Paper type:		        undefined
    Scan width:		        8.5 Inches
    Scan length:		12 Inches
    Image Calibrator Margin:	0 Iinches

=item B<$flg = $obj-E<gt>landscape>

Return true if it uses a landscape page format.

=item B<$flg = $obj-E<gt>orientation>

Return the orientation string, "L" or "P".

=item B<$flg = $obj-E<gt>portrait>

Return true if it uses a portrait page format.

=item B<($width, $height) = $obj-E>gt>ScanDimensions>

Retrieve the page dimensions to be used for scanning. The height may include
extra space for calibration devices as earlier discussed in the
Scanner::Format->setDefaultCalibratorFlag section:

	(width, height+calibratorheight)

The scanner might of course have something to say about the height or width we
have selected! That, however, is not the Format's problem. It is what it is
and it might be too large for the scanner you have.

=item B<($width, $height) = $obj-E>gt>UserDimensions>

Retrieve the page dimensions as originally supplied by the user.

=back 4

=head1 Private Class Methods

 None.

=head1 Private Instance Methods

 None.

=head1 Errors and Warnings

 None.

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

 None.

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: Format.pm,v $
# Revision 1.2  2008-09-24 19:18:03  amon
# Fix bug in info method printout; improve formating of info output.
#
# Revision 1.1  2008-08-28 23:31:43  amon
# Major rewrite. Shuffled code between classes and add lots of features.
#
# Revision 1.2  2008-08-07 19:52:48  amon
# Upgrade source format to current standard.
#
# Revision 1.1.1.1  2006-06-15 22:06:59  amon
# Classes for scanner use abstractions.
#
# 20060615	Dale Amon <amon@islandone.org>
#		Added check for an attempt to set a zero height or width.
# 20040818	Dale Amon <amon@islandone.org>
#		Created.
1;
