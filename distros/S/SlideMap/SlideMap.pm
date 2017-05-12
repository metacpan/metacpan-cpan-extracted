####################################################################
# Copyright @ 2002 Joseph A. White and The Institute for Genomic 
#	Research (TIGR) 
# All rights reserved.
####################################################################
package SlideMap;

require 5.005_02;
use strict;
#use warnings;
use vars qw(@ISA @EXPORT %EXPORT_TAGS @EXPORT_OK $VERSION);

require Exporter;

@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use SlideMap ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw() ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw();

$VERSION = '1.1';


# Preloaded methods go here.

package SlideMap;
my %defaults;
{
	## set default values in case user neglects to do so; use old CT-72 format
	%defaults = (machine => 'IAS', x_pin => 2, y_pin => 6, x_spacing => 24,
				y_spacing => 25, x_repeat => 1, y_repeat => 1, x_pitch => 0,
				y_pitch => 0, num_spots => 0);
}

package SlideMap;
sub new {
	my $class = shift;
	my %args = (%defaults, @_);

	my $self = bless {
		# print head dimensions
		_x_pin => int($args{x_pin}),
		_y_pin => int($args{y_pin}),
		# block dimensions (in spots)
		_xspacing => int($args{x_spacing}),
		_yspacing => int($args{y_spacing}),
		# for future use; define the spacing in micrometers
		_x_pitch => int($args{x_pitch}),
		_y_pitch => int($args{y_pitch}),
		# microtitre plate dimensions (in wells)
		_max_plate_row => 0,			
		_max_plate_col => 0,
		# no. of dips in x (row) dimension
		_max_xpass => 0,			
		# no. of dips in y (col) dimension
		_max_ypass => 0,			
		# total # of dips per plate
		_pass_plate => 0,
		# number of wells per plate
		_num_wells => 0,			
		# total number of spots on slide; default 0
		_num_spots => int($args{num_spots}),,			
		# absolute array dimensions
		_max_row => 0,				
		_max_col => 0,
		# total number of plates to fill array
		_num_plates => 0,			
		# print order (labels for plates)
		_plates => [],				
		# 1 => 96-well, 2=> 384-well
		_format => 1,				
		# 0 => normal mode, 1 => repeat mode; for MD/MD3
		_repeat => 0,
		# number repeated blocks; 1 => none, 2 => 2 reps, etc.
		_x_repeat => int($args{x_repeat}),
		_y_repeat => int($args{y_repeat}),
		# 0 => top->bottom printing, 1 => left->right printing
		_print_dir => 0,			
		# 0 => (1,1)->B1 (IAS 12-pen mode), 1 => (1,1)->A1
		_nocomplement => 0,			
		_machine => $args{machine},
		# the slide map (row,col,plate,well)
		_map => [],
		# for Lucidia printer
		_paramA => 0,
		_paramB => 0,
		_convert_well => {},
		_convert_spot => {},
		_test => $args{test}
		
	}, $class;
	
	if($args{machine} eq 'MD3') {
		$self->{_format} = 2;
		$self->{_print_dir} = 1;
		$self->{_x_repeat} = 2;
		$self->{_x_repeat} = 1;
		$self->{_xspacing} = 32;
		$self->{_x_pin} = 1;
		$self->{_y_pin} = 12;
		$self->{_nocomplement} = 1;
		if($self->{_yspacing} > 12) { $self->{_yspacing} = 12; }
	} elsif($args{machine} eq 'Lucidia') {
		$self->{_format} = 2;
		$self->{_print_dir} = 1;
		$self->{_x_pin} = 2;
		$self->{_y_pin} = 12;
	} elsif($args{machine} eq 'Stanford') {
		$self->{_format} = 2;
		$self->{_print_dir} = 0;
		$self->{_x_pin} = 4;
		$self->{_y_pin} = 4;
		$self->{_nocomplement} = 0;
	} elsif($args{machine} eq 'MD') {
		$self->{_x_repeat} = 2;
		$self->{_x_repeat} = 1;
		$self->{_yspacing} = 16;
		$self->{_x_pin} = 1;
		$self->{_y_pin} = 6;
		$self->{_nocomplement} = 1;
		if($self->{_xspacing} > 16) { $self->{_yspacing} = 16; }
	} elsif($args{machine} eq 'IAS') {
	} else {
		$self->{_format} = 1;
		$self->{_print_dir} = 0;
		$self->{_x_repeat} = 1;
		$self->{_x_repeat} = 1;
		$self->{_nocomplement} = 0;
	}
	&initialize($self);

	return $self;
}

