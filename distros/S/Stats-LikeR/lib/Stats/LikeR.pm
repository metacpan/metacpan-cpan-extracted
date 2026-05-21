#!/usr/bin/env perl
# ABSTRACT: Get basic statistical functions, like in R, but with Perl using XS for performance
require 5.010;
use strict;
use feature 'say';
package Stats::LikeR;
our $VERSION = 0.06;
require XSLoader;
use Devel::Confess 'color';
use warnings FATAL => 'all';
use autodie ':default';
use Exporter 'import';
XSLoader::load('Stats::LikeR', $VERSION);
our @EXPORT_OK = qw(aov chisq_test cor cor_test cov fisher_test glm hist kruskal_test ks_test lm matrix mean median min max p_adjust power_t_test quantile rbinom read_table rnorm runif sample scale sd seq shapiro_test sum t_test var var_test wilcox_test write_table);
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

sub summary {
	my $data = shift;
	my $ref_type = ref $data;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1];
	if (($ref_type ne 'ARRAY') && ($ref_type ne 'HASH')) {
		die "data for $current_sub must either be a hash or an array, not \"$ref_type\"";
	}
	my %args = (
		nrows => 10,
		@_,
	);
	if ($ref_type eq 'ARRAY') {
		
	}
}

#sub sample {
#	my $ref = shift;
#	my $n = 1;
#	$n = shift if defined $_[0];
#	my $ref_type = ref $ref;
#	if ($ref_type eq 'HASH') {
#		my %return;
#		my @keys = shuffle( keys %{ $ref } );
#		foreach my $k (@keys) {
#			$return{$k} = $ref->{$k};
#			last if (scalar keys %return) == $n;
#		}
#		return \%return;
#	} elsif ($ref_type eq 'ARRAY') {
#		my @shuffled = shuffle( @{ $ref } );
#		return \@shuffled[0..$n-1];
#	}
#}

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

Get basic R statistical functions working in Perl as if they were part of List::Util, like C<min>, C<max>, C<sum>, etc.
I've used Artificial Intelligence tools such as Claude, Gemini, and Grok to write this as well as using my own gray matter.
There are other similar tools on CPAN, but I want speed and a form like List::Util, which I've gotten here with the help of AI, which often required many attempts to do correctly.
This is meant to call subroutines directly through eXternal Subroutines (XS) for performance and portability.

There B<are> other modules on CPAN that can do B<PARTS> of this, but this works the way that I B<want> it to.

=head1 Functions/Subroutines

=head2 aov

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

=head2 hist

Computes the histogram of the given data values, operating in single $O(N)$ pass performance. It returns the bin counts, computed breaks, midpoints, and density. 

 my $res = hist([1, 2, 2, 3, 3, 3, 4, 4, 5], breaks => 4);

If C<breaks> is not explicitly provided, it defaults to calculating the number of bins using Sturges' formula.

=head2 kruskal_test

Essentially the test determines if all groups have the same median (same distribution) (an excellent review is at https://library.virginia.edu/data/articles/getting-started-with-the-kruskal-wallis-test)

Performs a Kruskal-Wallis rank sum test, see 
https://www.rdocumentation.org/packages/stats/versions/3.6.2/topics/kruskal.test

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

=head2 ks_test

The Kolmogorov-Smirnov test, which tests whether or not two arrays/lists of data are part of the same distribution is implemented simply:

 $ks = ks_test(\@x, \@y, alternative => 'greater');

returning a hash reference.

Also, a single array can be tested against a normal distribution:

 $ks = ks_test($ksx, 'pnorm');

The p-value precision is about 1e-8, which I want to improve, but am not sure how.

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

=head2 p_adjust

Returns array of false-discovery-rate-corrected p-values, where methods available are "holm", "hochberg", "hommel", "bonferroni", "BH", "BY", "fdr"

 my @q = p_adjust(\@pvalues, $method);

=head2 power_t_test

 $test_data = power_t_test(
     n   => 30,  delta     => 0.5, 
     sd  => 1.0, sig_level => 0.05
 );

It also allows configuring the test type (C<< type =E<gt> 'one.sample' >>, C<'two.sample'>, C<'paired'>) and alternative hypothesis (C<< alternative =E<gt> 'one.sided' >>). You can also pass C<< strict =E<gt> 1 >> to strictly evaluate both tails of the distribution.

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

=head2 rnorm

Make a normal distribution of numbers, with pre-set mean C<mean>, standard deviation C<sd>, and number C<n>.

 my ($rmean, $sd, $n) = (10, 2, 9999);
 my $normals = rnorm( n => $n, mean => $rmean, sd => $sd);

=head2 runif

=head3 named arguments

Make a distribution of approximately uniform distribution

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

which is shorter and much easier to read

as of version 0.02, C<sum> will cause the script to die if any undefined values are provided

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
 my @z = (2.8, 3.4, 3.7, 2.2, 2.0);
 
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

mimics R's "write.table", with data as first argument to subroutine, and output file as second

 write_table(\@data_aoh, $tmp_file, sep => "\t", 'row.names' => true);

You can also precisely filter and reorder which columns are written by passing an array reference to C<col.names>:

 write_table(\@data, $tmp_file, sep => "\t", 'col.names' => ['c', 'a']);

undefined variables are printed as C<NA> by default, but can be set as you wish using C<undef.val>

 write_table(\%data_hoa, '/tmp/undef.val.tsv', sep => "\t", 'undef.val' => 'nan')

=head1 changes

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
