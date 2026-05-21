#!/usr/bin/env perl
require 5.010;
package Stats::LikeR;
our $VERSION = 0.01;
require XSLoader;
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use warnings FATAL => 'all';
use autodie ':default';
use Exporter 'import';
XSLoader::load('Stats::LikeR', $VERSION);
our @EXPORT_OK = qw(aov chisq_test cor cor_test cov fisher_test glm hist kruskal_test ks_test lm matrix mean median min max p_adjust power_t_test quantile rbinom read_table rnorm runif scale sd seq shapiro_test t_test var wilcox_test write_table);
our @EXPORT = @EXPORT_OK;

require XSLoader;

# Wrapper to mimic R's structure
sub chisq_test {
	my ($data) = @_;

	die 'Input must be an array reference' unless ref($data) eq 'ARRAY';

	# The XS function handles the heavy lifting
	my $result = _chisq_c($data);

	# Format the output to look like R's htest object
	return {
	  'statistic' => { 'X-squared' => $result->{statistic} },
	  'parameter' => { 'df' => $result->{df} },
	  'p.value'   => $result->{p_value},
	  'method'    => $result->{method},
	  'data.name' => 'Perl ArrayRef',
	  'observed'  => $data,
	  'expected'  => $result->{expected}
	};
}

sub read_table {
	my $file = shift;
	die "\"$file\" is either unreadable or not a file" unless -r -f $file;
	my %args = (
		sep => ',', comment => '#',
		@_,
	);
	my %allowed_args = map {$_ => 1} (
		'comment',	'output.type',	'filter', 'row.names', 'sep',	'substitutions'
	);
	my @undef_args = sort grep {!$allowed_args{$_}} keys %args;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1];
	if (scalar @undef_args > 0) {
		p @undef_args;
		die "the above args aren't defined for $current_sub";
	}
	$args{'output.type'} = $args{'output.type'} // 'aoh';
	if ($args{'output.type'} !~ m/^(?:aoh|hoa|hoh)$/) {
		die "\"$args{'output.type'}\" isn't allowed";
	}
	# Normalize the filter argument
	my $filter = $args{filter};
	if (defined $filter && ref($filter) eq 'CODE') {
		$filter = { 0 => $filter }; # 0 means the whole row
	} elsif (defined $filter && ref($filter) ne 'HASH') {
		die "'filter' must be a CODE or HASH reference";
	}
	my (@data, %data, @header, %mapped_filters);
	# Execute the fast C-state machine. Pass an anonymous coderef to process streams.
	# This bypasses creating an intermediate AoA memory spike.
	_parse_csv_file($file, $args{sep} // '', $args{comment} // '', sub {
		my ($line_ref) = @_;
		my @line = @$line_ref;
		if (!@header) {
			# --- HEADER PROCESSING ---
			$line[0] =~ s/^\Q$args{comment}\E// if @line && defined $line[0];
			while (@line && $line[-1] eq '') { pop @line }
			@header = @line; 
			# R-LIKE BEHAVIOR
			if ((scalar @header > 0) && ($header[0] eq '')) {
				$header[0] = 'row_name'; 
			}
			if (($args{'output.type'} eq 'hoh') && (not defined $args{'row.names'})) {
				$args{'row.names'} = $header[0];
			}
			if ((defined $args{'row.names'}) && (!grep {$_ eq $args{'row.names'}} @header)) {
				die "\"$args{'row.names'}\" isn't in the header of $file";
			}
			# Map filters to 1-based indices (or 0 for whole row)
			if ($filter) {
				for my $k (keys %$filter) {
					if ($k =~ /^\d+$/) {
						$mapped_filters{$k} = $filter->{$k};
					} else {
						my ($idx) = grep { $header[$_] eq $k } 0..$#header;
						die "Filter column '$k' not found in header" unless defined $idx;
						$mapped_filters{$idx + 1} = $filter->{$k};
					}
				}
			}
			return; # Equivalent to 'next' out of the closure
		}
		# Check for column alignment
		if (scalar @line != scalar @header) {
			die "Alignment error on $file (" . scalar(@line) . " fields vs " . scalar(@header) . " headers).";
		}
		# --- DATA PROCESSING ---
		my %line_hash;
		for my $i (0 .. $#header) {
			if (!defined($line[$i]) || $line[$i] eq '') {
         	$line_hash{$header[$i]} = 'NA';
         } else {
         	$line_hash{$header[$i]} = $line[$i];
         }
		}
		# --- APPLY FILTERS ---
		my $skip = 0;
		if (%mapped_filters) {
			foreach my $fld (sort { $a <=> $b } keys %mapped_filters) {
				local %_ = %line_hash; # Make %_ available to the callback
				local $_ = $fld == 0 ? $line_ref : $line[$fld - 1]; # Localize $_

				my $keep = $mapped_filters{$fld}->($line_ref, \%line_hash);
				if (!$keep) {
					$skip = 1;
					last;
				}

				# If the callback modified $_, write the mutation back to the data
				if ($fld > 0) {
					$line[$fld - 1] = $_;
					$line_hash{$header[$fld - 1]} = (defined($_) && $_ eq '') ? 'NA' : $_;
				}
			}
		}
		return if $skip; # Reject the row if it failed the filter, skipping memory allocation

		# Populate requested data structure
		if ($args{'output.type'} eq 'aoh') {
			push @data, \%line_hash;
		} elsif ($args{'output.type'} eq 'hoa') {
			foreach my $col (@header) {
				push @{ $data{$col} }, $line_hash{$col};
			}
		} elsif ($args{'output.type'} eq 'hoh') {
			my $row_name = $line_hash{$args{'row.names'}};
			foreach my $col (@header) {
				next if $col eq $args{'row.names'};
				$data{$col}{$row_name} = $line_hash{$col};
			}
		}
	});
	@header = ();
	%mapped_filters = ();
	if ($args{'output.type'} eq 'aoh') {
		undef %data;
		my $final_ref = \@data;
		return $final_ref;
	} elsif ($args{'output.type'} =~ m/^(?:hoa|hoh)$/) {
		@data = ();
		return \%data;
	}
}