package SlideMap;
sub initialize {

	my $self = shift;
	my $flag = shift || 0;

	if($self->{_xspacing} < 1 || $self->{_xspacing} eq '') {
		die "x_spacing value not set\n"; }
	if($self->{_yspacing} < 1 || $self->{_yspacing} eq '') {
		die "y_spacing value not set\n"; }
	if($self->{_x_repeat} < 1 || $self->{_x_repeat} > 4) {
		die "x_repeat must be an integer between 1 and 4.\n"; }
	if($self->{_y_repeat} < 1 || $self->{_y_repeat} > 4) {
		die "x_repeat must be an integer between 1 and 4.\n"; }

	if($self->{_format} == 2) {
		$self->{_max_plate_row} = 16;
		$self->{_max_plate_col} = 24;
		$self->{_max_xpass} = 16 / $self->{_x_pin};
		$self->{_max_ypass} = 24 / $self->{_y_pin};
	} else {
		$self->{_max_plate_row} = 8;
		$self->{_max_plate_col} = 12;
		$self->{_max_xpass} = 8 / $self->{_x_pin};
		$self->{_max_ypass} = 12 / $self->{_y_pin};
	}
	if($self->{_x_pin} > $self->{_max_plate_row}) {
		die "x_pin must be an even integer <= plate row dimension\n"; }
	if($self->{_y_pin} > $self->{_max_plate_col}) { 
		die "y_pin must be an even integer <= plate column dimension\n"; }
	$self->{_num_wells} = $self->{_max_plate_row} 
		* $self->{_max_plate_col};
	$self->{_pass_plate} = $self->{_max_xpass} 
		* $self->{_max_ypass};
	$self->{_max_row} = $self->{_yspacing} * $self->{_y_pin} 
		* $self->{_y_repeat};
	$self->{_max_col} = $self->{_xspacing} * $self->{_x_pin} 
		* $self->{_x_repeat};
	$self->{_num_spots} = $self->{_max_row} * $self->{_max_col};
	$self->{_num_plates} = int(($self->{_num_spots} - 1)/ 
		($self->{_x_repeat} * $self->{_y_repeat} 
		* $self->{_num_wells})) + 1;
#	$self->{_max_pass} = $self->{_num_plates} * $self->{_pass_plate};
	if(! $flag) {
		@{ $self->{_plates} } = ( 1 .. $self->{_num_plates} );
	}
	$self->{_paramA} = $self->{_max_plate_row}/(2 * $self->{_x_pin});
	$self->{_paramB} = 2 * $self->{_x_pin};

	my $code1 = &make_convert_well($self);
	$self->{_convert_well} = eval "sub { $code1 }" or die $!;
	my $code2 = &make_convert_spot($self);
	$self->{_convert_spot} = eval "sub { $code2 }" or die $!;
	
}

package SlideMap;
sub fill_map {
	my $self = shift;
	for my $i (1 .. $self->{_max_row}) {
		for my $j (1 .. $self->{_max_col}) {
			my $spot = (($i - 1) * $self->{_max_col}) + $j;
			my ($plate, $well) = &convert_spot($self, $i, $j);
			my $current_plate = $self->{_plates}->[$plate - 1];
			$self->{_map}->[$spot] = [ $i, $j, $current_plate, 
				$well ];
		}
	}
	return $self->{_map};
}

package SlideMap;
sub diagnostics {
	my($self) = shift;
	print "machine: $self->{_machine}\n";
	print "x_pin: $self->{_x_pin}\ty_pin: $self->{_y_pin}\txspacing:"
		. " $self->{_xspacing}\t";
	print "yspacing: $self->{_yspacing}\n";
	print "x_repeat: $self->{_x_repeat}\ty_repeat: $self->{_y_repeat}\n";
	if($self->{_machine} eq 'Lucidia') {
		print "paramA: $self->{_paramA}\tparamB: $self->{_paramB}\n";
	}
	print "max_xpass: $self->{_max_xpass}\tmax_ypass: "
		. "$self->{_max_ypass}\t";
	print "pass_plate: $self->{_pass_plate}\n";
	print "max_row: $self->{_max_row}\tmax_col: $self->{_max_col}"
		. "\tnum_wells: ";
	print "$self->{_num_wells}: \tnum_spots: $self->{_num_spots}\n";
	print "format: $self->{_format}\tprint_dir: $self->{_print_dir}\n";
	print "nocomplement: $self->{_nocomplement}\trepeat mode: "
		. "$self->{_repeat}\n";
	print "num_plates: $self->{_num_plates}\n";
	print "plate_order: @{ $self->{_plates} }\n";
}

package SlideMap;
sub print_spots {
	my $self = shift;
	my $w = shift || 0;
	for my $y (1 .. $self->{_max_row}) {
			for my $x (1 .. $self->{_max_col}) {
				my $array_row = $y;
				my $array_col = $x;
				my $meta_row = int(($array_row - 1) 
						/ $self->{_yspacing})  + 1;
				my $meta_col = int(($array_col - 1) 
						/ $self->{_xspacing})  + 1;
				my ($plate_num, $well, $plate_row, $plate_col) 
					= &convert_spot($self,$array_row,$array_col);
				my $block = ((($meta_row) - 1) * $self->{_x_pin}) 
					+ $meta_col;
				if(length($plate_num) == 1) {
					$plate_num = "00" . $plate_num;
				} elsif(length($plate_num) == 2) {
					$plate_num = "0" . $plate_num;
				}
				if($w == 1) {
					if(length($well) == 1) {
						$well = "00" . $well;
					} elsif(length($well) == 2) {
						$well = "0" . $well;
					}
					print "$array_row\t$array_col\t$plate_num\t"
						. "$well\n";
				} else {
					my $rowstr = substr("ABCDEFGHIJKLMNOP", 
							$plate_row - 1, 1);
					if(length($plate_col) == 1) {
						$plate_col = "0" . $plate_col;
					}
					print "$array_row\t$array_col\t$plate_num\t"
						. "$rowstr$plate_col\n";
				}
			}
#		}
	}
}

