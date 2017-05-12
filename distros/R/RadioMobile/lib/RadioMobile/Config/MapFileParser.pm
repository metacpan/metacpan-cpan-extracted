package RadioMobile::Config::MapFileParser;

our $VERSION    = '0.10';

use strict;
use warnings;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);


__PACKAGE__->valid_params( 
							bfile	=> {isa => 'File::Binary'},
							config	=> {isa => 'RadioMobile::Config'},
);

use Class::MethodMaker [scalar => [qw/bfile config/] ];

# This module parse map file path
sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	return $s;
}

sub parse {
	my $s		= shift;

	my $f	  	= $s->bfile;
	my $c		= $s->config;

	my $l = unpack("s",$f->get_bytes(2));
	my $map_file = '';
	if ($l > 0) {
		$map_file = unpack("A$l",$f->get_bytes($l));
	} 
	$c->mapfilepath($map_file);
}

sub write {
	my $s		= shift;

	my $f	  	= $s->bfile;
	my $c		= $s->config;

	my $cstring	= $c->mapfilepath;
	my $l		= length($cstring);
	
	$f->put_bytes(pack("s",$l));
	if ($l > 0) {
		$f->put_bytes(pack("A$l",$cstring));
	} 
}

1;

__END__