#sub write_table {
#	my $data_ref = (ref($_[0]) eq 'HASH' || ref($_[0]) eq 'ARRAY') ? shift : undef;
#	my $file = shift;
#	my %args = (
#		sep         => ',',
#		'row.names' => 1,      
#		@_,
#	);
#	my $current_sub = (split(/::/,(caller(0))[3]))[-1];
#	$args{data} //= $data_ref;
#	my %allowed = map { $_ => 1 } qw(data file row.names sep col.names);
#	my @err = grep { !$allowed{$_} } keys %args;
#	if (@err > 0) {
#		die "$current_sub: Unknown arguments passed: " . join(", ", @err) . "\n";
#	}
#	die "$current_sub: 'data' must be a HASH or ARRAY reference\n" 
#		unless defined $args{data} && (ref($args{data}) eq 'HASH' || ref($args{data}) eq 'ARRAY');

#	my $col_names = $args{'col.names'};
#	if (defined $col_names && ref($col_names) ne 'ARRAY') {
#		die "$current_sub: 'col.names' must be an ARRAY reference\n";
#	}
#	my $data         = $args{data};
#	my $sep          = $args{sep};
#	my $inc_rownames = $args{'row.names'};
#	my $quote_field = sub {
#		my ($val, $sep) = @_;
#		return '' unless defined $val;
#		die "$current_sub: Cannot write nested reference types to table\n" if ref($val);
#		
#		my $str = "$val";  
#		if (index($str, $sep) != -1 || index($str, '"') != -1 || $str =~ /[\r\n]/) {
#			$str =~ s/"/""/g;
#			$str = qq{"$str"};
#		}
#		return $str;
#	};
#	my $data_type = ref $data;
#	my ($is_hoh, $is_hoa, $is_aoh) = (0, 0, 0);
#	my @rows;
#	if ($data_type eq 'HASH') {
#		@rows = keys %$data;
#		return if @rows == 0; 
#		my $first_type = ref $data->{$rows[0]};
#		die "$current_sub: Data values must be either all HASHes or all ARRAYs\n"
#			unless $first_type eq 'HASH' || $first_type eq 'ARRAY';

#		my @type_err = grep { ref $data->{$_} ne $first_type } @rows;
#		if (@type_err > 0) {
#			die "$current_sub: Mixed data types detected. Ensure all values are $first_type references.\n";
#		}
#		$is_hoh = ($first_type eq 'HASH');
#		$is_hoa = ($first_type eq 'ARRAY');
#	} else {
#		return if @$data == 0;

#		my $first_elem = $data->[0];
#		die "$current_sub: For ARRAY data, all elements must be HASH references (Array of Hashes)\n"
#			unless defined $first_elem && ref($first_elem) eq 'HASH';