package SlideMap;
sub print_wells {
	my $self = shift;
	my $w = shift || 0;
	foreach my $plate_num (@{ $self->{_plates} }) {
		foreach my $well (1 .. $self->{_num_wells}) {
			my $row = int(($well - 1) / $self->{_max_plate_col}) + 1;
			my $col = int(($well - 1) % $self->{_max_plate_col}) + 1;
			my @data_refs = &convert_well($self,$plate_num,$well);
			foreach my $ref (@data_refs) {
				my ($array_row, $array_col, $meta_row, $meta_col, 
					$sub_row, $sub_col) = @$ref;
				my $plate_str;
				if(length($plate_num) == 1) {
   	    	        $plate_str = "00" . $plate_num;
   	        	} elsif(length($plate_num) == 2) {
					$plate_str = "0" . $plate_num;
				} else {
					$plate_str = $plate_num;
				}
				if($w == 1) {
					if(length($well) == 1) {
						$well = "00" . $well;
					} elsif(length($well) == 2) {
						$well = "0" . $well;
					}
					print "$plate_str\t$well\t$array_row\t$array_col\n";
				} else {
					my $rowstr = substr("ABCDEFGHIJKLMNOP", $row - 1, 1);
					my $plate_col;
					if(length($col) == 1) {
						$plate_col = "0" . $col;
					} else {
						$plate_col = $col;
					}
					print "$plate_str\t$rowstr$plate_col\t$array_row\t"
						. "$array_col\n";
				}
			}
		}
	}
}

package SlideMap;
sub convert_well {
	my $self = $_[0];
	my @data = $self->{_convert_well}->(@_);
	return @data;
}

package SlideMap;
sub convert_spot {
	my $self = $_[0];
	my @data = $self->{_convert_spot}->(@_);
	return @data;
}

sub get_meta {
		my($self, $_array_row, $_array_col) = @_;

## get current 'meta' pin coordinates
	my $_meta_row = int(($_array_row - 1) / $self->{_yspacing})  + 1;
	my $_meta_col = int(($_array_col - 1) / $self->{_xspacing})  + 1;

## now find sub-grid coordinates
	my $_sub_row = $_array_row - (($_meta_row - 1) * $self->{_yspacing});
	my $_sub_col = $_array_col - (($_meta_col - 1) * $self->{_xspacing});

	return ($_meta_row,$_meta_col,$_sub_row,$_sub_col);
}

package SlideMap;
sub setFormat {
	my($self,$informat) = @_;
	if($informat == 1 || $informat == 2) {
		$self->{_format} = $informat;
		&initialize($self);
	} else {
		print "Format error: 1 = 96-well, 2 = 384-well\n";
	}
	return $self->{_format};
}

sub setPrintDirection {
	my($self,$dir) = @_;
	if($dir == 0 || $dir == 1) {
		$self->{_print_dir} = $dir;
	} else {
		print "Print Direction error: '0' => top->bottom, "
			. "'1' => left->right\n";
	}
	return $self->{_print_dir};
}
sub setNoComplement {
	my ($self,$nocomp) = @_;
	if($nocomp == 0 || $nocomp == 1) {
		$self->{_nocomplement} = $nocomp;
	} else {
		print "Complement error: '0' => complemented, "
			. "'1' => NOT complemented\n";
	}
	return $self->{_nocomplement};	
}
sub setRepeatMode {
	my ($self,$mode) = @_;
	if($mode == 1) {
		$self->{_repeat} = $mode;
		if($self->{_machine} eq 'MD' || $self->{_machine} eq 'MD3') {
			$self->{_x_repeat} = 1;
			$self->{_y_repeat} = 1;
			$self->{_print_dir} = 0;
			if($self->{_machine} eq 'MD3') {
				$self->{_xspacing} = 32;
				$self->{_yspacing} = 12;
			} else {
				$self->{_xspacing} = 16;
				$self->{_yspacing} = 16;
			}
		}
	} elsif($mode == 0) {
		$self->{_repeat} = $mode;
		if($self->{_machine} eq 'MD' || $self->{_machine} eq 'MD3') {
			$self->{_x_repeat} = 2;
			$self->{_y_repeat} = 1;
			if($self->{_machine} eq 'MD3') {
				$self->{_print_dir} = 1;
			} else {
				$self->{_print_dir} = 0;
			}
		}
	} else {
		print "Repeat error: '0' => normal mode, '1' => repeat"
			. "mode\n";
	}
	return $self->{_repeat};
}
sub setRepeats {
	my ($self,$xrep,$yrep) = @_;
	if($xrep > 0 && $xrep < 5) {
		$self->{_x_repeat} = $xrep;
	} else {
		print "Repeat error: '1' => NO repeat, '2','3','4' "
			. "repeats in x dimension\n";
	}
	if($yrep > 0 && $yrep < 5) {
		$self->{_y_repeat} = $yrep;
	} else {
		print "Repeat error: '1' => NO repeat, '2','3','4' "
			. "repeats in y dimension\n";
	}
	return $self->{_x_repeat},$self->{_y_repeat};
}
sub setPlateOrder {
	my $self = shift;
	my $order_string = shift;
	my @tmp = split(/\W+/,$order_string);
	if($order_string eq '') {
		@{ $self->{_plates} } = (1 .. $self->{_num_plates});
	} else {
		@{ $self->{_plates} } = @tmp;
	}
	# re-initialize with flag = 1 so plate_order is not re-set
	&initialize($self,1);		
	return $self->{_plates};
}
sub setPrintHead {
	my($self,$x,$y) = @_;
	if($x > 0 && $y > 0) {
		$self->{_x_pin} = int($x);
		$self->{_y_pin} = int($y);
		&initialize($self);
	} else {
		print "Print head dimensions must be non-zero integers.\n";
	}
	return $self->{_x_pin},$self->{_y_pin};
}

