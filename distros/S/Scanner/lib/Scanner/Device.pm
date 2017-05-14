#================================ Device.pm ===================================
# Filename:  	       Device.pm
# Description:         Physical Page Class for Scanners.
# Original Author:     Dale M. Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:31:43 $ 
# Version:             $Revision: 1.2 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#==============================================================================
use strict;
use File::Spec;
use Fault::DebugPrinter;

package Scanner::Device;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

#==============================================================================
#				Class Methods
#==============================================================================
$Scanner::DEFAULT_SCANNER = "umax";

sub defaultScannerIs ($$) {
  my ($class, $scanner) = @_; 
  defined $scanner || return 0;
  if (Scanner::Device->_validateScanner ($scanner)) {
    $Scanner::DEFAULT_SCANNER = lc $scanner;
    
    # Apply a kludge for the hp5590. It cannot deal with 150dpi.
    my ($type) = (split ":", $scanner);
    if ($type eq "hp5590") {Scanner::Device->defaultDpiIs (200);}
    return 1;
  }
  return 0;
}

#------------------------------------------------------------------------------
$Scanner::DEFAULT_DPI = 150;

sub defaultDpiIs ($$) {
  my ($class, $dpi) = @_; 
  defined $dpi || return 0;
  if (Scanner::Device->_validateDpi ($dpi)) {
    $Scanner::DEFAULT_DPI = $dpi; return 1;
  }
  return 0;
}

#------------------------------------------------------------------------------
$Scanner::DEFAULT_PAGESOURCE = "flatbed";

sub defaultPageSourceIs ($$) {
  my ($class, $pgsrc) = @_; 
  defined $pgsrc || return 0;
  if (Scanner::Device->_validatePageSource ($pgsrc)) {
    $Scanner::DEFAULT_PAGESOURCE = lc $pgsrc;
    return 1;
  }
  return 0;
}

#------------------------------------------------------------------------------
$Scanner::DEFAULT_SHUTDOWN = 0;

sub defaultShutdownIs ($$) {
  my ($class, $shutdown) = @_; 
  $shutdown=0 if !defined ($shutdown);
  $Scanner::DEFAULT_DPI = $shutdown;
  return 1;
}

#------------------------------------------------------------------------------
# If there are Environment variables defined for $SCANNER or 
# $SCANNER_AUTO_SHUTDOWN, use them. This must be done after all the above set 
# up so this code will override the defaults.

if (defined $ENV{'SCANNER'})
  {Scanner::Device->defaultScannerIs  ($ENV{'SCANNER'});}

if (defined $ENV{'SCANNER_AUTO_SHUTDOWN'})
  {Scanner::Device->defaultShutdownIs ($ENV{'SCANNER_AUTO_SHUTDOWN'});}

#==============================================================================

sub new ($$) {
  my $class  = shift;
  my %params = @_;
  my $self   = bless {}, $class;
  
  # Order dependance: scanner type must be set before pagesource and dpi as 
  # the allowable values may be scanner dependant.
  #
  $self->_setScanner    (\%params) || return undef;
  $self->_setPageSource (\%params) || return undef;
  $self->_setDpi        (\%params) || return undef;
  
  $self->_initScanner   (\%params) || return undef;
  return $self;
}

#==============================================================================
#			Object Methods
#==============================================================================

sub scan ($$$) {
  my ($self,$page,$dpath)      = @_;
  
  my ($x,$y)                   = $page->ScanDimensions;
  my $pagetitle                = $page->pagetitle;
  my ($dpi,$dev,$pgsrc,$extra) = @$self{'dpi','scanner','pagesource','extra'};
  my $SourceArg                = ($pgsrc eq "NotApplicable") ? 
    "" : "--source $pgsrc ";
  my $tmpfile		       = File::Spec->catfile ($dpath,"tmp.pnm");
  my $dstfile		       = File::Spec->catfile ($dpath,"$pagetitle.jpeg");
  
  Fault::DebugPrinter->dbg1 
      ("scanimage --device-name=\"$dev\" --mode Color --resolution $dpi -x $x -y $y $SourceArg $extra > \"$tmpfile\" 2> /dev/null");
  
  system "scanimage --device-name=\"$dev\" --mode Color --resolution $dpi -x $x -y $y $SourceArg $extra > \"$tmpfile\" 2> /dev/null";
  
  if ($page->landscape) {
    system "convert -rotate -90 \"$tmpfile\" \"$dstfile\"";}
  else {
    system "convert             \"$tmpfile\" \"$dstfile\"";}
  
  unlink "$tmpfile";
  return 1;
}

#------------------------------------------------------------------------------