#		my @type_err = grep { !defined($_) || ref($_) ne 'HASH' } @$data;
#		if (@type_err > 0) {
#			die "$current_sub: Mixed data types detected in Array of Hashes. All elements must be HASH references.\n";
#		}
#		$is_aoh = 1;
#	}
#	open my $fh, '>', $file or die "$current_sub: Could not open '$file' for writing: $!\n";
#	if ($is_hoh) {
#		my @headers;
#		if (defined $col_names) {  # Bug 6 fix: was "if ($col_names)" — use defined
#			@headers = @$col_names;
#		} else {
#			my %col_map;
#			for my $r (@rows) {
#				$col_map{$_} = 1 for keys %{ $data->{$r} };
#			}
#			@headers = sort keys %col_map;
#		}

#		my @header_row = @headers;
#		unshift @header_row, '' if $inc_rownames;
#		@header_row = map { $quote_field->($_, $sep) } @header_row;
#		print $fh join($sep, @header_row) . "\n";

#		for my $r (sort @rows) {
#			my @row_data = map { defined $data->{$r}{$_} ? $data->{$r}{$_} : "NA" } @headers;
#			unshift @row_data, $r if $inc_rownames;
#			my @quoted = map { $quote_field->($_, $sep) } @row_data;
#			print $fh join($sep, @quoted) . "\n";
#		}
#	} elsif ($is_hoa) {
#		# 1. Find the maximum number of rows
#		my $max_rows = 0;
#		foreach my $col (keys %$data) {
#			my $len = scalar @{ $data->{$col} };
#			$max_rows = $len if $len > $max_rows;
#		}
#		$max_rows--; # Convert length to max index

#		# 2. Determine headers
#		my @headers;
#		if (defined $col_names) {
#			@headers = @$col_names;
#		} else {
#			@headers = sort keys %$data;
#		}
#		
#		die "Could not get headers in $current_sub" if @headers == 0;

#		# Bug 5 fix: if row.names is a column name (non-numeric string), pull it out to be first
#		my $rownames_col;
#		if ($inc_rownames && $inc_rownames =~ /\D/) {
#			$rownames_col = $inc_rownames;
#			@headers = grep { $_ ne $rownames_col } @headers;
#		}

#		# 3. Print Header Row
#		my @header_row = @headers;
#		unshift @header_row, '' if $inc_rownames;
#		@header_row = map { $quote_field->($_, $sep) } @header_row;
#		print $fh join($sep, @header_row) . "\n";

#		# 4. Process and Print Data Rows
#		for my $i (0 .. $max_rows) {
#			my @row_data;
#			
#			foreach my $col (@headers) {
#				push @row_data, defined($data->{$col}[$i]) ? $data->{$col}[$i] : 'NA';
#			}
#			
#			if ($inc_rownames) {
#				# Bug 5 fix: use named column value if row.names is a column name
#				my $rn_val = defined $rownames_col
#					? (defined $data->{$rownames_col}[$i] ? $data->{$rownames_col}[$i] : 'NA')
#					: $i + 1;
#				unshift @row_data, $rn_val;
#			}
#			
#			my @quoted = map { $quote_field->($_, $sep) } @row_data;
#			print $fh join($sep, @quoted) . "\n";
#		}
#	} elsif ($is_aoh) {
#		my @headers;
#		if (defined $col_names) {  # Bug 6 fix: was "if ($col_names)" — use defined
#			@headers = @$col_names;
#		} else {
#			my %col_map;
#			for my $row_hash (@$data) {
#				$col_map{$_} = 1 for keys %$row_hash;
#			}
#			@headers = sort keys %col_map;
#		}

#		# Bug 5 fix: if row.names is a column name (non-numeric string), pull it out to be first
#		my $rownames_col;
#		if ($inc_rownames && $inc_rownames =~ /\D/) {
#			$rownames_col = $inc_rownames;
#			@headers = grep { $_ ne $rownames_col } @headers;
#		}

