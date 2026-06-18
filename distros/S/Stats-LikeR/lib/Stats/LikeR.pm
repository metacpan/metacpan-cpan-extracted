#!/usr/bin/env perl
# ABSTRACT: Get basic statistical functions, like in R, but with Perl using XS for performance
require 5.010;
use strict;
use feature 'say';
package Stats::LikeR;
our $VERSION = 0.16;
require XSLoader;
use Devel::Confess 'color';
use warnings FATAL => 'all';
use autodie ':default';
use Exporter 'import';
use Scalar::Util 'looks_like_number';
XSLoader::load('Stats::LikeR', $VERSION);
our @EXPORT_OK = qw(add_data aoh2hoa aov cfilter chisq_test col col2col cor cor_test cov csort dnorm filter fisher_test glm group_by hoh2hoa hist kruskal_test ks_test ljoin lm matrix max mean median min mode oneway_test p_adjust power_t_test prcomp quantile rbinom read_table rnorm runif sample scale sd seq shapiro_test sum summary t_test transpose value_counts var var_test view wilcox_test write_table);
our @EXPORT = @EXPORT_OK;

require XSLoader;
# ---- filter DSL: col() builds a predicate via overloading (pure Perl) -------
# Exported: filter (XS) and col.  Place col()/Col/Pred near the top of the .pm;
# they need no XS.  filter() is the XSUB.
sub col { Stats::LikeR::Col->new($_[0]) }
{
	package Stats::LikeR::Col;
	sub new { bless { name => $_[1] }, ref($_[0]) || $_[0] }
	# build a comparison leaf; if operands were swapped (4 > col('x')), flip the op
	sub _c {
		my ($self, $val, $swapped, $op, $flip) = @_;
		Stats::LikeR::Pred->_leaf($self->{name}, $swapped ? $flip : $op, $val);
	}
	use overload
		'>'  => sub { $_[0]->_c($_[1],$_[2],'>','<')  },
		'<'  => sub { $_[0]->_c($_[1],$_[2],'<','>')  },
		'>=' => sub { $_[0]->_c($_[1],$_[2],'>=','<=') },
		'<=' => sub { $_[0]->_c($_[1],$_[2],'<=','>=') },
		'==' => sub { $_[0]->_c($_[1],$_[2],'==','==') },
		'!=' => sub { $_[0]->_c($_[1],$_[2],'!=','!=') },
		'lt' => sub { $_[0]->_c($_[1],$_[2],'lt','gt') },
		'gt' => sub { $_[0]->_c($_[1],$_[2],'gt','lt') },
		'le' => sub { $_[0]->_c($_[1],$_[2],'le','ge') },
		'ge' => sub { $_[0]->_c($_[1],$_[2],'ge','le') },
		'eq' => sub { $_[0]->_c($_[1],$_[2],'eq','eq') },
		'ne' => sub { $_[0]->_c($_[1],$_[2],'ne','ne') },
		fallback => 1;
}
{
	package Stats::LikeR::Pred;
	sub _leaf { bless { op => $_[2], col => $_[1], val => $_[3] }, 'Stats::LikeR::Pred' }
	sub _node { bless { op => $_[0], l => $_[1], r => $_[2] }, 'Stats::LikeR::Pred' }
	use overload
		'&' => sub { Stats::LikeR::Pred::_node('and', $_[0], $_[1]) },
		'|' => sub { Stats::LikeR::Pred::_node('or',  $_[0], $_[1]) },
		'!' => sub { Stats::LikeR::Pred::_node('not', $_[0], undef) },
		fallback => 1;
}
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
	die "read_table: \"$file\" is not a file\n"   unless -f $file;
	die "read_table: \"$file\" is not readable\n" unless -r $file;

	my %input_args = @_;
	if (exists $input_args{delim}) {
		# FIX: sep + delim together used to silently prefer delim
		die "read_table: pass either 'sep' or 'delim', not both\n"
			if exists $input_args{sep};
		$input_args{sep} = delete $input_args{delim};
	}

	my $default_sep = $file =~ /\.tsv$/i ? "\t" : ',';
	my %args = (
		sep     => $default_sep,
		comment => '#',
		%input_args,
	);

	my %allowed_args = map { $_ => 1 } (
		'comment', 'output.type', 'filter', 'row.names', 'sep',
	);
	my @undef_args = sort grep { !$allowed_args{$_} } keys %args;
	if (@undef_args) {
		my $current_sub = ( split /::/, (caller(0))[3] )[-1];
		# FIX: no more printing to STDOUT from a library ('say'); the die
		# message carries the offending argument names itself
		die "the args \"@undef_args\" aren't defined for $current_sub\n";
	}
	my $otype = $args{'output.type'} // 'aoh';
	die "read_table: output.type \"$otype\" isn't allowed (aoh, hoa, hoh)\n"
		unless $otype =~ m/^(?:aoh|hoa|hoh)$/;

	my $filter = $args{filter};
	if (defined $filter && ref($filter) eq 'CODE') {
		$filter = { 0 => $filter };
	} elsif (defined $filter && ref($filter) ne 'HASH') {
		die "'filter' must be a CODE or HASH reference\n";
	}

	my (@data, %data, @header, @uniq_header,
	    %mapped_filters, @sorted_filter_flds, %seen_rownames);
	my $data_row = 0;
	_parse_csv_file($file, $args{sep} // '', $args{comment} // '', sub {
		my ($line_ref) = @_;
		if (!@header) {
			# --- HEADER PROCESSING (copy made only here; runs once) ---
			my @line = @$line_ref;
			$line[0] =~ s/^\Q$args{comment}\E//
				if @line && defined $line[0] && length( $args{comment} // '' );
			@header = @line;
			if (@header && $header[0] eq '') {
				$header[0] = 'row_name';
			}
			my %seen_h;
			# FIX: hoa output with duplicate column names used to push the
			# same cell once PER OCCURRENCE, silently corrupting the column
			# lengths. Iterate unique names (order preserved) instead.
			@uniq_header = grep { !$seen_h{$_}++ } @header;
			my @dup_cols = grep { $seen_h{$_} > 1 } @uniq_header;
			warn "read_table: duplicate column name(s) in $file: @dup_cols (later values win)\n"
				if @dup_cols;
			if ($otype eq 'hoh' && !defined $args{'row.names'}) {
				$args{'row.names'} = $header[0];
			}
			if (defined $args{'row.names'}
					&& !grep { $_ eq $args{'row.names'} } @header) {
				die "\"$args{'row.names'}\" isn't in the header of $file\n";
			}
			if ($filter) {
				for my $k (keys %$filter) {
					if ($k =~ /^\d+$/) {
						# FIX: a numeric key past the last column used to be
						# accepted and then silently extended every row via
						# the $_ write-back
						die "read_table: numeric filter key $k exceeds the "
						  . scalar(@header) . " columns of $file\n"
							if $k > @header;
						$mapped_filters{$k} = $filter->{$k};
					} else {
						my ($idx) = grep { $header[$_] eq $k } 0 .. $#header;
						die "Filter column '$k' not found in header\n"
							unless defined $idx;
						$mapped_filters{ $idx + 1 } = $filter->{$k};
					}
				}
				@sorted_filter_flds = sort { $a <=> $b } keys %mapped_filters;
			}
			return;
		}
		# --- DATA PROCESSING (operate on $line_ref directly; no row copy) ---
		$data_row++;
		if (@$line_ref != @header) {
			# FIX: alignment errors now say WHICH row is ragged
			die sprintf "Alignment error on %s data row %d (%d fields vs %d headers).\n",
				$file, $data_row, scalar @$line_ref, scalar @header;
		}
		my %line_hash;
		for my $i (0 .. $#header) {
			my $v = $line_ref->[$i];
			$line_hash{ $header[$i] } = ( !defined($v) || $v eq '' ) ? undef : $v;
		}
		# --- APPLY FILTERS ---
		if (@sorted_filter_flds) {
			# FIX: 'local %_ = %line_hash' copied the whole row for every
			# filtered row AND went stale after a $_ write-back. Aliasing the
			# glob makes %_ THE row hash: zero copy, mutations always visible.
			local *_ = \%line_hash;
			my $skip = 0;
			foreach my $fld (@sorted_filter_flds) {
				local $_ = $fld == 0 ? $line_ref : $line_hash{ $header[ $fld - 1 ] };
				if ( !$mapped_filters{$fld}->( $line_ref, \%line_hash ) ) {
					$skip = 1;
					last;
				}
				if ( $fld > 0 ) {	# write back any mutation made to $_
					$line_ref->[ $fld - 1 ] = $_;
					$line_hash{ $header[ $fld - 1 ] }
						= ( !defined($_) || $_ eq '' ) ? undef : $_;
				}
			}
			return if $skip;
		}
		# Populate requested data structure
		if ($otype eq 'aoh') {
			push @data, \%line_hash;
		} elsif ($otype eq 'hoa') {
			push @{ $data{$_} }, $line_hash{$_} for @uniq_header;
		} elsif ($otype eq 'hoh') {
			my $row_name = $line_hash{ $args{'row.names'} };
			# FIX: an undef/empty row-name cell used to become the '' hash
			# key with "uninitialized" warnings; now it dies with the row
			die sprintf "read_table: undefined row name (column '%s') in %s data row %d\n",
				$args{'row.names'}, $file, $data_row
				unless defined $row_name;
			warn "read_table: duplicate row name '$row_name' in $file (later values win)\n"
				if $seen_rownames{$row_name}++;
			foreach my $col (@uniq_header) {
				next if $col eq $args{'row.names'};
				$data{$row_name}{$col} = $line_hash{$col};
			}
		}
	});
	if ($otype eq 'aoh') {
		return \@data;
	} else { # hoa or hoh
		return \%data;
	}
}
# ---------------------------------------------------------------------------
# view(): an R-style `head` for the structures read_table() returns.
#
# Handles all three output.type values:
#   aoh  -> ARRAY of HASH refs
#   hoa  -> HASH of ARRAY refs
#   hoh  -> HASH of HASH refs
#
# Pure Perl; the only dependency is Scalar::Util (core). There is nothing for
# XS to speed up here: view only touches the first n rows, and the total-row
# count is O(1) for every structure (scalar @$aoh, array length, scalar keys).
# Keeping it pure Perl also keeps install portable (no compiler needed).
#
# Usage:
#   view($data);                      # first 6 rows, like head()
#   view($data, n => 20);             # first 20 rows
#   view($data, cols => [...]);       # pin explicit column order
#   view($data, na => '.', max_width => 30, gap => 1, ellipsis => '~');
#   view($data, 'row.names' => 'id'); # use column 'id' as the row label
#   view($data, to => \*STDERR);      # print elsewhere
#   my $s = view($data, return_only => 1);  # capture string, suppress print
#
# Column order: read_table stores rows as hashes, so the original CSV column
# order is gone. view sorts columns by name for a stable layout and treats a
# column literally named 'row_name' (read_table's label for a leading blank
# header) as the row label. Pass cols => [...] to override the order.
# ---------------------------------------------------------------------------

