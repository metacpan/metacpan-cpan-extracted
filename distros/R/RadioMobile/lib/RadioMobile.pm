	package RadioMobile;

	use 5.008000;
	use strict;

	use Class::Container;
	use Params::Validate qw(:types);
	use base qw(Class::Container);

	use File::Binary;
	use IO::Scalar;
	sub IO::Scalar::write {
		# rewrote write to work with File::Binary
		my $self = $_[0];
		$self->print($_[1]);
	}
	use warnings;

	use RadioMobile::Header;
	use RadioMobile::Units;
	use RadioMobile::UnitIconParser;
	use RadioMobile::UnitDescriptionParser;
	use RadioMobile::UnitsSystemParser;
	use RadioMobile::UnitsHeightParser;
	use RadioMobile::UnitsAzimutDirectionParser;
	use RadioMobile::UnitsElevationParser;
	use RadioMobile::Systems;
	use RadioMobile::SystemCableLossParser;
	use RadioMobile::SystemAntennaParser;
	use RadioMobile::Nets;
	use RadioMobile::NetUnknown1Parser;
	use RadioMobile::NetsUnits;
	use RadioMobile::Cov;
	use RadioMobile::Config;

	__PACKAGE__->valid_params(
								file	=> { type => SCALAR, optional => 1 },
								filepath=> { type => SCALAR, optional => 1 },
								debug 	=> { type => SCALAR, optional => 1, default => 0 },
								header	=> { isa  => 'RadioMobile::Header'},
								units	=> { isa  => 'RadioMobile::Units'},
								systems	=> { isa  => 'RadioMobile::Systems'},
								nets	=> { isa  => 'RadioMobile::Nets'},
								netsunits	=> { isa  => 'RadioMobile::NetsUnits'},
								config	=> { isa  => 'RadioMobile::Config'},
								cov		=> { isa  => 'RadioMobile::Cov'},

	);

	__PACKAGE__->contained_objects(
		'header'	=> 'RadioMobile::Header',
		'units'		=> 'RadioMobile::Units',
		'systems'	=> 'RadioMobile::Systems',
		'nets'		=> 'RadioMobile::Nets',
		'netsunits'	=> 'RadioMobile::NetsUnits',
		'config'	=> 'RadioMobile::Config',
		'cov'		=> 'RadioMobile::Cov',
	);

	use Class::MethodMaker [ scalar => [qw/filepath debug header units 
		bfile file systems nets netsunits config cov/] ];

	our $VERSION	= '0.11';

	sub new {
		my $proto 	= shift;
		my $self	= $proto->SUPER::new(@_);
		$self->{log_last_code} = 0;
		return $self;
	}


	sub parse {
		my $s 	= shift;
		my $cb	= shift;

		$s->_cb($cb,10000,"Open file for parsing");
		# open binary .net file
		if ($s->file) {
			# first try to see if you give me binary raw data
			my $data	= $s->file;
			my $io		= new IO::Scalar(\$data);
			$s->{bfile}	= new File::Binary($io);
		} elsif ($s->filepath) {
			# then try to see if you give me a file path
			$s->{bfile} = new File::Binary($s->filepath);
		} else {
			die "You must set file or filepath for enable parsing";
		}
		$s->_cb($cb,10000,"Open file for parsing");

		# read header
		$s->_cb($cb,10100,"Header Parsing");
		$s->header->parse;
		print $s->header->dump if $s->debug;
		$s->_cb($cb,10100,"Header Parsing");

		# read units
		$s->_cb($cb,10200,"Read Units");
		$s->units->parse;
		print $s->units->dump if $s->debug;
		$s->_cb($cb,10200,"Read Units");

		# read systems
		$s->_cb($cb,10300,"Read Systems");
		$s->systems->parse;
		print $s->systems->dump if $s->debug;
		$s->_cb($cb,10300,"Read Systems");

		# initialize nets (I need them in net_role structure)
		$s->_cb($cb,10400,"Init Nets");
		$s->nets->reset;
		$s->_cb($cb,10400,"Init Nets");
		#print $s->nets->dump if $s->debug;


		# read net_role
		$s->_cb($cb,10500,"Setting Nets <-> Units and Roles");
		$s->netsunits->parse;
		print "isIn: \n", $s->netsunits->dump('isIn') if $s->debug;
		print "role: \n", $s->netsunits->dump('role') if $s->debug;
		$s->_cb($cb,10500,"Setting Nets <-> Units and Roles");

		# read system for units in nets
		$s->_cb($cb,10600,"Read Systems for Units");
		my $ns = new RadioMobile::UnitsSystemParser( parent => $s );
		$ns->parse;
		print "system: \n", $s->netsunits->dump('system') if $s->debug;
		$s->_cb($cb,10600,"Read Systems for Units");

		# read nets
		$s->_cb($cb,10700,"Read Nets information");
		$s->nets->parse;
		print $s->nets->dump if $s->debug;
		$s->_cb($cb,10700,"Read Nets information");

		# read and unpack coverage
		$s->_cb($cb,10800,"Parsing Coverage");
		$s->cov->parse($s->bfile);
		print "Coverage: " . $s->cov->dump . "\n" if $s->debug;
		$s->_cb($cb,10800,"Parsing Coverage");

		# lettura del percorso al file map
		$s->_cb($cb,10900,"Read Map File path");
		$s->config->parse_mapfilepath;
		print "Map file path: " . $s->config->mapfilepath . "\n" if $s->debug;
		$s->_cb($cb,10900,"Read Map File path");

		# lettura dei percorsi delle picture da caricare
		$s->_cb($cb,11000,"Read Pictures path");
		$s->config->pictures->parse;
		print "PICTURES: " . $s->config->pictures->dump . "\n" if $s->debug;
		$s->_cb($cb,11000,"Read Pictures path");

		# read net_h 
		$s->_cb($cb,11100,"Parsing Antenna Height for Units");
		my $hp = new RadioMobile::UnitsHeightParser(
											bfile 		=> $s->bfile,
											header		=> $s->header,
											netsunits 	=> $s->netsunits
										);
		$hp->parse;
		print "height: \n", $s->netsunits->dump('height') if $s->debug;
		$s->_cb($cb,11100,"Parsing Antenna Height for Units");

		# unit icon
		$s->_cb($cb,11200,"Setting Units Icon");
		my $up = new RadioMobile::UnitIconParser(parent => $s);
		$up->parse;
		print "UNITS with ICONS: \n", $s->units->dump if $s->debug;
		$s->_cb($cb,11200,"Setting Units Icon");

		# system cable loss
		$s->_cb($cb,11300,"Setting Additional System Cable Loss");
		my $cp = new RadioMobile::SystemCableLossParser(parent => $s);
		$cp->parse;
		print "SYSTEMS with CABLE LOSS: \n", $s->systems->dump if $s->debug;
		$s->_cb($cb,11300,"Setting Additional System Cable Loss");

		# parse Style Networks properties
		$s->_cb($cb,11400,"Parsing Style Network Properties");
		$s->config->parse_stylenetworks;
		print "Style Network Properties: " . 
					$s->config->stylenetworksproperties->dump if $s->debug;
		$s->_cb($cb,11400,"Parsing Style Network Properties");

		# parse an unknown structure of 8 * networkCount bytes
		$s->_cb($cb,11500,"Parsing Unknown Network structure");
		my $un = new RadioMobile::NetUnknown1Parser(parent => $s);
		$un->parse;
		print "Network after unknown1 structure: " .
					$s->nets->dump if $s->debug;
		$s->_cb($cb,11500,"Parsing Unknown Network structure");

		# parse system antenna
		$s->_cb($cb,11600,"Reading Antenna for Systems");
		my $ap = new RadioMobile::SystemAntennaParser(parent => $s);
		$ap->parse;
		print "SYSTEMS with Antenna: \n", $s->systems->dump if $s->debug;
		$s->_cb($cb,11600,"Reading Antenna for Systems");


		# read azimut antenas
		$s->_cb($cb,11700,"Reading Azimut/Direction for Units");
		my $ad = new RadioMobile::UnitsAzimutDirectionParser(parent => $s);
		$ad->parse;
		print "Azimut: \n", $s->netsunits->dump('azimut') if $s->debug;
		print "Direction: \n", $s->netsunits->dump('direction') if $s->debug;
		$s->_cb($cb,11700,"Reading Azimut/Direction for Units");

		# read unknown units property
		$s->_cb($cb,11800,"Parsing Description Unit structure");
		my $uu = new RadioMobile::UnitDescriptionParser(parent => $s);
		$uu->parse;
		print "UNITS after description structure: " .  $s->units->dump if $s->debug;
		$s->_cb($cb,11800,"Parsing Description Unit structure");

		# read elevation antenas
		$s->_cb($cb,11900,"Reading Elevation for Units");
		my $ep = new RadioMobile::UnitsElevationParser(parent => $s);
		$ep->parse;
		print "Elevation: \n", $s->netsunits->dump('elevation') if $s->debug;
		$s->_cb($cb,11900,"Reading Elevation for Units");

		# got version number again
		my $b = $s->bfile->get_bytes(2);
		my $versionNumberAgain = unpack("s",$b);
		die "not find version number where expected" unless ($versionNumberAgain == $s->header->version);

		# this is a zero, don't known what it's
		$b = $s->bfile->get_bytes(2);
		my $unknownZeroNumber = unpack("s",$b);
		die "unexpected value of $unknownZeroNumber while waiting 0 " unless ($unknownZeroNumber == 0);
		# lettura del percorso al file landheight
		$s->_cb($cb,12000,"Reading LandHeight path");
		$s->config->parse_landheight;
		print "Land Height path: " . $s->config->landheight . "\n" if $s->debug;
		$s->_cb($cb,12000,"Reading LandHeight path");

		$s->bfile->close;
	}