sub setBlockDimensions {
	my($self,$xs,$ys) = @_;
	if($xs > 0 && $ys > 0) {
		$self->{_xspacing} = int($xs);
		$self->{_yspacing} = int($ys);
		&initialize($self);
	} else {
		print "Block dimensions must be non-zero integers.\n";
	}
	return;
}

sub setMachine {
	my($self,$machine) = @_;

	$self->{_machine} = $machine;
	if($machine eq 'MD3') {
		$self->{_format} = 2;
		$self->{_print_dir} = 1;
		$self->{_x_repeat} = 2;
		$self->{_y_repeat} = 1;
		$self->{_xspacing} = 32;
		$self->{_x_pin} = 1;
		$self->{_y_pin} = 12;
		$self->{_nocomplement} = 1;
	} elsif($machine eq 'Lucidia') {
		$self->{_format} = 2;
		$self->{_print_dir} = 1;
		$self->{_x_repeat} = 1;
		$self->{_y_repeat} = 1;
		$self->{_nocomplement} = 0;
		$self->{_x_pin} = 2;
		$self->{_y_pin} = 12;
	} elsif($machine eq 'Stanford') {
		$self->{_format} = 2;
		$self->{_print_dir} = 0;
		$self->{_x_pin} = 4;
		$self->{_y_pin} = 4;
		$self->{_x_repeat} = 1;
		$self->{_y_repeat} = 1;
		$self->{_nocomplement} = 0;
	} elsif($machine eq 'MD') {
		$self->{_format} = 1;
		$self->{_print_dir} = 1;
		$self->{_x_repeat} = 2;
		$self->{_y_repeat} = 1;
		$self->{_yspacing} = 16;
		$self->{_x_pin} = 1;
		$self->{_y_pin} = 6;
		$self->{_nocomplement} = 1;
	} elsif($machine eq 'IAS') {
		$self->{_format} = 1;
		$self->{_print_dir} = 0;
		$self->{_x_repeat} = 1;
		$self->{_y_repeat} = 1;
		$self->{_nocomplement} = 0;
	} else {
		$self->{_format} = 1;
		$self->{_print_dir} = 0;
		$self->{_x_repeat} = 1;
		$self->{_y_repeat} = 1;
		$self->{_nocomplement} = 0;
	}
	$self->initialize;
}

sub getFormat { return $_[0]->{_format}; }
sub getPrintDirection { return $_[0]->{_print_dir}; }
sub getNoComplement { return $_[0]->{_nocomplement}; }
sub getRepeats { return $_[0]->{_x_repeat}, $_[0]->{_y_repeat}; }
sub getRepeatMode { return $_[0]->{_repeat}; }
sub getPrintHead { return $_[0]->{_x_pin}, $_[0]->{_y_pin}; }
sub getBlockDimensions { return $_[0]->{_xspacing}, 
		$_[0]->{_yspacing}; }
sub getMachine { return $_[0]->{_machine}; }
sub getPlateOrder { return $_[0]->{_plates}; }
sub getMap { return $_[0]->{_map}; }
sub getArrayDimensions { return $_[0]->{_max_row}, $_[0]->{_max_col}; }
sub getPitch { return $_[0]->{_x_pitch}, $_[0]->{_y_pitch}; }
sub getNumSpots { return $_[0]->{_num_spots}; }
sub showConvertWell { print "\nconvert_well:\n", &make_convert_well($_[0]); }
sub showConvertSpot { print "\nconvert_spot:\n", &make_convert_spot($_[0]); }

