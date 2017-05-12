

package Neuron;

$VERSION = "0.0.1";

=head1 NAME
	Neuron networks

=head1

=head1 AUTHOR

	Yuri Kostylev
	based on stuff by
	Daniel Franklin (d.franklin@computer.org)

=cut

# -------------------------------------------------------------------------

sub sigma {
#    my $d = shift;
    return 1.0 / (1.0 + exp(- shift));
}

# -------------------------------------------------------------------------

sub new {
	my $self = {};
	$self->{NAME} = shift;
	$self->{NUMIN} = shift;
	$self->{IN} = [];
	$self->{OUT} = 0;
	bless $self;
	$self -> init();
	return $self;
}

# ------------------------------------------------------------------------
# not used

sub numin {
    my $self = shift;
    if (@_) { $self -> {NUMIN} = shift;}
    return $self->{NUMIN};
}

# ------------------------------------------------------------------------

sub out {
#    my $self = shift;
#    return $self -> {OUT};
	return shift -> {OUT};
}

# ------------------------------------------------------------------------
# not used

sub show_in {
    my $self = shift;
    my $i;
    for($i = 0; $i < $self->{NUMIN}; $i ++) {
	print $self->{IN}[$i], " ";
    }
    print "\n";
}

# ------------------------------------------------------------------------
# not used for now

sub compute {
    my $self = shift;
    my @data = @_;
    my $sum = 0;
    my $i;
    for($i = 0; $i < $self -> {NUMIN}; $i ++) {
	$sum += $data[$i] * $self->{IN}[$i];	
	# print $data[$i], "\n";
    }
    $out = sigma($sum/$self->{NUMIN});
    # print $out, "\n";
    $self -> {OUT} = $out;
    return $out;
}

# -----------------------------------------------------------------------
# constructor

sub init {
    my $self = shift;
    my($i);
    for($i = 0; $i < $self -> {NUMIN}; $i ++) {
	$self->{IN}[$i] = 0.5 - rand;
#	$self->{IN}[$i] = 0;
    }
}

# -----------------------------------------------------------------------

package NLayer;

sub new {
    my $self = {};
    $self -> {NAME} = shift;
    $self -> {SIZE} = shift;
    $self -> {BOT_SIZE} = shift;
    $self -> {NEURONS} = [];
    
    bless $self;
    
    $self -> init;
    
    return $self;
}

# -----------------------------------------------------------------------

sub init {
    my $self = shift;
    my $i;
    for($i = 0; $i < $self -> {SIZE}; $i ++) {
	$self -> {NEURONS}[$i] = Neuron -> new($self -> {BOT_SIZE});
    }
}

# -----------------------------------------------------------------------
# not used

sub show_neurons {
    my $self = shift;
    my $i;
    for($i = 0; $i < $self -> {SIZE}; $i ++) {
	$self -> {NEURONS}[$i] -> show_in;
    }
}

# -----------------------------------------------------------------------
# retrieves single neuron by index

sub neuron {
    my $self = shift;
#    my $n = shift;	# index of neuron
    return  $self -> {NEURONS}[ shift ];
}

# -----------------------------------------------------------------------
# not used

sub show_out {
    my $self = shift;
    my $i;
    for($i = 0; $i < $self -> {SIZE}; $i ++) {
	print $self -> {NEURONS}[$i] -> out, "\n";
    }
}

# ------------------------------------------------------------------------
# not used for now

sub compute {
    my $self = shift;
    my @data = @_;		# size of data == $self -> {BOT_SIZE} !!!
    my $i;
    
    for($i = 0; $i < $self -> {SIZE}; $i ++) {
	$self -> {NEURONS}[$i] -> compute(@data);
    }    
}

# -------------------------------------------------------------------------

package NNet;

sub new {
    my $self = {};
    
    $self -> {NAME} = shift;
    $self -> {IN_SIZE} = shift;
    $self -> {HIDDEN_SIZE} = shift;
    $self -> {OUT_SIZE} = shift;
    
    $self -> {OUT_LAYER} = undef;
    $self -> {HIDDEN_LAYER} = undef;
    
    if(! $self -> {IN_SIZE} || ! $self -> {HIDDEN_SIZE}
	|| ! $self -> {OUT_SIZE} ) {
	    die "Bad network sizes";
    }
    bless $self;
    $self -> init;
    return $self;
}

