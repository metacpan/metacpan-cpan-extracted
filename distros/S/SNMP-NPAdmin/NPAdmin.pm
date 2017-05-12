package SNMP::NPAdmin;
#
# prerequisites:
#  UCD SNMP v4.2.0
#  SNMP module v4.2.0
#  Printer MIB and HP MIB (provided)
#
# assumptions
#  1. only SNMPv1 will be supported initially
#  2. only mib-2 and printmib will be supported initially
#  3. SNMPv2 support will be added later
#  4. private mib support will be added after printmib support is complete
#
#  a. incorporated an HP JETDIRECT MIB that I found
#
# types of queries
#	boolean
#	max/min
#	data, list format, i.e. a hash
#	data, table format, i.e. a list of hashes

require 5.005_03;

use strict;
use vars qw/ $VERSION $CVSver @ISA $AUTOLOAD
	$DEBUG
	$VERBOSE
	%vendors
	%language_map
	$language_code
	%filter_map
	$filter_code
	%answer_map
	@paper_sizes
	$paper_sizes_indexed
	$answer_code
	/;

$VERSION = '1.0';
$CVSver= '$Id: NPAdmin.pm,v 1.23 2002/11/15 03:57:23 bozzio Exp $';

use SNMP::NPAdmin::Neon;

##################################### PODs

=pod

=head1 NAME

SNMP::NPAdmin - high-level API to query printers via SNMP

=head1 SYNOPSIS

  # object-oriented
  $p= SNMP::NPAdmin->new(
	printer		=> 'porky',
	community	=> 'corpslp'
	);
  printf "Your printer, %s, does%s support PCL.\n",
	$printer, ( $p->pcl() ? "" : " not");

  # procedural
  $p= npa_connect(
	printer		=> 'porky',
	community	=> 'corpslp'
	);
  printf "Your printer, %s, does%s support PCL.\n",
	$printer, ( npa_pcl( $p) ? "" : " not");

=head1 DESCRIPTION

The C<SNMP::NPAdmin> package is a complete port of a SNMP/printer utility called C<npadmin> that provides a high-level interface to query printers via SNMP
without specific knowledge of SNMP MIBs or the printer's vendor-specific configuration.

The original C<npadmin> was written in C++ by Ben Woodard who continues to maintain it on SourceForge.

The primary objective in this port is to have a B<maintainable> and B<extensible> version of the same functionality that the original C<npadmin> provides.

It is B<not> optimized for performance at all; it is optimized for B<extensibility> and B<maintainability>.
The original C<npadmin> is very much extremely performance, the idea being to query many printers very quickly, especially since SNMP can be quite slow.

To be fair, C<SNMP::NPAdmin> might even be slow by Perl standards due to the extensive use of run-time compilation through the AUTOLOAD subroutine.
I don't necessarily believe this since a programmer/sys-admin frequently will not use all of the available methods/subroutines which would typically
be compiled during startup; given that only a few methods/subroutines will be called, then only a few will be compiled during the process's lifetime.
Probably the difference in speed due to this will be insignificant either way. 

The design was chosen in order to get as much information into a maintainable table format and make the logic as generic as possible; not for speed.

So this is your choice.  If you have some unsupported printers and you want to be able to modify the code to support them then use C<SNMP::NPAdmin>.
If you need to support B<a lot> of printers continuously with this kind of utility then you should use Ben Woodard's C<npadmin>.

=head1 THE PACKAGE

The C<SNMP::NPAdmin> package is composed of a module, C<SNMP::NPAdmin>, and a script, C<npadmin.pl>.
The heart of this package is the C<SNMP::NPAdmin> module.
Everything happens in the module.
All that the script does is parse command-line arguments, call the C<SNMP::NPAdmin> module and report the results.
Actually, two modules are provided; but only one is publicly available.
I will not even tell you its name; you can find it yourself if you're so curious.

The script is provide for two reasons.
The first is to fulfill the original objective of writing a Perl-version of C<npadmin> which is a command-line utility.
The second is to provide an example script.

=head1 THE INTERFACE:  OBJECT-ORIENTED OR PROCEDURAL?  BOTH!

While writing this module, I received a lot a negative feedback about using OO techniques.
Therefore I decided to ensure that it could be used by using both OO and procedural techniques.

It is probably true that most modules/classes are similarly Janus-faced since Perl always passes the object-reference (or class name) as the first argument.
That is not so different from the way many procedural libraries work, particularly those that establish some kind of state such as network connections:
initiate a connection and pass the returned struct to future library calls as the first argument.

B<NOTE!>   B<NOTE!>   B<NOTE!>   B<NOTE!>   B<NOTE!>

The procedural API is not been fully implemented yet.  But it is the current task and should be complete soon.

=cut

##################################### class method POD: new

=pod

=head1 CLASS METHODS

=head2 THE CONSTRUCTOR