sub make_convert_spot {

	my $self = shift;
	my $code = '
	my($self, $_array_row, $_array_col) = @_;
	';

## A.	get current 'meta' pin coordinates

	$code .= '
	my $_meta_row = int(($_array_row - 1) / $self->{_yspacing})  + 1;
	my $_meta_col = int(($_array_col - 1) / $self->{_xspacing})  + 1;
	';

## B.	get current pin coordinates

	$code .= '
	my $_curr_ypin = int(($_meta_row - 1) / $self->{_y_repeat})  + 1;
	my $_curr_xpin = int(($_meta_col - 1) / $self->{_x_repeat})  + 1;
	';

## C.	now find sub-grid coordinates

	$code .= '
	my $_spot_row = $_array_row - (($_meta_row - 1) * $self->{_yspacing});
	my $_spot_col = $_array_col - (($_meta_col - 1) * $self->{_xspacing});
	';

	if($self->{_machine} eq 'Stanford') {
		$code .= '
	$_spot_col = ($self->{_xspacing} + 1 - $_spot_col);
		';
	}
	$code .= '
	my $_sub_row = $_spot_row;
	my $_sub_col = $_spot_col;
	';

## D.	calc. cummulative head-pass, i.e. number of times head prints on slide

	if($self->{_print_dir} == 1) {
		## MD3 style printing; left -> right
		$code .= '
	my $_cum_pass = (($_spot_row - 1) * $self->{_xspacing}) + $_spot_col;
		';
	} else {
		## default; IAS style printing; top -> bottom
		$code .= '
	my $_cum_pass = (($_spot_col - 1) * $self->{_yspacing}) + $_spot_row;
		';
	}
## get plate number, equivalent to ordinal
	$code .= '
	my $_plate_num = int(($_cum_pass - 1) / $self->{_pass_plate}) + 1;
	';
## calc. current pass number
	$code .= '
	my $_curr_pass = int(($_cum_pass - 1) % $self->{_pass_plate}) + 1;
	';
## now get x and y pass coordinates
	
	if($self->{_machine} eq 'Stanford') {
		$code .= '
	my $_x_pass = int(($_curr_pass - 1) / $self->{_max_ypass}) + 1;
	my $_y_pass = int(($_curr_pass - 1) % $self->{_max_ypass}) + 1;
		';
	} else {
		$code .= '
	my $_y_pass = int(($_curr_pass - 1) / $self->{_max_xpass}) + 1;
	my $_x_pass = int(($_curr_pass - 1) % $self->{_max_xpass}) + 1;
		';
	}

## E.	now get plate row and col coordinates

	if($self->{_machine} eq 'Lucidia' && $self->{_nocomplement} == 1) {
		$code .= '
	my $_plate_row = (($_x_pass - 1) % $self->{_paramA}) 
		* $self->{_paramA} + int(($_x_pass - 1) / $self->{_paramB}) 
		+ 2 * ($_curr_xpin) - 1;
		';
	} elsif($self->{_machine} eq 'Lucidia') {
		$code .= '
	my $_plate_row = (($_x_pass - 1) % $self->{_paramA}) 
		* $self->{_paramA} + int(($_x_pass - 1) / $self->{_paramB})
		+ 2 * (1 - $_curr_xpin + $self->{_x_pin}) - 1;
		';
	} elsif($self->{_nocomplement} == 1) {
		$code .= '
	my $_plate_row = (($_x_pass - 1) * $self->{_x_pin}) + $_curr_xpin;
		';
	} else {
		$code .= '
	my $_plate_row = (($_x_pass - 1) * $self->{_x_pin}) 
		+ (1 - $_curr_xpin + $self->{_x_pin});
		';
	}
	$code .= '
	my $_plate_col = (($_y_pass - 1) * $self->{_y_pin}) + $_curr_ypin;
	';

## F.	convert row, col coordinates to well number
	$code .= '
	my $_well = (($_plate_row - 1) * $self->{_max_plate_col}) + $_plate_col;
	return ($_plate_num, $_well, $_plate_row, $_plate_col);
	';

	return $code;
}


