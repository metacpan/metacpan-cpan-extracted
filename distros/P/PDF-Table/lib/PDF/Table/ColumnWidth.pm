package PDF::Table::ColumnWidth;

use strict;
use warnings;

use Carp;
use List::Util qw[min max];  # core

our $VERSION = '1.003'; # VERSION
our $LAST_UPDATE = '1.003'; # manually update whenever code is changed

###################################################################
# calculate the column widths
#   minimum: any specified min_w, increased to longest word in column
#   maximum: largest total length of content, reduced to any spec. max_w
#   maximum must be at least as large as minimum
#   TBD: rules and borders? currently overlay cells. consider 
#        expanding h and w by width of rules and borders. would involve
#        mucking with cell background fill dimensions? remember that
#        rule widths could vary by cell. perhaps could just increase cell
#        dimensions (and padding) by rule widths, and continue to overlay?
#   expand min widths to fill to desired total width, try not to
#     exceed maximum widths
# NOTE: this routine is called directly from t/PDF-Table.t
###################################################################

sub CalcColumnWidths {
    my $avail_width     = shift;  # specified table width
    my $col_min_width   = shift;  # content-driven min widths (longest word) and
                                  # optional min_w
    my $col_max_content = shift;  # content-driven max widths 
    my $max_w           = shift;  # -1 unless optional max_w for column

    my $min_width       = 0;      # calculate minimum overall table width needed
    my $calc_widths ;             # each column's calculated width

    my $num_cols = scalar(@$max_w);
    # total requested minimum width (min_w property) plus min for content
    # also initialize result calc_widths to min_width
    for (my $j = 0; $j < scalar $num_cols; $j++) {
        # min_w requested minimum AND longest word
        $calc_widths->[$j] = $col_min_width->[$j];
        # overall table minimum width
        $min_width += $calc_widths->[$j];
    }

    # minimum possible width for each column results in wider table?
    if ($avail_width < $min_width) {
        carp "!!! Warning !!!\n Table width expanded from $avail_width to $min_width\n";
        $avail_width = $min_width;
    }

    # Calculate how much can be added to every column to fit the available width
    # Allow columns to expand to max_w before applying extra space equally.
    # @max is SMALLER of max_w (if given) and content length, but at least as
    #   large as $col_min_width
    my (@max, @natural, @indices);

    # @max = absolute widest this column can be
    # initially max_w if given (>0), else table width
    for (my $col=0; $col<$num_cols; $col++) {
        $max[$col] = $avail_width;
        if ($max_w->[$col] > 0) {
            $max[$col] = min($max[$col], $max_w->[$col]);
        }
        $max[$col] = max($max[$col], $col_min_width->[$col]);
    }

    # @natural = width fraction of avail_width, based only on content size
    # ($col_max_content), before any limits applied
    my $sum_content_size = 0;
    for (my $col=0; $col<$num_cols; $col++) {
        $sum_content_size += $col_max_content->[$col];
    }
    $sum_content_size /= $avail_width;
    for (my $col=0; $col<$num_cols; $col++) {
        $natural[$col] = $col_max_content->[$col]/$sum_content_size;
    }

    # loop to adjust sizes, after setting size to natural
   #my $old_total_delta = -1;
    my $total_delta = 0;
    my $again = 1;
    for (my $col=0; $col<$num_cols; $col++) {
        $calc_widths->[$col] = $natural[$col];
    }

    while ($again) {
        $again = 0;

        # let expand to satisfy min be offset by contract to satisfy max
        # note that $total_delta adjusted from previous loop, not restarted
        for (my $col = 0; $col < $num_cols; $col++) {
            if      ($calc_widths->[$col] < $col_min_width->[$col]) {
                $total_delta += $col_min_width->[$col] - $calc_widths->[$col];
                $calc_widths->[$col] = $col_min_width->[$col];
            } elsif ($calc_widths->[$col] > $max[$col]) {
                $total_delta -= $calc_widths->[$col] - $max[$col];
                $calc_widths->[$col] = $max[$col];
            }
        }
        # total_delta within +/-.1% of avail_width? we're done!
        if (abs($total_delta) <= 0.001*$avail_width) { last; }

        my $change_amt;
        if ($total_delta > 0) {
            # net was we expanded more to satisfy min, so reduce any column
            # not at min, proportional to content (natural)
            @indices = ();
            # @indices lists all columns NOT already at min
            $sum_content_size = 0;
            for (my $col=0; $col<$num_cols; $col++) {
                if ($calc_widths->[$col] == $col_min_width->[$col]) { next; }
                push @indices, $col;
                $sum_content_size += $col_max_content->[$col];
            }
            if (!scalar @indices || $sum_content_size <= 0) {
                # everyone at min but need to reduce... should NOT see this
                carp "Problem... need to reduce column widths, but all already at minimum!";
                last;
            }
            my $max_reduce_size;
            $sum_content_size /= $total_delta;
            foreach my $col (@indices) {
                $max_reduce_size = $calc_widths->[$col] - $col_min_width->[$col];
                # change amount is positive
                $change_amt = $col_max_content->[$col]/$sum_content_size;
                $change_amt = min($change_amt, $max_reduce_size);
                $calc_widths->[$col] -= $change_amt;
                $total_delta -= $change_amt;
                $again = 1;
            }

        } else { # total_delta < 0
            # net was we contracted more to satisfy max, so expand any column
            # not at max, proportional to content (natural) 
            @indices = ();
            # @indices lists all columns NOT already at max
            $sum_content_size = 0;
            for (my $col=0; $col<$num_cols; $col++) {
                if ($calc_widths->[$col] == $max[$col]) { next; }
                push @indices, $col;
                $sum_content_size += $col_max_content->[$col];
            }
            if (!scalar @indices || $sum_content_size <= 0) {
                # everyone at max but need to increase... should NOT see this
                carp "Problem... need to increase column widths, but all already at maximum!";
                last;
            }
            my $max_increase_size;
            $sum_content_size /= $total_delta;
            foreach my $col (@indices) {
                $max_increase_size = $max[$col] - $calc_widths->[$col];
                # change amount is positive
                $change_amt = -$col_max_content->[$col]/$sum_content_size;
                $change_amt = min($change_amt, $max_increase_size);
                $calc_widths->[$col] += $change_amt;
                $total_delta += $change_amt;
                $again = 1;
            }

        } # if-elsif to handle decrease or increase by total_delta

    } # while($again) loop

    return ($calc_widths, $avail_width);
} # End of CalcColumnWidths()