# --------------------------------------------------------------------------

sub init {
    my $self = shift;
    $self -> {HIDDEN_LAYER} = NLayer ->
	new($self -> {HIDDEN_SIZE}, $self -> {IN_SIZE});
    $self -> {OUT_LAYER} = NLayer ->
	new($self -> {OUT_SIZE}, $self -> {HIDDEN_SIZE});
}

# ---------------------------------------------------------------------------

sub load {
	my $self = {};
	$self -> {NAME} = shift;
	my $fname = shift;

    	$self -> {OUT_LAYER} = undef;
    	$self -> {HIDDEN_LAYER} = undef;

	my ($s, $i, $j);
	my $line = 1;
	my @a;

	open FILE, "<$fname" || die "Cant open file";

	$s = <FILE>; chomp($s);
	if($s =~ /^Insize /) {
		$self -> {IN_SIZE} = $';
	} else {
		die "Bad file format in $line";
	}
	$line ++;
	$s = <FILE>; chomp($s);
	if($s =~ /^Hiddensize /) {
		$self -> {HIDDEN_SIZE} = $';
	} else {
		die "Bad file format in $line";
	}
	$line ++;
	$s = <FILE>; chomp($s);
	if($s =~ /^Outsize /) {
		$self -> {OUT_SIZE} = $';
	} else {
		die "Bad file format in $line";
	}
	$line ++;
	if(! $self -> {IN_SIZE} || ! $self -> {HIDDEN_SIZE}
		|| ! $self -> {OUT_SIZE} ) {
			die "Bad network sizes";
	}
	bless $self;

	$self -> {HIDDEN_LAYER} = NLayer ->
		new($self -> {HIDDEN_SIZE}, $self -> {IN_SIZE});
	$self -> {OUT_LAYER} = NLayer ->
		new($self -> {OUT_SIZE}, $self -> {HIDDEN_SIZE});

# read data
	$s = <FILE>; chomp($s);
	if(! $s =~ /^Hiddenlayer:/) {
		die "Bad file format in $line";
	}
	$line ++;

	for($i = 0; $i < $self -> {HIDDEN_SIZE}; $i ++) {
		$s = <FILE>; chomp($s);
		@a = split(/ /, $s);
		for($j = 0; $j < $self -> {IN_SIZE}; $j ++) {
			$self -> {HIDDEN_LAYER} -> neuron($i) -> {IN}[$j] =
				$a[$j];
		}

		$line ++;
	}

	$s = <FILE>; chomp($s);
	if(! $s =~ /^Outlayer:/) {
		die "Bad file format in $line";
	}
	$line ++;

	for($i = 0; $i < $self -> {OUT_SIZE}; $i ++) {
		$s = <FILE>; chomp($s);
		@a = split(/ /, $s);
		for($j = 0; $j < $self -> {HIDDEN_SIZE}; $j ++) {
			$self -> {OUT_LAYER} -> neuron($i) -> {IN}[$j] =
				$a[$j];
		}

		$line ++;
	}


	close FILE;
	return $self;
}

# ---------------------------------------------------------------------------

sub show {
    my $self = shift;
    print "Hiden in:\n";
    $self -> {HIDDEN_LAYER} -> show_neurons;
    print "Hidden out:\n";
    $self -> {HIDDEN_LAYER} -> show_out;
    print "Out in:\n";
    $self -> {OUT_LAYER} -> show_neurons;
    print "Out out:\n";
    $self -> {OUT_LAYER} -> show_out;
}

# --------------------------------------------------------------------------