=over 4

=item B<C<SNMP::NPAdmin-E<gt>new()>>

This is the constructor (duh!).  It returns an C<SNMP::NPAdmin> object which can then be queried with the object methods that are described below.
For arguments, a hash is used which can include values for five keys: C<printer>, C<community>, C<port>, C<timeout> and C<retries>.  The C<printer>
key is required; the constructor B<will> fail without it.

	$P= SNMP::NPAdmin->new(
		printer		=> 'mega-print',
		community	=> 'myhouse',
		);

=item B<C<npa_connect()>>

This is the procedural call to start a C<SNMP::NPAdmin> session for a specific printer.  It accepts the same arguments and returns the same results as
the constructor.  I didn't bother B<not> blessing the reference just for a procedural call.  It will still work when it is passed to the query subroutines.

	$P= npa_connect(
		printer		=> 'mega-print',
		community	=> 'myhouse',
		);

=back

=cut

##################################### new

sub new
{
#warn "new";
  my $class= shift;
  my %options= @_;
  my $self;

  $self->{boolean}= $options{boolean}
     ? delete $options{boolean}
     : [ qw/ 0 1 / ]
     ;

  $self->{Neon}= SNMP::NPAdmin::Neon->new( @_);

  return undef if ! $self->{Neon};

  bless $self, $class;
  return $self;
}

##################################### class method POD: version

=pod

=over 4

=item B<C<SNMP::NPAdmin-E<gt>version()>> or B<C<npa_version()>>

This method returns the version of SNMP::NPAdmin that is being used.

=back

=cut

##################################### version

sub version
{
#warn "version";
  return $VERSION;
}

##################################### class method POD: verbose

=pod

=over 4

=item B<C<SNMP::NPAdmin-E<gt>verbose()>> or B<C<npa_verbose()>>

This method toggles the 'verbose' flag for the entire class.
All objects will verbosely report its progress during execution of any methods.
The previous value of the 'verbose' flag is returned.
Currently, the 'verbose' flag is ineffectual.

=back

=cut

##################################### verbose

sub verbose
{
#warn "verbose";
  my $class= shift;
  my $value= shift;

  if ( defined $value )
  {
    $VERBOSE= $value;
  }
  else
  {
    $VERBOSE |= 1;
  }
}

##################################### class method POD: debug

=pod

=over 4

=item B<C<SNMP::NPAdmin-E<gt>debug()>> or  B<C<npa_debug()>>

This method toggles the 'debug' flag for the entire class.
All objects will report in painful detail everything that is happening during a SNMP::NPAdmin method call.
The previous value of the 'debug' flag is returned.
Currently, the 'debug' flag is ineffectual.

=back

=cut

##################################### debug

sub debug
{
#warn "debug";
  my $class= shift;
  my $value= shift;

  if ( defined $value )
  {
    $DEBUG= $value;
  }
  else
  {
    $DEBUG |= 1;
  }
}

##################################### class method POD: debugsnmp

=pod

=over 4

=item B<C<SNMP::NPAdmin-E<gt>debugsnmp()>> or B<C<npa_debugsnmp()>>

This method toggles the 'debugsnmp' flag for all objects/sessions.
All objects will report in excruciating detail everything that happens during all actual SNMP transactions.
This flag is actually used by the underlying SNMP module.  It does work and very well.

=back

=cut

##################################### debugsnmp

*debugsnmp= *SNMP::NPAdmin::Neon::debugsnmp;

##################################### DESTROY

sub DESTROY {};

##################################### object PODs

=pod

=head1 OBJECT METHODS

=head2 MIB queries

The MIB queries determine whether or not the queried printer supports the MIB in question.
Currently, SNMP::NPAdmin only asks about the Printer-MIB and the Host-Resources-MIB.

=over 4

=item B<C<$P-E<gt>printmib()>> or B<C<npa_printmib( $P)>>

 Answers the question, "Does the printer support the Printer-MIB?"

=item B<C<$P-E<gt>hostmib()>> or B<C<npa_hostmib( $P)>>

 Answers the question, "Does the printer support the Host-Resources-MIB?"

=back

=over 4

=head2 Information queries

The information queries provide information that requires additional processing in addition to merely querying the printer for data.
For most of these, this does involve simply querying the printer and reporting the results.
The ones that do require this kind of heuristics are C<vendor()>, C<model()>, C<netconfig()>, C<enginespeed()>, C<maxpapersize()>, C<minpapersize()>.

=item B<C<$P-E<gt>contact()>> or B<C<npa_contact( $P)>>

Retrieves contact and location information as contained in C<system.sysDescr> and C<system.sysLocation>.

=item B<C<$P-E<gt>vendor()>> or B<C<npa_vendor( $P)>>

