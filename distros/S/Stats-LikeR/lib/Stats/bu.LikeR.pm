#!/usr/bin/env perl
# ABSTRACT: Get basic statistical functions, like in R, but with Perl using XS for performance
require 5.010;
use strict;
use feature 'say';
package Stats::LikeR;
our $VERSION = 0.11;
require XSLoader;
use Devel::Confess 'color';
use warnings FATAL => 'all';
use autodie ':default';
use Exporter 'import';
use Scalar::Util 'looks_like_number';
XSLoader::load('Stats::LikeR', $VERSION);
our @EXPORT_OK = qw(add_data aov chisq_test cor cor_test cov dnorm fisher_test glm group_by hist kruskal_test ks_test ljoin lm matrix max mean median min mode oneway_test p_adjust power_t_test prcomp quantile rbinom read_table rnorm runif sample scale sd seq shapiro_test sum summary t_test value_counts var var_test wilcox_test write_table);
our @EXPORT = @EXPORT_OK;

require XSLoader;

sub summary {
	my ($data, %args);
	my $current_sub = (split(/::/,(caller(0))[3]))[-1];

	if (@_ && ref $_[0]) {
	  # Handles: summary(\@arr) or summary(\@arr, nrows => 5) or summary(\%h, nrow => 3)
	  $data = shift;
	  %args = @_; # capture any trailing key/value pairs
	} else {
	  # Handles: summary(@runif) or summary(@runif, nrows => 2)
	  # Extract known trailing named arguments from the flat list
	  while (@_ >= 2 && defined $_[-2] && !ref($_[-2]) && $_[-2] =~ /^(?:nrows|nrow)$/) {
	  	  my $val = pop @_;
		  my $key = pop @_;
		  $args{$key} = $val;
	  }
	  # The remaining items in @_ make up the actual data array
	  my @list = @_;
	  $data = \@list;
	}
	# Normalize nrow -> nrows, default to 10
	$args{nrows} //= delete($args{nrow}) // 10;
	my $ref_type = ref $data;
	if (($ref_type ne 'ARRAY') && ($ref_type ne 'HASH')) {
		die "$current_sub' data must either be a hash or an array, not \"$ref_type\"";
	}
	my $single_arr = 0;
	if (($ref_type eq 'ARRAY') && (ref $data->[0] eq '')) {
		$single_arr = 1;
	}
	my @header = ('# values', 'Min.', '1st Qu.', 'Median', 'Mean', '3rd Qu.', 'Max.');
	my @out;
	if ($single_arr == 1) {
		push @out, '-' x 75;
		my $header = sprintf('%9s ' x scalar @header, @header);
		push @out, $header;
		push @out, '-' x 75;
		my @undef = grep {!defined $data->[$_]} 0..scalar @{ $data }-1;
		if (scalar @undef > 0) {
			say STDERR join (',', @undef);
			die "The above indices are not defined in $current_sub";
		}
		my @numeric = grep {looks_like_number($_)} @{ $data };
		my $q = quantile(\@numeric, probs => [0.25, 0.75]);
		my $vals = sprintf('%9.4g ' x scalar @header, scalar @numeric, min(\@numeric), $q->{'25%'}, median(\@numeric), mean(\@numeric), $q->{'75%'}, max(\@numeric));
		push @out, $vals;
	} elsif ($ref_type eq 'ARRAY') {
		push @out, '-' x 75;
		my $header = sprintf('%9s ' x scalar @header, @header);
		unshift @header, 'Index';
		$header = 'Index ' . $header;
		push @out, $header;
		push @out, '-' x 75;
		my $rows_printed = 0;
		foreach my $index (0..$#$data) {
			my @undef = grep {!defined $data->[$index][$_]} 0..scalar @{ $data->[$index] }-1;
			if (scalar @undef > 0) {
				say STDERR join (',', @undef);
				die "The above indices are not defined for index $index in $current_sub";
			}
			my @numeric = grep {looks_like_number($_)} @{ $data->[$index] };
			my $q = quantile(\@numeric, probs => [0.25, 0.75]);
			my $vals = sprintf('%6.4g', $index) . sprintf('%9.4g ' x (scalar @header - 1), scalar @numeric, min(\@numeric), $q->{'25%'}, median(\@numeric), mean(\@numeric), $q->{'75%'}, max(\@numeric));
			push @out, $vals;
			$rows_printed++;
			last if $rows_printed >= $args{nrows}; # Changed to >= just to be safe
		}
	} elsif ($ref_type eq 'HASH') {
		push @out, '-' x 78;
		my $header = sprintf('%9s ' x scalar @header, @header);
		unshift @header, 'Key';
		$header = '  Key    ' . $header;
		push @out, $header;
		push @out, '-' x 78;
		my $rows_printed = 0;
		foreach my $key (sort {lc $a cmp lc $b} keys %{ $data }) {
			my @undef = grep {!defined $data->{$key}[$_]} 0..scalar @{ $data->{$key} }-1;
			if (scalar @undef > 0) {
				say STDERR join (',', @undef);
				die "The above indices are not defined for key $key in $current_sub";
			}
			my @numeric = grep {looks_like_number($_)} @{ $data->{$key} };
			my $q = quantile(\@numeric, probs => [0.25, 0.75]);
			my $print_key = substr($key, 0, 9);
			if ((length $print_key) < 9) { # make sure that short keys line up correctly
				$print_key .= ' ' x (9 - length $print_key);
			}
			my $vals = $print_key . sprintf('%9.4g ' x (scalar @header - 1), scalar @numeric, min(\@numeric), $q->{'25%'}, median(\@numeric), mean(\@numeric), $q->{'75%'}, max(\@numeric));
			push @out, $vals;
			$rows_printed++;
			last if $rows_printed >= $args{nrows};
		}
	}
	say join ("\n", @out);
	return \@out;
}