sub make_convert_well {
	
	my($self) = shift;
	
	my $code = '
	my($self, $_plate_num, $_well) = @_;
	';

## convert well number to row, col

	$code .= '
	my $_row = int(($_well - 1) / $self->{_max_plate_col}) + 1;
	my $_col = int(($_well - 1) % $self->{_max_plate_col}) + 1;
	';
	
## get current pin coordinates

	if($self->{_machine} eq 'Lucidia') {
		$code .= '
	my $_curr_xpin = $self->{_x_pin} - (int(($_row - 1)/2) % $self->{_x_pin});
		';
	} elsif($self->{_nocomplement} == 1) {
		$code .= '
	my $_curr_xpin = (($_row - 1) % $self->{_x_pin}) + 1;
		';
	} else {
		$code .= '
	my $_curr_xpin = $self->{_x_pin} - (($_row - 1) % $self->{_x_pin});
		';
	}
	$code .= '
	my $_curr_ypin = (($_col - 1) % $self->{_y_pin}) + 1;
	';

## get pass numbers

	if($self->{_machine} eq 'Lucidia') {
		$code .= '
	my $_xpass = ((($_row - 1) % 2) * $self->{_paramA}) 
		+ int(($_row - 1) / $self->{_paramB}) + 1;
		';
	} else {
		$code .= '
	my $_xpass = int(($_row - 1) / $self->{_x_pin}) + 1;
		';
	}
	$code .= '
	my $_ypass = int(($_col - 1) / $self->{_y_pin}) + 1;
	';

## get cummulative print-head pass on plate

	if($self->{_machine} eq 'Stanford') {
	$code .= '
	my $_cum_pass = (($_plate_num - 1) * $self->{_pass_plate}) 
		+ (($_xpass - 1) * $self->{_max_ypass}) + $_ypass;
	';
	} else {
	$code .= '
	my $_cum_pass = (($_plate_num - 1) * $self->{_pass_plate}) 
		+ (($_ypass - 1) * $self->{_max_xpass}) + $_xpass;
	';
	}

## calc. sub-grid coordinates

	if($self->{_print_dir} == 1) {
		$code .= '
	my $_spot_row = int(($_cum_pass - 1) / $self->{_xspacing}) + 1;
	my $_spot_col = int(($_cum_pass - 1) % $self->{_xspacing}) + 1;
		';
	} else {
		$code .= '
	my $_spot_row = int(($_cum_pass - 1) % $self->{_yspacing}) + 1;
	my $_spot_col = int(($_cum_pass - 1) / $self->{_yspacing}) + 1;
		';
	}
	if($self->{_machine} eq 'Stanford') {
		$code .= '
	$_spot_col = ($self->{_xspacing} + 1 - $_spot_col);
		';
	}
	$code .= '
	my $_sub_row = $_spot_row;
	my $_sub_col = $_spot_col;
	';

## calc. array coordinates
## now handle the repeats and return a list of references to the data

	$code .= '
	my($_array_row,$_array_col,$_meta_row,$_meta_col);
	my @data;
	for my $j (1 .. $self->{_y_repeat}) {
		$_meta_row = $j + ($_curr_ypin - 1) * $self->{_y_repeat};
		$_array_row = $_spot_row + ($_meta_row - 1) * $self->{_yspacing};
		for my $i (1 .. $self->{_x_repeat}) {
			$_meta_col = $i + ($_curr_xpin - 1) * $self->{_x_repeat};
			$_array_col = $_spot_col + ($_meta_col - 1) * $self->{_xspacing};
			push @data, [ $_array_row, $_array_col, $_meta_row, $_meta_col, 
				$_sub_row, $_sub_col ];
		}
	}
	return @data;
	';
	
	return $code;
}

1;
__END__

=head1 NAME

SlideMap - Perl module for the creation of MicroArray slide maps

=head1 SYNOPSIS

  use SlideMap;
  
  $sm = SlideMap->new( machine => "arrayer", x_pin => 2, y_pin => 6,
  					xspacing => 0, yspacing => 0, x_repeat => 1, 
  					y_repeat => 1);
  
  $sm->initialize;
  $sm->fill_map;
  $map_ref = $sm->getMap;
  
  ($array_row, $array_col, $meta_row, $meta_col, $sub_row, $sub_col) 
  		= $sm->convert_well($plate_num, $well);
  
  ($plate_num, $well, $plate_row, $plate_col) 
  		= $sm->convert_spot($array_row, $array_col);

  ($_meta_row,$_meta_col,$_sub_row,$_sub_col) 
  		= $sm->get_meta($array_row, $array_col);
  		
  $sm->setMachine("arrayer");
  $arrayer = $sm->getMachine;
  
  $sm->setPrintHead(2, 6);
  ($x_pin, $y_pin) = $sm->getPrintHead;
  
  $sm->setBlockDimensions(25, 24);
  ($x_spacing, $y_spacing) = $sm->getBlockDimensions;
  
  $sm->setNoComplement([ 0 | 1 ]);
  $noComplement = $sm->getNoComplement;
  
  $sm->setRepeats([ 1 | 2 | 3 | 4 ], [ 1 | 2 | 3 | 4 ]);
  ($x_repeat,$y_repeat) = $sm->getRepeatMode;

  $sm->setRepeatMode([ 0 | 1 ]);
  $repeatMode = $sm->getRepeatMode;
  
  $sm->setFormat([ 1 | 2 ]);
  $plate_format = $sm->getFormat;
  
  $sm->setPrintDirection([ 0 | 1 ]);
  $direction = $sm->getPrintDirection;
  
  $sm->setPlateOrder("[A,B,C,D,E,F,G ... | 1,2,3,4,5, ... ]");
  $plate_order = $sm->getPlateOrder;
  
  ($max_array_row,$max_array_col) = $sm->getArrayDimensions;

  ($x_pitch,$y_pitch) = $sm->getPitch;

  $number_of_spots = $sm->getNumSpots;

  $sm->diagnostics;
  $sm->print_spots([ 1 | 0 ]);
  $sm->print_wells([ 1 | 0 ]);
  $sm->showConvertWell;
  $sm->showConvertSpot;
  

=head1 DESCRIPTION

SlideMap is used to create a row/col -> plate/well map of a microarray 
slide.  It does not as yet incorporate annotation data into the map, 
but simply creates the map object based on input parameters.  The map 
is an ordered list of spots with references to annonymous arrays 
containing array_row, array_col, plate_alias, well.  SlideMap currently 
supports 5 types of arrayers: IAS (default), MD, MD3, Lucidia, and 
Stanford.  (Others will be implemented as needed.)  