sub write {
	my $s			= shift;
	# open binary .net file
	my $data ='';
	my $io			= new IO::Scalar(\$data);
    $s->{bfile} 	= new File::Binary($io);
    #$s->{bfile} 	= new File::Binary(">pippo.net");
	
	$s->header->write;
	$s->units->write;
	$s->systems->write;
	$s->netsunits->write;
	my $ns = new RadioMobile::UnitsSystemParser( parent => $s );
	$ns->write;
	$s->nets->write;
	$s->cov->write($s->bfile);
	$s->config->write_mapfilepath;
	$s->config->pictures->write;
	my $hp = new RadioMobile::UnitsHeightParser(
							bfile 		=> $s->bfile,
							header		=> $s->header,
							netsunits 	=> $s->netsunits
						);
	$hp->write;
	my $up = new RadioMobile::UnitIconParser(parent => $s);
	$up->write;
	my $cp = new RadioMobile::SystemCableLossParser(parent => $s);
	$cp->write;
	$s->config->write_stylenetworks;
	my $un = new RadioMobile::NetUnknown1Parser(parent => $s);
	$un->write;
	my $ap = new RadioMobile::SystemAntennaParser(parent => $s);
	$ap->write;
	my $ad = new RadioMobile::UnitsAzimutDirectionParser(parent => $s);
	$ad->write;
	my $uu = new RadioMobile::UnitDescriptionParser(parent => $s);
	$uu->write;
	my $ep = new RadioMobile::UnitsElevationParser(parent => $s);
	$ep->write;
	$s->bfile->put_bytes(pack('f',$s->header->version));
	$s->bfile->put_bytes(pack('s',0));
	$s->config->write_landheight;
	
	$s->bfile->close;

	return $data;
}