###################################################################
# set the column widths per 'size' string
#   width = available width of table (points)
#   size  = string describing each column's width
#     NvalUnit for each, where Nval is a positive number
#        (default 1) and Unit is an optional unit or float
#        specifier. Nval, or Unit, or both must be given for 
#        each column.
#     If Unit not given, the number is assumed to be Points
#        (1/72 inch). Permitted units are cm, mm, in, em, ex, pt
#        (any case).
#   returned values are array of column widths (points) and
#                   total width (points), increased if necessary
###################################################################

sub SetColumnWidths {
    my $avail_width  = shift;  # specified table width
    my $size         = shift;  # width specifications
    my $em_size      = shift;  # size of em in points
    my $ex_size      = shift;  # size of ex in points

    my @colspecs = split /\s+/, $size;
    if (!scalar @colspecs) {
	die "!! Error !!\nNo column width specifications found in size '$size'!\n";
    }

    my ($calc_widths, $float_widths, $number, $unit);
    for (my $col=0; $col<scalar(@colspecs); $col++) {
	if      ($colspecs[$col] =~ m#^([\d.]+)([*a-z]+)$#i) {
	    # it appears to be NvalUnit in $1, $2
	    $number = $1;
	    $unit = $2;
        } elsif ($colspecs[$col] =~ m#^([\d.]+)$#) {
            # found just Nval in $1
	    $number = $1;
	    $unit = 'pt';
        } elsif ($colspecs[$col] =~ m#^([*a-z]+)$#i) {
            # found just Unit in $1
	    $number = 1;
	    $unit = $1;
            # it is discouraged, but legal, for e.g., 'in' => 1 inch
	} else {
	    # unable to disassemble this entry, including negative numbers
	    carp "!! Warning !!\nUnable to decode column $col entry '$colspecs[$col]', using '*' instead\n";
	    $number = 1;
	    $unit = '*';
	}

	# see if legal number \d+, \d+., \d+.\d+, .\d+
	if ($number =~ m#^\d+$#      ||
	    $number =~ m#^\d+\.$#    ||
	    $number =~ m#^\d+\.\d+$# ||
	    $number =~ m#^\.\d+$#) {
	    # valid number, use $number
	} else {
	    # invalid number format, replace by 1
	    # can detect multiple decimal points, but no check for range
	    carp "!! Warning !!\nInvalid number '$number' in column $col, using '1' instead.\n";
	    $number = 1;
        }

	# see if legal unit *, pt, in, cm, mm, em, ex
	# if so, convert to points, add to calc_widths array
	if      ($unit =~ m#^\*$#) {
	    $calc_widths->[$col] = -1; # mark as floating for now
	    $float_widths->[$col] = $number;
	} elsif ($unit =~ m#^pt$#i) {
	    $calc_widths->[$col] = $number;
	    $float_widths->[$col] = -1;
	} elsif ($unit =~ m#^in$#i) {
	    $calc_widths->[$col] = $number * 72;
	    $float_widths->[$col] = -1;
	} elsif ($unit =~ m#^cm$#i) {
	    $calc_widths->[$col] = $number * 72 / 2.54;
	    $float_widths->[$col] = -1;
	} elsif ($unit =~ m#^mm$#i) {
	    $calc_widths->[$col] = $number * 72 / 25.4;
	    $float_widths->[$col] = -1;
	} elsif ($unit =~ m#^em$#i) {
	    $calc_widths->[$col] = $number * $em_size;
	    $float_widths->[$col] = -1;
	} elsif ($unit =~ m#^ex$#i) {
	    $calc_widths->[$col] = $number * $ex_size;
	    $float_widths->[$col] = -1;
	} else {
	    # invalid unit, replace by mm
	    carp "!! Warning !!\nInvalid unit '$unit' in column $col, using 'mm' instead.\n";
	    $unit = 'mm';
	    $calc_widths->[$col] = $number * 72 / 25.4;
	    $float_widths->[$col] = -1;
	}
    } # loop through columns $col

    # calc_widths -1 need updating from float_widths
    # first need to calculate available space to allocate (if < 1 pt, increase
    # width with warning). divide by sum of float_widths to get size of 1*, 
    # and finally, transfer to calc_widths.
    my $width_used = 0; # used for fixed widths, non-*
    my $total_float = 0; # sum up float_widths
    for (my $col=0; $col<scalar(@colspecs); $col++) {
	if ($float_widths->[$col] > 0) {
	    # we have a float (*) to handle
	    $total_float += $float_widths->[$col];
	} else {
	    # presumably a fixed value
	    $width_used += $calc_widths->[$col];
	}
    }

    # check if width_used exceeds available width!
    if ($width_used > $avail_width) {
	carp "!! Warning !!\nSum of fixed widths ($width_used) exceeds available width ($avail_width), increase width.\n";
	$avail_width = $width_used;
    }

    # if == 0, should already be valid number (width in pts) in all calc_widths
    if ($total_float > 0) {
	# at least one * entry to allocate among at least 1 pt of space
	# first, how much space to allocate, or does width need to be increased?
	if ($avail_width - $width_used < 1) {
	    # too little space available, must increase total width
	    carp "!! Warning !!\nToo little space (".($avail_width-$width_used)."pts) to allocate among floats.\nIncrease table width by 5em per float unit.\n";
	    $avail_width += 5*$em_size*$total_float;
	}

	# have SOME room to allocate, so how many points per *?
	my $star_size = ($avail_width - $width_used)/$total_float;
	# should be a positive value
	for (my $col=0; $col<scalar(@colspecs); $col++) {
	    if ($float_widths->[$col] > 0) {
		$calc_widths->[$col] = $star_size * $float_widths->[$col];
	    }
	}
    }

    # no floating column widths, and total of fixed < available width
    if ($total_float == 0 && $width_used < $avail_width) {
	carp "!! Warning !!\nAllocated width is narrower than specified table width. Reduce table width.\n";
	$avail_width = $width_used;
    }
    # other choice would be to increase all columns by same percentage
    
    return ($calc_widths, $avail_width);
} # End of SetColumnWidths()

1;