SlideMap provides 2 methods for conversion of spots->wells and vise-versa,
based on instantiated parameters.  

The main parameters are: 
machine: 	the type of array printing machine used (IAS is the default)
x_pin: 		the number of print head pens in the 'X' (plate_row) dimension
y_pin: 		the number of print head pens in the 'Y' (plate_col) dimension
			(x_pin = 2, and y_pin = 6 are the defaults)
x_spacing: 	the number of spots in one row of a block on the array
y_spacing: 	the number of spots in one column of a block on the array
			(x_spacing = 24, and y_spacing = 25 are the defaults)
x_repeat:	the number of repeated block in the 'X' dimension (default = 1)
y_repeat:	the number of repeated block in the 'Y' dimension (default = 1)

The SlideMap module can be used in several ways:
a) 'use' SlideMap, call the constructor with all parameters, and convert 
	spots or wells, fill the map object and loop over it:
	
	use SlideMap;
	$sm->SlideMap->new( machine => "MD3", x_pin => 1, y_pin => 12,
				xspacing => 32, yspacing => 10);
	$ref = $sm->fill_map;
	foreach $row_ref (@$ref)) {
		($row,$col,$plate,$well) = @$row_ref;
		...
	}

b) 'use' SlideMap, call the constructor with minimal parameters, and set 
	parameters individually, then re-initialize and loop over the map:

	use SlideMap;
	$sm->SlideMap->new( machine => "MD3");
	$sm->setBlockDimensions(32,6);
	$ref = $sm->fill_map;
	foreach $row_ref (@$ref)) {
		($row,$col,$plate,$well) = @$row_ref;
		...
	}

c) 'use' SlideMap, call the constructor with machine argument not 
	listed above, set parameters individuzlly, then initialize the 
	map. This is useful for arrayers that are not listed above but 
	operate similarly to one of the above mentioned machines. NOTE:
	default values for parameters are used in this case).
	
	use SlideMap;
	$sm->SlideMap->new(x_pin => 2, y_pin => 12, xspacing => 32, 
		yspacing => 10, machine => 'arrayer');
	$sm->setNoComplement(1);
	$sm->setFormat(1);
	$sm->setPrintDirection(1);
	$sm->setRepeats(1,1);
	$ref = $sm->fill_map;
	foreach $row_ref (@$ref)) {
		($row,$col,$plate,$well) = @$row_ref;
		...
	}

There are several default values associated with each arrayer listed 
above.  They are:

IAS:
Default:
format = 1
print_direction = 0
x_repeat = 1
y_repeat = 1
noComplement = 0

MD3:
format = 2
print_direction = 1
x_repeat = 2
y_repeat = 1
x_spacing = 32
x_pin = 1
y_pin = 12
noComplement = 1

MD:
format = 1
print_direction = 0
x_repeat = 2
y_repeat = 1
yspacing = 16
x_pin = 1
y_pin = 6
noComplement = 1

Stanford:
format = 2
print_direction = 0
x_pin = 4
y_pin = 4
x_repeat = 1
y_repeat = 1
noComplement = 0

Lucidia:
format = 2
print_dir = 1
x_repeat = 1
y_repeat = 1
nocomplement = 0
x_pin = 2
y_pin = 12

=head1 DETAILS

This constructor call will create a SlideMap object using the default 
parameter settings: 

$sm = SlideMap->new( machine => "IAS", x_pin => 2, y_pin => 6,
				x_spacing => 24, y_spacing => 25, x_repeat => 1,
				y_repeat => 1);

The constructor will do all initialization, but will 'NOT' create a 
map in memory.  That can be done as follows:

$sm->fill_map;

After the map has been created in memory, a reference to the map 
object is obtained by calling getMap.  The map object is an array 
consisting of references to annonymous arrays holding array_row, 
array_col, plate_alias (or number), well number.

$map_ref = $sm->getMap;

Individual spots can be mapped back to their originating microtitre 
plate by supplying the row and column index of the spot to 
convert_spot:

($plate_num, $well, $plate_row, $plate_col) 
	= $sm->convert_spot($array_row, $array_col);
  
Well is an integer representing the well position on a plate.  
Starting from well 1 (A1), this number increases across a row and 
then to the next row, so A12 in a 96-well plate is well 12 and B1 
is well 13, etc.  Plate_row is an 1-based integer that represents 
the row.

Likewise, the row and column indeces for a spot can be obtained 
from the plate_num and well used as source for the spot.  
NOTE: plate_num here refers to the position of the plate in the 
series of plates used for the printing, i.e. it is an plate ordinal.  

	@array_of_arrays = $sm->convert_well($plate_num, $well);

This method returns an array of references to arrays.  Since a well
may be spotted more than once on a slide (due to repeat status) 
this method returns data for multiple spots.  Eeach reference
points to an array with the following data:

($array_row, $array_col, $meta_row, $meta_col, $sub_row, $sub_col) 

The meta_row and meta_col indeces refer to the row/col indeces of 
the pin that printed the spot in question.  The sub_row and sub_col 
indeces refer to the indeces of the spot within a block.  The 
array_row and array_col indeces are obvious.

