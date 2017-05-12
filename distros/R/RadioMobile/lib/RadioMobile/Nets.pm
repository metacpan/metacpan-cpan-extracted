package RadioMobile::Nets;

use strict;
use warnings;

use Class::Container;
use base qw(Class::Container Array::AsObject);

use File::Binary;

use RadioMobile::Net;

our $VERSION    = '0.10';

sub parse {
	my $s	= shift;
	my $f	= $s->container->bfile;
	my $len	= $s->container->header->networkCount;
	foreach (1..$len) {
		my $net = $s->length >= $_ ? $s->at($_-1) : new RadioMobile::Net;
		$net->parse($f);
		$s->add($net) unless ($s->at($_-1));
	}
}

sub write {
	my $s	 	= shift;
	my $f	  	= $s->container->bfile;
	my $len		= $s->container->header->networkCount;
	foreach (0..$len-1) {
		my $net = $s->at($_);
		$net->write($f);
	}
}

sub dump {
	my $s	= shift;
	my $ret	= "NETS => [\n";
	foreach ($s->list) {
		$ret .= "\t" . $_->dump;
	}
	$ret .= "]\n";
	return $ret;
}

sub reset {
	my $s	= shift;
	my $len = shift || $s->container->header->networkCount;
	$s->clear();
	foreach (1..$len) {
		$s->addNew(sprintf('Net%3.3s', $_));
	}
}

sub add {
	my $s		= shift;
	my $item	= shift;
	$s->push($item);
	my $net = $s->at(-1);
	$net->idx($s->length-1);
	if ($s->container) {
		# sincronizzo header
		$s->container->header->networkCount($s->length);
		my $nus		= $s->container->netsunits;
		# se serve, sincronizzo NetsUnits
		unless ($s->container->units->length == 0) {
			unless (defined $nus->at($net->idx,0)) {
				foreach my $idxUnit (0..$s->container->header->unitCount-1) {
					$nus->resetNetUnit($idxUnit,$net->idx);
				}
			}
		}
	}
	return $s->at(-1);
}

sub addNew {
	my $s		= shift;
	my $name	= shift;
	my $item = new RadioMobile::Net;
	$item->name($name);
	return $s->add($item)
}


1;

__END__