sub view {
	my $data = shift;
	my %args = @_;

	# --- reject unknown arguments (mirrors read_table/write_table) ---
	my %allowed = map { $_ => 1 } qw(
		n rows na max_width ellipsis gap cols columns
		to return_only row.names row_names
	);
	my @bad = sort grep { !$allowed{$_} } keys %args;
	die "view: unknown argument(s): @bad\n" if @bad;

	# --- n / rows (synonyms); reject conflicting or non-integer values ---
	die "view: pass either 'n' or 'rows', not both\n"
		if exists $args{n} && exists $args{rows};
	my $n = exists $args{rows} ? $args{rows}
		  : exists $args{n}    ? $args{n}
		  :                       6;
	die "view: 'n'/'rows' must be a non-negative integer\n"
		unless defined $n && $n =~ /^\d+$/;

	my $na    = exists $args{na}        ? $args{na}        : 'NA';
	my $maxw  = exists $args{max_width} ? $args{max_width} : 80;
	my $ell   = exists $args{ellipsis}  ? $args{ellipsis}  : '...';
	my $gap   = exists $args{gap}       ? (' ' x $args{gap}) : '  ';
	my $ucols = $args{cols} || $args{columns};
	my $fh    = $args{to};
	my $quiet = $args{return_only};

	# 'row.names' takes precedence over the row_names alias (both accepted)
	my $label_col = exists $args{'row.names'} ? $args{'row.names'}
		          : exists $args{row_names}   ? $args{row_names}
		          : undef;

	my $rt = ref $data;
	die "view: expected an ARRAY (AoH) or HASH (HoA/HoH) reference, got "
	  . ($rt || 'a non-reference') . "\n"
	  unless $rt eq 'ARRAY' or $rt eq 'HASH';

	my ($kind, @cols, @labels, @raw, $total, $lab_header);
	if ($rt eq 'ARRAY') { # ---- AoH ----
		$kind  = 'AoH';
		$total = scalar @$data;
		my $show = $n < $total ? $n : $total;

		if ($ucols) {
			@cols = @$ucols;
		} else {
			# BUG FIX: scan at least one row when data exists, so the header
			# still lists columns even when showing 0 rows (n => 0). PERF:
			# collect unique keys once, then sort once -- not sort-per-row.
			my $scan = $show > 0 ? $show : ($total > 0 ? 1 : 0);
			my %seen;
			for my $i (0 .. $scan - 1) {
				my $row = $data->[$i];
				next unless ref $row eq 'HASH';
				$seen{$_} = 1 for keys %$row;
			}
			@cols = sort keys %seen;
		}
		my $lc = defined $label_col ? $label_col
			   : (grep { $_ eq 'row_name' } @cols) ? 'row_name' : undef;
		if (defined $lc) {
			@cols = grep { $_ ne $lc } @cols;
			$lab_header = $lc;
		}
		for my $i (0 .. $show - 1) {
			my $row = $data->[$i];
			$row = {} unless ref $row eq 'HASH';
			push @labels, defined $lc ? $row->{$lc} : ($i + 1);
			push @raw, [ map { $row->{$_} } @cols ];
		}
		$lab_header = '' unless defined $lab_header;
	} elsif ($rt eq 'HASH') {
		my @keys = keys %$data;
		my $sample;
		for my $k (@keys) { $sample = $data->{$k}; last if defined $sample; }
		my $vt = ref $sample;

		if (!@keys) {                                       # ---- empty ----
			# BUG FIX: an empty hash used to die ("neither ARRAY nor HASH");
			# treat it as an empty table, mirroring an empty AoH.
			$kind = 'Hash';
			$total = 0;
			$lab_header = '';
		} elsif ($vt eq 'ARRAY') {                          # ---- HoA ----
			$kind = 'HoA';
			my @allcols = $ucols ? @$ucols : sort @keys;
			$total = 0;
			for my $k (@keys) {
				next unless ref $data->{$k} eq 'ARRAY';
				my $l = scalar @{ $data->{$k} };
				$total = $l if $l > $total;
			}
			my $show = $n < $total ? $n : $total;
			my $lc = defined $label_col ? $label_col
				   : (grep { $_ eq 'row_name' } @allcols) ? 'row_name' : undef;
			@cols = grep { !defined $lc || $_ ne $lc } @allcols;
			$lab_header = defined $lc ? $lc : '';
			for my $i (0 .. $show - 1) {
				push @labels, defined $lc
					? (ref $data->{$lc} eq 'ARRAY' ? $data->{$lc}[$i] : undef)
					: ($i + 1);
				push @raw, [ map {
					ref $data->{$_} eq 'ARRAY' ? $data->{$_}[$i] : undef
				} @cols ];
			}
		} elsif ($vt eq 'HASH') {                           # ---- HoH ----
			$kind = 'HoH';
			$total = scalar @keys;
			my @rk = sort @keys;
			my $show = $n < $total ? $n : $total;
			my @shown = $show > 0 ? @rk[0 .. $show - 1] : ();
			if ($ucols) {
				@cols = @$ucols;
			} else {
				# PERF: gather unique inner keys, sort once.
				my %seen;
				for my $rkk (@shown) {
					next unless ref $data->{$rkk} eq 'HASH';
					$seen{$_} = 1 for keys %{ $data->{$rkk} };
				}
				@cols = sort keys %seen;
			}
			@cols = grep { $_ ne $label_col } @cols if defined $label_col;
			# BUG FIX: honour the row_names alias here too (was 'row.names'
			# only, so row_names => 'x' showed a 'row_name' header).
			$lab_header = defined $label_col ? $label_col : 'row_name';
			for my $rkk (@shown) {
				push @labels, $rkk;
				my $inner = ref $data->{$rkk} eq 'HASH' ? $data->{$rkk} : {};
				push @raw, [ map { $inner->{$_} } @cols ];
			}
		} else {                                            # ---- flat hash ----
			# BUG/FEATURE: a hash whose values are plain scalars
			# ({ a => 1, b => 2, ... }) used to die ("neither ARRAY nor
			# HASH"). Render it like write_table's flat hash: one row, keys
			# as columns, a numeric '1' row label.
			$kind = 'Hash';
			$total = 1;
			my $show = $n < $total ? $n : $total;
			if ($ucols) {
				@cols = @$ucols;
			} else {
				@cols = sort @keys;
			}
			my $lc = defined $label_col ? $label_col
				   : (grep { $_ eq 'row_name' } @cols) ? 'row_name' : undef;
			if (defined $lc) {
				@cols = grep { $_ ne $lc } @cols;
				$lab_header = $lc;
			}
			$lab_header = '' unless defined $lab_header;
			for my $i (0 .. $show - 1) {
				push @labels, defined $lc ? $data->{$lc} : ($i + 1);
				push @raw, [ map { $data->{$_} } @cols ];
			}
		}
	}

	# numeric detection per column (drives right/left alignment)
	my @numeric = (1) x scalar @cols;
	for my $r (@raw) {
		for my $j (0 .. $#cols) {
			my $v = $r->[$j];
			next unless defined $v;
			$numeric[$j] = 0 unless looks_like_number($v);
		}
	}
	my $lab_numeric = @labels ? 1 : 0;
	for my $l (@labels) {
		$lab_numeric = 0, last unless defined $l && looks_like_number($l);
	}

	# stringify + sanitize + truncate cells (column names left intact)
	my $ell_len = length $ell;
	my $clean = sub {
		my $v = shift;
		return $na unless defined $v;
		$v = "$v";
		$v =~ s/\t/\\t/g; $v =~ s/\r/\\r/g; $v =~ s/\n/\\n/g;
		if ($maxw && length($v) > $maxw) {
			my $keep = $maxw - $ell_len;
			$keep = 0 if $keep < 0;
			$v = substr($v, 0, $keep) . $ell;
		}
		return $v;
	};
	my @lab_s  = map { $clean->($_) } @labels;
	my @rows_s = map { [ map { $clean->($_) } @$_ ] } @raw;
	my @head_s = @cols;

	# column widths
	my $lab_w = length $lab_header;
	for my $s (@lab_s) { my $l = length $s; $lab_w = $l if $l > $lab_w; }
	my @w = map { length $_ } @head_s;
	for my $r (@rows_s) {
		for my $j (0 .. $#cols) {
			my $l = length $r->[$j];
			$w[$j] = $l if $l > $w[$j];
		}
	}

	my $pad = sub {
		my ($s, $width, $right) = @_;
		my $g = $width - length $s; $g = 0 if $g < 0;
		return $right ? (' ' x $g) . $s : $s . (' ' x $g);
	};

	my @out;
	my $shown = scalar @rows_s;
	push @out, sprintf("# %s: %d row%s x %d col%s  (showing %d)",
		$kind, $total, ($total == 1 ? '' : 's'),
		scalar(@cols), (@cols == 1 ? '' : 's'), $shown);

	my @hcells = ( $pad->($lab_header, $lab_w, 0) );
	push @hcells, $pad->($head_s[$_], $w[$_], $numeric[$_]) for 0 .. $#cols;
	push @out, join($gap, @hcells);

	for my $ri (0 .. $#rows_s) {
		my @cells = ( $pad->($lab_s[$ri], $lab_w, $lab_numeric) );
		push @cells, $pad->($rows_s[$ri][$_], $w[$_], $numeric[$_]) for 0 .. $#cols;
		push @out, join($gap, @cells);
	}
	push @out, sprintf("# ... %d more row%s", $total - $shown,
		($total - $shown == 1 ? '' : 's')) if $shown < $total;

	my $str = join("\n", @out) . "\n";
	unless ($quiet) { defined $fh ? print {$fh} $str : print $str; }
	return $str;
}

1;
=encoding utf8

=head1 Synopsis

Get basic statistical functions working in Perl as if they were part of List::Util, like C<min>, C<max>, C<sum>, etc.
I've used Artificial Intelligence tools such as Claude, Gemini, and Grok to write this as well as using my own gray matter.
There are other similar tools on CPAN, but I want speed and a form like List::Util, which I've gotten here with the help of AI, which often required many attempts to do correctly.
This is meant to call subroutines directly through eXternal Subroutines (XS) for performance and portability.

There B<are> other modules on CPAN that can do B<PARTS> of this, but this works the way that I B<want> it to.

=head1 Functions/Subroutines

========================================================================

=head2 add_data

Add data to an existing hash or array reference. This function acts as the equivalent of adding new rows, as well as an C<ljoin> (described below). It dynamically infers your target data structure, handles deeply nested records, and seamlessly coerces mismatched data shapes to preserve the structural integrity of your primary reference.

=head3 Hash of Hashes (HoH)

When the target is a Hash of Hashes, incoming hash keys update existing rows, and new keys create new rows.

 $data = { 'Jack Smith' => { age => 30 } };
 
 $n = { 
     'Jack Smith' => {    # Update existing (Hash)
         dept => 'Engineering'
      },
     'Jane Doe'   => { age => 25, dept => 'Sales' }, # Add new (Hash)
     'Invalid'    => 'Not a reference'               # Edge case safety
 };
 
 add_data($data, $n); 

B<Resulting Structure:>

 {
     "Jack Smith":  {
         "age":  30,
         "dept": "Engineering"
     },
     "Jane Doe":    {
         "age":  25,
         "dept": "Sales"
     }
 }

=head3 Hash of Arrays (HoA)

When the target is a Hash of Arrays, incoming arrays are pushed onto the existing arrays, appending the new elements, similarly to R's C<rbind>.

 $data = { 'Project Alpha' => [ 'task1', 'task2' ] };
 $n = {
     'Project Alpha' => [ 'task3' ],         # Appends to existing array
     'Project Beta'  => [ 'task1', 'task2' ] # Creates new array row
 };
 add_data($data, $n);

B<Resulting Structure:>

 {
     "Project Alpha": [ "task1", "task2", "task3" ],
     "Project Beta":  [ "task1", "task2" ]
 }

=head3 Array of Hashes / Arrays (AoH / AoA)

C<add_data> now natively supports Array references at the root level. When targeting an Array, it iterates through the source array and merges data at the corresponding indices.

 $data = [ 
     { id => 1, name => 'Alice' } 
 ];
 
 $n = [ 
     { role => 'Admin' },             # Updates index 0
     { id => 2, name => 'Bob' }       # Creates index 1
 ];
 
 add_data($data, $n);

B<Resulting Structure:>

 [
     { "id": 1, "name": "Alice", "role": "Admin" },
     { "id": 2, "name": "Bob" }
 ]

=head3 Advanced Structural Coercion & Cross-Merging

C<add_data> strictly enforces the primary structure of your target reference (determined by inspecting its outer and inner bounds). If you mix Array and Hash types, the function automatically coerces the incoming data to match the target.

B<1. Inner Coercion (Mixing Rows):>

=over

=item * B<Target is HoH:> Source Array rows are read in pairs and converted to key-value pairs.

=item * B<Target is HoA:> Source Hash rows are flattened into key-value pairs and pushed onto the array.

=back

B<2. Root-Level Coercion (Mixing Outer Containers):>

=over

=item * B<Target is Array, Source is Hash:> The function evaluates the Hash keys as numeric indices. (e.g., source key C<"0"> merges into target array index C<[0]>). Non-numeric keys are safely ignored.

=item * B<Target is Hash, Source is Array:> The function converts the Array indices into stringified Hash keys. (e.g., source array index C<[1]> merges into target hash key C<"1">).

=back

=head3 Source is a mixed Hash. Keys dictate the target array index!

 $n = {
     '0' => { y => 20 },                 # Merges into $data->[0]
     '1' => [ 'z', 30 ],                 # Array pair coerced to Hash, creates $data->[1]
     'ignored' => { k => 'v' }           # Ignored: cannot map to an array index
 };
 
 add_data($data, $n);

B<Resulting Structure strictly remains an Array of Hashes:>

 [
     { "x": 10, "y": 20 },
     { "z": 30 }
 ]

NB: If C<add_data> is called on a completely empty target reference (e.g., C<$data = {}> or C<$data = []>), it will intelligently infer the required inner structure (Hashes vs Arrays) by inspecting the first valid row of the source data.

=head2 aoh2hoa

C<aoh2hoa($aoh)> — transpose an B<array-of-hashes> (row-major) into a B<hash-of-arrays> (column-major).

 my $hoa = aoh2hoa([ { a => 1, b => 2 }, { a => 3 } ]);
 # $hoa = { a => [1, 3], b => [2, undef] }

Rows go in, columns come out: each distinct key across the input rows becomes one output column, and the values are gathered down that column in row order.

=head3 Arguments

C<$aoh> — an array ref of hash refs, one hash per row. This is the only argument, and it is required. Passing anything that is not an array ref is fatal:

 aoh2hoa({ a => 1 });   # dies: argument must be an arrayref of hashrefs

=head3 Returns

A hash ref of array refs. Each key is a column name (the union of all keys seen across the rows); each value is an array ref holding that column's cells. Every column has exactly C<scalar @$aoh> elements, so the result is rectangular even when the input is ragged.

=head3 Behavior

The column set is the B<union> of every row's keys — a key that appears in only some rows still produces a full-length column, with C<undef> in the rows that lacked it.

Each column is padded to exactly the row count. Cells missing from a given row come through as C<undef>, including trailing gaps (a column whose last contributing row is early still runs the full length). These absent cells are cheap holes in the array, not stored SVs.

Values are B<copied> (C<newSVsv>), so the returned structure is independent of the input — mutating C<$aoh> afterward won't disturb the result. The copy is shallow: a value that is itself a reference is copied the same way C<< $col-E<gt>[$i] = $row-E<gt>{$k} >> would, i.e. the ref is duplicated but its referent is shared.

Keys are handled SV-first (C<hv_iterkeysv> / C<hv_fetch_ent>), so UTF-8 and otherwise non-trivial hash keys round-trip correctly.

A row that is B<not> a hash ref is skipped rather than fatal: it contributes C<undef> to every column at its index. So a stray C<undef> or scalar in the input thins the columns at that position instead of dying.

=head3 Notes

The output column order follows hash iteration order and is therefore not guaranteed — sort the keys if you need a stable layout. Round-tripping through C<hoa2aoh> (or the reverse) reconstructs the data but not necessarily the original key/row ordering, and rows originally absent a key will gain it as an explicit C<undef>.

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

=head3 Input Parameters



=begin html

