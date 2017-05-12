package RadioMobile::Config;

use strict;
use warnings;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

use RadioMobile::Config::StyleNetworksProperties;
use RadioMobile::Config::MapFileParser;
use RadioMobile::Config::StyleNetworksPropertiesParser;
use RadioMobile::Config::Pictures;
use RadioMobile::Config::LandHeightParser;

our $VERSION    = '0.10';

__PACKAGE__->valid_params(
							stylenetworksproperties	=> { isa  =>
								'RadioMobile::Config::StyleNetworksProperties'},
							pictures	=> { isa  => 'RadioMobile::Config::Pictures'},
							landheight => {type => SCALAR, 
								default => 'C:\Program Files (x86)\Radio Mobile\landheight.dat'},
							mapfilepath => {type => SCALAR,  
								default => ''},
);
__PACKAGE__->contained_objects(
	stylenetworksproperties => 'RadioMobile::Config::StyleNetworksProperties',
	pictures => 'RadioMobile::Config::Pictures',
);

use Class::MethodMaker [ scalar => [qw/stylenetworksproperties mapfilepath
	pictures landheight/] ];

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	return $s;
}

sub parse_mapfilepath {
	my $s	= shift;
	my $p	= new RadioMobile::Config::MapFileParser(
					bfile 	=> $s->container->bfile,
					config	=> $s
			);
	$p->parse;
}

sub write_mapfilepath {
	my $s	= shift;
	my $p	= new RadioMobile::Config::MapFileParser(
					bfile 	=> $s->container->bfile,
					config	=> $s
			);
	$p->write;
}


sub parse_stylenetworks {
	my $s	= shift;
	my $p	= new RadioMobile::Config::StyleNetworksPropertiesParser(
					bfile   => $s->container->bfile,
					config	=> $s
	);
	$p->parse;
}

sub write_stylenetworks {
	my $s	= shift;
	my $p	= new RadioMobile::Config::StyleNetworksPropertiesParser(
					bfile   => $s->container->bfile,
					config	=> $s
	);
	$p->write;
}

sub parse_landheight {
	my $s	= shift;
	my $p	= new RadioMobile::Config::LandHeightParser(
					bfile 	=> $s->container->bfile,
					config	=> $s
			);
	$p->parse;
}

sub write_landheight {
	my $s	= shift;
	my $p	= new RadioMobile::Config::LandHeightParser(
					bfile 	=> $s->container->bfile,
					config	=> $s
			);
	$p->write;
}

sub dump {
	my $s	= shift;
	return Data::Dumper::Dumper($s) unless (@_);
	my $method = shift;
	my $ret = '';
	foreach (0..$s->rowsCount-1) {
		my @row 	= $s->rows->at($_)->list;
		my @func	= map {$_->$method} @row;
		$ret .= '| ' . join(' | ',@func) . " |\n";
	}
	return $ret;
}


1;