sub run {
    my $self = shift;
    my @data = @_;
    my ($i, $j, $k, $sum);
    my @result = ();
    my ($hidden_size, $in_size, $out_size);
    my ($hidden_layer, $out_layer);

    $hidden_size = $self -> {HIDDEN_SIZE};
    $in_size = $self -> {IN_SIZE};
    $out_size = $self -> {OUT_SIZE};

    $hidden_layer = $self -> {HIDDEN_LAYER};
    $out_layer = $self -> {OUT_LAYER};
    
    for($j = 0; $j < $hidden_size; $j ++) {
	$sum = 0;
	for($i = 0; $i < $in_size; $i ++) {
	    $sum += $hidden_layer -> neuron($j) -> {IN}[$i]
		* $data[$i];
	}
	$hidden_layer -> neuron($j) -> {OUT} = Neuron::sigma($sum);
    }
    for($k = 0; $k < $out_size; $k ++) {
	$sum = 0;
	for($j = 0; $j < $hidden_size; $j ++) {
	    $sum += $out_layer -> neuron($k) -> {IN}[$j]
		* $hidden_layer -> neuron($j) -> out;
	}
	$result[$k] = $out_layer -> neuron($k) -> {OUT}
	    = Neuron::sigma($sum);
    }
    return @result;
}

# -----------------------------------------------------------------------

sub train {
    my $self = shift;
    my $max_mse = shift;
    my $eta = shift;
    my @data = @_;
    my $N = $self -> {IN_SIZE};
    
    my ($mse, $mse_max, $sum, $i, $j, $k);
    my @output = ();
    my @owd = ();
    my @hwd = ();
    my $count = 0;

    my ($out_size, $hidden_size, $in_size);
    my ($hidden_layer, $out_layer);
    my $aux;

    $hidden_layer = $self -> {HIDDEN_LAYER};
    $out_layer = $self -> {OUT_LAYER};
    
    $mse_max = $max_mse * 2;
    $in_size = $self -> {IN_SIZE};
    $out_size = $self -> {OUT_SIZE};
    $hidden_size = $self -> {HIDDEN_SIZE};

    while(1) {
	@output = $self -> run(@data);
	$mse = 0;
	for($k = 0; $k < $out_size; $k ++) {
	    $aux = $output[$k];
	    $owd[$k] = $data[$k + $N] - $aux;
	    
	    $mse += $owd[$k] * $owd[$k];
	    
	    $owd[$k] *= $aux * (1 - $aux);
	}
	
#if($count % 100 == 0) {	    
#    print "$count\t", $mse, "\n";
#}
	
	last if($mse < $mse_max);
	
	for($j = 0; $j < $hidden_size; $j ++) {
	    $sum = 0;
	    for($k = 0; $k < $out_size; $k ++) {
		$sum += $owd[$k] * $out_layer -> neuron($k) -> {IN}[$j];
	    }
	    $aux = $hidden_layer -> neuron($j) -> out;
	    $hwd[$j] = $sum * $aux * (1 - $aux);
	}
	for($k = 0; $k < $out_size; $k ++) {
	    for($j = 0; $j < $hidden_size; $j ++) {
		$out_layer -> neuron($k) -> {IN}[$j] +=
		    $eta * $owd[$k] * $hidden_layer -> neuron($j) -> out;
	    }
	}
	for($j = 0; $j < $hidden_size; $j ++) {
	    for($i = 0; $i < $in_size; $i ++) {
		$hidden_layer -> neuron($j) -> {IN}[$i] +=
		    $eta * $hwd[$j] * $data[$i];
	    }
	}
	$count ++;
    }
#    print $count, "\n";
    return $count;
}

# --------------------------------------------------------------------------

sub save {
	my $self = shift;
	my $fname = shift;
	my ($i, $j);
	open FILE, ">$fname" || die "Cant open file\n";

	print FILE "Insize ", $self -> {IN_SIZE}, "\n";
	print FILE "Hiddensize ", $self -> {HIDDEN_SIZE}, "\n";
	print FILE "Outsize ", $self -> {OUT_SIZE}, "\n";

	print FILE "Hiddenlayer:\n";
	for($i = 0; $i < $self -> {HIDDEN_SIZE}; $i ++) {
		for($j = 0; $j < $self -> {IN_SIZE}; $j ++) {
			print FILE $self -> {HIDDEN_LAYER} -> neuron($i) ->
				{IN}[$j], " ";
		}
		print FILE "\n";
	}
	print FILE "Outlayer:\n";
	for($i = 0; $i < $self -> {OUT_SIZE}; $i ++) {
		for($j = 0; $j < $self -> {HIDDEN_SIZE}; $j ++) {
			print FILE $self -> {OUT_LAYER} -> neuron($i) ->
				{IN}[$j], " ";
		}
		print FILE "\n";
	}

	close FILE;
}

1;