<table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>data_sv</code></td>
  <td><code>HashRef</code> or <code>ArrayRef</code></td>
  <td><i>(Required)</i></td>
  <td>The dataset to analyze. Accepts a Hash of Arrays (HoA) or Array of Hashes (AoH). If no formula is provided, it must be an HoA to allow automatic stacking (mimicking R's <code>stack()</code> on a named list).</td>
  <td></td>
</tr>
<tr>
  <td><code>formula_sv</code></td>
  <td><code>String</code></td>
  <td><code>undef</code></td>
  <td>A symbolic description of the model to be fitted. If omitted, the formula automatically defaults to <code>'Value ~ Group'</code> and the input data is stacked.</td>
  <td><code>'yield ~ N * P'</code></td>
</tr>
</tbody>
</table>

=end html



=head3 Output Variables

The function returns a single C<HashRef> containing the evaluated statistical results. Because the keys map dynamically to the terms parsed from your formula, the structure will vary based on your inputs.



=begin html

<table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><i>(Term Name)</i></td>
  <td><code>HashRef</code></td>
  <td><code>undef</code></td>
  <td>A nested hash for each independent term in the formula (e.g., <code>'Group'</code>, <code>'N:P'</code>), containing its ANOVA table statistics.</td>
  <td><code>{'Df' => 1, 'Sum Sq' => 14.2, 'Mean Sq' => 14.2, 'F value' => 25.81, 'Pr(>F)' => 0.0004}</code></td>
</tr>
<tr>
  <td><code>Residuals</code></td>
  <td><code>HashRef</code></td>
  <td><code>undef</code></td>
  <td>A nested hash containing the residual (error) statistics for the fitted model.</td>
  <td><code>{'Df' => 10, 'Sum Sq' => 5.5, 'Mean Sq' => 0.55}</code></td>
</tr>
<tr>
  <td><code>group_stats</code></td>
  <td><code>HashRef</code></td>
  <td><code>undef</code></td>
  <td>A nested hash containing descriptive statistics (<code>mean</code> and <code>size</code> / count) for every column evaluated in the original unstacked data structure.</td>
  <td><code>{'mean' => {'A' => 2.1, 'B' => 5.4}, 'size' => {'A' => 10, 'B' => 10}}</code></td>
</tr>
</tbody>
</table>

=end html



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

=head2 cfilter

Select B<columns> out of a table and return it in the same shape. A column is
the inner (second-level) key of a B<hash of hashes> or an B<array of hashes>,
or the outer key of a B<hash of arrays>:

 use Stats::LikeR;
 my %hoa = ( x => [1,2,3], y => [4,5,6], z => [0,0,0] );
 cfilter(\%hoa, keep   => ['x','y']);  # { x => [1,2,3], y => [4,5,6] }
 cfilter(\%hoa, remove => ['z']);      # { x => [1,2,3], y => [4,5,6] }

C<cfilter> takes exactly one of C<keep> or C<remove>. C<keep> returns only the
matching columns; C<remove> returns everything except them. The result is the
same shape as the input (HoH → HoH, HoA → HoA, AoH → AoH), with cell values
copied and the original structure left untouched.

=head3 Selecting by name

Pass an array ref of column names. Naming a column that is not present in the
data is an error (it catches typos), and a row that happens not to contain a
kept column simply comes back without it:

 my @aoh = ( { a => 1, b => 2 }, { a => 3 } );
 cfilter(\@aoh, keep => ['b']);   # [ { b => 2 }, {} ]

=head3 Selecting by a predicate

Instead of names, C<keep>/C<remove> accept a B<predicate> — a CODE ref or a
function name — evaluated once per column. It is called as

 $predicate->($column_values, $column_name)

where C<$column_values> is an array ref of the column's B<defined> cells (undef
and missing cells are dropped, so functions like C<sd> get clean input).
With C<keep>, columns for which the predicate is true are kept; with C<remove>,
those columns are dropped.

 # Keep only the constant columns (standard deviation zero):
 my $const = cfilter(\%hoa, keep => sub { sd($_[0]) == 0 });   # { z => [0,0,0] }
 # Drop the constant columns instead:
 my $varying = cfilter(\%hoa, remove => sub { sd($_[0]) == 0 }); # { x=>..., y=>... }
 # A bare function name resolves in Stats::LikeR:: (use a package for your own):
 cfilter(\%hoa, keep => 'some_predicate');

A bare string is always treated as a B<function name>, not a single column
name, so to keep one column by name use an array ref: C<< keep =E<gt> ['x'] >>.

=head3 Errors

C<cfilter> dies (via C<croak>) when:

=over

=item * neither C<keep> nor C<remove> is given, or both are,

=item * a named column is not present in the data,

=item * the selector is neither an array ref nor a code ref / function name, or the
function name cannot be resolved,

=item * an unknown option is given, or the options are not C<< name =E<gt> value >> pairs,

=item * the data is not a hash/array reference of the expected shape (a hash of hash
refs or array refs, or an array of hash refs).

=back

=head2 chisq_test

The C<chisq_test> function performs chi-squared contingency table tests and goodness-of-fit tests. It natively accepts both arrays and hashes (1D and 2D) and mathematically mirrors R's C<chisq.test()>, returning a structured hash reference of the results.

For 2x2 matrices, Yates' Continuity Correction is applied automatically.

=head3 Accepted Inputs



=begin html

<table>
<thead>
<tr>
  <th>Input Type</th>
  <th>Data Structure</th>
  <th>Applied Test</th>
</tr>
</thead>
<tbody>
<tr>
  <td><b>1D Array</b></td>
  <td><code>[ $v1, $v2, ... ]</code></td>
  <td>Chi-squared test for given probabilities</td>
</tr>
<tr>
  <td><b>2D Array</b></td>
  <td><code>[ [ $v1, $v2 ], [ $v3, $v4 ] ]</code></td>
  <td>Pearson's Chi-squared test (Yates' correction if 2x2)</td>
</tr>
<tr>
  <td><b>1D Hash</b></td>
  <td><code>{ key1 => $v1, key2 => $v2 }</code></td>
  <td>Chi-squared test for given probabilities</td>
</tr>
<tr>
  <td><b>2D Hash</b></td>
  <td><code>{ row1 => { c1 => $v1, c2 => $v2 } }</code></td>
  <td>Pearson's Chi-squared test (Yates' correction if 2x2)</td>
</tr>
</tbody>
</table>

=end html



=head3 Output Object Structure

The function returns a single Hash Reference containing the following key-value pairs. The internal structure of C<expected> and C<observed> will always identically match the structure of your input.



=begin html

<table>
<thead>
<tr>
  <th>Key</th>
  <th>Data Type</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><b>data.name</b></td>
  <td>String</td>
  <td>Identifies the input type (e.g., <code>"Perl ArrayRef"</code> or <code>"Perl HashRef"</code>).</td>
</tr>
<tr>
  <td><b>expected</b></td>
  <td>Array/Hash Ref</td>
  <td>The expected frequencies, matching the geometry of the input.</td>
</tr>
<tr>
  <td><b>method</b></td>
  <td>String</td>
  <td>The specific statistical test applied.</td>
</tr>
<tr>
  <td><b>observed</b></td>
  <td>Array/Hash Ref</td>
  <td>The original data passed to the function.</td>
</tr>
<tr>
  <td><b>p.value</b></td>
  <td>Float</td>
  <td>The calculated p-value of the test.</td>
</tr>
<tr>
  <td><b>parameter</b></td>
  <td>Hash Ref</td>
  <td>Contains the degrees of freedom (<code>df</code>).</td>
</tr>
<tr>
  <td><b>statistic</b></td>
  <td>Hash Ref</td>
  <td>Contains the test statistic (<code>X-squared</code>).</td>
</tr>
</tbody>
</table>

=end html



=head3 Two-Dimensional Array

Passing an Array of Arrays (AoA) triggers a standard Pearson's Chi-squared test. If the input is exactly a 2x2 matrix, Yates' continuity correction is applied automatically.

 my $test_data = [
     [762, 327, 468], 
     [484, 239, 477]
 ];
 my $res = chisq_test($test_data);

B<Output:>

 {
     'data.name' => 'Perl ArrayRef',
     'expected'  => [
         [ 703.671381936888, 319.645266594124, 533.683351468988 ],
         [ 542.328618063112, 246.354733405876, 411.316648531012 ]
     ],
     'method'    => "Pearson's Chi-squared test",
     'observed'  => [
         [ 762, 327, 468 ],
         [ 484, 239, 477 ]
     ],
     'p.value'   => 2.95358918321176e-07,
     'parameter' => { 'df' => 2 },
     'statistic' => { 'X-squared' => 30.0701490957547 }
 }

=head3 1-Dimensional Array (Goodness of Fit)

Passing a flat Array Reference triggers a Goodness of Fit test, assuming equal expected probabilities across all items.

 my $data = [10, 20, 30];
 my $res = chisq_test($data);

B<Output:>

 {
     'data.name' => 'Perl ArrayRef',
     'expected'  => [ 20, 20, 20 ],
     'method'    => 'Chi-squared test for given probabilities',
     'observed'  => [ 10, 20, 30 ],
     'p.value'   => 0.00673794699908547,
     'parameter' => { 'df' => 2 },
     'statistic' => { 'X-squared' => 10 }
 }