SlideMap includes a convenience method to return the meta_row/col, 
and sub_row/col indeces for a pair of array_row, array_col indeces:

($_meta_row,$_meta_col,$_sub_row,$_sub_col) 
  		= $sm->get_meta($array_row, $array_col);

The following are get/set methods that can be used to customize a
SlideMap object to accomodate array printers not supported at the 
time of release of SlideMap.pm.  

getMachine: returns the current machine setting:

$arrayer = $sm->getMachine;

setMachine: sets the machine type used for printing.  Currently 
SlideMap supports 4 types of arrayers: 'IAS', 'MD', 'MD3', 'Lucidia'
and 'Stanford'.  Note: This method resets all parameters to their 
pre-defined default values and reinitializes the SlideMap object.  
Using this methode requires that other parameters be set with the 
methods below (if they are different from the defaults).  To set 
the machine type:

$sm->setMachine("arrayer");

setPrintHead: defines the numbers of pens in the print head, 
	'X' (plate_row) and 'Y' (plate_col):

$sm->setPrintHead(2, 6);

getPrintHead: returns the numbers of pens in the print head:

($x_pin, $y_pin) = $sm->getPrintHead;
  
setBlockDimensions: set maximumn row and column indeces in blocks 
on the array, row first then column:

$sm->setBlockDimensions(25, 24);

getBlockDimensions: returns block dimensions:

($x_spacing, $y_spacing) = $sm->getBlockDimensions;
  
NOTE: All of the following 'set*' methods require re-initialization of 
the SlideMap object:

$sm->initialize;

setNoComplement: switches printing pattern in the 'X' dimension; 
this is in effect complementing (1 - x) in the 'X' dimension only.  
Valid values are 0 => complemented, and 1 => 'NOT' complemented:

$sm->setNoComplement([ 0 | 1 ]);

getNoComplement: returns the current value of the noComplement 
parameter:

$noComplement = $sm->getNoComplement;
  
setRepeats: number of repeated blocks in 'X' and 'Y' dimension.  
Valid values are 1 - 4:

$sm->setRepeats([ 1 | 2 | 3 | 4 ], [ 1 | 2 | 3 | 4 ]);

getRepeatMode: returns the current values of x_repeat and y_repeat:

($x_repeat, $y_repeat) = $sm->getRepeatMode;

SlideMap supports repeat mode for the MD/MD3 arrayers only.  
setRepeatMode: normal mode ('0') does nothing, but repeat mode ('1')
sets x_repeat = y_repeat = 1, and print_direction = 0 (like default):
  
$sm->setRepeatMode([ 0 | 1 ]);

getRepeatMode: returns the current value of the repeat parameter:

$repeatMode = $sm->getRepeatMode;

setFormat: microtitre plate format: valid values are 1 => 96-well, 
and 2=> 384-well:

$sm->setFormat([ 1 | 2 ]);

getFormat: returns the current value of the format parameter:

$plate_format = $sm->getFormat;
  
setPrintDirection: defines the order of printing used by the 
printer.  Valid values are 0 => top->bottom, and 1 => left->right:

$sm->setPrintDirection([ 0 | 1 ]);

getPrintDirection: returns the current value of the print_dir 
parameter:

$direction = $sm->getPrintDirection;
  
setPlateOrder: define a list of plate labels (aliases) for the 
complete set of plates used for printing.  The list should include 
all repeats of the plate:

$sm->setPlateOrder("[A,B,C,D,E,F,G ... | 1,2,3,4,5, ... ]");

getPlateOrder: returns a reference to an array containing the 
entire list of plate labels:

$plate_order_ref = $sm->getPlateOrder;

getArrayDimensions: returns the maximum row and column indeces 
for the current SlideMap object:

($max_array_row,$max_array_col) = $sm->getArrayDimensions;

getPitch: returns the pitch values used to create the current 
SlideMap object:

($x_pitch,$y_pitch) = $sm->getPitch;

getNumSpots: returns the number of spots in the current SlideMap
object:

$number_of_spots = $sm->getNumSpots;


=head1 DIAGNOTICS

diagnostics: returns the full set of current values for the 
SlideMap parameters:

$sm->diagnostics;

print_spots/print_wells: prints an entire set of row/col/plate/well 
values based on the current SlideMap parameters.  if the optional 
parameter is set to 1 (true) then well numbers are printed as well 
numbers; if set to 0 or not set, then the well number is returned 
as row_col, i.e. A1, B12, etc.  These methods are useful for 
diagnosing errors in the print pattern.  

$sm->print_spots([ 1 | 0 ]);
$sm->print_wells([ 1 | 0 ]);

The algorithms used to convert spots to wells and vise-versa are 
dynamically generated based on the type of arrayer (machine) supplied
as a parameter to the constructor (or to setMachine).  To view the 
algorithm currently being used, use either of the following methods:

$sm->showConvertWell;
$sm->showConvertSpot;


=head2 EXPORT

None by default.


=head1 AUTHOR

Joseph A. White;	jwhite@tigr.org		Version 1.2		Feb. 7, 2002

=head1 SEE ALSO

perl(1).

=cut