Attempts to determine the vendor/manufacturer of the printer.
Currently, only a few vendors can be reliably detected:  HP, Tektronix, Lexmark, IBM, Xerox, EFI, Fuji and QMS.
If a device can be determined to not be a printer then 'not_a_printer' is returned.
If the vendor cannot be determined then 'unknown is returned.
If you are able to determine an unsupported vendor then please send the information to me (see below).

=item B<C<$P-E<gt>model()>> or B<C<npa_model( $P)>>

Attempts to determine the model of the printer.
The vendor is determined as the first step.  So, this will only work for printers that are supported
by the vendor() method.  Even then, the module only guarantees its best-effort.
If you are able to determine an unsupported model then please send the information to me (see below).

=item B<C<$P-E<gt>cfgsrc()>> or B<C<npa_cfgsrc( $P)>>

The configuration source or method is determined as given by the HP private MIB OID
C<.iso.org.dod.internet.private.enterprises.hp.nm.interface.npCard.npCfg.npCfgSource>.

=item B<C<$P-E<gt>status()>> or B<C<npa_status( $P)>>

Attempts to determine the status of the printer from the Host-Resources-MID OID C<hrPrinterStatus>.

=item B<C<$P-E<gt>memory()>> or B<C<npa_memory( $P)>>

Attempts to determine the amount memory in the printer from the Host-Resources-MID OID C<hrMemorySize>.

=item B<C<$P-E<gt>netconfig()>> or B<C<npa_netconfig( $P)>>

Attempts to determine the network configuration of the printer from these MIB-2 OIDs: C<ipPhysAddress>, C<ipAdEntAddr>, C<ipAdEntNetMask>, C<ipRouteNextHop>.

=item B<C<$P-E<gt>pagecount()>> or B<C<npa_pagecount( $P)>>

Attempts to number of pages printed by the printer from the Printer-MIB OIDs C<prtMarkerLifeCount> and C<prtMarkerCounterUnit>.

=item B<C<$P-E<gt>colors()>> or B<C<npa_colors( $P)>>

Attempts to determine the number of colors supported by the printer from the Printer-MIB OID C<prtMarkerProcessColorants>.

=item B<C<$P-E<gt>resolution()>> or B<C<npa_resolution( $P)>>

This returns the values for the Printer-MIB OIDs C<prtMarkerAddressabilityFeedDir> and C<prtMarkerAddressabilityXFeedDir>.

??? I am not sure what they mean.

=item B<C<$P-E<gt>minmargin()>> or B<C<npa_minmargin( $P)>>

This really should be just C<margin> since it is determined from the C<prtMarkerTable> and most printers in use only have one marker.
Nonetheless, this merely returns the margins for all of the markers in the printer from the Printer-MIB OIDs C<prtMarkerNorthMargin>,
C<prtMarkerSouthMargin>, C<prtMarkerEastMargin> and C<prtMarkerWestMargin>.

=item B<C<$P-E<gt>enginespeed()>> or B<C<npa_enginespeed( $P)>>

Determines the maximum speed that one of the media-paths provides from the Printer-MIB OID C<prtMediaPathSpeed>.

=item B<C<$P-E<gt>maxpapersize()>> or B<C<npa_maxpapersize( $P)>>

Determines the largest paper-size that is supported by the printer.
This does not reflect the largest size paper that is actually in the printer.
By "largest" and "max", we mean the paper-size with the most area, as determined from the Printer-MIB OIDs C<prtMediaPathMaxMediaFeedDir> and
C<prtMediaPathMaxMediaXFeedDir>.

=item B<C<$P-E<gt>minpapersize()>> or B<C<npa_minpapersize( $P)>>

Determines the smallest paper-size that is supported by the printer.
This does not reflect the smallest size paper that is actually in the printer.
By "smallest" and "min", we mean the paper-size with the least area, as determined from the Printer-MIB OIDs C<prtMediaPathMinMediaFeedDir> and
C<prtMediaPathMinMediaXFeedDir>.


=back

=over 4

=head2 SNMP table queries

The next set of queries merely return the contents of the Printer-MIB tables.
Just for brevity, I will only list the method/subroutine names and the respective table OIDs.

=item B<C<$P-E<gt>display()>> or B<C<npa_display( $P)>>

	printmib.prtConsoleDisplayBuffer.prtConsoleDisplayBufferTable

=item B<C<$P-E<gt>languages()>> or B<C<npa_languages( $P)>>

	printmib.prtInterpreter.prtInterpreterTable

=item B<C<$P-E<gt>covers()>> or B<C<npa_covers( $P)>>

	printmib.prtCover.prtCoverTable

=item B<C<$P-E<gt>inputtray()>> or B<C<npa_inputtray( $P)>>

	printmib.prtInput.prtInputTable

=item B<C<$P-E<gt>marker()>> or B<C<npa_marker( $P)>>

	printmib.prtMarker.prtMarkerTable

