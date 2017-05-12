package RadioMobile::Systems;

use strict;
use warnings;

use Class::Container;
use base qw(Class::Container Array::AsObject);

use File::Binary;

use RadioMobile::System;

our $VERSION    = '0.10';

sub parse {
	my $s	 	= shift;
	my $f	  	= $s->container->bfile;
	my $len		= $s->container->header->systemCount;
	foreach (0..$len-1) {
		my $system = new RadioMobile::System;
		$system->parse($f);
		$s->add($system);
	}
}

sub write {
	my $s	 	= shift;
	my $f	  	= $s->container->bfile;
	my $len		= $s->container->header->systemCount;
	foreach (0..$len-1) {
		my $system = $s->at($_);
		$system->write($f);
	}
}

sub dump {
	my $s	= shift;
	my $ret	= "SYSTEMS => [\n";
	foreach ($s->list) {
		$ret .= "\t" . $_->dump;
	}
	$ret .= "]\n";
	return $ret;
}

sub add {
	my $s		= shift;
	my $item	= shift;
	$s->push($item);
	$s->container->header->systemCount($s->length);
	$s->at(-1)->idx($s->length-1);
	return $s->at(-1);
}

sub addNew {
	my $s		= shift;
	my $name	= shift;
	my $item = new RadioMobile::System;
	$item->name($name);
	return $s->add($item)
}

1;

__END__