sub _cb {
	my $s		= shift;
	my $cb		= shift;
	my $code	= shift;
	my $descr	= shift;

	if ($code == $s->{log_last_code}) {
		$descr 	= 'END   - ' . $descr;
		$code	+= 10;
	} else {
		$s->{log_last_code} = $code;
		$s->{log_last_descr} = $descr;
		$descr 	= 'START - ' . $descr;
	}

	$cb->({code => $code, descr => $descr}) if ($cb);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

RadioMobile - A Perl interface to Radio Mobile .net file

=head1 SYNOPSIS

  use RadioMobile;
  my $rm = new RadioMobile();
  $rm->file('path_to_radiomobile_file.net');
  $rm->parse;

  my $header = $rm->header;
  my $units  = $rm->units;

  foreach my $idxUnit (0..$header->unitCount-1) {
	  my $unit = $units->at($idxUnit);
	  printf("%s at lon %s and lat %s\n", $unit->name, 
	    $unit->lon, $unit->lat);
  }

=head1 DESCRIPTION

This module is a Perl interface to .net file of Radio Mobile, a software
to predict the performance of a radio system.

Currently this module only parse .net file to extract all information
available inside it such as units, radio systems, networks, some
configuration of program behaviour, the header with version file, number
of units, systems and networks. It also extract the relation between
units, systems and networks to show the units associated to a network,
their systems and so on.

As soon as possible it will be possible to create a .net from scratch
with information available, as an example, from a database.

This module supports only .net file with 4000 as version number (I don't
know exactly from which it has been adopted this but I'm sure that all
Radio Mobile file starting from version 9.x.x used this).

=head1 BE CAREFUL

This is a beta test release. Interfaces can change in future. Report me
any bug you will find.

=head1 METHODS

=head2 new()

Call C<new()> to create a new RadioMobile object

  my $rm = new RadioMobile();

You can call C<new()> to force parsing to dump all structures found using
the debug parameter

  my $rm = new RadioMobile(debug => 1);

=head2 file()

Use this method to set a scalar with Radio Mobile .net raw data

  $rm->file('net1.net');

=head2 filepath()

Use this method to set the path, relative or absolute, to a .net file
created by Radio Mobile software.

  open(NET,$filepath);
  binmode(NET);
  my $dotnet = '';
  while (read(NET,my $buff,8*2**10)) { $dotnet .=  $buff }
  close(NET);
  $rm->file($dotnet);

=head2 parse()

Execute this method for parsing the .net file set with C<file()> or 
C<filepath()> method and fullfill C<header()>, C<config()>, C<units()>,
C<systems()>, C<nets()> and C<netsunits()> elements.

You can pass a callback function to get progress status while parsing 
is running. Currently the system suppors these status

  10000 START - Open file for parsing
  10010 END   - Open file for parsing
  10100 START - Header Parsing
  10110 END   - Header Parsing
  10200 START - Read Units
  10210 END   - Read Units
  10300 START - Read Systems
  10310 END   - Read Systems
  10400 START - Init Nets
  10410 END   - Init Nets
  10500 START - Setting Nets <-> Units and Roles
  10510 END   - Setting Nets <-> Units and Roles
  10600 START - Read Systems for Units
  10610 END   - Read Systems for Units
  10700 START - Read Nets information
  10710 END   - Read Nets information
  10800 START - Parsing Coverage
  10810 END   - Parsing Coverage
  10900 START - Read Map File path
  10910 END   - Read Map File path
  11000 START - Read Pictures path
  11010 END   - Read Pictures path
  11100 START - Parsing Antenna Height for Units
  11110 END   - Parsing Antenna Height for Units
  11200 START - Setting Units Icon
  11210 END   - Setting Units Icon
  11300 START - Setting Additional System Cable Loss
  11310 END   - Setting Additional System Cable Loss
  11400 START - Parsing Style Network Properties
  11410 END   - Parsing Style Network Properties
  11500 START - Parsing Unknown Network structure
  11510 END   - Parsing Unknown Network structure
  11600 START - Reading Antenna for Systems
  11610 END   - Reading Antenna for Systems
  11700 START - Reading Azimut/Direction for Units
  11710 END   - Reading Azimut/Direction for Units
  11800 START - Parsing Unknown Unit structure
  11810 END   - Parsing Unknown Unit structure
  11900 START - Reading Elevation for Units
  11910 END   - Reading Elevation for Units
  12000 START - Reading LandHeight path
  12010 END   - Reading LandHeight path

The prototype for callback function is

  sub callback {
    my $data = shift;
    print $data->{status}, " ", $data->{descr};
  }

=head2 header()

Returns a L<RadioMobile::Header> object with information about .net
version file, number of units, systems and networks

=head2 config()

Returns a L<RadioMobile::Config> object with Style Network Properties
window setting, list of pictures to be open, the mapfile and landheight
path.

=head2 units()

Returns a L<RadioMobile::Units> object with a list of all units.

=head2 systems()

Returns a L<RadioMobile::Systems> object with a list of all systems.


=head2 nets()

Returns a L<RadioMobile::Nets> object with a list of all networks.

=head2 cov()

Returns a L<RadioMobile::Cov> object with parameters about coverage window.

=head2 netsunits

Returns a L<RadioMobile::NetsUnits> object which is a matrix
C<$header-E<gt>networkCount * $header-E<gt>unitCount> with all relation between
units, networks and systems.

=head1 OBJECT MODEL

In F<docs/> distribution directory you can find a PDF with a summarize 
of RadioMobile object model.

=head1 AUTHOR

Emiliano Bruni, <lt>info@ebruni.it<gt>

=head1 COPYRIGHT AND LICENSE

This module is a copyright by Emiliano Bruni

Radio Mobile software is a copyright by Roger Coude' VE2DBE.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