=head3 2-Dimensional Hash (Pearson's Chi-squared)

Passing a Hash of Hashes (HoH) applies the exact same logic as a 2D Array, but preserves your nested string keys in the output. This is particularly useful when mapping data extracted directly from JSON, databases, or categorical mappings.

 my $data = {
     GroupA => { Success => 10, Failure => 15 },
     GroupB => { Success => 20, Failure => 5  }
 };
 
 my $res = chisq_test($data);

B<Output:>

 {
     'data.name' => 'Perl HashRef',
     'expected'  => {
     'GroupA' => { 'Failure' => 10, 'Success' => 15 },
     'GroupB' => { 'Failure' => 10, 'Success' => 15 }
 },
 'method'    => "Pearson's Chi-squared test with Yates' continuity correction",
     'observed'  => {
     'GroupA' => { 'Failure' => 15, 'Success' => 10 },
     'GroupB' => { 'Failure' => 5,  'Success' => 20 }
     },
     'p.value'   => 0.00937475878430379,
     'parameter' => { 'df' => 1 },
     'statistic' => { 'X-squared' => 6.75 }
 }

=head3 One-Dimensional Hash (Goodness of Fit)

Flat Hash References evaluate Goodness of Fit while preserving your categorical keys in the C<expected> and C<observed> output blocks.

 my $data = { 
     Apples  => 10, 
     Oranges => 20, 
     Bananas => 30 
 };
 
 my $res = chisq_test($data);

=head2 C<col2col>

Apply a B<two-column function> to every pair of columns in a table and collect
the answers in a hash of hashes.

It's the workhorse behind things like correlation matrices: give it your data and
the name of a function that takes two columns (C<cor>, C<t_test>, …) and you get
back every column compared against every other column.

 use Stats::LikeR;
 
 my %data = (
     height => [ 170, 165, 180, 175 ],
     weight => [  70,  60,  85,  77 ],
     age    => [  30,  41,  25,  38 ],
 );
 
 my $result = col2col(\%data, 'cor');
 
 # $result->{height}{weight}  == correlation of height vs weight
 # $result->{height}{age}     == correlation of height vs age
 # ...and so on for every pair

========================================================================

=head3 Arguments

 col2col( $data, $command, $cols, %options )
 col2col( $data, $command, \%options )      # options in place of $cols



=begin html

<table>
<thead>
<tr>
  <th>Position</th>
  <th>Argument</th>
  <th>What it is</th>
</tr>
</thead>
<tbody>
<tr>
  <td>1</td>
  <td><code>$data</code></td>
  <td>Your table, as a reference (see <b>Data shapes</b> below).</td>
</tr>
<tr>
  <td>2</td>
  <td><code>$command</code></td>
  <td>A code block <b>or</b> the name of a two-column function.</td>
</tr>
<tr>
  <td>3</td>
  <td><code>$cols</code></td>
  <td><i>(optional)</i> Which columns to use as the "from" side. Omit for all.</td>
</tr>
<tr>
  <td>4+</td>
  <td><code>%options</code></td>
  <td><i>(optional)</i> <code>na</code>, <code>skip.errors</code>, … (see <b>Options</b>).</td>
</tr>
</tbody>
</table>

=end html



========================================================================

=head3 Data shapes

C<col2col> understands three layouts. In every case a B<column> is the thing that
gets compared, and the result is keyed by column name.

B<Hash of arrays (HoA)> — keys are column names:

 my %hoa = ( a => [1, 2, 3], b => [4, 5, 6] );

B<Hash of hashes (HoH)> — First keys are row names, second keys are columns:

 my %hoh = (
     row1 => { a => 1, b => 4 },
     row2 => { a => 2, b => 5 },
 );

B<Array of hashes (AoH)> — each element is a row, inner keys are columns:

 my @aoh = ( { a => 1, b => 4 }, { a => 2, b => 5 } );

All three produce the same result for the same underlying numbers. Missing or
C<undef> cells are handled by the C<na> option (below).

========================================================================

=head3 The command

The second argument is the function applied to each pair of columns. It is called
as:

 $command->( $column_a, $column_b )    # two ARRAY refs

so inside a block the two columns arrive in C<@_>:

 my $result = col2col(\%data, sub {
     my ($x, $y) = @_;       # $x and $y are array refs
     cor($x, $y);
 });

You can also pass a B<function name as a string>. A bare name is looked up in
C<Stats::LikeR::>, so these two are equivalent:

 col2col(\%data, 'cor');
 col2col(\%data, sub { cor($_[0], $_[1]) });

========================================================================

=head3 The result

Always a hash of hashes: B<< C<< $result-E<gt>{from}{to} >> >>.

 for my $from (sort keys %$result) {
    for my $to (sort keys %{ $result->{$from} }) {
       printf "%s vs %s = %s\n", $from, $to, $result->{$from}{$to};
    }
 }

A column is never compared with itself, so C<< $result-E<gt>{a}{a} >> does not exist.

========================================================================

=head3 Restricting columns (C<$cols>)

By default every column is used as the "from" side. The third argument narrows
that down — handy when you only care about one variable.

 # all columns vs all columns
 my $all = col2col(\%data, 'cor');
 # just ONE column vs every other column
 my $one = col2col(\%data, 'cor', 'height');
 my $cors = $one->{height};          # { weight => ..., age => ... }
 # a FEW specific columns vs every other column
 my $few = col2col(\%data, 'cor', ['height', 'weight']);

The "to" side is always every other column; C<$cols> only limits the outer keys.

========================================================================

=head3 Options

Options can be given two ways:

 col2col(\%data, 'cor', $cols, 'skip.errors' => 0);   # after $cols
 col2col(\%data, 'cor', { 'skip.errors' => 0 });      # hash ref, no $cols needed

The hash-ref form is convenient when you have B<no> column restriction — it saves
you from passing a placeholder. (A hash ref I<replaces> C<$cols>, so you can't use
it to restrict columns at the same time; use the trailing form for that.)

=head4 C<na> — how undefined values are handled

Real data has gaps. C<na> decides what the function sees.



=begin html

<table>
<thead>
<tr>
  <th>Value</th>
  <th>Behaviour</th>
  <th>Use for</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>'pairwise'</code> <i>(default)</i></td>
  <td>A row is used for a pair only if <b>both</b> columns are defined there. The two columns arrive aligned and equal-length.</td>
  <td>Paired stats like <code>cor</code>.</td>
</tr>
<tr>
  <td><code>'omit'</code></td>
  <td>Each column drops <b>its own</b> undefined values independently. The two columns may end up <b>different lengths</b>.</td>
  <td>Unpaired tests like <code>t_test</code>, <code>kruskal_test</code>, where a gap in one sample shouldn't discard a value in the other.</td>
</tr>
<tr>
  <td><code>'keep'</code></td>
  <td>Every row is passed through, <code>undef</code> and all.</td>
  <td>When your function does its own missing-data handling.</td>
</tr>
</tbody>
</table>

=end html



 # correlation: keep only complete pairs (the default)
 col2col(\%data, 'cor');
 # two-sample test: each column keeps its own values
 col2col(\%data, 't_test', undef, na => 'omit');
 col2col(\%data, 't_test', { na => 'omit' });        # same, no placeholder

C<rm.undef> / C<rm.na> remain as boolean aliases for backward compatibility:
C<true> means C<'pairwise'>, C<false> means C<'keep'>. Don't combine them with C<na>.

=head4 C<skip.errors> — keep going when a pair fails I<(default: true)>

Some functions croak on degenerate input — for example C<cor> dies if a column has
zero variance. By default C<col2col> B<traps> that croak per pair: instead of
aborting the whole run, it stores the B<first line> of the error message in that
cell, so the result tells you I<which> pair failed and I<why>. Every other cell is
computed normally.

 my $r = col2col(\%data, 'cor');
 # a good pair:   $r->{a}{b} == 0.83
 # a bad pair:    $r->{a}{const} eq 'cor: standard deviation of y is 0'

To restore the old "die on the first error" behaviour, turn it off:

 col2col(\%data, 'cor', undef, 'skip.errors' => 0);
 col2col(\%data, 'cor', { 'skip.errors' => 0 });

Only errors from B<your function> are trapped. Mistakes in the call itself
(unknown column, bad data, unknown function name, unknown option) always die.

========================================================================

=head3 Worked examples

B<Full correlation matrix:>

 my $m = col2col(\%data, 'cor');

B<One variable against all others, sorted strongest first, skipping failures:>

 my $col  = 'Testosterone, total (nmol/L)';
 my $cors = col2col($hoa, 'cor', $col)->{$col};
 for my $other (sort { ($cors->{$b} // -2) <=> ($cors->{$a} // -2) } keys %$cors) {
     next unless $cors->{$other} =~ /^-?\d/;        # skip cells holding an error message
     printf "%-30s % .3f\n", $other, $cors->{$other};
 }

B<Two-sample test across columns of unequal completeness:>

 my $t = col2col($hoa, 't_test', undef, na => 'omit');

B<Find which pairs could not be computed:>

 my $m = col2col($hoa, 'cor');
 for my $from (sort keys %$m) {
     for my $to (sort keys %{ $m->{$from} }) {
         my $v = $m->{$from}{$to};
         warn "$from vs $to: $v\n" if defined $v && $v !~ /^-?\d/;   # non-numeric = error
     }
 }

========================================================================

=head3 Gotchas

=over

=item * B<Your function receives two array refs>, C<($col_a, $col_b)> — not a column and
a name. Unpack with C<my ($x, $y) = @_;>.

=item * B<< C<'pairwise'> can still hit a constant I<subset>. >> A column with overall
variance can be flat on just the rows it shares with one partner, so C<cor> may
still croak for that pair. With the default C<skip.errors>, that shows up as a
message in the single offending cell rather than killing the run.

=item * B<< C<col2col> does not modify your data. >> It reads the table and returns a new
hash of hashes.

=item * B<In the error message, "x" is the first column and "y" is the second> — i.e.
C<y> is the inner ("to") key. So C<< $result-E<gt>{A}{B} >> reading C<…deviation of y is 0>
means column C<B> is the degenerate one for that pair.

=back

=head2 cor

 cor($array1, $array2, $method = 'pearson'),

that is, C<pearson> is the default and will be used if C<$method> is not specified.

Just like R, C<pearson>, C<spearman>, and C<kendall> are available

If you provide an array of arrays (a matrix), C<cor> will compute the correlation matrix automatically. 

=head2 cor_test

 my $result = cor_test(
         'x'         => $x,
         'y'         => $y,
         alternative => 'two.sided',
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

=head2 csort

Sort a table by a column or by a custom comparator. Works on both common Perl table shapes and can transpose between them on the way out. Stable, non-destructive.

=head3 Signature

 my $sorted = csort($data, $by);
 my $sorted = csort($data, $by, $output);

=over

=item * B<< C<$data> >> — your table, in either shape:
=over

=item * B<AoH> — arrayref of hashrefs (a list of rows): C<< [ {id=E<gt>1, v=E<gt>10}, {id=E<gt>2, v=E<gt>20} ] >>

=item * B<HoA> — hashref of arrayrefs (parallel columns): C<< { id=E<gt>[1,2], v=E<gt>[10,20] } >>

=back

=item * B<< C<$by> >> — I<how> to sort:
=over

=item * a B<column name> (string), or

=item * a B<comparator> coderef using C<$a> / C<$b>, just like Perl's C<sort>

=back

=item * B<< C<$output> >> I<(optional)> — C<'aoh'> or C<'hoa'> (case-insensitive). Defaults to the input shape; C<undef> also means "same as input".

=back

Returns a B<new> structure. The input is never modified.

=head3 What it does

=over

=item * B<Column-name sort> — numeric if every defined value in that column looks like a number, otherwise string comparison. Missing / C<undef> values sort B<last> (matching R's C<na.last>).

=item * B<Comparator sort> — C<$a> and C<$b> are set in the comparator's I<own> package, so a named sub from another package still sees its own C<$a>/C<$b>. For AoH they're the row hashrefs; for HoA they're per-row hashref views synthesized from the columns.

=item * B<Stable> — equal keys keep their original order (merge sort, same as Perl C<sort> and R C<order()>).

=item * B<Shape control> — keep the input shape, or transpose: AoH→HoA builds the union of all row keys (ordered by first appearance, gaps filled with C<undef>); HoA→AoH emits one hashref per row.

=back

=head3 Examples

 # by column, ascending numeric, AoH in / AoH out
 my $rows = csort($aoh, 'score');
 
 # custom comparator (descending), HoA in / HoA out
 my $cols = csort($hoa, sub { $b->{score} <=> $a->{score} });
 
 # sort an AoH but hand it back as columns (HoA)
 my $cols = csort($aoh, 'name', 'hoa');

=head3 Notes

=over

=item * B<Non-destructive:> AoH output reuses the original row hashrefs (re-ordered); HoA output permutes every column in lockstep.

=item * Empty and single-row tables are handled for all four in/out combinations.

=item * An invalid C<$output> value croaks.

=back

=head2 dnorm

gives the density of the normal distribution, with the specified mean and standard deviation.

In other words, the predicted height of the value C<x>, given a mean, standard deviation, and whether or not to use a log value.

returns a single scalar/number if a single value is given, otherwise returns an array reference.

Usage:

 dnorm(4) # assumes a mean of 0 and standard deviation of 1

but default mean, standard deviation, and log can be passed as parameters:

 $x = dnorm(0, mean => 0, sd => 2, 'log' => 0);

=head2 filter

Return a new data frame containing only the rows of C<$df> that match a predicate. The original C<$df> is never modified.

 my $df2 = filter($df, col('column.name') > 4);

C<filter> accepts a predicate in one of two forms:

=over

=item 1. a B<< C<col()> expression >> — a small, composable comparison built with overloaded operators, and

=item 2. a B<code reference> — for anything the operators can't express (multiple columns, regexes, arbitrary logic), in the same spirit as the C<filter> option of L<#>.

=back

Both C<filter> and C<col> are exported by default.

=head3 Arguments



=begin html

<table>
<thead>
<tr>
  <th>Position</th>
  <th>Name</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td>1</td>
  <td><code>$df</code></td>
  <td>The data frame to filter. Either an <b>array of hashes</b> (AoH — e.g. the default output of <code>read_table</code>) or a <b>hash of arrays</b> (HoA).</td>
</tr>
<tr>
  <td>2</td>
  <td>predicate</td>
  <td>Either a <code>col()</code> comparison object or a <code>CODE</code> reference.</td>
</tr>
</tbody>
</table>

=end html



The return value is a B<new> data frame of the B<same shape> as the input (AoH in → AoH out, HoA in → HoA out). For an HoA, every column is filtered in parallel by row index, so all returned columns stay the same length and aligned.

=head3 The C<col()> form

C<col('name')> is a deferred reference to a column. It carries no data — only the column name — so it can be compared with a literal (or another value) to build a predicate that C<filter> evaluates once per row.

 filter($df, col('age') >= 18);  # keep rows where age >= 18
 filter($df, col('sex') eq 'f'); # keep rows where sex is 'f'
 filter($df, 18 <= col('age'));  # operands may be in either order

=head3 Comparison operators



=begin html

<table>
<thead>
<tr>
  <th>Kind</th>
  <th>Operators</th>
  <th>Comparison</th>
</tr>
</thead>
<tbody>
<tr>
  <td>Numeric</td>
  <td><code>></code> <code><</code> <code>>=</code> <code><=</code> <code>==</code> <code>!=</code></td>
  <td>numeric (the cell and the value are compared as numbers)</td>
</tr>
<tr>
  <td>String</td>
  <td><code>gt</code> <code>lt</code> <code>ge</code> <code>le</code> <code>eq</code> <code>ne</code></td>
  <td>string (the cell and the value are compared as strings)</td>
</tr>
</tbody>
</table>

=end html



C<col('x')> may appear on either side of the operator; C<< 4 E<lt> col('x') >> is automatically rewritten to the equivalent C<< col('x') E<gt> 4 >>.

=head3 Combining predicates: C<&>, C<|>, C<!>

Predicates compose with bitwise C<&> (and), C<|> (or), and C<!> (not):

 filter($df, (col('age') > 18) & (col('sex') eq 'f'));   # and
 filter($df, (col('grp') eq 'a') | (col('grp') eq 'c')); # or
 filter($df, !(col('x') > 100));                         # not

Comparison operators bind more tightly than C<&> and C<|>, so C<< (col('a') E<gt> 4) & (col('b') E<lt> 2) >> is parsed correctly, but the parentheses are recommended for readability.

=head3 The code-reference form

For logic the operators can't express, pass a C<sub>. It is called once per row; the B<row is a hash reference>, available both as C<$_> and as the first argument C<$_[0]>. Return a true value to keep the row.

 filter($df, sub { $_->{x} > 4 && $_->{grp} eq 'a' });
 filter($df, sub { $_->{name} =~ /^A/ });
 filter($df, sub { $_[0]{score} > $_[0]{threshold} });

For an HoA, each row is assembled into a temporary hash reference (C<< { column =E<gt> value, ... } >>) before the sub is called, so the same C<< $_-E<gt>{column} >> syntax works regardless of the input shape.

=head3 Examples

 use Stats::LikeR;
 my $df = read_table('patients.csv');                 # array of hashes
 # numeric threshold
 my $adults = filter($df, col('Age') >= 18);
 # combine conditions
 my $target = filter($df, (col('Age') >= 18) & (col('Sex') eq 'f'));
 # arbitrary logic with a coderef
 my $flagged = filter($df, sub { $_->{ALT} > 40 || $_->{AST} > 40 });
 # hash-of-arrays input -> hash-of-arrays output, columns filtered in parallel
 my $hoa = read_table('patients.csv', 'output.type' => 'hoa');
 my $sub = filter($hoa, col('Age') > 32);
 # $sub->{Age}, $sub->{Sex}, ... are all the same length and row-aligned

=head3 Behavior and notes

=over

=item * B<The input is never modified.> C<filter> builds and returns a new frame; C<$df> is left untouched.

=item * B<< A missing or C<undef> cell never matches >> a C<col()> comparison. For example C<< col('x') E<gt> 0 >> silently drops any row that has no C<x> value or whose C<x> is C<undef>.

=item * B<AoH rows are shared, not deep-copied>, into the returned frame: the returned array references the I<same> row hashes as the input (fast, low-memory). Mutating a row in the result would therefore also change it in the original. HoA values are copied into fresh arrays.

=item * B<Keep-all / keep-none> are well defined: a predicate true for every row returns a copy-shaped frame with all rows; a predicate true for none returns an empty frame (C<[]> for AoH, a hash of empty arrays for HoA).

=item * B<Supported shapes are AoH and HoA.> Passing a non-reference, an array element that is not a hash reference, or an HoA column that is not an array reference raises a descriptive error.

=item * B<Perl 5.10 compatible.> The C<col()>/operator layer is pure Perl (operator overloading); the per-row evaluation is done in XS.

=back

=head3 See also

C<read_table> (whose C<filter> option applies the same coderef convention while reading a file), C<col2col>.

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
     [0] 2.75343836564204,
     [1] 300.682787419401
 ],
 conf_level    0.95,
 estimate      {
     "odds ratio"   21.3053312750168
 },
 method        "Fisher's Exact Test for Count Data",
 p_value       0.000536724119143435
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

In addition to the C<gaussian> default, it fully supports logistic regression using the C<binomial> family parameter via Iteratively Reweighted Least Squares (IRLS):

 my $glm_bin = glm(formula => 'am ~ wt + hp', data => \%mtcars, family => 'binomial');

=head3 Input Parameters



=begin html

<table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>formula</code></td>
  <td><code>String</code></td>
  <td><i>None (Required)</i></td>
  <td>A symbolic description of the model to be fitted. Supports operators like <code>+</code>, <code>:</code>, <code>*</code>, <code>^</code>, and <code>-1</code> (to remove the intercept).</td>
  <td><code>'am ~ wt + hp'</code>, <code>'y ~ x - 1'</code></td>
</tr>
<tr>
  <td><code>data</code></td>
  <td><code>HashRef</code> or <code>ArrayRef</code></td>
  <td><i>None (Required)</i></td>
  <td>The dataset containing the variables used in the formula. Accepts either a Hash of Arrays (HoA) or an Array of Hashes (AoH).</td>
  <td><code>\%mtcars</code>, <code>[{x => 1, y => 2}, ...]</code></td>
</tr>
<tr>
  <td><code>family</code></td>
  <td><code>String</code></td>
  <td><code>'gaussian'</code></td>
  <td>A description of the error distribution and link function to be used in the model. Currently supports <code>'gaussian'</code> (identity link) and <code>'binomial'</code> (logit link).</td>
  <td><code>'binomial'</code></td>
</tr>
</tbody>
</table>

=end html



=head3 Output variables



=begin html

<table>
<thead>
<tr>
  <th>Variable</th>
  <th>Type</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>aic</code></td>
  <td><code>Double</code></td>
  <td>Akaike's Information Criterion for the fitted model.</td>
  <td><code>123.45</code></td>
</tr>
<tr>
  <td><code>boundary</code></td>
  <td><code>Integer (Boolean)</code></td>
  <td><code>1</code> if the fitted values computationally reached the <code>0</code> or <code>1</code> boundary (specific to the binomial family), <code>0</code> otherwise.</td>
  <td><code>0</code></td>
</tr>
<tr>
  <td><code>coefficients</code></td>
  <td><code>HashRef</code></td>
  <td>A hash mapping the expanded model term names to their estimated coefficient values.</td>
  <td><code>{'Intercept' => 1.5, 'wt' => -0.5}</code></td>
</tr>
<tr>
  <td><code>converged</code></td>
  <td><code>Integer (Boolean)</code></td>
  <td><code>1</code> if the Iteratively Reweighted Least Squares (IRLS) algorithm converged within the maximum iterations, <code>0</code> otherwise.</td>
  <td><code>1</code></td>
</tr>
<tr>
  <td><code>deviance</code></td>
  <td><code>Double</code></td>
  <td>The residual deviance of the fitted model.</td>
  <td><code>15.2</code></td>
</tr>
<tr>
  <td><code>deviance.resid</code></td>
  <td><code>HashRef</code></td>
  <td>A hash mapping data row names to their computed deviance residuals.</td>
  <td><code>{'Mazda RX4' => 0.12}</code></td>
</tr>
<tr>
  <td><code>df.null</code></td>
  <td><code>Integer</code></td>
  <td>The residual degrees of freedom for the null model.</td>
  <td><code>31</code></td>
</tr>
<tr>
  <td><code>df.residual</code></td>
  <td><code>Integer</code></td>
  <td>The residual degrees of freedom for the fitted model.</td>
  <td><code>30</code></td>
</tr>
<tr>
  <td><code>family</code></td>
  <td><code>String</code></td>
  <td>The statistical family used to fit the model.</td>
  <td><code>"gaussian"</code></td>
</tr>
<tr>
  <td><code>fitted.values</code></td>
  <td><code>HashRef</code></td>
  <td>A hash mapping data row names to the fitted mean values (the model's predictions on the scale of the response).</td>
  <td><code>{'Mazda RX4' => 0.85}</code></td>
</tr>
<tr>
  <td><code>iter</code></td>
  <td><code>Integer</code></td>
  <td>The number of IRLS iterations performed before convergence or hitting the iteration limit.</td>
  <td><code>4</code></td>
</tr>
<tr>
  <td><code>null.deviance</code></td>
  <td><code>Double</code></td>
  <td>The deviance for the null model (a baseline model containing only an intercept, or an offset of 0 if the intercept is removed).</td>
  <td><code>43.5</code></td>
</tr>
<tr>
  <td><code>rank</code></td>
  <td><code>Integer</code></td>
  <td>The numeric rank of the fitted linear model (the number of estimated, non-aliased parameters).</td>
  <td><code>2</code></td>
</tr>
<tr>
  <td><code>summary</code></td>
  <td><code>HashRef</code></td>
  <td>A nested hash mapping each term to its detailed summary statistics, including <code>Estimate</code>, <code>Std. Error</code>, <code>t value</code> / <code>z value</code>, and <code>Pr(> t )</code> / <code>Pr(> z )</code>. Aliased parameters return <code>"NaN"</code>.</td>
  <td><code>{'wt' => {'Estimate' => -0.5, 'Std. Error' => 0.1, ...}}</code></td>
</tr>
<tr>
  <td><code>terms</code></td>
  <td><code>ArrayRef</code></td>
  <td>An ordered list of the expanded term names included in the model matrix.</td>
  <td><code>['Intercept', 'wt', 'hp']</code></td>
</tr>
</tbody>
</table>

=end html



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

all become hash of arrays:

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
     { 'Race/Hispanic origin w/ NH Asian' => sub { $_ eq $n } },# filter
     { 'Testosterone, total (nmol/L)' => sub { $_ ne 'NA' } } # filter
 );

where each filter filters on the columns, e.g. second hash keys.

=head2 hoh2hoa

Convert a B<hash of hashes> (row-major: outer key = row, inner key = column)
into a B<hash of arrays> (column-major: key = column, value = that column's
cells down the rows).

 use Stats::LikeR;
 
 my %hoh = (
     'r1' => { 'a' => 1, 'b' => 2 },
     'r2' => { 'a' => 3, 'b' => 4 },
 );
 
 my $hoa = hoh2hoa(\%hoh);

which returns
    {
      a => [1, 3],
      b => [2, 4],
    }

=head3 Behavior

=over

=item * B<Columns> are the union of every inner key, so a key that appears in only
some rows still becomes a column.

=item * B<Rows> are emitted in sorted outer-key (row-name) order, and that one order
is used for every column, so the arrays stay aligned and the result is
reproducible regardless of hash ordering.

=item * B<Gaps> — a missing inner key, or a cell whose value is C<undef> — are filled
with the fill value (see C<undef.val> below). Every column therefore has
exactly one entry per row.

=item * Values are B<copied> into the result; the original structure is left
untouched.

=item * An B<empty> hash of hashes returns an empty hash of arrays (it is not an
error).

=back

=head3 Options

Options are passed as trailing C<< name =E<gt> value >> pairs.



=begin html

<table>
<thead>
<tr>
  <th>Option</th>
  <th>Default</th>
  <th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>undef.val</code></td>
  <td><code>undef</code></td>
  <td>Value used to fill a missing key or an <code>undef</code> cell. Any defined scalar works, including <code>0</code> and <code>''</code>. Passing <code>undef</code> keeps the default.</td>
</tr>
<tr>
  <td><code>row.names</code></td>
  <td><i>(none)</i></td>
  <td>If set to a string, an extra column of that name is added holding the sorted row labels, aligned with the data. Dies if the name collides with an existing column.</td>
</tr>
</tbody>
</table>

=end html



 # Ragged input with an explicit fill string:
 my %ragged = (
     'r1' => { 'a' => 1, 'b' => 2 },
     'r2' => { 'a' => 3, 'c' => 9 },
 );
 my $hoa = hoh2hoa(\%ragged, 'undef.val' => 'NA');
 # {
 #   a => [1,    3   ],
 #   b => [2,    'NA'],
 #   c => ['NA', 9   ],
 # }
 
 # Keep the row labels as a column:
 my $with_ids = hoh2hoa(\%ragged, 'row.names' => 'id');
 # {
 #   id => ['r1', 'r2'],
 #   a  => [1,    3   ],
 #   b  => [2,    undef],
 #   c  => [undef, 9  ],
 # }

=head3 Errors

C<hoh2hoa> dies (via C<croak>) when:

=over

=item * the argument is not a hash reference,

=item * any value in the hash is not itself a hash reference,

=item * an unknown option is given, or the options are not C<< name =E<gt> value >> pairs,

=item * C<row.names> is not a plain string, or it names an already-present column.

=back

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
 $kt = kruskal_test(\%x);

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
 my $kt = kruskal_test(\@x, \@g);

=head2 ks_test

The Kolmogorov–Smirnov test checks whether two samples are drawn from the
same distribution (two-sample), or whether a single sample is drawn from a
given reference distribution (one-sample). It works by comparing the empirical
cumulative distribution functions (ECDFs) and measuring the largest gap
between them.

Two-sample form — pass two array references:

 $ks = ks_test(\@x, \@y);
 $ks = ks_test(\@x, \@y, alternative => 'greater');

One-sample form — pass one array reference and the name of a reference CDF.
Currently only C<'pnorm'> is supported, i.e. the standard normal distribution
(mean 0, standard deviation 1):

 $ks = ks_test(\@x, 'pnorm');

Arguments may be given positionally (as above) or by name:

 $ks = ks_test(x => \@x, y => \@y, alternative => 'less', exact => 1);

Non-numeric and undefined elements are silently dropped before the test runs.

C<alternative> selects which gap between the ECDFs is measured:

=over

=item * C<'two.sided'> (default) — the largest gap in either direction,
D = sup |F_x − F_y|.

=item * C<'greater'> — the largest gap where x's ECDF rises above the other,
D⁺ = sup (F_x − F_y).

=item * C<'less'> — the largest gap in the other direction, D⁻ = sup (F_y − F_x).

=back

These follow R's C<ks.test> convention: C<'greater'>/C<'less'> describe which CDF
lies I<above> the other, which (because a higher CDF means smaller values) is
the opposite of which sample tends to be larger.

C<exact> controls how the p-value is computed. Omit it to let the test choose:
the exact distribution is used for small samples (two-sample when nx·ny 
10000, one-sample when n < 100) and the asymptotic (Kolmogorov limiting)
approximation otherwise. Pass C<< exact =E<gt> 1 >> to force the exact computation or
C<< exact =E<gt> 0 >> to force the asymptotic one. Exact p-values cannot be computed
when the data contain ties; if ties are present on the exact path, the test
warns and falls back to the asymptotic p-value. (The exact one-sample test is
only available for the two-sided alternative; a one-sided one-sample request
also falls back to asymptotic.)

=head3 Return value

C<ks_test> returns a hash reference with four keys:

=over

=item * B<< C<statistic> >> — the KS statistic for the chosen C<alternative>: D, D⁺, or
D⁻. It is the maximum distance between the two ECDFs (or, for the one-sample
test, between the ECDF and the reference CDF), always in the range [0, 1].
Larger values mean the distributions are further apart.

=item * B<< C<p_value> >> — the probability, under the null hypothesis that the samples
share a distribution, of observing a statistic at least this large. It is
clamped to [0, 1]; a small value (e.g. < 0.05) is evidence against the null.

=item * B<< C<method> >> — a human-readable description of exactly what was run, handy
for logging or reproducing a result. One of:
C<"Two-sample Kolmogorov-Smirnov exact test">,
C<"Two-sample Kolmogorov-Smirnov test (asymptotic)">,
C<"One-sample Kolmogorov-Smirnov exact test">, or
C<"One-sample Kolmogorov-Smirnov test (asymptotic)">.

=item * B<< C<alternative> >> — the alternative hypothesis that was applied
(C<'two.sided'>, C<'greater'>, or C<'less'>), echoed back so the result is
self-describing.

=back

For example:

 my $ks = ks_test(\@x, \@y);
 if ($ks->{p_value} < 0.05) {
     printf "reject H0: D=%.4f, p=%.4g (%s)\n",
         $ks->{statistic}, $ks->{p_value}, $ks->{method};
 }

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

A one-way test for equality of group means that, unlike C<aov>/ANOVA, B<does not
assume equal variances>. By default it performs B<Welch's one-way test> (the
same default as R's C<oneway.test>), so the residual degrees of freedom are
usually fractional. Pass C<< var_equal =E<gt> 1 >> for the classic equal-variance form.

 use Stats::LikeR qw(oneway_test);

=head3 Input

C<oneway_test> accepts your data in one of three shapes. In every case each
I<group> is a vector of at least two numeric observations.



=begin html

<table>
<thead>
<tr>
  <th>Shape</th>
  <th>What it means</th>
  <th>Group labels</th>
</tr>
</thead>
<tbody>
<tr>
  <td><b>Hash of arrays</b> <code>{ a => [...], b => [...] }</code></td>
  <td>Each key is a group (R's <code>stack()</code> view of a named list)</td>
  <td>the hash keys</td>
</tr>
<tr>
  <td><b>Array of arrays</b> <code>[ [...], [...] ]</code></td>
  <td>Each element is a group</td>
  <td><code>"Index 0"</code>, <code>"Index 1"</code>, …</td>
</tr>
<tr>
  <td><b>Hash + <code>formula</code></b> <code>{ resp => [...], grp => [...] }, formula => 'resp ~ grp'</code></td>
  <td>Long-format columns split by a factor column</td>
  <td>the distinct values of the factor</td>
</tr>
</tbody>
</table>

=end html



=head3 Options



=begin html

<table>
<thead>
<tr>
  <th>Option</th>
  <th>Default</th>
  <th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>var_equal</code> (alias <code>var.equal</code>)</td>
  <td><code>0</code> (false)</td>
  <td><code>0</code> → Welch's test (unequal variances). <code>1</code> → pooled-variance test.</td>
</tr>
<tr>
  <td><code>formula</code></td>
  <td><i>none</i></td>
  <td><code>'response ~ factor'</code>. Only valid with a <b>hash</b> input; an error with an array of arrays.</td>
</tr>
</tbody>
</table>

=end html



=head3 Data validation

Every observation must be B<defined and numeric>; an C<undef> or non-numeric
cell makes the call C<die> with the offending group and position. This matches
the rest of C<Stats::LikeR> (C<mean>, C<sum>, C<cor>, … all die on C<undef>) and
prevents missing values from being silently treated as C<0>.

Each group needs at least two observations, and you need at least two groups.

=head3 Output

A hash reference with three top-level keys:



=begin html

<table>
<thead>
<tr>
  <th>Key</th>
  <th>Value</th>
</tr>
</thead>
<tbody>
<tr>
  <td><i>factor name</i> (<code>Group</code>, or the formula's factor, e.g. <code>supp</code>)</td>
  <td>the between-groups row: <code>Df</code>, <code>Sum Sq</code>, <code>Mean Sq</code>, <code>F value</code>, <code>Pr(>F)</code></td>
</tr>
<tr>
  <td><code>Residuals</code></td>
  <td>the within-groups row: <code>Df</code>, <code>Sum Sq</code>, <code>Mean Sq</code> (<code>Df</code> is fractional under Welch)</td>
</tr>
<tr>
  <td><code>group_stats</code></td>
  <td><code>{ mean => { group => mean, … }, size => { group => n, … } }</code></td>
</tr>
</tbody>
</table>

=end html



=head3 Examples

=head4 Hash of arrays (each key is a group)

 my $res = oneway_test({
     yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
     ctrl  => [1,   1,   1,   0,   0,   0  ],
 });
 
 {
     Group => {
         Df        => 1,
         "Sum Sq"  => 61.6533333333333,
         "Mean Sq" => 61.6533333333333,
         "F value" => 177.504798464491,
         "Pr(>F)"  => 1.31343255160843e-07,
     },
     Residuals => {
         Df        => 9.81767348326473,   # fractional: Welch correction
         "Sum Sq"  => 3.47333333333333,
         "Mean Sq" => 0.353783749200256,
     },
     group_stats => {
         mean => { ctrl => 0.5, yield => 5.03333333333333 },
         size => { ctrl => 6,   yield => 6 },
     },
 }

=head4 Array of arrays (groups named by index)

 my $res = oneway_test([
     [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
     [1,   1,   1,   0,   0,   0  ],
 ]);

Identical to the hash form, except C<group_stats> is keyed by position:

 group_stats => {
     mean => { "Index 0" => 5.03333333333333, "Index 1" => 0.5 },
     size => { "Index 0" => 6,                "Index 1" => 6   },
 }

=head4 Long format with a formula

When your data is in columns rather than pre-split groups, name the response
and factor columns with a formula. The factor's I<values> become the groups and
the factor's I<name> becomes the top-level key:

 my $res = oneway_test(
     {
         len  => [4.2, 11.5, 7.3, 16.5, 17.3, 13.6, 23.6, 18.5, 33.9],
         supp => [qw(VC VC VC OJ OJ OJ HI HI HI)],
     },
     formula => 'len ~ supp',
 );
 # $res->{supp}, $res->{Residuals}, $res->{group_stats} ...

=head3 Classic equal-variance form

 my $res = oneway_test(\%groups, var_equal => 1);   # or 'var.equal' => 1

=head3 Notes

=over

=item * The default (Welch) does B<not> require equal group sizes or equal variances;
the pooled form (C<< var_equal =E<gt> 1 >>) assumes equal variances.

=item * C<formula> is only meaningful for a hash input. Passing it with an array of
arrays is an error.

=item * Group order in the output is not guaranteed for hash inputs (it follows hash
iteration order); read results by name, not position.

=item * Avoid naming a factor C<Residuals> or C<group_stats> in a formula, since those
are reserved top-level keys in the result.

=back

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
  <td>0 (False)</td>
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

=head4 Returned Data Structure

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
     scale      0,
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

=head3 options



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
  <td><code>comment => %</code> or whatever; does not apply with header</td>
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

 my @scaled_results = scale(1..5, { center => false, scale => 1 });

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

=head3 Standard integer sequence

 say 'seq(1, 5):';
 my @seq = seq(1, 5);
 say join(', ', @seq), "\n";
 
 say 'seq(1, 2, 0.25):';
 @seq = seq(1, 2, 0.25);

=head3 Fractional steps

 say 'seq(1, 2, 0.25):';
 @seq = seq(1, 2, 0.25);
 say join(", ", @seq), "\n";
 for (my $idx = 2; $idx >= 1; $idx -= 0.25) { # count down to pop
     is_approx(pop @seq, $idx, "seq item $idx with fractional step");
 }

=head3 Negative steps

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

There are 1-sample and 2-sample t-tests, from one or two arrays:

 my $t_test = t_test( $array1, mu => 0.2334 );

or 2-sample:

 $t_test = t_test(
     $array1,    $array2,
     paired => 1
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
     'x' => $array1, 'y' => $array2,
     paired => 1
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



=head2 transpose

Transposes a two-dimensional data structure, swapping rows and columns. Accepts either an array of arrays or a hash of hashes.
Returns a new reference of the same type; the input is never modified.

=head3 Array of array input

Takes a reference to an array of array references and returns a new AoA where C<output[j][i] = input[i][j]>.

 my $matrix = [[1, 2, 3], [4, 5, 6]];
 my $t = transpose($matrix);
 # [[1, 4],
 #  [2, 5],
 #  [3, 6]]

All rows must be the same length; a ragged input is a fatal error.
C<undef> is valid as an element value and is preserved exactly. An empty outer array or an array of empty rows both return C<[]>.

Dies if:
- any inner element is not an array reference
- rows differ in length (ragged array)

=head3 Hash of hash input

Takes a reference to a hash of hash references and returns a new HoH where C<output{col}{row} = input{row}{col}>.

 my $table = { alice => { score => 97, grade => 'A' }, bob   => { score => 84, grade => 'B' } };
 my $t = transpose($table);
 # { score => { alice => 97,  bob => 84  },
 #   grade => { alice => 'A', bob => 'B' } }

Inner keys do not need to be uniform across rows. If a given column key appears in only some rows, the output hash for that column will simply contain only those rows — no padding or C<undef>-filling is performed.

 my $sparse = {
 a => { x => 1, y => 2 },
 b => { x => 3, z => 4 } };
 
 my $t = transpose($sparse);
 # { x => { a => 1, b => 3 },
 #   y => { a => 2 },
 #   z => { b => 4 } }

An empty outer hash or an outer hash whose inner hashes are all empty both return C<{}>.

Dies if any inner element is not a hash reference

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
 
 my @x = (2.9, 3.0, 2.5, 2.6, 3.2);
 my @y = (3.8, 2.7, 4.0, 2.4);
 
 my $vt = var_test(\@x, \@y);

also, conf_level can be set:

 $vt = var_test(\@x, \@y, conf_level => 0.99);

as well as a ratio (from R: the hypothesized ratio of the population variances of C<x> and C<y>:

 $test_data = var_test(\@xk, \@yk, ratio => 2);

=head2 view

An R-style C<head> for the structures C<read_table> returns. Prints the first
few rows of a dataframe as an aligned text table, with numeric columns
right-justified, string columns left-justified, and undefined cells shown as
C<NA>. Works on all three C<output.type> values:



=begin html

<table>
<thead>
<tr>
  <th>`output.type`</th>
  <th>Perl structure</th>
  <th>What `view` shows</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>aoh</code></td>
  <td>array of hash refs</td>
  <td>one line per row, sequential row numbers</td>
</tr>
<tr>
  <td><code>hoa</code></td>
  <td>hash of array refs</td>
  <td>values gathered column-wise by row index</td>
</tr>
<tr>
  <td><code>hoh</code></td>
  <td>hash of hash refs</td>
  <td>top-level keys become the row label column</td>
</tr>
</tbody>
</table>

=end html



=head3 Synopsis

 my $aoh = read_table('all.data.tsv', 'output.type' => 'aoh');
 
 view($aoh);                       # first 6 rows, like head()
 view($aoh, n => 20);              # first 20 rows
 view($aoh, cols => [qw(id age tt)]);   # force a column order
 view($aoh, 'row.names' => 'id');  # use column 'id' as the row label
 view($aoh, na => '.', max_width => 30);
 
 my $txt = view($aoh, return_only => 1);  # capture the string, print nothing
 view($aoh, to => \*STDERR);              # print somewhere other than STDOUT

=head3 Output

 # AoH: 7 rows x 3 cols  (showing 6)
 row_name  Testosterone, total (nmol/L)  age  sex
 p1                                18.2   41  M
 p2                                  NA    7  F
 p3                                1.05   33  F
 p4                                22.9   55  M
 p5                                  14   29  M
 p6                                  NA   62  F
 # ... 1 more row

The banner reports the structure type, full dimensions, and how many rows are
displayed. A footer appears only when rows are hidden.

=head3 Arguments

All arguments after the data reference are optional name/value pairs.



=begin html

<table>
<thead>
<tr>
  <th>Argument</th>
  <th>Default</th>
  <th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>n</code></td>
  <td><code>6</code></td>
  <td>Number of rows to show. <code>n</code> greater than the table shows everything.</td>
</tr>
<tr>
  <td><code>rows</code></td>
  <td><code>6</code></td>
  <td>Number of rows to show. <code>n</code> greater than the table shows everything  (synonymous with <code>n</code>)</td>
</tr>
<tr>
  <td><code>cols</code> / <code>columns</code></td>
  <td>—</td>
  <td>Array ref pinning column order (and which columns appear).</td>
</tr>
<tr>
  <td><code>row.names</code></td>
  <td>—</td>
  <td>Column to use as the row label (for <code>aoh</code>/<code>hoa</code>). See ordering note.</td>
</tr>
<tr>
  <td><code>na</code></td>
  <td><code>'NA'</code></td>
  <td>Token printed for undefined cells.</td>
</tr>
<tr>
  <td><code>max_width</code></td>
  <td><code>80</code></td>
  <td>Truncate any cell wider than this (column names are never truncated).</td>
</tr>
<tr>
  <td><code>ellipsis</code></td>
  <td><code>'...'</code></td>
  <td>Marker appended to truncated cells.</td>
</tr>
<tr>
  <td><code>gap</code></td>
  <td><code>2</code></td>
  <td>Spaces between columns.</td>
</tr>
<tr>
  <td><code>to</code></td>
  <td>STDOUT</td>
  <td>Filehandle to print to.</td>
</tr>
<tr>
  <td><code>return_only</code></td>
  <td><code>0</code></td>
  <td>If true, return the string and print nothing.</td>
</tr>
</tbody>
</table>

=end html



C<view> always returns the formatted string, whether or not it also prints.

=head3 A note on column order

C<read_table> stores rows as hashes, so the original CSV column order is not
preserved. C<view> therefore sorts columns by name for a stable, reproducible
layout. Two conveniences soften this:

=over

=item * A column literally named C<row_name> (the label C<read_table> assigns to a
leading blank header) is detected automatically and moved to the left as the
row label.

=item * Pass C<< cols =E<gt> [ ... ] >> to control both the order and the selection of columns
shown.

=back

When no label column is present, C<view> numbers the rows C<1, 2, 3, …>, the way
R prints row names for an unnamed data frame.

=head3 Edge cases

=over

=item * Empty input (C<[]> or C<{}>) prints a clean C<0 rows x 0 cols> banner.

=item * Tabs, carriage returns, and newlines inside a cell are escaped (C<\t>, C<\r>,
C<\n>) so one record always stays on one line.

=item * A non-reference argument, or a hash whose values are plain scalars, dies with
a clear message rather than producing garbled output.

=back

=head3 Tests

The behavior above is covered by C<view.t> (run with C<prove view.t>): the three
structure types, C<n> boundaries, alignment, C<NA> rendering, truncation,
C<row.names>/C<cols> handling, control-character escaping, the C<return_only> and
C<to> output paths, empty structures, and the error cases.

=head2 wilcox_test

 $test_data = wilcox_test(
     [1.83,  0.50,  1.62,  2.48, 1.68, 1.88, 1.55, 3.06, 1.30],
     [0.878, 0.647, 0.598, 2.05, 1.06, 1.29, 1.06, 3.14, 1.29]
 );

Computes the Wilcoxon rank-sum / Mann-Whitney test (two samples) or the Wilcoxon signed-rank test (one sample or paired), following R's C<wilcox.test> conventions.
This is an alternative to the t-test, that does not assume a normal distribution.
With two array refs and no C<paired> flag it runs the two-sample rank-sum test; with a single sample, or with C<< paired =E<gt> 1 >>, it runs the signed-rank test. It calculates exact p-values by default for C<< N E<lt> 50 >> without ties; when ties (or, for the signed-rank case, zero differences) are present it automatically switches to the normal approximation with continuity correction.

=head3 Calling conventions

The first one or two array-ref arguments are taken positionally as C<x> and C<y>; everything after that is parsed as C<< key =E<gt> value >> pairs. The named forms C<< x =E<gt> >> and C<< y =E<gt> >> are also accepted and override the positional values. The flat argument list following the positional refs must contain an even number of elements, or the call dies with a usage message.

 # positional
 wilcox_test(\@x, \@y, paired => 1);
 
 # fully named
 wilcox_test(x => \@x, y => \@y, alternative => "greater", exact => 0);

=head3 Input parameters



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
  <td>ARRAY ref</td>
  <td><i>(required)</i></td>
  <td>The first sample. Passed positionally or as <code>x =></code>. Non-numeric and undefined elements are silently dropped; an empty or all-missing <code>x</code> is fatal. In the two-sample test <code>mu</code> is subtracted from each <code>x</code> value.</td>
</tr>
<tr>
  <td><code>y</code></td>
  <td>ARRAY ref</td>
  <td><code>undef</code></td>
  <td>The second sample. If present and <code>paired</code> is false, a two-sample rank-sum test is run. If <code>paired</code> is true, <code>y</code> is required and must be the same length as <code>x</code>. Omit it for the one-sample signed-rank test.</td>
</tr>
<tr>
  <td><code>paired</code></td>
  <td>boolean</td>
  <td><code>0</code> (false)</td>
  <td>Run a paired signed-rank test on the per-element differences <code>x[i] - y[i] - mu</code>. Requires <code>y</code> of equal length.</td>
</tr>
<tr>
  <td><code>correct</code></td>
  <td>boolean</td>
  <td><code>1</code> (true)</td>
  <td>Apply the continuity correction (±0.5) when using the normal approximation. Ignored when an exact p-value is computed.</td>
</tr>
<tr>
  <td><code>mu</code></td>
  <td>number</td>
  <td><code>0.0</code></td>
  <td>Null-hypothesis location shift. Subtracted from <code>x</code> (two-sample) or from each difference (one-sample / paired).</td>
</tr>
<tr>
  <td><code>exact</code></td>
  <td>boolean / undef</td>
  <td><code>undef</code> (auto)</td>
  <td>Tri-state. <code>undef</code> (or absent) selects exact automatically: when both group sizes are <code>< 50</code> and there are no ties (two-sample), or <code>n < 50</code> with no ties (signed-rank). A true value forces the exact test, a false value forces the approximation. Exact is impossible with ties — or, for the signed-rank test, with zero differences — and falls back to the approximation with a warning.</td>
</tr>
<tr>
  <td><code>alternative</code></td>
  <td>string</td>
  <td><code>"two.sided"</code></td>
  <td>One of <code>"two.sided"</code>, <code>"less"</code>, or <code>"greater"</code>. Selects the tail(s) used for the p-value.</td>
</tr>
</tbody>
</table>

=end html



=head3 Output

Returns a hash ref with the following keys:



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
  <td><code>statistic</code></td>
  <td>number</td>
  <td>The test statistic. For the two-sample test this is the Mann-Whitney <b>W</b> (the <code>x</code> rank sum minus <code>nx*(nx+1)/2</code>). For the signed-rank test it is <b>V</b>, the sum of the ranks assigned to the positive differences.</td>
</tr>
<tr>
  <td><code>p_value</code></td>
  <td>number</td>
  <td>The p-value for the chosen <code>alternative</code>, capped at <code>1.0</code>. Two-sided p-values are <code>2 * min(p_less, p_greater)</code>.</td>
</tr>
<tr>
  <td><code>method</code></td>
  <td>string</td>
  <td>A human-readable description of the exact test variant that was run (see below).</td>
</tr>
<tr>
  <td><code>alternative</code></td>
  <td>string</td>
  <td>Echoes the <code>alternative</code> actually used (<code>"two.sided"</code>, <code>"less"</code>, or <code>"greater"</code>).</td>
</tr>
</tbody>
</table>

=end html



The C<method> string reports which path executed:

=over

=item * Two-sample: C<"Wilcoxon rank sum exact test">, C<"Wilcoxon rank sum test with continuity correction">, or C<"Wilcoxon rank sum test">.

=item * One-sample / paired: C<"Wilcoxon exact signed rank test">, C<"Wilcoxon signed rank test with continuity correction">, or C<"Wilcoxon signed rank test">.

=back

=head3 Notes and edge cases

Missing data is handled by listwise removal of non-numeric / undefined cells before ranking; in the paired case a pair is dropped if either member is missing. An empty C<x> (or, in the two-sample case, an empty C<y>) after this filtering is fatal.

For the signed-rank test, exact zero differences are discarded before ranking (matching R), and their presence disables the exact computation. Both empty-after-filtering and all-zero-difference inputs are fatal.

Ties are detected during ranking and trigger the tie-corrected variance in the normal approximation; they also rule out the exact p-value. When C<exact> is left on auto, the size thresholds (C<< E<lt> 50 >> per group, or C<< E<lt> 50 >> differences) are what gate the exact vs. approximate decision.

=head2 write_table

mimics R's C<write.table>, with data as first argument to subroutine, and output file as second

 write_table(\@data_aoh, $tmp_file, sep => "\t", 'row.names' => 1);

You can also precisely filter and reorder which columns are written by passing an array reference to C<col.names>:

 write_table(\@data, $tmp_file, sep => "\t", 'col.names' => ['c', 'a']);

undefined variables are printed as C<NA> by default, but can be set as you wish using C<undef.val>

 write_table(\%data_hoa, '/tmp/undef.val.tsv', sep => "\t", 'undef.val' => 'nan')

as of version 0.07, C<write_table> determines comma and tab-separated delimiters from the filename, but will override if C<sep> or C<delim> are explicitly set.

Args can also be accepted:

 write_table( 'data' => \%flat, 'file' => $f );

=head1 changes

=head2 0.16

changes to dist.ini, the minimum Perl version disappeared when I fixed other problems

clarifications between run time and test dependencies

addition of C<csort> function to sort AoH and HoA

addition of C<aoh2hoa> to translate array of hashes into a hash of arrays

fix of long double functions: https://www.cpantesters.org/cpan/report/5d5d9836-6a5f-11f1-aadb-63fd6d8775ea

=head3 C<glm>

output residual keys now use names, not integers

=head3 C<lm>

=head3 Bug fixes

B<Memory leak on the zero-degrees-of-freedom error path.> When
C<< valid_n E<lt>= p >>, the cleanup freed the C<valid_row_names> I<array> but not the
per-row name strings it held (those had been transferred out of C<row_names>,
whose own array was already freed). The strings leaked on every such error.
Added the per-entry C<Safefree> loop before freeing the array, matching the
normal path.

B<HoH input validated only the first row.> Only the first hash value was
checked to be a C<HASHREF>; subsequent values were C<SvRV>'d unconditionally, so
a malformed row (C<< { a =E<gt> {...}, b =E<gt> 5 } >>) dereferenced a non-reference. Every
row is now validated, with the partial allocations cleaned up before the
C<croak>, mirroring the existing AoH path.

B<< C<isspace> on a possibly-signed C<char>. >> C<isspace(*src)> is undefined for
byte values ≥ 0x80 on platforms where C<char> is signed. Cast to
C<(unsigned char)> before the call.

=head3 Speed / RAM improvements

B<Formula buffer is now heap-allocated to fit.> C<char f_cpy[512]> silently
truncated any longer formula. Replaced with a buffer sized to
C<strlen(formula) + 1>, so there is no fixed limit and no truncation.

B<< C<.>-expansion buffer is now a growable heap buffer. >> C<char rhs_expanded[2048]>
silently dropped expanded terms once full. It is now a buffer that doubles on
demand. Appends also went from C<strcat> (which rescans from the start every
time — O(n²) over many columns) to an O(1) amortised append that tracks the
write position.

B<No more per-row scratch allocation in matrix construction.> The original
C<safemalloc>'d a C<row_x> buffer, filled it, copied it into C<X>, and freed it
I<for every row> — C<n> allocations plus C<n*p> copies. Each candidate row is now
written straight into C<X> at its prospective commit slot; a row that fails
listwise deletion is simply overwritten by the next candidate. This removes the
C<n> allocate/free cycles and the copy loop entirely.

B<< Categorical levels sorted with C<qsort>. >> The level list used an O(n²) bubble
sort; replaced with C<qsort> (relevant only for high-cardinality factors).

B<< Unused tail of C<X> reclaimed after listwise deletion. >> C<X> is allocated for
all C<n> rows up front (C<valid_n> is unknown until rows are scanned). When rows
are dropped, C<X> is now C<Renew>ed down to C<valid_n * p>, returning the unused
tail to the allocator before the OLS phase.

B<Minor robustness.> The argument-parsing index was widened from
C<unsigned short> to C<I32> to match C<items>, and the HoH row count now uses
C<HvUSEDKEYS> rather than relying on C<hv_iterinit>'s return value.

=head3 Known limitations (left unchanged)

=over

=item * A multi-way term such as C<a*b*c> is split only on the first C<*>, so it yields
C<a>, C<b*c>, and C<a:b*c> rather than a full three-way expansion. Deeper
interactions silently fail (the unparsable term evaluates to C<NaN> and the
rows are dropped). This matches the documented two-way C<*> support.

=item * HoA input takes the row count from the first column; columns shorter than
that simply contribute dropped rows rather than raising an error.

=back

=head3 C<oneway_test>

=head4 Bug fixes

B<Memory leaks on error paths.> Nearly every C<croak> after an allocation
leaked memory. C<croak> does a C<longjmp>, so anything allocated but not yet
freed is lost. Affected paths:

=over

=item * AoA and hash first-pass errors leaked C<sizes> and any C<gnames[]> entries
allocated so far.

=item * Formula-mode "not found as an array ref" errors leaked C<lhs> and C<rhs>.

=back

All post-allocation errors now route through a single C<fail:> label that frees
every pointer unconditionally. Pointers are initialised to C<NULL> and C<gnames>
is zero-allocated with C<Newxz>, so the cleanup is always safe to run.

B<< Undefined and non-numeric cells silently coerced to C<0.0>. >> The original
second pass used C<(svp && *svp) ? SvNV(*svp) : 0.0>, meaning an C<undef> or
non-numeric cell was quietly treated as zero, silently corrupting the
F-statistic. Each cell is now validated with C<SvOK> and C<looks_like_number>;
the call dies naming the group and observation index, consistent with the rest
of C<Stats::LikeR> (C<mean>, C<sum>, C<cor>, etc.).

B<Unsigned wraparound on empty array input.> C<k = (size_t)av_len(in_av) + 1>
cast to C<size_t> I<before> adding, so an empty array (C<av_len> returns C<-1>)
produced C<SIZE_MAX> rather than C<0>. Changed to
C<k = (size_t)(av_len(in_av) + 1)> so the C<+1> is done in signed arithmetic
before the cast.

B<< Unreliable group count from C<hv_iterinit>. >> C<hv_iterinit> returns the
number of buckets in use rather than the number of keys for tied hashes.
Replaced with C<HvUSEDKEYS>, which always returns the correct key count.

=head4 Improvements

B<< C<var.equal> accepted as an alias for C<var_equal>. >> R users write
C<var.equal>; the argument parser now accepts both spellings.

B<Perl memory API used throughout.> C<safemalloc> and manual C<memcpy> replaced
with C<Newx>, C<Newxz>, C<savepv>, and C<savepvn>. C<savepvn> additionally
preserves embedded NUL bytes in group key strings, which the previous
C<strlen>-based copies silently truncated.

=head4 Known limitations (not changed)

=over

=item * A factor column named C<Residuals> or C<group_stats> in a formula call will
collide with reserved top-level keys in the result hash.

=item * Group names containing an embedded NUL are stored correctly but are still
truncated at C<strlen> when written into the output hash keys.

=back

=head3 C<view>

default view shifted to 80 characters to match Linux window length

=head4 New features

=over

=item * B<< C<rows> is accepted as a synonym for C<n> >> (the number of rows shown).
Passing both C<n> and C<rows> is an error.

=item * B<Unknown arguments are now rejected.> C<view> validates its argument names
against the documented set (C<n>, C<rows>, C<na>, C<max_width>, C<ellipsis>,
C<gap>, C<cols>, C<columns>, C<to>, C<return_only>, C<row.names>, C<row_names>) and
dies listing any it does not recognise, so a misspelt option (e.g. C<widht>)
is caught instead of silently ignored.

=item * B<< C<n> / C<rows> is validated. >> It must be a non-negative integer; C<undef> or
a non-numeric value now dies with a clear message instead of producing
warnings and being treated as C<0>.

=item * B<flat/simple hashes are accepted as input>

=back

=head4 Bug fixes

=over

=item * B<< C<< n =E<gt> 0 >> now still prints the column header. >> Column names were collected
only from the rows being shown, so requesting zero rows produced an empty
header line. At least one row is now scanned (when data exists) so the
header always lists the columns.

=item * B<< An empty hash (C<{}>) no longer dies. >> It was rejected as
I<"neither ARRAY nor HASH">; it is now shown as an empty table
(C<0 rows x 0 cols>), matching the handling of an empty array.

=item * B<< The C<row_names> alias now drives the Hash-of-Hashes label header. >> The
header for the row-label column consulted only C<row.names>, so
C<< row_names =E<gt> 'id' >> displayed C<row_name> instead of C<id>. Both spellings are
now honoured consistently.

=item * B<Malformed nested values degrade gracefully.> A Hash-of-Arrays column or
Hash-of-Hashes row whose value is not actually an array/hash reference now
renders as empty cells rather than throwing a dereference error.

=back

=head4 Performance

=over

=item * Column gathering no longer sorts once per scanned row. Unique column names
are collected across the scanned rows and sorted a single time (same output
order), and the ellipsis length is computed once rather than per cell.

=back

=head4 Tests

=over

=item * C<t/view.t> is self-contained (the C<view> implementation is inlined; it loads
no other files) and covers the new argument handling, the bug fixes above,
and the existing AoH / HoA / HoH behaviour, alignment, truncation, and
output-path handling.

=back

=head3 C<wilcox_test>

Corrected four bugs in the C<wilcox_test> XSUB plus a portability fix in its exact signed-rank helper. Behaviour on valid input is unchanged: the R-agreement cases (unpaired C<W = 58>, C<p = 0.13292>; paired one-sided C<V = 40>, C<p = 0.019531>; separated exact C<W = 0>, C<p = 0.028571>) all still match R's C<wilcox.test>.

=head4 Bug fixes

=over

=item * B<< Invalid C<alternative> is now rejected. >> Any value other than C<less> or C<greater> previously fell through to the two-sided branch and returned a two-sided result mislabelled with the bad string, so a typo like C<< alternative =E<gt> "twosided" >> silently "worked". It now croaks unless C<alternative> is one of C<two.sided>, C<less>, C<greater>.

=item * B<Zero/negative variance is guarded.> When every observation is tied the approximation's variance collapses to 0 and the old code divided by C<sqrt(0)>: C<wilcox_test([5,5,5], [5,5,5])> returned C<p = 0> (a "significant" difference between identical samples). It now warns and returns C<p = 1>.

=item * B<< Two-sided continuity correction at C<z = 0>. >> R uses C<sign(z) * 0.5>, so the correction is C<0> when the statistic sits exactly on its mean; the old code used C<-0.5>. Example: C<< wilcox_test([1,4], [2,3], exact =E<gt> 0) >> changed from C<p = 0.698535> to C<p = 1> (matches R).

=item * B<< C<exp> no longer shadows libm. >> The local C<exp> accumulator (mean of the statistic) shadowed the C library C<exp()>; renamed to C<mean_w> (two-sample) and C<mean_v> (signed-rank). No active miscompute, removed as a latent hazard.

=back

=head4 Cosmetic

=over

=item * Collapsed a no-op ternary that assigned the same signed-rank exact method string on both branches; the C<method> field is now simply C<Wilcoxon signed rank exact test>.

=back

=head4 Portability (exact signed-rank helper)

=over

=item * B<< C<exact_psignrank> no longer calls C<powl()>. >> The C<2^n> normaliser is now built by exact repeated doubling, which has no long-double libm dependency. This fixes an C<Undefined symbol "powl"> load failure reported by a CPAN smoker (FreeBSD, perl 5.20, C<nvtype=double>) whose libm lacks the long-double math functions; the symbol resolved on glibc, which is why local builds passed. C<long double> accumulation in the DP is retained — only the C<powl> call was at fault.

=item * B<< C<int> → C<size_t> >> for C<n>, C<max_v>, and the DP loop counters, which also removes a C<size_t>-to-C<int> narrowing at the call site. The C<floor()> result (C<k>) stays signed so its negative-C<q> sentinel still fires, and is cast to C<size_t> only after the C<< k E<lt> 0 >> check.

=back

=head4 Tests

=over

=item * Added C<t/wilcox_test.t> (flat, no subtests): R-agreement cases, option handling (C<paired>, C<correct>, C<exact>, C<mu>, named/positional C<x>/C<y>, NA dropping), regressions for all four bug fixes, argument-error and C<alternative>-validation checks, output shape, and C<no_leaks_ok> coverage of the two-sample, exact, and paired allocation paths.

=back

=head2 0.15

C<view> function added, similar to R's C<head>

C<read_table>:
    filter => {
        'Testosterone, total (nmol/L)' => sub { defined $_ },
    }

was broken by the change in undefined variables in 0.14, but is back to being C<undef>

C<col2col> improvement in sectioning in README

Numerous changes to prevent quadmath/long double CPAN test failures

Minimum Scalar::Util version in dist.ini is now 1.22, see https://www.cpantesters.org/cpan/report/6b682236-6567-11f1-a3bc-a055f9c4ba34

C<Digest::SHA> is no longer needed, and removed as a dependency

=head3 C<read_table>

=head4 Bug fixes

=over

=item * B<A comment-prefixed header is now read correctly.> C<read_table> strips a
leading comment marker from the header line (so a file may begin with
C<#id,val>), but that strip was dead code: the XS parser skipped I<every> line
beginning with the comment string before the callback ever saw it, so a
commented header was silently dropped and the first data row was mistaken for
the header. The parser now delivers the first content line even when it
begins with the comment marker, and only skips comment lines after the header
has been seen.

=item * B<Carriage returns inside quoted fields are preserved.> The parser stripped
C<\r> unconditionally, so a quoted value such as C<"x\ry"> lost its carriage
return and would not survive a C<write_table> -> C<read_table> round-trip. C<\r>
is now stripped only as part of a trailing CRLF line ending and as a stray CR
I<outside> quotes; inside quotes it is literal data.

=item * B<< Duplicate column names no longer corrupt C<hoa> output. >> With
C<< output.type =E<gt> 'hoa' >>, a repeated column name pushed the same cell once per
occurrence, so the affected columns came out longer than the others and the
arrays no longer lined up by row. Columns are now keyed by unique header name
(first-seen order preserved, later values win, one warning emitted).

=item * B<A defined non-CODE callback is now an error.> Passing a defined argument
that was not a CODE reference silently fell through to slurp mode and ignored
the argument; it now croaks
(I<"callback must be a CODE reference">).

=item * B<< An undefined/empty C<hoh> row-name now dies instead of keying on C<"">. >>
With C<< output.type =E<gt> 'hoh' >>, a row whose row-name column was empty/undef was
stored under the C<''> key and raised I<"uninitialized value"> warnings. It now
dies, naming the column and the offending data row.

=item * B<A numeric filter key past the last column now dies.> A 1-based numeric
filter key greater than the column count was accepted, then silently extended
every row through the C<$_> write-back. It is now rejected up front with a
message naming the column count.

=item * B<< C<sep> and C<delim> together now die. >> Supplying both silently preferred
C<delim>; passing both is now an explicit error (C<delim> remains an alias for
C<sep> when used alone).

=item * B<The library no longer prints to STDOUT.> The unknown-argument path used
C<say> to dump the offending names to STDOUT before dying; the names are now
carried in the C<die> message itself.

=back

=head4 Better diagnostics

=over

=item * Alignment errors now report B<which data row> is ragged
(I<"Alignment error on FILE data row N (X fields vs Y headers)">), instead of
only the field/header counts.

=back

=head4 Memory-leak fixes (exception paths)

The parser allocated its working buffers (C<current_row>, C<field>, and — in
slurp mode — C<data>) in the XS C<INIT:> block, i.e. I<before> any validation, and
freed them only by falling off the end of the function. Any non-local exit
therefore leaked:

=over

=item * the open-failure C<croak> leaked the row buffer and field (and the slurp
accumulator);

=item * far more commonly, a C<die> thrown B<inside the row callback> — which
C<read_table> does routinely on alignment errors, bad row names, and filter
exceptions — unwound straight out of the XS frame and leaked the field, the
current row, the line buffer, the slurp accumulator, I<and the open file
handle>.

=back

Allocations now happen in C<CODE:> after every croak-able check, and every
long-lived resource (the file handle via C<SAVEDESTRUCTOR_X>, the buffers via
C<SAVEFREESV>) is tied to the save stack, which an exception unwinds. Measured
with C<Test::LeakTrace>: a C<die> mid-file went from 5 leaked SVs to 0, and an
open failure from 2 to 0. This is the likely source of the constant-size leaks
seen in CPAN-tester reports for the exception-path tests.

=head4 Performance

=over

=item * B<~2.5x faster parsing> (57 -> 145 MB/s on a 100k-row quoted file). The core
loop appended one character at a time with C<sv_catpvn(field, &ch, 1)>; it now
scans runs of ordinary bytes with C<memchr> / a bounded scan and appends each
run in a single C<sv_catpvn>, copying field contents in bulk rather than byte
by byte.

=back

=head4 Internal / non-behavioral

=over

=item * XS declarations moved from C<INIT:> to C<PREINIT:>; allocations deferred into
C<CODE:> (see the leak fixes above).

=item * The filter loop now aliases the row hash with C<local *_ = \%line_hash>
instead of copying it with C<local %_ = %line_hash>. This removes a full
per-row hash copy for every filtered row and fixes a latent staleness bug:
after a filter mutated C<$_> and the change was written back, C<%_> still
reflected the pre-mutation copy, so a subsequent filter in the same row saw
stale values. With aliasing, C<%_> I<is> the row, so write-backs are always
visible.

=back

=head4 Known limitation (not changed)

=over

=item * B<< C<undef.val> does not round-trip back to C<undef>. >> C<write_table> renders an
C<undef> cell as an empty field by default, and C<read_table> maps an empty
field back to C<undef>, so the I<default> round-trip is clean. But if a file is
written with a token such as C<< 'undef.val' =E<gt> 'NA' >>, C<read_table> has no
inverse option and reads C<NA> back as the string C<'NA'>. C<read_table> also
cannot distinguish a deliberately quoted empty string (C<"">) from a missing
value -- both become C<undef>. Adding an C<na.strings>-style option to
C<read_table> (mapping configurable tokens and/or empty fields to C<undef>)
would close this gap.

=back

=head3 C<write_table>

=head4 Behavior change

=over

=item * B<< C<undef> cells now write as an empty field, not an empty string. >> A missing
or C<undef> value renders as nothing between separators (C<a,,c>) rather than a
quoted empty string (C<a,'',c> / C<a,"",c>). Supplying C<< 'undef.val' =E<gt> 'NA' >>
(or any other token) still overrides this, exactly as before. This is the
only change that can alter the bytes of an existing output file; if you relied
on the previous default, pass C<< 'undef.val' =E<gt> '' >> to keep an explicit empty
field, or your chosen placeholder.

=back

=head4 Bug fixes

=over

=item * B<Wide-character / UTF-8 column names and row keys now round-trip.>
Previously, cells were looked up with the raw bytes of the column name
(C<hv_fetch(..., SvPV_nolen(name), strlen(name), ...)>), which fails to match a
UTF-8-flagged hash key: the column header printed correctly but every cell
under it came back empty. All lookups now fetch by SV (C<hv_fetch_ent>), header
lists are gathered and sorted as SVs (C<sortsv> + C<sv_cmp>, preserving the
flag) instead of being round-tripped through C<char *>, and the C<row.names>
column is matched with C<sv_eq> rather than C<strcmp>. Embedded NUL bytes in
keys are handled correctly as a side effect.

=item * B<< C<< col.names =E<gt> [] >> no longer loops forever. >> An empty C<col.names> array made
C<av_len()> return C<-1>, which — compared against an unsigned C<size_t> loop
index — wrapped to C<SIZE_MAX> and ran effectively without end. This was fixed
for flat hashes previously; it was still present for hash-of-hashes,
hash-of-arrays, and array-of-hashes, plus both C<row.names> header-filtering
loops. All such loops now use a signed index.

=item * B<Tables wider than 65,535 columns no longer hang.> One header loop used an
C<unsigned short> index that silently wrapped past 65,535 and never terminated.
It now uses C<size_t> like the rest of the code.

=item * B<Flat-hash cells holding a reference now croak.> Every other input shape
rejects a nested reference with
I<"Cannot write nested reference types to table">; a flat hash instead
stringified it (e.g. C<ARRAY(0x55...)>) into the file. It now croaks
consistently.

=item * B<< C<< 'undef.val' =E<gt> undef >> is handled cleanly. >> It previously called
C<SvPV_nolen> on C<undef>, raising an I<"uninitialized value"> warning and
yielding an empty string by accident. It is now treated explicitly as an empty
field, with no warning.

=back

=head4 Memory-leak fixes (exception paths)

=over

=item * The row-key list gathered for hash-of-hashes input was leaked when the output
file could not be opened.

=item * The I<"Could not get headers"> croak on hash-of-arrays input leaked both the
already-open filehandle and the headers array.

=back

=head4 Internal / non-behavioral

=over

=item * Numeric row labels are now formatted into a reused stack buffer instead of a
per-row C<savepv()> / C<safefree()> allocation (no functional change; removes a
cast-away-C<const> and one allocation per row).

=item * Several signed/unsigned index types were made consistent (C<SSize_t> vs
C<size_t>) to match C<av_len()> and silence the conditions behind the loop bugs
above.

=back

=head4 Tests

=over

=item * C<t/write_table.t> expanded from 17 to 69 assertions. New coverage targets each
fix above: the empty-field default and C<< undef.val =E<gt> undef >> (no warning),
C<< col.names =E<gt> [] >> termination across all four input shapes, the
 >65,535-column header loop (gated behind C<EXTENDED_TESTING=1>), in-sequence
numeric row labels, nested-reference rejection, CSV quoting corners
(carriage return, separators inside column names, multi-character separators),
empty input writing no file, and UTF-8 column names and row keys. Two leak
assertions cover the exception paths above.

=back

=head2 0.14

C<filter> function added for rows

C<read_table> reads undefined values to C<undef> instead of C<NA>, which makes calculations easier

C<write_table> writes undef by default as an empty string C<''>

C<hoh2hoa> transforms a hash of hashes into an hash of arrays

C<quantile> uses C<NV> instead of C<double> to allow for high-precision 128-bit floats to be used on quadmath machines when available: https://www.cpantesters.org/cpan/report/296f4868-631f-11f1-abba-ff15558d240b

Numerous switches from C<double> to C<NV> for local precision, like above

numerous changes to C<col2col> for ease of use and working with datasets with numerous undefined values

dist.ini now links to math library when compiling: https://www.cpantesters.org/cpan/report/785e26d8-6397-11f1-89c0-dc066e8775ea

C<fisher_test> now should be complete, errors with confidence intervals fixed

=head2 0.13

C<read_table>: speed improvements; commented headers are now allowed

C<write_table>: fix for 

 Attempt to free temp prematurely: SV 0x56417a2ae610 at t/write_table.t line 182.
     main::wrote_ok(",age\x{a}Alice,30\x{a}Bob,25\x{a}", "row.names => 'name' uses that column as labels", HASH(0x56417a272250), "row.names", "name") called at t/write_table.t line 203
 Attempt to free unreferenced scalar: SV 0x56417a2ae610 at t/write_table.t line 183.
     main::wrote_ok(",age\x{a}Alice,30\x{a}Bob,25\x{a}", "row.names => 'name' uses that column as labels", HASH(0x56417a272250), "row.names", "name") called at t/write_table.t line 203

C<write_table> gives better warnings for incorrect types of data given

Numerous changes to dist.ini to improve CPAN testing, especially for Win32

=head2 0.12

C<add_data> can also take hash of arrays, and various mixes of data types

C<ljoin>: Addition of C<restrict> keywords in many places; should improve CPU performance

Better POD formatting, correction of output hash for README's C<add_data>

C<chisq_test> can now accept hash of hashes as input

new C<transpose> function for switching 2D hash keys and 2D array indices, and C<col2col> for comparing columns against columns

removed unused function from C helpers

C<value_counts>: addition of restrict keywords in preinit, should improve CPU performance

MANIFEST.skip changed to MANIFEST.SKIP to improve CPAN testing

using C<is_deeply> for tests of C<transpose>, which may or may not work with CPAN testers (experimental)

Added function name to warnings, so I actually know which function is producing the error

C<write_table> can also take C<file> and C<data> as args, in addition to positions

fixed C<write_table> as it could hang if given empty C<col.names> or C<row.names>

Added C<__EXTENSIONS__> to source XS file for better CPAN testing

=head2 0.11

better POD formatting for tables

addition of MANIFEST.skip to get better testing results on CPAN

C<glm>: bugfix for when there is no intercept in the formula, new test cases in t/glm.t

C<write_table> now accepts simple hashes as input, in addition to hash of arrays, hash of hashes, and arrays of hashes

Better documentation for t-test

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

C<write_table> now has C<undef.val> option, which shows how undefined values are printed to tables, which is C<NA> by default.