sub shutdown ($) {
  my $self = shift;
  if ($self->{'type'} eq "hp")     { }
  if ($self->{'type'} eq "umax")   { }
  if ($self->{'type'} eq "hp5590") { }
  
  # This is the only way I can turn off the lamp after we are done.
  if ($self->{'type'} eq "gt68xx") {
    system ("scanimage -d \"" . 
	    $self->{'scanner'} . 
	    "\" --lamp-off-at-exit=yes --dont-scan 2> /dev/null") ;
  }
  return 1;
}

#------------------------------------------------------------------------------

sub DESTROY ($) {
  my $self  = shift; 
  $self->shutdown if ($Scanner::DEFAULT_SHUTDOWN);
  return $self;}


#-----------------------------------------------------------------------------

sub info ($$) {
  my ($self,$str) = @_;
  my $u = $self->{'units'};

  printf "[Scanner]\n" . 
          "Scanner:                   %s\n" .
	  "Type:                      %s\n" .
	  "Device id:                 %s\n" .
	  "Page source:               %s\n" .
	  "Dots per inch:             %d\n",
	  $self->{'scanner'},
	  $self->{'type'},
	  $self->{'deviceid'},
	  $self->{'pagesource'},
	  $self->{'dpi'};
  return $self;
}

#==============================================================================
#			Internal Class Methods
#==============================================================================
# STUB METHODS. ALWAYS RETURNS TRUE FOR NOW.
		
sub _validateScanner    ($$) {shift;         my $s = lc shift; return 1;}
sub _validatePageSource ($$) {my $c = shift; my $p = lc shift; return 1;}
sub _validateDpi        ($$) {shift;         my $s = lc shift; return 1;}

#==============================================================================
#			Internal Object Methods
#==============================================================================
# All of these methods use an input parameter hash.
#------------------------------------------------------------------------------

sub _setScanner ($$) {
  my ($self, $params) = @_;
  my $scanner = (defined $params->{'scanner'}) ?
    lc $params->{'scanner'} : $Scanner::DEFAULT_SCANNER;
  $self->_validateScanner($scanner) || (return 0);
  
  @$self{'scanner','type','deviceid'} = ($scanner, split ":", $scanner,2);
  
  # Apply kludge for hp5590
  if ($self->{'type'} eq "hp5590") {Scanner::Device->defaultDpiIs (200);}
  
  return 1;
}

#------------------------------------------------------------------------------
# ASSUMES: _setScanner has been executed beforehand.

sub _setPageSource ($$) {
  my ($self, $params) = @_;
  my $extra           = "";
  my $pgsrc           = "NotApplicable";

  my $pagesource      = (defined $params->{'pagesource'}) ?
    lc $params->{'pagesource'} : $Scanner::DEFAULT_PAGESOURCE;

  # If we get something wierd, default to flatbed.
  $pagesource = "flatbed" 
    if (($pagesource ne "flatbad") and ($pagesource ne "adf"));

  # I do not know what XPA is
  # Normal|ADF|XPA [Normal]
  if ($self->{'type'} eq "hp") {
    $pgsrc = ($pagesource eq "flatbed") ? "Normal"   : "ADF";
    $extra = ""
  }
  # I do not know what ADF Duplex is... the backend cannot even handle
  # regular ADF. It scans one page and ejects the next two for no reason.
  # Flatbed|ADF|ADF Duplex [Flatbed]
  if ($self->{'type'} eq "hp5590") {
    $pgsrc = ($pagesource eq "flatbed") ? "Flatbed"  : "ADF";
    $extra = ""
  }
  # Flatbed [Flatbed]
  elsif ($self->{'type'} eq "umax") {
    $pgsrc = "Flatbed";
    $extra = "";
  }
  # I do not know how to make this option active.
  #Flatbed|Transparency Adapter [inactive]
  elsif  ($self->{'type'} eq "gt68xx") {
    $pgsrc = "NotApplicable";
    $extra = "--auto-warmup=yes --lamp-off-at-exit=no"
  }
  else {
    $pgsrc = "NotApplicable";
    $extra = "";
  }

  $self->_validatePageSource($pgsrc) || (return 0);
  $self->{'pagesource'} = $pgsrc;
  $self->{'extra'}      = $extra;
  return 1;
}

#------------------------------------------------------------------------------

sub _setDpi ($$) {
  my ($self, $params) = @_;
  my $dpi = (defined $params->{'dpi'}) ? 
    $params->{'dpi'} : $Scanner::DEFAULT_DPI;
  $self->_validateDpi($dpi) || (return 0);
  $self->{'dpi'} = $dpi;
  return 1;
}