#		my @header_row = @headers;
#		unshift @header_row, "" if $inc_rownames;
#		@header_row = map { $quote_field->($_, $sep) } @header_row;
#		print $fh join($sep, @header_row) . "\n";  # Bug 7 fix: was "say $fh" — use print consistently
#		for my $i (0 .. $#$data) {
#			my $row_hash = $data->[$i];
#			my @row_data = map { defined $row_hash->{$_} ? $row_hash->{$_} : "NA" } @headers;
#			if ($inc_rownames) {
#				# Bug 5 fix: use named column value if row.names is a column name
#				my $rn_val = defined $rownames_col
#					? (defined $row_hash->{$rownames_col} ? $row_hash->{$rownames_col} : 'NA')
#					: $i + 1;
#				unshift @row_data, $rn_val;
#			}
#			my @quoted = map { $quote_field->($_, $sep) } @row_data;
#			print $fh join($sep, @quoted) . "\n";
#		}
#	}
#	close $fh;  # Bug 8 fix: file handle was never closed
#}
1;
#sub mean {
#	my @n = map { ref($_) eq 'ARRAY' ? @$_ : $_ } @_;
#	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
#	die "$current_sub needs >= 1 element in the array" if scalar @n < 1;
#	return sum(@n) / scalar @n;x
#}

#sub stdev {
#	my @n = map { ref($_) eq 'ARRAY' ? @$_ : $_ } @_;
#	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
#	die "$current_sub needs >= 2 elements in the array" if scalar @n < 2;
#	my $mean = sum(@n) / scalar @n;
#	my $standard_deviation = 0;
#	foreach my $element (@n) {
#		$standard_deviation += ($element-$mean)**2;
#	}
#	return sqrt($standard_deviation/((scalar @n)-1));
#}

#sub population_variance { # sample variance
#	my @n = map { ref($_) eq 'ARRAY' ? @$_ : $_ } @_;
#	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
#	die "$current_sub needs >= 1 elements in the array" if scalar @n < 1;
#	my $mean = sum(@n) / scalar @n;
#	my $var = 0;
#	foreach my $element (@n) {
#		$var += ($element-$mean)**2;
#	}
#	return $var / scalar @n;
#}

#sub sample_variance { # sample variance
#	my @n = map { ref($_) eq 'ARRAY' ? @$_ : $_ } @_;
#	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
#	die "$current_sub needs >= 1 elements in the array" if scalar @n < 1;
#	my $mean = sum(@n) / scalar @n;
#	my $var = 0;
#	foreach my $element (@n) {
#		$var += ($element-$mean)**2;
#	}
#	return $var / (scalar @n - 1);
#}

#sub pvalue ($array1, $array2) {
#	return 1.0 if scalar @$array1 <= 1;
#	return 1.0 if scalar @$array2 <= 1;
#	my $mean1 = sum(@{ $array1 });
#	my $mean2 = sum(@{ $array2 });
#	return 1.0 if ($mean1 == $mean2);
#	$mean2 /= scalar @$array2;
#	$mean1 /= scalar @$array1;
#	my ($variance1, $variance2) = (0, 0);
#	foreach my $x (@$array1) {
#	$variance1 += ($x-$mean1)*($x-$mean1);
#	}
#	foreach my $x (@$array2) {
#	$variance2 += ($x-$mean2)*($x-$mean2);
#	}
#	if (($variance1 == 0.0) && ($variance2 == 0.0)) {
#	return 1.0;
#	}
#	$variance1 = $variance1/(scalar @$array1-1);
#	$variance2 = $variance2/(scalar @$array2-1);
#	my $array1_size = scalar @$array1;
#	my $array2_size = scalar @$array2;
#	my $WELCH_T_STATISTIC = ($mean1-$mean2)/sqrt($variance1/$array1_size+$variance2/$array2_size);
#	my $DEGREES_OF_FREEDOM = (($variance1/$array1_size+$variance2/(scalar @$array2))**2)
#	/
#	(
#	($variance1*$variance1)/($array1_size*$array1_size*($array1_size-1))+
#	($variance2*$variance2)/($array2_size*$array2_size*($array2_size-1))
#	);
#	my $A = $DEGREES_OF_FREEDOM/2;
#	my $value = $DEGREES_OF_FREEDOM/($WELCH_T_STATISTIC*$WELCH_T_STATISTIC+$DEGREES_OF_FREEDOM);
##from here, translation of John Burkhardt's C
#	my $beta = lgamma($A)+0.57236494292470009-lgamma($A+0.5);
#	my $acu = 10**(-15);
#	my($ai,$cx,$indx,$ns,$pp,$psq,$qq,$rx,$temp,$term,$xx);
## Check the input arguments.
#	return $value if $A <= 0.0;# || $q <= 0.0;
#	return $value if $value < 0.0 || 1.0 < $value;
## Special cases
#	return $value if $value == 0.0 || $value == 1.0;
#	$psq = $A + 0.5;
#	$cx = 1.0 - $value;
#	if ($A < $psq * $value) {
#		($xx, $cx, $pp, $qq, $indx) = ($cx, $value, 0.5, $A, 1);
#	} else {
#		($xx, $pp, $qq, $indx) = ($value, $A, 0.5, 0);
#	}
#	$term = 1.0;
#	$ai = 1.0;
#	$value = 1.0;
#	$ns = int($qq + $cx * $psq);
##Soper reduction formula.
#	$rx = $xx / $cx;
#	$temp = $qq - $ai;
#	$rx = $xx if $ns == 0;
#	while (1) {
#		$term = $term * $temp * $rx / ( $pp + $ai );
#		$value = $value + $term;
#		$temp = abs ($term);
#		if ($temp <= $acu && $temp <= $acu * $value) {
#	   	$value = $value * exp ($pp * log($xx)
#	                          + ($qq - 1.0) * log($cx) - $beta) / $pp;
#	   	$value = 1.0 - $value if $indx;
#	   	last;
#		}
#	 	$ai = $ai + 1.0;
#		$ns = $ns - 1;
#		if (0 <= $ns) {
#			$temp = $qq - $ai;
#			$rx = $xx if $ns == 0;
#		} else {
#			$temp = $psq;
#			$psq = $psq + 1.0;
#		}
#	}
#	return $value;
#}