=item B<C<$P-E<gt>protocol()>> or B<C<npa_protocol( $P)>>

	printmib.prtChannel.prtChannelTable

=item B<C<$P-E<gt>supplies()>> or B<C<npa_supplies( $P)>>

	printmib.prtMarkerSupplies.prtMarkerSuppliesTable

=item B<C<$P-E<gt>mediapath()>> or B<C<npa_mediapath( $P)>>

	printmib.prtMediaPath.prtMediaPathTable

=item B<C<$P-E<gt>alerts()>> or B<C<npa_alerts( $P)>>

	printmib.prtAlert.prtAlertTable


=back

=over 4

=head2 Truth queries

The truth queries answer a "Yes or No" question about the capabilities of the printer.
The questions fall into one of several categories: languages (prtInterpreter), paper-size (prtMediaPath) or protocol (prtChannel).

=item B<C<$P-E<gt>pjl()>> or B<C<npa_pjl( $P)>>

	supports PJL printer language?

=item B<C<$P-E<gt>pcl()>> or B<C<npa_pcl( $P)>>

	supports PCL printer language?

=item B<C<$P-E<gt>hpgl()>> or B<C<npa_hpgl( $P)>>

	supports HPGL printer language?

=item B<C<$P-E<gt>psprint()>> or B<C<npa_psprint( $P)>>

	supports PSPRINT printer language?

=item B<C<$P-E<gt>postscript()>> or B<C<npa_postscript( $P)>>

	supports Postscript printer language?

=item B<C<$P-E<gt>autolang()>> or B<C<npa_autolang( $P)>>

	automatically selects the appropriate language?

=item B<C<$P-E<gt>duplex()>> or B<C<npa_duplex( $P)>>

	supports duplex printing?

=item B<C<$P-E<gt>letter()>> or B<C<npa_letter( $P)>>

	supports letter papersize?

=item B<C<$P-E<gt>legal()>> or B<C<npa_legal( $P)>>

	supports legal papersize?

=item B<C<$P-E<gt>executive()>> or B<C<npa_executive( $P)>>

	supports executive papersize?

=item B<C<$P-E<gt>tabloid()>> or B<C<npa_tabloid( $P)>>

	supports tabloid papersize?

=item B<C<$P-E<gt>a3()>> or B<C<npa_a3( $P)>>

	supports a3 papersize?

=item B<C<$P-E<gt>a4()>> or B<C<npa_a4( $P)>>

	supports a4 papersize?

=item B<C<$P-E<gt>b3()>> or B<C<npa_b3( $P)>>

	supports b4 papersize?

=item B<C<$P-E<gt>b5()>> or B<C<npa_alerts( $P)>>

	supports b5 papersize?

=item B<C<$P-E<gt>appletalk()>> or B<C<npa_appletalk( $P)>>

	supports Appletalk protocol?

=item B<C<$P-E<gt>lpd()>> or B<C<npa_lpd( $P)>>

	supports LPD protocol?

=item B<C<$P-E<gt>netware()>> or B<C<npa_netware( $P)>>

	supports Netware protocol?

=item B<C<$P-E<gt>port9100()>> or B<C<npa_port9100( $P)>>

	supports port 9100 bidirectional connections?

=over

=cut

##################################### vendor

use constant Xerox230_1	=> '131;C1H011131;';
use constant Xerox230_2	=> ';C1H017730;';
use constant Xerox265	=> '3UP060485';

%vendors= (
	HP		=> qr/JETDIRECT/o,
	Lexmark		=> qr/Lexmark/o,
	Tektronix	=> qr/Tektronix/o,
	Xerox		=> qr/ Xerox | @{[Xerox230_1]} | @{[Xerox230_2]} | @{[Xerox265]} /ox,
	QMS		=> qr/qms/o,
	IBM		=> qr/IBM/o,
	EFI		=> qr/EFI FieryColor Printer Server|EFI Fiery Server ZX/o,
	Fuji		=> qr/Able Model-PRII/o,
	not_a_printer	=> qr/HP-UX|HPUX|Windows NT|Sun SNMP Agent|SunOS|Macintosh|UNIX/o,
	);

sub vendor
{
#warn "vendor";
  my $self= shift;

  my $x;
  $x= $self->{Neon}->mib2_system();

  while ( my( $k, $v)= each %vendors )
  {
    if ( $x->{sysDescr} =~ $v )
    {
      $self->{vendor}= $k;
      last;
    }
    $self->{vendor} |= 'unknown';
  }

  return { vendor => $self->{vendor} };
}

##################################### model