#------------------------------------------------------------------------------
# Device specific setup, if any.

sub _initScanner ($$) {
  my ($self, $params) = @_;
  if ($self->{'type'} eq "hp")     { }
  if ($self->{'type'} eq "umax")   { }
  if ($self->{'type'} eq "hp5590") { }
  
  # This is the only way I can enable the lamp control features!
  if ($self->{'type'} eq "gt68xx") {$ENV{'SANE_DEBUG_GT68XX'}=1;}
  return 1;
}

#==============================================================================
#                       Pod Documentation
#==============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 Scanner::Device - Class to control scanner hardware via SANE scanimage CLI.

=head1 SYNOPSIS

 use Scanner::Device;

 $obj  = Scanner::Device->new ( hashargs );
 $bool = Scanner::Device->defaultScannerIs    ($scanner);
 $bool = Scanner::Device->defaultDpiIs        ($dpi);
 $true = Scanner::Device->defaultShutdownIs   ($bool);
 $bool = Scanner::Device->defaultPageSourceIs ($pgsrc);
 $bool = $obj->scan ($pgobj,$dpath);
 $bool = $obj->shutdown;

=head1 Inheritance

 UNIVERSAL

=head1 Description

Creates Scanner::Device objects that represent a scanner to which Scanner::Page
objects may be passed for scanning.

=head1 Examples

 use Scanner::Device;
 use Scanner::Device::Page;
 my $bool = Scanner::Device->defaultScannerIs    ("hp:libusb:001:010");
    $bool = Scanner::Device->defaultDpi          (150);
    $bool = Scanner::Device->defaultPageSourceIs ("adf");

 my $scanner = Scanner::Device->new;
 my $pg      = Scanner::Page->new ( 'date'   => "20040830",
                                    'title'  => "DailyBoggle",
                                    'pageid' => "001",
                                  );
 my $bool    = $scanner->scan     ( $pg );

=head1 Class Variables

 $Scanner::DEFAULT_SCANNER	Default is "umax". If there is an $SCANNER
                                Environment variable, that value will be used 
                                instead.

 $Scanner::DEFAULT_DPI          Default is 150 dpi. If the Scanner is an 
                                hp5590, it will be set to 200 dpi instead.

 $Scanner::DEFAULT_PAGESOURCE   Default source is "flatbed".

 $Scanner::DEFAULT_SHUTDOWN     Default is false, for no shutdown.

=head1 Instance Variables

 scanner    Default device is "umax" or the contents of the Environment 
            variable $SCANNER. It can also be a usb device like 
            "hp:libusb:001:01"

 type       The device type portion of the scanner string.

 deviceid   The device address portion of the scanner string.

 pagesource Default page source is "flatbed". It can be either 'flatbed'
            or 'adf' for automatic document feeder. This value will be used 
	    to select the best available and possibly device specific internal 
            setting for 'devpgsrc', as allowed by scanimage.

 devpgsrc   Best match to requested 'pagesource' that is available on the
            scanner 'type'.

 extra      Type dependant args. These are set automatically based on 'type'.

 dpi        Default value of dots per inch is 150. scanimage measure pages in
            mm and uses dpi to measure resolution. Don't ask me, ask them.

=head1 Environment Variables

 $SCANNER   If defined and if it contains a valid scanner device string at 
	    load time, it will be used as the default scanner.

 $SCANNER_AUTO_SHUTDOWN
            If defined at load time, it will be used as the default boolean 
	    value for $Scanner::DEFAULT_SHUTDOWN.

=head1 Class Methods

Note that argument validity checking is not implimented yet.

=over 4

=item B<$bool = Scanner::Device-E<gt>defaultScannerIs ($device)>

Set the default device for the Scanner::Device class. The device string
may be anything allowed by the scanimage program. You can find
out what is available using the command:

 scanimage -L

If the device argument is missing, the value defaults to "umax" for
no better reason than that is was the scanner I had when I first
wrote this code. 

If the device is an hp5590, the default dpi setting is raised from
150 dpi to 200 dpi since that scanner does not have a 150 dpi setting.

Returns true on success and false if there is no arg or it is not a 
scanner device string.

=item B<$bool = Scanner::Device-E<gt>defaultDpiIs ($dpi)>

Set the default dots per inch for the Scanner::Device Class. The dpi integer 
may be anything allowed by the scanner.

Returns true on success and false if there is no arg or it is not a 
valid dpi value.

=item B<$bool = Scanner::Device-E<gt>defaultPageSourceIs ($pgsrc)>

