#!/usr/bin/env perl
require 5.010;
use strict;
use warnings FATAL => 'all';
use feature 'say';
use Carp;
use File::Temp qw(tempfile);
use Test::More;

# --- optional test modules: import if present, else install skipping stubs ---
BEGIN {
	if (eval { require Test::Exception; 1 }) {
		Test::Exception->import;
	} else {
		*throws_ok = sub (&;$$) { SKIP: { skip 'Test::Exception not installed', 1 } };
		*dies_ok   = sub (&;$)	{ SKIP: { skip 'Test::Exception not installed', 1 } };
		*lives_ok  = sub (&;$)	{ SKIP: { skip 'Test::Exception not installed', 1 } };
	}
}

# Custom helper for floating-point comparisons
sub is_approx {
	my ($got, $expected, $test_name, $epsilon) = @_;
	$epsilon = 1e-7 if not defined $epsilon;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	my $i = 0;
	foreach my $arg ($got, $expected, $test_name) {
		next if defined $arg;
		die "\$arg[$i] (see subroutine signature for name) isn't defined in $current_sub";
		$i++;
	}
	my $diff = abs($got - $expected);
	if ($diff <= $epsilon) {
		pass("$test_name: within $epsilon");
		return 1;
	} else {
		fail($test_name);
		diag("		   got: $got\n	  expected: $expected; diff = $diff");
		return 0;
	}
}

# Minimal stand-in for the real XS _parse_csv_file: split each line on $sep and
# hand the field arrayref to the callback. The real parser also does quote and
# comment handling; field *counts* are all the row-names logic depends on, so
# this is enough to exercise read_table here.
sub _parse_csv_file {
	my ($file, $sep, $comment, $cb) = @_;
	open my $fh, '<', $file or die "open $file: $!";
	while (my $line = <$fh>) {
		chomp $line;
		next if $line eq '';
		my @f = split /\Q$sep\E/, $line, -1;
		$cb->(\@f);
	}
	close $fh;
}

# Write $content to a throwaway .tsv (the .tsv suffix picks the tab default sep).
sub write_tmp_tsv {
	my ($content) = @_;
	my ($fh, $path) = tempfile('rtXXXXXX', SUFFIX => '.tsv', TMPDIR => 1, UNLINK => 1);
	print $fh $content;
	close $fh;
	return $path;
}