#sub paired_pvalue ($array1, $array2) {
#	return 1.0 if scalar @$array1 <= 1;
#	return 1.0 if scalar @$array2 <= 1;
#	my $array_size = scalar @$array1;
#	if ($array_size != scalar @$array2) {
#		die 'arrays have different sizes, cannot calculate paired p-value.';
#	}
#	my ($sd, $xd) = (0,0);
#	foreach my $x (0..$array_size-1) {
#		$xd += (@$array2[$x] - @$array1[$x]);
#	}
#	return 1.0 if $xd == 0;
#	$xd /= $array_size;
#	foreach my $x (0..$array_size-1) {
#		$sd += ($xd - (@$array2[$x] - @$array1[$x]))**2;
#	}
#	$sd = sqrt($sd / ($array_size - 1));
#	my $t = $xd / ($sd / sqrt($array_size));
#	my $DEGREES_OF_FREEDOM = $array_size - 1;#http://oak.ucc.nau.edu/rh232/courses/EPS525/Handouts/Understanding%20the%20Dependent%20t%20Test.pdf
#	my $A = $DEGREES_OF_FREEDOM/2;
#	my $value = $DEGREES_OF_FREEDOM/($t*$t+$DEGREES_OF_FREEDOM);
##from here, translation of John Burkhardt's C
#	my $beta = lgamma($A)+0.57236494292470009-lgamma($A+0.5);
#	my $acu = 10**(-15);
#	my($ai,$cx,$indx,$ns,$pp,$psq,$qq,$rx,$temp,$term,$xx);
## Check the input arguments.
#	return $value if $A <= 0.0;# || $q <= 0.0;
#	return $value if $value < 0.0 || 1.0 < $value;
## Special cases
#	return $value if $value == 0.0 || $value == 1.0;
#	$psq = $A + 0.5;
#	$cx = 1.0 - $value;
#	if ($A < $psq * $value) {
#		($xx, $cx, $pp, $qq, $indx) = ($cx, $value, 0.5, $A, 1);
#	} else {
#		($xx, $cx, $pp, $qq, $indx) = ($value, $cx, $A, 0.5, 0);
#	}
#	$term = 1.0;
#	$ai = 1.0;
#	$value = 1.0;
#	$ns = int($qq + $cx * $psq);
##Soper reduction formula.
#	$rx = $xx / $cx;
#	$temp = $qq - $ai;
#	$rx = $xx if $ns == 0;
#	while (1) {
#		$term = $term * $temp * $rx / ( $pp + $ai );
#		$value = $value + $term;
#		$temp = abs ($term);
#		if ($temp <= $acu && $temp <= $acu * $value) {
#			$value = $value * exp ($pp * log($xx)
#				                   + ($qq - 1.0) * log($cx) - $beta) / $pp;
#			$value = 1.0 - $value if $indx;
#			last;
#		}
#		$ai = $ai + 1.0;
#		$ns = $ns - 1;
#		if (0 <= $ns) {
#			$temp = $qq - $ai;
#			$rx = $xx if $ns == 0;
#		} else {
#			$temp = $psq;
#			$psq = $psq + 1.0;
#		}
#	}
#	$value;
#}

1;