Set the Class default scanner page source. Flatbed/Normal or ADF (automatic 
document feeder). "flatbed" or "normal" means the scanner table; "adf" means
use an automatic document feeder. 

Note that at object-creation time the appropriate device 
tupe dependant pseudonym of flatbed or normal will be used regardless of 
which was named the default.

The page source string will in some cases be internally mapped to scanner 
specific equivalents, for example flatbed=>normal for some HP scanners.
Either flatbed or normal is acceptable on input. The appropriate
one will be used when actually communicating with the scanner.

Returns true on success and false if there is no arg or it is not a 
valid page source.

=item B<$bool = Scanner::Device-E<gt>defaultShutdownIs ($boolean)>

Set the default for shutdown after a scan. 1 means carry out special shutdown
such as turning off the lamp, if required; 0 or undef means do not do so. It
is often useful not to do a shutdown if you are scanning multiple pages as it
can slow down your scanning immensely.

The $boolean arg should be 1 or 0 to make things easier to understand, but 
it can be absolutely anything. whatever it is will be interpreted as true
or false, ie "anystring" is true; "" is false, undef is false, etc.

Always returns true.

=item B<$obj = Scanner::Device-E<gt>new (scanner =E<gt> $devicestr, pagesource =E<gt> $src, dpi =E<gt> $dpi>

This is the Class method for creating new Scanner::Device objects and has 
three option args:

  scanner    => scanner type as returned by 
                "scanimage -L" [OPT: default is "umax"]

  pagesource => flatbed|adf. Any other value will be changed to flatbed.
                [OPT: default is "flatbed"]

  dpi        => integer [OPT: default is 150 dpi]

It returns either a pointer to the newly created and initialized object
or undef if the object could not be created.

=back 4

=head1 Instance Methods

=over 4

=item B<$bool = $obj-E<gt>scan ($pageobj,$dpath)>

Scan the page identified by the pageobj and create an appropriately named file 
at $dpath. The $dpath location must be a directory that is writeable to the 
user.

Returns true if it succeeds.

If debug is enabled, it will print the generated scanimage command line before
executing it.

=item B<$bool = $obj-E<gt>shutdown>

Turn the scanner off if it is a type which requires special handling that we
know about. Only used for Mustek at the moment, noop otherwise.

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

 Scanner::Page, Scanner::Format.

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: Device.pm,v $
# Revision 1.2  2008-08-28 23:31:43  amon
# Major rewrite. Shuffled code between classes and add lots of features.
#
# Revision 1.1  2008-08-25 19:58:36  amon
# Changed name of Scanner.pm to Scanner/Device.pm
#
# Revision 1.3  2008-08-19 15:06:07  amon
# Added SCANNER_AUTO_SHUTDOWN Env variable. Also send scan shutdown output to
# dev null. Use unlink instead of system call to rm; changes to handle updates
# in Page class.
#
# Revision 1.2  2008-08-07 19:52:16  amon
# Upgrade source format to current standard.
#
# Revision 1.1.1.1  2008-01-20 17:59:30  amon
# Classes for scanner use abstractions.
#
# 20070506	Dale Amon <amon@islandone.org>
#		Add support for hp5590 SANE backend.
#
# 20070501	Dale Amon <amon@islandone.org>
#		Added support for $SCANNER environment variable.
#
# 20060615	Dale Amon <amon@islandone.org>
#		Added code to set the Environment variable required by the mustek
#		to get at most of the special features like lamp control.
#
# 20060416	Dale Amon <amon@islandone.org>
#		I patched the code 'temporarily' around 20051024 because
#		the Mustek A3 USB does not accept the --source option and
#		cannot be shut up over it. I now have sorted that problem
#		out by adding a source type of "NotApplicable" which suppresses
#		the --source entirely.
#
# 20050825	Dale Amon <amon@islandone.org>
#		Umax uses flatbed where hp used normal. I generalized
#		_setPageSource to convert one to the other depending on
#		the type, hp or umax. Type is now parsed from the scanner
#		string by _setScanner. Also fixed some minor bugs in
#		the mostly unused default*****Is class methods.
#
# 20050710	Dale Amon <amon@islandone.org>
#		Made dpi a modifiable default. A couple weeks ago I
#		also added scanner type and document source option
#		support, although with stubs on the validation 
#		routines.
#
# 20050228	Dale Amon <amon@islandone.org>
#		BAD NEWS: scanimage just de-generalized and
#		has made things like resolution and colour
#		into device specific parameters! I've had to lock this
#		down to work only on Umax so I can get work done!
#		*** MUST REGENERALIZE ****
#
# 20040819	Dale Amon <amon@islandone.org>
#		Created.
#
1;
