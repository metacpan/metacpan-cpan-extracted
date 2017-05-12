package RadioMobile::Utils::Matrix;

our $VERSION    = '0.10';

use strict;
use warnings;

use Data::Dumper;

use Array::AsObject;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

__PACKAGE__->valid_params ( 
							rowsSize => {type=>SCALAR, optional => 1},
							colsSize => {type=>SCALAR, optional => 1},
);
use Class::MethodMaker [scalar => [qw/data cols rows/]];

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	$s->_init(@_);
	return $s;
}

sub _init {
	my $s	= shift;
	$s->{rows} = new Array::AsObject();
	#my $singleCell = new Array::AsObject();
	#$s->rows->set(0,$singleCell);
	my %p = @_;
	$s->rowsCount($p{rowsSize}) if ($p{rowsSize});
	$s->colsCount($p{colsSize}) if ($p{colsSize});
}

sub at {
	my $s	= shift;
	my $row	= shift;
	my $col	= shift;
	if (@_) {
		my $v	= shift;
		$s->rowsCount($row+1) if ($row+1 > $s->rowsCount);
		$s->colsCount($col+1) if ($col+1 > $s->colsCount);
		$s->rows->at($row)->set($col,$v)
	}
	return undef unless ($s->rows->at($row));
	return $s->rows->at($row)->at($col);
}

sub size {
	my $s	= shift;
	if (@_) {
		my $newRowsCount = shift;
		my $newColsCount = shift;
		$s->rowsCount($newRowsCount);
		$s->colsCount($newColsCount);
	}

	return ($s->rowsCount,$s->colsCount);
}

sub length {
	my $s	= shift;
	my @s	= $s->size;
	return $s[0] * $s[1];
}

sub rowsCount {
	my $s	= shift;
	if (@_) {
		my $newSize = shift;
		my $diff = $newSize - $s->rows->length;
		if ($diff > 0) {
			$s->rows->push($s->_newRow) foreach (1..$diff);
		} elsif ($diff <0) {
			$s->rows->pop foreach (1..$diff);
		}
	}
	return $s->rows->length;
}

sub colsCount {
	my $s	= shift;
	if (@_) {
		my $newSize = shift;
		my $diff = $newSize - $s->rows->at(0)->length;
		if ($diff > 0) {
			my @push;
			push @push, undef foreach (1..$diff);
			foreach (0..$s->rowsCount-1) {
				$s->rows->at($_)->push(@push);
			}
		} elsif ($diff <0) {
			foreach (0..$s->rowsCount-1) {
				$s->rows->at($_)->pop foreach (1..$diff);
			}
		}
	}
	return $s->rows->length == 0 ? 0 : $s->rows->at(0)->length;
}

sub setRow {
	my $s 	= shift;
	my $i	= shift;
	my @d	= @_;
	$s->colsCount(scalar(@d)) if (scalar(@d) > $s->colsCount);
	$s->rows->at($i)->set($_,$d[$_]) foreach(0..scalar(@d)-1);
}

sub addRow {
	my $s	= shift;
	my @d	= @_;
	$s->rowsCount($s->rowsCount+1);
	$s->setRow(-1,@d);
}

sub setCol {
	my $s 	= shift;
	my $i	= shift;
	my @d	= @_;
	$s->rowsCount(scalar(@d)) if (scalar(@d) > $s->rowsCount);
	$s->rows->at($_)->set($i,$d[$_]) foreach(0..scalar(@d)-1);
}

sub addCol {
	my $s	= shift;
	my @d	= @_;
	$s->colsCount($s->colsCount+1);
	$s->setCol(-1,@d);
}

sub _newRow {
	my $s	= shift;
	my $r	= new Array::AsObject;
	$r->fill(undef,0,$s->colsCount);
	return $r;
}

sub getRow {
	my $s	= shift;
	my $i	= shift;
	return $s->rows->at($i)->list;
}

sub getCol {
	my $s	= shift;
	my $i	= shift;
	my @ret;
	push @ret, $s->rows->at($_)->at($i) foreach(0..$s->rowsCount-1);
	return @ret;
}

sub dump {
	my $s	= shift;
	my $ret = '';
	foreach (0..$s->rowsCount-1) {
		my @row = $s->rows->at($_)->list;
		@row = map(defined $_ ? $_ : '',@row);
		$ret .= '| ' . join(' | ',@row) . " |\n";
	}
	return $ret;
}


1;

__END__