sub read_table {
	my $file = shift;
	die "\"$file\" is not a file" unless -f $file;
	die "\"$file\" is not readable" unless -r $file;

	# 1. Parse the incoming arguments into a temporary hash
	my %input_args = @_;

	# 2. Handle 'delim' as a synonym for 'sep'
	if (defined $input_args{delim}) {
	  $input_args{sep} = delete $input_args{delim};
	}

	# 3. Determine the default separator based on the file extension
	my $default_sep = ','; # fallback default
	if ($file =~ /\.tsv$/i) {
	  $default_sep = "\t";
	} elsif ($file =~ /\.csv$/i) {
	  $default_sep = ",";
	}

	# 4. Merge defaults with user inputs (user inputs override defaults)
	my %args = (
	  sep     => $default_sep,
	  comment => '#',
	  %input_args,
	);

	# 5. Define allowed arguments (including 'delim' since it can be passed in)
	my %allowed_args = map {$_ => 1} (
	  'comment', 'output.type', 'filter', 'row.names', 'sep', 'delim'
	);
	my @undef_args = sort grep {!$allowed_args{$_}} keys %args;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1];
	if (scalar @undef_args > 0) {
		say join (', ', @undef_args);
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
				$data{$row_name}{$col} = $line_hash{$col};
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
=encoding utf8

=head1 Synopsis

Get basic statistical functions working in Perl as if they were part of List::Util, like C<min>, C<max>, C<sum>, etc.
I've used Artificial Intelligence tools such as Claude, Gemini, and Grok to write this as well as using my own gray matter.
There are other similar tools on CPAN, but I want speed and a form like List::Util, which I've gotten here with the help of AI, which often required many attempts to do correctly.
This is meant to call subroutines directly through eXternal Subroutines (XS) for performance and portability.

There B<are> other modules on CPAN that can do B<PARTS> of this, but this works the way that I B<want> it to.

=head1 Functions/Subroutines

=head2 add_data

Add data to a hash

 $data = { 'Jack Smith' => { age => 30 } };
 $n = { 
     'Jack Smith' => { dept => 'Engineering' },             # Update existing (Hash)
     'Jane Doe'   => { age => 25, dept => 'Sales' },        # Add new (Hash)
     'Bob Brown'  => [ 'age', 40, 'dept', 'IT' ],           # Add new (Array)
     'Invalid'    => 'Not a reference'                      # Edge case safety
 };
 add_data($data, $n); # will add data to 'Jack Smith', as well as new keys for Jane and Bob.

this is the equivalent of adding new rows, as well as C<ljoin>, which is described below.

where the resulting hash-of-hash looks like:

     {
     1st   {
         a   "A",
         b   "B"
     },
     2nd   {
         a   "C",
         b   "D"
     }
 }

=head3 no pivot key/row name

with no pivot key, each array index becomes a hash key, which is less useful, but necessary for completeness.  The same C<@aoh> above becomes:

 {
     0   {
         a   "A",
         b   "B",
         r   "1st" (dualvar: 1)
     },
     1   {
         a   "C",
         b   "D",
         r   "2nd" (dualvar: 2)
     }
 }

=head2 aov

Warning: assumes normal distribution

 aov(
 {
     yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
     ctrl  => [1,     1,   1,   0,   0,   0]
 },
 'yield ~ ctrl');

which returns

 {
     ctrl        {
         Df          1,
         "F value"   25.6000000000001,
         "Mean Sq"   1.70666666666667,
         Pr(>F)      0.00718232855871859,
         "Sum Sq"    1.70666666666667
     },
     Residuals   {
         Df          4,
         "Mean Sq"   0.0666666666666665,
         "Sum Sq"    0.266666666666666
    }
 }

You can also perform Two-Way ANOVA with categorical interactions using the C<*> operator. The parser will implicitly evaluate the main effects alongside the interaction:

 my $res_2way = aov($data_2way, 'len ~ supp * dose');

It is robust against rank deficiency; collinear terms will gracefully receive 0 degrees of freedom and 0 sum of squares, matching R's behavior.

=head3 omitting formula

As of version 0.07, in the case of an omitted formula, stacking is done:

 aov(
 {
     yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
     ctrl  => [1,     1,   1,   0,   0,   0]
 },
 );

is the equivalent of:

 yield <- c(5.5, 5.4, 5.8, 4.5, 4.8, 4.2)
 ctrl <- c(1,     1,   1,   0,   0,   0)
 
 # Combine them into a named list (the R equivalent of your hash)
 my_list <- list(yield = yield, ctrl = ctrl)
 
 # Convert the list into a "long" dataframe
 # This creates two columns: "values" and "ind" (the group name)
 my_data <- stack(my_list)
 
 # Rename columns for clarity (optional but good practice)
 colnames(my_data) <- c("Value", "Group")
 anova_model <- aov(Value ~ Group, data = my_data)
 summary(anova_model)

in R

=head2 chisq_test

 my @test_data = ([762, 327, 468], [484, 239, 477]);
 my $test_data = chisq_test(\@test_data);

which outputs:

 {
 data.name   "Perl ArrayRef",
 expected    [
     [0] [
             [0] 703.671381936888,
             [1] 319.645266594124,
             [2] 533.683351468988
         ],
     [1] [
             [0] 542.328618063112,
             [1] 246.354733405876,
             [2] 411.316648531012
         ]
 ],
 method      "Pearson's Chi-squared test",
 observed    [
     [0] [
             [0] 762,
             [1] 327,
             [2] 468
         ],
     [1] [
             [0] 484,
             [1] 239,
             [2] 477
         ]
 ],
 p.value     2.95358918321176e-07,
 parameter   {
     df   2
 },
 statistic   {
     X-squared   30.0701490957547
 }
 }

It also supports 1D arrays for Goodness of Fit tests:

 my $chisq_1d = chisq_test([10, 20, 30]);

For 2x2 matrices, Yates' Continuity Correction is applied automatically, exactly like in R.

=head2 cor

 cor($array1, $array2, $method = 'pearson'),

that is, C<pearson> is the default and will be used if C<$method> is not specified.

Just like R, C<pearson>, C<spearman>, and C<kendall> are available

If you provide an array of arrays (a matrix), C<cor> will compute the correlation matrix automatically. 

=head2 cor_test

 my $result = cor_test(
         'x'         => $x,
         'y'         => $y,
         alternative => 'two.sided'
         method      => 'pearson',
         continuity  => 1
     );

C<cor_test> safely handles C<undef> (or C<NA>) values seamlessly by computing over pairwise complete observations. 

=head2 cov

 cov($array1, $array2, 'pearson')

or

 cov($array1, $array2, 'spearman')

or

 cov($array1, $array2, 'kendall')

=head2 dnorm

gives the density of the normal distribution, with the specified mean and standard deviation.

In other words, the predicted height of the value C<x>, given a mean, standard deviation, and whether or not to use a log value.

returns a single scalar/number if a single value is given, otherwise returns an array reference.

Usage:

 dnorm(4) # assumes a mean of 0 and standard deviation of 1

but default mean, standard deviation, and log can be passed as parameters:

 $x = dnorm(0, mean => 0, sd => 2, 'log' => 0);

=head2 fisher_test

=head3 array reference entry

 my $array_data = [
     [10, 2],
     [3, 15]
 ];
 my $res1 = fisher_test($array_data);

which returns a hash reference:

 {
 alternative   "two.sided",
 conf_int      [
     [0] 2.75338278824932,
     [1] 301.462337971516
 ],
 estimate      {
     "odds ratio"   21.3053175567504
 },
 method        "Fisher's Exact Test for Count Data",
 p_value       0.00053672411914343
 }

=head3 hash reference entry

 $ft = fisher_test( {
     Guess => {
         Milk => 3, Tea => 1
     },
     Truth => {
         Milk => 1, Tea => 3
     }
 });

I have the p-value calculated very precisely, but there are some inexactness (approximately 1% for the confidence intervals) which I couldn't rectify.  The answers are very close to R besides the p-value, where they are identical.

=head2 glm

takes a hash of an array as input

 my %tooth_growth = (
     dose => [qw(0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0
 1.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5
 0.5 0.5 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0
 2.0 2.0 2.0)],
     len  => [qw(4.2 11.5  7.3  5.8  6.4 10.0 11.2 11.2  5.2  7.0 16.5 16.5 15.2 17.3 22.5
 17.3 13.6 14.5 18.8 15.5 23.6 18.5 33.9 25.5 26.4 32.5 26.7 21.5 23.3 29.5
 15.2 21.5 17.6  9.7 14.5 10.0  8.2  9.4 16.5  9.7 19.7 23.3 23.6 26.4 20.0
 25.2 25.8 21.2 14.5 27.3 25.5 26.4 22.4 24.5 24.8 30.9 26.4 27.3 29.4 23.0)],
     supp => [qw(VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC
 VC VC VC VC VC OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ
 OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ)]
 );
 
 my $glm_teeth = glm(
     data    => \%tooth_growth,
     formula => 'len ~ dose + supp',
     family  => 'gaussian'
 );

I'm not completely confident that this is working perfectly, though I've gotten this subroutine to work for simple cases.

In addition to the C<gaussian> default, it fully supports logistic regression using the C<binomial> family parameter via Iteratively Reweighted Least Squares (IRLS):

 my $glm_bin = glm(formula => 'am ~ wt + hp', data => \%mtcars, family => 'binomial');

=head2 group_by

Take a hash of arrays, hash of hashes, or array of hashes, and group a column by another column.

 my $aoh_data = [
     { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 20.5 },
     { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => 1.8 },
     { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 18.2 },
     { 'Gender' => 'Female' } # Intentional missing target value
 ];

as well as

 $hoh_data = {
     'Patient_A' => { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 20.5 },
     'Patient_B' => { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => 1.8 },
     'Patient_C' => { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 18.2 },
     'Patient_D' => { 'Gender' => 'Female' }, # Intentional missing target value
     'Patient_E' => { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => undef } # Explicit undef
     };

and

 my $hoa_data = {
     'Gender'                       => ['Male', 'Female', 'Male', 'Female'],
     'Testosterone, total (nmol/L)' => [22.1,   2.5,      19.4,   undef   ]
 };

then run the function thus:

 group_by( $hoa_data, 'Testosterone, total (nmol/L)', 'Gender');

The output can be thought of like a hash, with the first string broken down by the second.

all become the hash of arrays:

 {
     Female   [
         [0] 1.8
     ],
     Male     [
         [0] 18.2,
         [1] 20.5
     ]
 }

returns an empty array of hashes if neither target nor group keys are found.

=head3 Filtering

Data can be further broken down with filter/subs like in C<read_table>:

 my $testosterone = group_by($d, # group testosterone by "Gender"
     'Testosterone, total (nmol/L)',
     'Gender',
     { 'Race/Hispanic origin w/ NH Asian' => sub { $_ eq $n } },
     { 'Testosterone, total (nmol/L)' => sub { $_ ne 'NA' } } # filter
 );

where each filter filters on the columns, e.g. second hash keys.

=head2 hist

Computes the histogram of the given data values, operating in single $O(N)$ pass performance. It returns the bin counts, computed breaks, midpoints, and density. 

 my $res = hist([1, 2, 2, 3, 3, 3, 4, 4, 5], breaks => 4);

If C<breaks> is not explicitly provided, it defaults to calculating the number of bins using Sturges' formula.

=head2 kruskal_test

Essentially the test determines if all groups have the same median (same distribution) (an excellent review is at https://library.virginia.edu/data/articles/getting-started-with-the-kruskal-wallis-test)

Performs a Kruskal-Wallis rank sum test, see 
https://www.rdocumentation.org/packages/stats/versions/3.6.2/topics/kruskal.test

=head3 hash of array entry

I feel that this is better, and more easily read, than what you get in R:

 my %x = (
 'normal.subjects' => [2.9, 3.0, 2.5, 2.6, 3.2],
 'obs. airway disease' => [3.8, 2.7, 4.0, 2.4],
 'asbestosis' => [2.8, 3.4, 3.7, 2.2, 2.0]
 );
 $t0 = Time::HiRes::time();
 $kt = kruskal_test(\%x);
 $t1 = Time::HiRes::time();
 printf("Kruskal calculation via HoA in %g seconds.\n", $t1-$t0);
 p $kt;

=head3 R-like array entry

 my @xk = (2.9, 3.0, 2.5, 2.6, 3.2); # normal subjects
 my @yk = (3.8, 2.7, 4.0, 2.4);      # with obstructive airway disease
 my @zk = (2.8, 3.4, 3.7, 2.2, 2.0); # with asbestosis
 my @x = (@xk, @yk, @zk);
 my @g = (
     (map {'Normal subjects'} 0..4),
     (map {'Subjects with obstructive airway disease'} 0..3),
     map {'Subjects with asbestosis'} 0..4
 );
 my $t0 = Time::HiRes::time();
 my $kt = kruskal_test(\@x, \@g);
 my $t1 = Time::HiRes::time();
 printf("Kruskal calculation in %g seconds.\n", $t1-$t0);
 p $kt;

=head2 ks_test

The Kolmogorov-Smirnov test, which tests whether or not two arrays/lists of data are part of the same distribution is implemented simply:

 $ks = ks_test(\@x, \@y, alternative => 'greater');

returning a hash reference.

Also, a single array can be tested against a normal distribution:

 $ks = ks_test($ksx, 'pnorm');

The p-value precision is about 1e-8, which I want to improve, but am not sure how.

=head2 ljoin

Consider a hash: C<$h{$row}{$col}>, and another hash C<$i{$row}{$col}>.
C<ljoin> will add information for C<$col> in C<%i> for each C<$row> to C<%h>, where C<$row> exists in both C<%h> and C<%i>

For example,

 {
 "Jack Smith"   {
     age   30
 }
 }

and a second hash,
    {
        "Jack Smith"   {
            dept   "Engineering"
        },
        "Jane Doe"     {
            age   25
        }
    }

in this case, running C<ljoin(\%h, \%i)> will modify \%h to result:

 {
 "Jack Smith"   {
     age    30,
     dept   "Engineering"
 }
 }

=head2 lm

This is the linear models function.

 $lm = lm(formula =>  'mpg ~ wt + hp', data => $mtcars);

where C<$mtcars> is a hash of hashes

C<lm> also supports generating interaction terms directly within the formula using the C<*> operator:

 my $lm = lm(formula => 'mpg ~ wt * hp^2', data => \%mtcars);

If your data contains missing numbers (C<NA> or C<undef>), C<lm> handles listwise deletion dynamically to ensure mathematical integrity before fitting.

the dot operator also works:

 $lm = lm(formula => 'y ~ .', data => $dot_data);

=head2 matrix

 my $mat1 = matrix(
     data => [1..6],
     nrow => 2
 );

You can also pass C<< byrow =E<gt> 1 >> if you want the matrix populated row-wise instead of column-wise.

As of version 0.10, parameters do not need to be named, so that C<matrix> works more like R:

 my $d = matrix(rnorm(32000), 1000, 32);

works as C<data>, C<nrow>, and C<ncol>

=head2 max

 max(1,2,3);

or

 my @arr = 1..8;
 max(@arr, 4, 5)

as of version 0.02, max will die if any undefined values are provided

=head2 mean

 mean(1,2,3);

or

 my @arr = 1..8;
 mean(@arr, 4, 5)

or

 mean([1,1], [2,2]) # 1.5

as of version 0.02, mean will die if any undefined values are provided

=head2 median

works like mean, taking array references and arrays:

 median( $test_data[$i][0] )

as of version 0.02, median will die if any undefined values are provided

=head2 min

 min(1,2,3);

or

 my @arr = 1..8;
 min(@arr, 4, 5)

as of version 0.02, min will die if any undefined values are provided

=head2 mode

Takes either an array or an array reference, and returns an array of the most common scalars (numbers or strings)

 @arr = mode([1,3,3,3]); # returns (3)
 
 @arr = mode('a','a','c','c','z'); # returns ('a', 'c')

=head2 oneway_test

Like ANOVA/aov but does not assume normality

=head3 hash of array input

 $test_data = oneway_test({
     yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
     ctrl  => [1,     1,   1,   0,   0,   0]
 });

which will output a hash reference:

 {
 Group         {
     Df          1,
     "F value"   177.504798464491,
     "Mean Sq"   61.6533333333333,
     Pr(>F)      1.31343255160843e-07,
     "Sum Sq"    61.6533333333333
 },
 group_stats   {
     mean   {
         ctrl    0.5,
         yield   5.03333333333333
     },
     size   {
         ctrl    6,
         yield   6
     }
 },
 Residuals     {
     Df          9.81767348326473,
     "Mean Sq"   0.353783749200256,
     "Sum Sq"    3.47333333333333
 }

}

=head3 array of array input

 oneway_test([
    [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
    [1,     1,   1,   0,   0,   0]
     ]);

which will output a nearly identical hash reference as for hash of arrays:

 {
 Group         {
     Df          1,
     "F value"   177.504798464491,
     "Mean Sq"   61.6533333333333,
     Pr(>F)      1.31343255160843e-07,
     "Sum Sq"    61.6533333333333
 },
 group_stats   {
     mean   {
         "Index 0"   5.03333333333333,
         "Index 1"   0.5
     },
     size   {
         "Index 0"   6,
         "Index 1"   6
     }
 },
 Residuals     {
     Df          9.81767348326473,
     "Mean Sq"   0.353783749200256,
     "Sum Sq"    3.47333333333333
 }
 }

=head2 p_adjust

Returns array of false-discovery-rate-corrected p-values, where methods available are "holm", "hochberg", "hommel", "bonferroni", "BH", "BY", "fdr"

 my @q = p_adjust(\@pvalues, $method);

=head2 power_t_test

 $test_data = power_t_test(
     n   => 30,  delta     => 0.5, 
     sd  => 1.0, sig_level => 0.05
 );

It also allows configuring the test type (C<< type =E<gt> 'one.sample' >>, C<'two.sample'>, C<'paired'>) and alternative hypothesis (C<< alternative =E<gt> 'one.sided' >>). You can also pass C<< strict =E<gt> 1 >> to strictly evaluate both tails of the distribution.



=begin html

<table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>n</code></td>
  <td>Float</td>
  <td><code>undef</code></td>
  <td>Number of observations (per group for two-sample, pairs for paired).</td>
</tr>
<tr>
  <td><code>delta</code></td>
  <td>Float</td>
  <td><code>undef</code></td>
  <td>True difference in means.</td>
</tr>
<tr>
  <td><code>sd</code></td>
  <td>Float</td>
  <td>1.0</td>
  <td>Standard deviation.</td>
</tr>
<tr>
  <td><code>sig_level</code></td>
  <td>Float</td>
  <td>0.05</td>
  <td>Significance level (Type I error probability). Also accepts <code>sig.level</code>.</td>
</tr>
<tr>
  <td><code>power</code></td>
  <td>Float</td>
  <td><code>undef</code></td>
  <td>Power of test (1 minus Type II error probability).</td>
</tr>
<tr>
  <td><code>type</code></td>
  <td>String</td>
  <td><code>"two.sample"</code></td>
  <td>Type of t-test: <code>"two.sample"</code>, <code>"one.sample"</code>, or <code>"paired"</code>.</td>
</tr>
<tr>
  <td><code>alternative</code></td>
  <td>String</td>
  <td><code>"two.sided"</code></td>
  <td>One- or two-sided test: <code>"two.sided"</code>, <code>"one.sided"</code>, <code>"greater"</code>, or <code>"less"</code>.</td>
</tr>
<tr>
  <td><code>strict</code></td>
  <td>Boolean</td>
  <td><code>FALSE</code></td>
  <td>Use strict interpretation of two-sided power calculations.</td>
</tr>
<tr>
  <td><code>tol</code></td>
  <td>Float</td>
  <td>~<code>1.22e-4</code></td>
  <td>Numerical tolerance used for the internal root-finding algorithm.</td>
</tr>
</tbody>
</table>

=end html



=head2 prcomp

Principal Component Analysis

=head3 Options



=begin html

<table>
<thead>
<tr>
  <th>Option</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>center</code></td>
  <td>Boolean</td>
  <td><code>1</code> (True)</td>
  <td>If true, the variables are shifted to be zero-centered before the analysis takes place.</td>
</tr>
<tr>
  <td><code>scale</code></td>
  <td>Boolean</td>
  <td><code>0</code> (False)</td>
  <td>If true, the variables are scaled to have unit variance before the analysis takes place. <i>Note: If a column has zero variance, the function will <code>croak</code> to prevent division by zero.</i></td>
</tr>
<tr>
  <td><code>retx</code></td>
  <td>Boolean</td>
  <td><code>1</code> (True)</td>
  <td>If true, the rotated data (the original data multiplied by the rotation matrix) is returned under the key <code>x</code>.</td>
</tr>
<tr>
  <td><code>tol</code></td>
  <td>Number</td>
  <td><code>undef</code></td>
  <td>A value indicating the magnitude below which components should be omitted. Components are omitted if their standard deviation is less than or equal to <code>tol</code> times the standard deviation of the first component.</td>
</tr>
<tr>
  <td><code>rank</code></td>
  <td>Integer</td>
  <td><code>undef</code></td>
  <td>Optionally specify a strict limit on the number of principal components to return. The function will return <code>min(rank, rows, columns)</code> components.</td>
</tr>
</tbody>
</table>

=end html



=head3 Results

=head3 Returned Data Structure

The C<prcomp> function returns a HashRef containing the following keys representing the results of the Principal Component Analysis:



=begin html

<table>
<thead>
<tr>
  <th>Key</th>
  <th>Type</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>sdev</code></td>
  <td>ArrayRef[Number]</td>
  <td>The standard deviations of the principal components. Mathematically, these are the square roots of the eigenvalues of the covariance matrix.</td>
</tr>
<tr>
  <td><code>rotation</code></td>
  <td>ArrayRef[ArrayRef]</td>
  <td>A 2D array representing the matrix of variable loadings (the eigenvectors). Each inner array represents a row, and the columns correspond to the principal components.</td>
</tr>
<tr>
  <td><code>x</code></td>
  <td>ArrayRef[ArrayRef]</td>
  <td>A 2D array containing the rotated data (often referred to as PCA scores). This is the original data projected onto the principal components. <i>Note: Only present if the <code>retx</code> option is true.</i></td>
</tr>
<tr>
  <td><code>center</code></td>
  <td>ArrayRef[Number] or <code>0</code></td>
  <td>The centering values used (typically the column means). Returns false (<code>0</code>) if centering was disabled.</td>
</tr>
<tr>
  <td><code>scale</code></td>
  <td>ArrayRef[Number] or <code>0</code></td>
  <td>The scaling values used (typically the column standard deviations). Returns false (<code>0</code>) if scaling was disabled.</td>
</tr>
<tr>
  <td><code>varnames</code></td>
  <td>ArrayRef[String]</td>
  <td>The sorted names of the original variables. <i>Note: Only present if the input data was a Hash of Arrays (HoA) or a Hash of Hashes (HoH).</i></td>
</tr>
</tbody>
</table>

=end html



=head3 Using array of arrays

 my $aoa = [ 
     [2, 4], 
     [4, 2], 
     [6, 6] 
 ];
 
 my $pca = prcomp($aoa);

which returns

 {
     center     [
         [0] 4,
         [1] 4
     ],
     rotation   [
         [0] [
                 [0] 0.707106781186547,
                 [1] 0.707106781186548
             ],
         [1] [
                 [0] 0.707106781186548,
                 [1] -0.707106781186547
             ]
     ],
     scale      false,
     sdev       [
         [0] 2.44948974278318,
         [1] 1.4142135623731
     ],
     x          [
         [0] [
                 [0] -1.41421356237309,
                 [1] -1.4142135623731
             ],
         [1] [
                 [0] -1.4142135623731,
                 [1] 1.41421356237309
             ],
         [2] [
                 [0] 2.82842712474619,
                 [1] 2.22044604925031e-16
             ]
     ]
 }

=head3 Hash of Arrays

 my $hoa = { B => [4, 2, 6], A => [2, 4, 6] };
 my $pca = prcomp($hoa);

=head2 quantile

Calculates sample quantiles using R's continuous Type 7 interpolation. 

 my $quantile = quantile('x' => [1..99], probs => [0.05, 0.1, 0.25]);

If the C<probs> parameter is omitted, it behaves identically to R by defaulting to the 0, 25, 50, 75, and 100 percentiles (C<c(0, .25, .5, .75, 1)>). The returned hash keys match R's standardized naming convention (e.g., C<"25%">, C<"33.3%">).

=head2 rbinom

Create a binomial distribution of numbers

 my $binom = rbinom( n => $n, prob => 0.5, size => 9);

It hooks directly into Perl's internal PRNG system, respecting C<srand()> seeds. 

=head2 read_table

I've tried to make this as simple as possible, trying to follow from R:

 my $test_data = read_table('t/HepatitisCdata.csv');

=head2 options



=begin html

<table>
<thead>
<tr>
  <th>Option</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>comment</code></td>
  <td>Comment character, by default <code>#</code></td>
  <td><code>comment = %</code> or whatever</td>
</tr>
<tr>
  <td><code>output.type</code></td>
  <td>data type for output: array of hash, hash of array, or hash of hash</td>
  <td><code>'output.type' => 'aoh'</code></td>
</tr>
<tr>
  <td><code>filter</code></td>
  <td>Only take in rows with a certain filter</td>
  <td><code>filter => {	Sex => sub {$_ eq 'f'} }</code></td>
</tr>
<tr>
  <td><code>row.names</code></td>
  <td>include row names in retrieved data; off by default</td>
  <td></td>
</tr>
<tr>
  <td><code>sep</code></td>
  <td>field separator character; synonym with <code>delim</code></td>
  <td><code>sep => "\t"</code></td>
</tr>
<tr>
  <td><code>delim</code></td>
  <td>field separator character; synonym with <code>sep</code></td>
  <td><code>delim => "\t"</code></td>
</tr>
</tbody>
</table>

=end html



output types can be AOH (aoa), HOA (hoa), HOH (hoh)

 read_table($filename, 'output.type' => 'aoh');
 
 read_table($filename, 'output.type' => 'hoa');

and, like Text::CSV_XS, filters can be applied in order to save RAM on big files:

 $test_data = read_table(
     't/HepatitisCdata.csv',
     filter => {
         Sex => sub {$_ eq 'f'} # where "Sex" is the column name, and "$_" is the value for that column
     },
     'output.type' => 'aoh'
 );

the default delimiter is C<,>
Suffixes C<.csv> and C<.tsv> are automatically detected from file names, but if specified, are overridden by C<delim> and/or C<sep>. C<sep> is given priority.

=head2 rnorm

Make a normal distribution of numbers, with pre-set mean C<mean>, standard deviation C<sd>, and number C<n>.

 my ($rmean, $sd, $n) = (10, 2, 9999);
 my $normals = rnorm( n => $n, mean => $rmean, sd => $sd);

=head2 runif

Make an approximately uniform distribution into an array

=head3 named arguments

 my $unif = runif( n => $n, min => 0, max => 1);

where C<n> is the number of items, the values are between C<min> and C<max>

=head3 positional args

this is to match R's behavior:

 runif( 9 )

will make 9 numbers in [0,1]

 runif(9, 0, 99)

will match C<n>, C<min>, and C<max> respectively

=head2 sample

take a sample of hash or array slices.

 my $h = sample(\%h, 4); # take 4 hash keys and their values into $h

or, alternatively, with arrays:

 my $arr = sample(\@arr, 3); # take 3 indices of an array

=head2 scale

 my @scaled_results = scale(1..5);

You can also pass an options hash to disable centering or scaling:

 my @scaled_results = scale(1..5, { center => false, scale => true });

It fully supports matrix operations. By passing an array of arrays, C<scale> processes the data column by column independently:

 my $scaled_mat = scale([[1, 2], [3, 4], [5, 6]]);

=head2 sd

 my $stdev = sd(2,4,4,4,5,5,7,9);

Correct answer is 2.1380899352994

C<sd> can accept both array references as well as arrays:

 my $stdev = sd([2,4,4,4,5,5,7,9]);

As of version 0.02, sd will croak/die if any undefined values are provided.

=head2 seq

Works as closely as I can to R's seq, which is very similar to Perl's C<for> loops.  Returns an array, not an array reference.

=head3 Example 1: Standard integer sequence

 say 'seq(1, 5):';
 my @seq = seq(1, 5);
 say join(', ', @seq), "\n";
 
 say 'seq(1, 2, 0.25):';
 @seq = seq(1, 2, 0.25);

=head3 Example 2: Fractional steps

 say 'seq(1, 2, 0.25):';
 @seq = seq(1, 2, 0.25);
 say join(", ", @seq), "\n";
 for (my $idx = 2; $idx >= 1; $idx -= 0.25) { # count down to pop
     is_approx(pop @seq, $idx, "seq item $idx with fractional step");
 }

=head3 Example 3: Negative steps

 say 'seq(10, 5, -1):';
 @seq = seq(10, 5, -1);
 say join(", ", @seq), "\n";
 for (my $idx = 5; $idx <= 10; $idx++) { # count down to pop
     is_approx(pop @seq, $idx, "seq item $idx with negative step");
 }

=head2 shapiro_test

tests to see if an array reference is normally distributed, returns a p-value and a statistic

 my $shapiro = shapiro_test(
     [1..5]
 );

and returns the hash reference:

 {
 p.value     0.589650577093106,
 p_value     0.589650577093106,
 statistic   0.960870680168535,
 W           0.960870680168535
 }

=head2 sum

returns sum, but using both arrays and array references.

 my $test_data = [1..8];
 sum($test_data)

which I prefer, compared to List::Util's required casting into an array:

 sum(@{ $test_data });

which passing a reference is shorter and much easier to read.  Stats::LikeR, however, will work for B<both>

as of version 0.02, C<sum> will cause the script to die if any undefined values are provided

=head2 summary

Analogous to R's C<summary>, but does not deal with outputs from other functions.
C<summary> only describes data as it is entered.
An option C<nrows> or its synonym C<nrow> specifies the maximum number of rows that will print.

=head3 array of array input

 my @arr;
 foreach my $i (0..18) {
     push @arr, runif(22);
 }

and then C<summary(\@arr)>, or C<summary(@arr)>

 ---------------------------------------------------------------------------
 Index  # values      Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
 ---------------------------------------------------------------------------
      0       22   0.04312     0.286    0.4975    0.5121    0.7296    0.9633 
      1       22   0.05932    0.1483     0.495    0.4737    0.7699    0.9371 
      2       22   0.02742    0.1588    0.4045    0.4325    0.6682    0.9878 
      3       22  0.009233    0.2552    0.5398    0.5147    0.7755    0.9808 
      4       22   0.06727    0.2432    0.5019    0.4855    0.7121    0.9043 
      5       22  0.001032    0.1646    0.3021    0.3727    0.5704    0.9556 

=head3 hash of array input

 $test_data = summary(
     {
         A => runif(9),
         B => runif(9)
     },
 );

=head2 t_test

There are 1-sample and 2-sample t-tests:

 my $t_test = t_test( $test_data[$i][$j], mu => mean( $test_data[$i][$j] ));

or 2-sample:

 $t_test = t_test(
     $test_data[3][0],
     $test_data[3][1],
     paired => true
 );

returns a hash reference, which looks like:

 conf_int     => [
     -0.06672889, 0.25672889
 ],
 df        => 5,
 estimate  => 0.095,
 p_value   => 0.19143688433660,
 statistic => 1.50996688705414

the two groups compared can be specified, though not necessarily, as C<x> and C<y>, just like in R:

 $t_test = t_test(
     'x' => test_data[3][0],
     'y' => $test_data[3][1],
     paired => true
 );

=head3 Parameters



=begin html

<table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>x</code></td>
  <td>Array Reference</td>
  <td>Required</td>
  <td>The first vector of data. Must contain at least 2 elements.</td>
</tr>
<tr>
  <td><code>y</code></td>
  <td>Array Reference</td>
  <td><code>undef</code></td>
  <td>The second vector of data. Required for two-sample or paired tests.</td>
</tr>
<tr>
  <td><code>mu</code></td>
  <td>Float</td>
  <td>0.0</td>
  <td>The true value of the mean (or difference in means) for the null hypothesis.</td>
</tr>
<tr>
  <td><code>paired</code></td>
  <td>Boolean</td>
  <td><code>FALSE</code></td>
  <td>If true, performs a paired t-test. <code>x</code> and <code>y</code> must be the same length.</td>
</tr>
<tr>
  <td><code>var_equal</code></td>
  <td>Boolean</td>
  <td><code>FALSE</code></td>
  <td>If true, assumes equal variances (standard two-sample). If false, performs Welch's t-test with unequal variances.</td>
</tr>
<tr>
  <td><code>conf_level</code></td>
  <td>Float</td>
  <td>0.95</td>
  <td>Confidence level for the returned confidence interval. Must be between 0 and 1.</td>
</tr>
<tr>
  <td><code>alternative</code></td>
  <td>String</td>
  <td><code>"two.sided"</code></td>
  <td>Direction of the alternative hypothesis: <code>"two.sided"</code>, <code>"less"</code>, or <code>"greater"</code>.</td>
</tr>
</tbody>
</table>

=end html



=head3 Return Hash



=begin html

<table>
<thead>
<tr>
  <th>Key</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>statistic</code></td>
  <td>The computed t-statistic.</td>
</tr>
<tr>
  <td><code>df</code></td>
  <td>Degrees of freedom for the test.</td>
</tr>
<tr>
  <td><code>p_value</code></td>
  <td>The calculated p-value based on the test directionality.</td>
</tr>
<tr>
  <td><code>conf_int</code></td>
  <td>An Array Reference containing two elements: <code>[lower_bound, upper_bound]</code>.</td>
</tr>
<tr>
  <td><code>estimate</code></td>
  <td>The estimated mean of <code>x</code> (one-sample) OR the mean of the differences (paired).</td>
</tr>
<tr>
  <td><code>estimate_x</code></td>
  <td>The estimated mean of the <code>x</code> vector (only returned in two-sample tests).</td>
</tr>
<tr>
  <td><code>estimate_y</code></td>
  <td>The estimated mean of the <code>y</code> vector (only returned in two-sample tests).</td>
</tr>
</tbody>
</table>

=end html



=head2 value_counts

Count the values in a given data set, return a hash reference showing how many times each particular value is present.

=head3 Scalar

 $hash = value_counts('c');

returns C<< { c =E<gt> 1 } >>

=head3 Array reference

 value_counts(['a','b','b']);

returns C<< { a =E<gt> 1, b =E<gt> 2} >>

=head3 Array

 my $value_counts = value_counts('a','b','b');

like an array reference above, returns C<< { a =E<gt> 1, b =E<gt> 2} >>

=head3 Hash

 my $value_counts = value_counts( { A => 'a', B => 'a', C => 'b' } );

returns C<< { a =E<gt> 2, b =E<gt> 1} >>

=head3 Hash of array

 my $value_counts = value_counts({ 'a' => ['j', 't', 't'], 'b' => ['j', 't', 'v']});

without a key (like above), the occurences of C<j>, C<t>, and C<v> are counted.

With a key, like C<a> for above, only values within that hash key are counted:

 my $vc = value_counts({ 'a' => ['j', 't', 't'], 'b' => ['j', 't', 'v']}, 'a');

=head3 Hash of hash (table)

 $hash = value_counts( {
     A => {
         a => 'x',
         b => 'z'
     },
     B => {
         a => 'x'
     },
     C => {
         a => 'y'
     }
 }, 'a');

the column, or second hash key, that you wish to count, is specified at the command line

=head2 var

as simple as possible:

 var(2, 4, 5, 8, 9)

as of version 0.02, C<var> will die if any undefined values are provided

like C<min>, C<max>, etc., C<var> can accept array references, to make code simpler:

 my $ref = \@arr;
 var($ref) = var(@arr)

=head2 var_test

As described by R: Performs an F test to compare the variances of two samples from normal populations

 use Stats::LikeR;
 use Time::HiRes;
 
 my @x = (2.9, 3.0, 2.5, 2.6, 3.2);
 my @y = (3.8, 2.7, 4.0, 2.4);
 
 my $t0 = Time::HiRes::time();
 my $vt = var_test(\@x, \@y);
 my $t1 = Time::HiRes::time();
 printf("var_tests in %g seconds.\n", $t1-$t0);

also, conf_level can be set:

 $vt = var_test(\@xk, \@yk, conf_level => 0.99);

as well as a ratio (from R: the hypothesized ratio of the population variances of C<x> and C<y>:

 $test_data = var_test(\@xk, \@yk, ratio => 2);

=head2 wilcox_test

 $test_data = wilcox_test(
     [1.83,  0.50,  1.62,  2.48, 1.68, 1.88, 1.55, 3.06, 1.30],
     [0.878, 0.647, 0.598, 2.05, 1.06, 1.29, 1.06, 3.14, 1.29]
 );

It fully supports paired tests (C<< paired =E<gt> true >>) and can calculate exact p-values (the default for C<< N E<lt> 50 >> without ties). If ties are encountered, it automatically switches to an approximation with continuity correction.

=head2 write_table

mimics R's C<write.table>, with data as first argument to subroutine, and output file as second

 write_table(\@data_aoh, $tmp_file, sep => "\t", 'row.names' => true);

You can also precisely filter and reorder which columns are written by passing an array reference to C<col.names>:

 write_table(\@data, $tmp_file, sep => "\t", 'col.names' => ['c', 'a']);

undefined variables are printed as C<NA> by default, but can be set as you wish using C<undef.val>

 write_table(\%data_hoa, '/tmp/undef.val.tsv', sep => "\t", 'undef.val' => 'nan')

as of version 0.07, C<write_table> determines comma and tab-separated delimiters from the filename, but will override if C<sep> or C<delim> are explicitly set.

=head1 changes

=head2 0.10

changes to compilation for CPAN, trying to get this work on Windows

Addition of C<prcomp> and C<value_counts>

C<matrix> will work without key names, just like in R.  Testing for C<matrix> has improved.

=head2 0.09

context changes in XS C<dTHX>, C<pTHX_>, and C<aTHX_> to get better CPAN testing results

C<restrict> keywords added to C<lm> to increase speed

=head2 0.08

Speed improvement in C<summary> of hashes.

Addition of C<add_data>, C<dnorm>, C<group_by>, C<ljoin>, and C<mode> functions

Chi-squared function no longer has Perl wrapper, and all code is in XS, which should result in a minor speed increase with 1 less function call.

Compiler changes for GNU source and inclusion of C<strings.h>, to ensure more CPAN testing works better.

C<read_table> now returns hash-of-hash in {row}{column}

=head2 0.07

Addition of C<summary> function.

Formulas can now be omitted from C<aov>, resulting in a stacked calculation as R would think.

Addition of C<oneway_test> for multi-group comparisons that does not assume normality like C<aov> does.

C<read_table> and C<write_table> now automatically set separators for C<.csv> files as C<,> and C<.tsv> files as C<"\t">, respectively, so these values no longer need to be specified separately from the file name.

=head2 0.06

Changed compiler options so that Solaris will work

signed integers changed to unsigned in C<glm>

Added restrict keywords to C<power_t_test>, and made C<int> to C<unsigned int>

=head2 0.05

Leak testing for C<sample>

removal of Data::Printer dependency for easier CPAN testing

switched several C<unsigned int> variable to C<I32> so that clang doesn't complain

added restrict keyword for C<sample>

=head2 0.04

addition of C<sample> function

GNU source, to maximize compatibility and ease installation

removal of JSON dependency to ease installation

=head2 0.03

Compatibility back to Perl 5.10

=head2 0.02

back-compatible to Perl 5.10, instead of original 5.40, ensuring more people can use it

added var_test

mean, min, sum, median, var, and max die with undefined values, and print the offending indices

"group_stats" added to aov, for TukeyHSD in the future

"cor" dies when given data with standard deviation of 0

var_test added

C<write_table> now has C<undef.val> option, which shows how undefined values are printed to tables, which is C<NA> by default.