sub model
{
#warn "model";
  my $self= shift;

  for ( $self->vendor()->{vendor} )
  {
    /^EFI$/ && do {
	last;
	};

    /^Fuji$/ && do {
	$self->{model}= 'Able PRII';
	last;
	};

    /^HP$/ && do {
	my $str= $self->{Neon}->hp_gdStatusId()->{gdStatusId};
	$self->{model}= ( $str =~ /;(?:MODEL|MDL):\s*(.+?)\s*;/ )[0];
	last;
	};

    /^Lexmark$/ && do {
	my $x;
	$x= $self->{Neon}->mib2_system()->{sysDescr};
	$self->{model}= ( $x =~ /Lexmark\s+(.+?)  / )[0];
	last;
	};

    /^Xerox$/ && do {
	my( $x, $y);
	$x= $self->{Neon}->mib2_system()->{sysDescr};
	if ( $x =~ /[?]{3}/ )
	{
		;
	}
	elsif ( $x =~ / @{[Xerox230_1]} | @{[Xerox230_2]} /ox )
	{
		$self->{model}= 'Document Centre 230ST';
	}
	elsif ( $x =~ / @{[Xerox265]} /ox )
	{
		$self->{model}= 'Document Centre 265';
	}
	else
	{
		$x =~ /\s*(?:(.+?),|(.+))/;
		$self->{model}= $1 || $2;
	}
	last;
	}

#	/^IBM$/ && do { };

#	/^QMS$/ && do { };

#	/^Tektronix$/ && do { };
  }

  return { model => $self->{model} };
}

##################################### final PODs

=pod

=head1 AUTHOR

Robert Lehr, bozzio@the-lehrs.com

I certainly would appreciate any feedback from people that use it, including complaints, suggestions or patches.
Even people that don't use it are welcome to send comments.

=head1 COPYRIGHT

Copyright (c) 2001 Robert Lehr. All rights reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Caveat emptor.  Use this module at your own risk.  I will accept no responsibility for any loss of any kind
that is the direct or indirect result of the use of this module.

=head1 SEE ALSO

the SNMP module v3.1.0; the UCD SNMP library v4.2.0  at http://www.net-snmp.org/; RFC 1759 - The Printer MIB

=cut

##################################### _check_paper_size

use constant Name			=> 0;
use constant Units			=> 1;
use constant DimA			=> 2;
use constant DimB			=> 3;

use constant null			=> 'null';
use constant tenThousandthsOfInches	=> 'tenThousandthsOfInches';
use constant micrometers		=> 'micrometers';

@paper_sizes= (
	[ 'other',	null,				-1,	-1	],
	[ 'unknown',	null,				-2,	-2	],
	[ 'letter',	tenThousandthsOfInches,		85000,	110000	],
	[ 'letter',	micrometers,			215900,	279400	],	#bw#
	[ 'legal',	tenThousandthsOfInches,		85000,	140000	],
	[ 'legal',	micrometers,			215900,	355600	],	#bw#
	[ 'tabloid',	tenThousandthsOfInches,		110000,	170000	],	#bw#
	[ 'tabloid',	micrometers,			279400,	431800	],	#bw#
	[ 'executive',	tenThousandthsOfInches,		75000,	105000	],	#bw#
	[ 'executive',	micrometers,			190500,	266700	],	#bw#
	[ 'a3',		tenThousandthsOfInches,		109842,	165354	],	#bw#
	[ 'a3',		micrometers,			297000,	420000	],
	[ 'a4',		tenThousandthsOfInches,		82677,	116929	],	#bw#
	[ 'a4',		micrometers,			210000,	297000	],
	[ 'b3',		micrometers,			353000,	500000	],
	[ 'b3',		tenThousandthsOfInches,		-1,	-1	],
	[ 'b5',		micrometers,			176000,	250000	],
	[ 'b5',		tenThousandthsOfInches,		-1,	-1	],
	);
#bw# == Ben Woodard, extracted from npadmin, file=npaconsts.h

map {
  $paper_sizes_indexed->{$_->[Name]}->{$_->[Units]}= [ undef, undef, $_->[DimA], $_->[DimB] ]
  } @paper_sizes; 

##################################### language_code	(this points the question at the answer)

use constant check_language	=> '_check_language';
use constant check_paper_size	=> '_check_paper_size';
use constant check_protocol	=> '_check_protocol';

%language_map= (
	pcl		=> check_language,
	postscript	=> check_language,
	psprint		=> check_language,
	pjl		=> check_language,
	hpgl		=> check_language,
	autolang	=> check_language,
	legal		=> check_paper_size,
	letter		=> check_paper_size,
	b5		=> check_paper_size,
	a3		=> check_paper_size,
	executive	=> check_paper_size,
	b4		=> check_paper_size,
	a4		=> check_paper_size,
	tabloid		=> check_paper_size,
	port9100	=> check_protocol,
	netware		=> check_protocol,
	lpd		=> check_protocol,
	appletalk	=> check_protocol,
	);

$language_code= q[
	sub ##SUBNAME##
	{
#warn '##SUBNAME##';
	  my $self= shift;

	  return $self->##HANDLER##( '##SUBNAME##');
	}
	];