# ---------------------------------------------------------------------------
# read_table() inlined verbatim from LikeR.pm so this test is self-contained.
# Once the change is in the module, delete this sub and the _parse_csv_file
# stub above, and load the real ones with:	use Stats::LikeR qw(read_table);
# ---------------------------------------------------------------------------
sub read_table {
	my $file = shift;
	die "read_table: \"$file\" is not a file\n"	  unless -f $file;
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
		sep		=> $default_sep,
		comment => '#',
		%input_args,
	);

	my %allowed_args = map { $_ => 1 } (
		'comment', 'output.type', 'filter', 'row.names', 'sep',
		'auto.row.names',
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

	# R's write.table(col.names=TRUE) default omits the header label for the
	# row-names column, so a header comes out one field short of every data
	# row. With 'auto.row.names' set, mirror read.table's rule: when (and only
	# when) the header is exactly one field short, treat the first data field
	# as an (otherwise unlabelled) row-names column. Any truthy value enables
	# it; a non-1 string is used as the synthesized column name.
	my $want_auto_rn = $args{'auto.row.names'} ? 1 : 0;
	my $auto_rn_name =
		($want_auto_rn && "$args{'auto.row.names'}" ne '1')
			? $args{'auto.row.names'} : 'row_name';

	my $filter = $args{filter};
	if (defined $filter && ref($filter) eq 'CODE') {
		$filter = { 0 => $filter };
	} elsif (defined $filter && ref($filter) ne 'HASH') {
		die "'filter' must be a CODE or HASH reference\n";
	}

	my (@data, %data, @header, @uniq_header,
		%mapped_filters, @sorted_filter_flds, %seen_rownames);
	my $data_row	= 0;
	my $header_seen = 0;
	my $header_done = 0;

	# Everything that depends on the (possibly augmented) @header lives here so
	# it can run either right after the header line (strict mode) or deferred
	# to the first data row (auto.row.names mode, once the width is known).
	my $finalize_header = sub {
		if (@header && $header[0] eq '') {
			$header[0] = 'row_name';
		}
		my %seen_h;
		# FIX: hoa output with duplicate column names used to push the same
		# cell once PER OCCURRENCE, silently corrupting the column lengths.
		# Iterate unique names (order preserved) instead.
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
			%mapped_filters = ();
			for my $k (keys %$filter) {
				if ($k =~ /^\d+$/) {
					# FIX: a numeric key past the last column used to be
					# accepted and then silently extended every row via the
					# $_ write-back
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
	};

	_parse_csv_file($file, $args{sep} // '', $args{comment} // '', sub {
		my ($line_ref) = @_;

		if (!$header_seen) {
			# --- HEADER CAPTURE (copy made only here; runs once) ---
			my @line = @$line_ref;
			$line[0] =~ s/^\Q$args{comment}\E//
				if @line && defined $line[0] && length( $args{comment} // '' );
			@header		 = @line;
			$header_seen = 1;
			unless ($want_auto_rn) {	# strict: finalize immediately
				$finalize_header->();
				$header_done = 1;
			}
			return;
		}

		if (!$header_done) {
			# First data row in auto.row.names mode: now the data width is
			# known, so decide whether the file carries an unlabelled leading
			# row-names column (header exactly one field short).
			if (@$line_ref == @header + 1) {
				unshift @header, $auto_rn_name;
			}
			$finalize_header->();
			$header_done = 1;
			# fall through and process THIS line as data
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
	# header-only files in auto mode never hit a data row: still validate
	$finalize_header->() if $header_seen && !$header_done;

	if ($otype eq 'aoh') {
		return \@data;
	} else { # hoa or hoh
		return \%data;
	}
}

# A 3-column mtcars subset as R writes it by default
# (write.table(col.names=TRUE, row.names=TRUE)): the header is one field short
# of every data row, because R omits the label for the row-names column.
my $r_default = <<"EOF";
mpg\tcyl\tdisp
Mazda RX4\t21\t6\t160
Datsun 710\t22.8\t4\t108
Valiant\t18.1\t6\t225
EOF

# 1) strict default still rejects the lopsided file (corruption guard intact)
{
	my $f = write_tmp_tsv($r_default);
	throws_ok { read_table($f) }
		qr/Alignment error.*data row 1 \(4 fields vs 3 headers\)/,
		'strict default croaks on R col.names=TRUE output';
}

# 2) auto.row.names => 1 : leading field becomes row_name, rest align
{
	my $f	= write_tmp_tsv($r_default);
	my $aoh = read_table($f, 'auto.row.names' => 1);
	is(scalar @$aoh, 3, 'auto: all 3 rows read');
	is($aoh->[0]{row_name}, 'Mazda RX4', 'auto: row_name holds the model name');
	is($aoh->[0]{mpg}, 21, 'auto: mpg aligned to its column');
	is_approx($aoh->[1]{mpg}, 22.8, 'auto: fractional value aligned');
	is($aoh->[0]{disp}, 160, 'auto: final column aligned');
}

# 3) auto.row.names => 'model' : custom name for the synthesized column
{
	my $f	= write_tmp_tsv($r_default);
	my $aoh = read_table($f, 'auto.row.names' => 'model');
	is($aoh->[2]{model}, 'Valiant', 'auto: custom column name used');
	ok(!exists $aoh->[2]{row_name}, 'auto: default name absent when custom given');
}

# 4) auto + hoh : key defaults to the synthesized first column (the model)
{
	my $f	= write_tmp_tsv($r_default);
	my $hoh = read_table($f, 'output.type' => 'hoh', 'auto.row.names' => 1);
	is($hoh->{'Datsun 710'}{cyl}, 4, 'auto + hoh: keyed by model name');
	ok(!exists $hoh->{'Datsun 710'}{row_name}, 'auto + hoh: key not duplicated as a field');
}

# 5) auto + hoa : synthesized column present and columns aligned
{
	my $f	= write_tmp_tsv($r_default);
	my $hoa = read_table($f, 'output.type' => 'hoa', 'auto.row.names' => 1);
	is_deeply($hoa->{row_name}, ['Mazda RX4', 'Datsun 710', 'Valiant'],
		'auto + hoa: row_name column collected');
	is_deeply($hoa->{cyl}, [6, 4, 6], 'auto + hoa: data column aligned');
}

# 6) flag ON but the file is already aligned: no synthesis, reads normally
{
	my $f = write_tmp_tsv("a\tb\n1\t2\n3\t4\n");
	my $aoh = read_table($f, 'auto.row.names' => 1);
	is_deeply($aoh, [ { a => 1, b => 2 }, { a => 3, b => 4 } ],
		'auto: aligned file untouched (only a one-field-short header triggers)');
}

# 7) R col.names=NA output (blank leading header) still works with NO flag
{
	my $f = write_tmp_tsv("\tmpg\tcyl\nMazda RX4\t21\t6\n");
	my $aoh = read_table($f);
	is($aoh->[0]{row_name}, 'Mazda RX4', 'col.names=NA: empty header becomes row_name');
	is($aoh->[0]{mpg}, 21, 'col.names=NA: columns aligned');
}

# 8) a genuinely ragged row (two extra fields) still croaks even with the flag
{
	my $f = write_tmp_tsv("a\tb\n1\t2\t3\t4\n");
	throws_ok { read_table($f, 'auto.row.names' => 1) }
		qr/Alignment error/,
		'auto: a 2-extra-field row still croaks (only +1 is special)';
}

done_testing;
