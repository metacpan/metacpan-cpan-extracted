package RadioMobile::NetsUnits;

use strict;
use warnings;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container RadioMobile::Utils::Matrix);

__PACKAGE__->valid_params();
__PACKAGE__->contained_objects();

use RadioMobile::NetUnit;

our $VERSION    = '0.10';

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
# non sono convinto di questa cosa...dovrebbe farlo gia' il new sopra
	$s->SUPER::_init(@_);
	return $s;
}

sub parse {
# read net_role
# NET_ROLE shows in which network is associated an unit
# and its role (master/slave/node/terminal) 
# it's a vector of byte with size $header->networkCount * $header->unitCount
# Given A,B,C... units and 1,2,3 Network so A1 is a byte
# indicate if unit A is in network 1 and its role
# It's structure is 
# A1 A2 A3 ... B1 B2 B3 ... C1 C2 C3 ...
# The following code traslate this in a AoA with this structure
# [ 
#   [A1 B1 C1 ... ] 
#   [A2 B2 C2 ....] 
#   [A3 B3 C3 ... ]
# ]
# like _NetData.csv
# Every byte it's so used A1 = aaaabbbb where aaaa is the first four bits
# and bbbb the others. aaaa is 1000 if the unit A
# belongs to network 1, 0000 else. 
# bbbb is an integer 0..127 setting its role index
# Example: (\x00 first role, no belong, \x01 second role, no belong, 
# \x80 (128) first role, belong to network, \x81 (129) second role, belong 
	my $s = shift;
	my $f = $s->container->bfile;
	my $h = $s->container->header;
	my $len	= $h->unitCount * $h->networkCount;
	my $b = $f->get_bytes($len);
	
	my $skip   = 'x[' . ($h->networkCount-1) .  ']';
	my @netRole;
	foreach (0..$h->networkCount-1) {
		my $format = 'x[' . $_ . '](C' .  $skip . ')' . ($h->unitCount-1) .  'C'; 
		push @netRole, [unpack($format,$b)];
	}

	# First generate NetUnit items and extract network isIn
	foreach my $netIdx (0..$h->networkCount-1) {
		my @unitNetwork;
		my @isInNetwork = map {$_ > 127 ? 1 : 0} @{$netRole[$netIdx]};
		my $net	 = $s->container->nets->at($netIdx);
		foreach my $unitIdx (0..$h->unitCount-1) {
			my $unit = $s->container->units->at($unitIdx);
			my $netunit = new RadioMobile::NetUnit(unit => $unit, net => $net);
			$netunit->isIn($isInNetwork[$unitIdx]);
			push @unitNetwork, $netunit;
		}
		$s->addRow(@unitNetwork);
	}
	
	# now add Roles
	foreach my $netIdx (0..$h->networkCount-1) {
		foreach my $unitIdx (0..$h->unitCount-1) {
			my $role = $netRole[$netIdx]->[$unitIdx];
			$s->at($netIdx,$unitIdx)->role($role > 127 ? $role - 128 : $role);
		}
	}

#my @unitRole;
#foreach my $item (@netRole) {
#push @unitRole, [map {$_ > 127 ? $_-128 : $_ } @$item] 
#}

}

sub write {
	my $s = shift;
	my $f = $s->container->bfile;
	my $h = $s->container->header;
	foreach my $unitIdx (0..$h->unitCount-1) {
		foreach my $netIdx (0..$h->networkCount-1) {
			my $netunit = $s->at($netIdx,$unitIdx);
			my $byte = $netunit->isIn ? 0x80 : 0x00;
			$byte |= $netunit->role;
			$f->put_bytes(pack("C",$byte));
		}
	}
	
}

sub dump {
	my $s	= shift;
	return $s->SUPER::dump unless (@_);
	my $method = shift;
	my $ret = '';
	foreach (0..$s->rowsCount-1) {
		my @row 	= $s->rows->at($_)->list;
		my @func	= map {$_->$method} @row;
		@func = map(defined $_ ? $_ : '',@func);
		$ret .= '| ' . join(' | ',@func) . " |\n";
	}
	return $ret;
}

sub sync {
	my $s	= shift;
	my $h = $s->container->header;
	foreach my $unitIdx (0..$h->unitCount-1) {
		foreach my $netIdx (0..$h->networkCount-1) {
			my $netunit = $s->at($netIdx,$unitIdx);
			unless (defined $netunit) {
				# se non esiste creo l'elemento
				$s->resetNetUnit($unitIdx,$netIdx);
			}
		}
	}
}

sub resetNetUnit {
	my $s		= shift;
	my $unitIdx	= shift;
	my $netIdx	= shift;

	my $unit	= $s->container->units->at($unitIdx);
	my $net		= $s->container->nets->at($netIdx);
	my $netunit = new RadioMobile::NetUnit(unit => $unit, net => $net);
	$netunit->system($s->container->systems->at(0));
	$s->at($netIdx,$unitIdx,$netunit);
	
}


1;

__END__