##################################### filter_code	(this fetches data and translates field names)

%filter_map= (
	status => [
		'hrPrinterStatus',
		{
		"hrPrinterStatus"			=> 'status',
		}],
	memory => [
		'hrMemorySize',
		{
		'hrMemorySize'				=> 'memsize',
		}],
	netconfig => [
		'netconfig',
		{
		'ipAdEntAddr'				=> 'ipaddr',
		'ifPhysAddress'				=> 'hwaddr',
		'ipRouteNextHop'			=> 'gateway',
		'ipAdEntNetMask'			=> 'netmask',
		}],
	cfgsrc => [
		'hp_npCfgSource',
		{
		'npCfgSource'				=> 'cfgsrc',
		}],
	storage => [
		'hrStorage',
		{
		'hrStorageDescr'			=> 'descr',
		'hrStorageSize'				=> 'size',
		'hrStorageUsed'				=> 'used',
		'hrStorageAllocationUnits'		=> 'allocunits',
		'hrStorageAllocationFailures'		=> 'allocfail',
		}],
	display => [
		'prtConsoleDisplayBuffer',
		{
		'prtConsoleDisplayBufferText'		=> 'displayBufferText',
		}],
	languages => [
		'prtInterpreter',
		{
		'prtInterpreterLangFamily'		=> 'langFamily',
		'prtInterpreterLangLevel'		=> 'langLevel',
		'prtInterpreterLangVersion'		=> 'langVersion',
		'prtInterpreterDescription'		=> 'description',
		'prtInterpreterVersion'			=> 'version',
		'prtInterpreterDefaultOrientation'	=> 'orientation',
		'prtInterpreterFeedAddressability'	=> 'feedAddressability',
		'prtInterpreterXFeedAddressability'	=> 'xFeedAddressability',
		'prtInterpreterTwoWay'			=> 'twoWay',
		}],
	protocol => [
		'prtChannel',
		{
		'prtChannelType'			=> 'type',
		'prtChannelProtocolVersion'		=> 'version',
		'prtChannelState'			=> 'state',
		'prtChannelStatus'			=> 'status',
		'prtChannelDefaultPageDescLangIndex'	=> 'defaultPageDescLang',
		'prtChannelCurrentJobCntlDescLangIndex'	=> 'currentJobControlLang',
		}],
	covers => [
		'prtCover',
		{
		'prtCoverDescription'			=> 'description',
		'prtCoverStatus'			=> 'status',
		}],
	mediapath => [
		'prtMediaPath',
		{
		'prtMediaPathType'			=> 'type',
		'prtMediaPathDescription'		=> 'description',
		'prtMediaPathStatus'			=> 'status',
		'prtMediaPathMediaSizeUnit'		=> 'mediaSizeunit',
		'prtMediaPathMaxMediaFeedDir'		=> 'maxMediaFeedDir',
		'prtMediaPathMaxMediaXFeedDir'		=> 'maxMediaXFeedDir',
		'prtMediaPathMinMediaFeedDir'		=> 'minMediaFeedDir',
		'prtMediaPathMinMediaXFeedDir'		=> 'minMediaXFeedDir',
		'prtMediaPathMaxSpeed'			=> 'maxSpeed',
		'prtMediaPathMaxSpeedPrintUnit'		=> 'maxSpeedPrintUnit',
		}],
	alerts => [
		'prtAlert',
		{
		'prtAlertTrainingLevel'			=> 'trainingLevel',
		'prtAlertGroup'				=> 'group',
		'prtAlertGroupIndex'			=> 'groupIndex',
		'prtAlertLocation'			=> 'location',
		'prtAlertCode'				=> 'code',
		'prtAlertDescription'			=> 'description',
		'prtAlertTime'				=> 'time',
		}],
	supplies => [
		'prtMarkerSupplies',
		{
		'prtMarkerSuppliesType'			=> 'type',
		'prtMarkerSuppliesSupplyUnit'		=> 'supplyunit',
		'prtMarkerSuppliesClass'		=> 'class',
		'prtMarkerSuppliesDescription'		=> 'desc',
		'prtMarkerSuppliesMaxCapacity'		=> 'maxcap',
		'prtMarkerSuppliesLevel'		=> 'level',
		}],
	marker => [
		'prtMarker',
		{
		'prtMarkerMarkTech'			=> 'markerTechnology',
		'prtMarkerCounterUnit'			=> 'counterUnits',
		'prtMarkerLifeCount'			=> 'lifeCount',
		'prtMarkerProcessColorants'		=> 'processColorants',
		'prtMarkerAddressabilityUnit'		=> 'addressabilityUnit',
		'prtMarkerAddressabilityFeedDir'	=> 'addressabilityFeedDir',
		'prtMarkerAddressabilityXFeedDir'	=> 'addressabilityXFeedDir',
		'prtMarkerNorthMargin'			=> 'northMargin',
		'prtMarkerSouthMargin'			=> 'southMargin',
		'prtMarkerEastMargin'			=> 'eastMargin',
		'prtMarkerWestMargin'			=> 'westMargin',
		'prtMarkerStatus'			=> 'status',
		}],
	inputtray => [
		'prtInput',
		{
		'prtInputType'				=> 'type',
		'prtInputDimUnit'			=> 'dimUnit',
		'prtInputMediaDimFeedDirChosen'		=> 'dimFeedDir',
		'prtInputMediaDimXFeedDirChosen'	=> 'dimXFeedDir',
		'prtInputCapacityUnit'			=> 'capUnit',
		'prtInputMaxCapacity'			=> 'maxCap',
		'prtInputCurrentLevel'			=> 'curLevel',
		'prtInputMediaName'			=> 'mediaName',
		'prtInputName'				=> 'name',
		'prtInputDescription'			=> 'description',
		'prtInputStatus'			=> 'status',
		}],
	contact => [
		'mib2_system',
		{
		"sysContact"				=> 'contact',
		"sysLocation"				=> 'location',
		}],
	pagecount => [
		'prtMarker',
		{
		"prtMarkerLifeCount"			=> 'pagecount',
		"prtMarkerCounterUnit"			=> 'countUnits',
		}],
	colors => [
		'prtMarker',
		{
		"prtMarkerProcessColorants"		 => 'processColorants',
		}],
	resolution => [
		'prtMarker',
		{
		"prtMarkerAddressabilityUnit"		=> 'addressabilityUnit',
		"prtMarkerAddressabilityFeedDir"	=> 'addressabilityFeedDir',
		"prtMarkerAddressabilityXFeedDir"	=> 'addressabilityXFeedDir',
		}],
	minmargin => [
		'prtMarker',
		{
		"prtMarkerAddressabilityUnit"		=> 'addressabilityUnit',
		"prtMarkerNorthMargin"			=> 'northMargin',
		"prtMarkerSouthMargin"			=> 'southMargin',
		"prtMarkerEastMargin"			=> 'eastMargin',
		"prtMarkerWestMargin"			=> 'westMargin',
		}],
	minpapersize => [
		'prtMediaPath',
		{
		"prtMediaPathMediaSizeUnit"		=> 'minMediaUnit',
		"prtMediaPathMinMediaFeedDir"		=> 'minMediaFeedDir',
		"prtMediaPathMinMediaXFeedDir"		=> 'minMediaXFeedDir',
		},
		[
		sub { my $x= shift; $x->{prtMediaPathMinMediaFeedDir} * $x->{prtMediaPathMinMediaXFeedDir} },
		sub { my @x= @_; $x[0] < ( $x[1] || 1e99 ) },
		],
		],
	maxpapersize => [
		'prtMediaPath',
		{
		"prtMediaPathMediaSizeUnit"		=> 'maxMediaUnit',
		"prtMediaPathMaxMediaFeedDir"		=> 'maxMediaFeedDir',
		"prtMediaPathMaxMediaXFeedDir"		=> 'maxMediaXFeedDir',
		},
		[
		sub { my $x= shift; $x->{prtMediaPathMaxMediaFeedDir} * $x->{prtMediaPathMaxMediaXFeedDir} },
		sub { my @x= @_; ( $x[0] > $x[1]) },
		],
		],
	enginespeed => [
		'prtMediaPath',
		{
		"prtMediaPathMaxSpeedPrintUnit"		=> 'maxSpeedUnit',
		"prtMediaPathMaxSpeed"			=> 'maxSpeed',
		},
		[
		sub { my $x= shift; $x->{prtMediaPathMaxSpeed} },
		sub { my @x= @_; ( $x[0] > $x[1] ) },
		],
		],
	);

$filter_code= q{
	sub ##SUBNAME##
	{
#warn '##SUBNAME##';
	  my $self= shift;
	  my( $x, $y, $z);

	  $x= $self->{Neon}->##SNMPTABLE##();
	  $x= $self->_munge_it( $x, $filter_map{##SUBNAME##}->[2]) if $filter_map{##SUBNAME##}->[2];

	  $z= $filter_map{##SUBNAME##}->[1];

	  if ( ref $x eq 'ARRAY' )
	  {
	    foreach my $var (( ref $x eq 'ARRAY' ) ? @$x : $x )
	    {
	      my %M;
	      %M= map { ( $z->{$_}, $var->{$_}) } ( grep { my $a= $_; grep { $a eq $_ } keys %$z } keys %$var );
	      push @$y, \%M if %M;
	    }
	  }
	  else
	  {
	    $y= { map { ( $z->{$_}, $x->{$_}) } ( grep { my $a= $_; grep { $a eq $_ } keys %$z } keys %$x ) };
	  }

	  return $y;
	}
	};

##################################### answer_code	(this answers boolean questions)

%answer_map= (
	duplex => [
		'prtMediaPath',
		[ 'longEdgeBindingDuplex', 'shortEdgeBindingDuplex'],
		sub { my @x= @_; grep { $x[0]->{prtMediaPathType} eq $_ } @{$x[1]} },
		],
	_check_language => [
		'prtInterpreter',
		{	pcl		=> 'langPCL',
			postscript	=> 'langPS',
			psprint		=> 'langPSPrinter',
			pjl		=> 'langPCL',
			hpgl		=> 'langHPGL',
			autolang	=> 'langAutomatic',
			},
		sub { my @x= @_; $x[0]->{prtInterpreterLangFamily} eq $x[1]->{$x[2]} },
		],
	_check_protocol => [
		'prtChannel',
		{	appletalk	=> [ qw/ chAppleTalkPAP / ],
			lpd		=> [ qw/ chLPDServer / ],
			port9100	=> [ qw/ chPort9100 chAppSocket chBidirPortTCP / ],
			},
		sub { my @x= @_; grep { $x[0]->{prtChannelType} eq $_ } @{$x[1]->{$x[2]}} },
		],
	_check_paper_size => [
		'prtInput',
		{},
		sub { my @x= @_;
			my $a= $x[0]->{prtInputMediaDimFeedDirChosen};
			my $b= $x[0]->{prtInputMediaDimXFeedDirChosen};
			my $c= $x[0]->{prtInputDimUnit};
			my $y= $paper_sizes_indexed->{$x[2]}->{$c}->[DimA];
			my $z= $paper_sizes_indexed->{$x[2]}->{$c}->[DimB];

			(( $a == $y ) && ( $b == $z ))
					||
			(( $a == $z ) && ( $b == $y ))
  			},
		],
	printmib => [
		'printmib',
                undef,
                sub { shift()->{printmib} },
		],
	hostmib => [
		'hostmib',
                undef,
                sub { shift()->{hostmib} },
		],
	);

$answer_code= q{
	sub ##SUBNAME##
	{
#warn "##SUBNAME##";
	  my( $self, $a)= @_;
	  my $answer= 0;
	  my( $x, $y, $z);

	  $x= $self->{Neon}->##SNMPTABLE##();
	  $y= $answer_map{##SUBNAME##}->[2];
	  $z= $answer_map{##SUBNAME##}->[1];

          if( ref $y =~ '^CODE(.+)' )
          {
	    foreach my $var ( @$x )
	    {
	      $answer++ if $y->( $var, $z, $a);
	    }
          }
          else
          {
	    $answer= $x;
          }

	  return { ##VALNAME## => $self->{boolean}->[$answer?1:0] };
	}
	};

##################################### AUTOLOAD

sub AUTOLOAD
{
#warn "AUTOLOAD";
  my $autoload= ( $AUTOLOAD =~ /.*::(\w+)/ )[0];

  my( $sub, %tags);
  if ( defined $language_map{$autoload} )
  {
    $sub= $language_code;
    %tags= (
	'##SUBNAME##'	=> $autoload,
	'##HANDLER##'	=> $language_map{$autoload},
	);
  }
  elsif ( defined $filter_map{$autoload} )
  {
    $sub= $filter_code;
    %tags= (
	'##SUBNAME##'	=> $autoload,
	'##SNMPTABLE##'	=> $filter_map{$autoload}->[0],
	'##MUNGE_FILTER##'	=> $filter_map{$autoload}->[1],
	);
  }
  elsif ( defined $answer_map{$autoload} )
  {
    $sub= $answer_code;
    %tags= (
	'##SUBNAME##'	=> $autoload,
	'##SNMPTABLE##'	=> $answer_map{$autoload}->[0],
	'##VALNAME##'	=> ( ref $answer_map{$autoload}->[1] eq 'HASH' ) ? '$a' : $autoload,
	);
  }

  if ( $sub )
  {
      map { $sub=~ s/\Q$_/$tags{$_}/g } keys %tags;
      eval $sub;
      die $@ if $@;
      goto &$autoload;
  }

  printf STDERR "Unimplemented method:\t'%s()'\n", $autoload;
  return undef;
}

##################################### _munge_it

sub _munge_it
{
#warn '_munge_it';
  my( $self, $x, $F)= @_;

  my( $M, $m);
  foreach my $var ( @$x )
  {
    my $a= $F->[0]->( $var);

    if (( ! $m ) || ( $F->[1]->( $a, $m) )) 
    {
      $M= $var;
      $m= $a;
    }
  }

  return $M;
}

##################################### the end
#
# $Id: NPAdmin.pm,v 1.23 2002/11/15 03:57:23 bozzio Exp $
#

1;
