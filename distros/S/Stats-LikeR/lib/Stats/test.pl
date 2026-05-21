#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';

sub read_table {
	my $file = shift;
	die "\"$file\" is either unreadable or not a file" unless -r -f $file;
	my %args = (
		sep => ',', comment => '#',
		@_,
	);
	my %allowed_args = map {$_ => 1} (
		'comment', #character to skip lines after the header
		'row.name',
		'sep', # by default ","
		'substitutions',
		'output.type'
	);
	my @undef_args = sort grep {!$allowed_args{$_}} keys %allowed_args;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1];
	if (scalar @undef_args > 0) {
		p @undef_args;
		die "the above args aren't defined for $current_sub";
	}
	# ... (argument validation logic from your original script) ...
	$args{'output.type'} = $args{'output.type'} // 'aoh';
	if ($args{'output.type'} !~ m/^(?:aoh|hoa)$/) {
		die "\"$args{'output.type'}\" isn't allowed";
	}
	$args{comment} = $args{comment} // '#';
	my (@data, %data, @header);
	open my $txt, '<', $file;
	while (<$txt>) {
		next if $_ =~ m/^$args{comment}/;
		next if /^\h*$/; # Skip empty lines
		$_ =~ s/\r?\n$//; # chomp with annoying and invisible Windows "\r"
		# Apply substitutions if any
		foreach my $sub (@{ $args{substitutions} // [] }) {
			$_ =~ s/$sub->[0]/$sub->[1]/g;
		}
		# Use -1 to keep trailing empty fields
		my @line = split /$args{sep}/, $_;
		if ($. == 1) {
			# --- HEADER PROCESSING ---
			foreach my $cell (@line) {
				$cell =~ s/^#//;      # Remove comment prefix if present
				$cell =~ s/"$//; # Strip surrounding quotes 
				$cell =~ s/^"//;
				$cell =~ s/\"\"/\"/g;  # Un-escape doubled quotes 
			}
			# FIX: Instead of grep, only remove trailing empty fields
			# that might exist due to a trailing separator.
			while (@line && $line[-1] eq '') { pop @line }
			@header = @line; 
			# R-LIKE BEHAVIOR: If the first header is blank (like in HepatitisCdata.csv),
			# give it a name so it can be used as a hash key for the index column.
			if ((scalar @header > 0) && ($header[0] eq '')) {
				$header[0] = 'row_name'; 
			}
			next;
		}
		# Check for column alignment
		if (scalar @line != scalar @header) {
			warn "Alignment error on $file line $. (" . scalar(@line) . " fields vs " . scalar(@header) . " headers).";
			next;
		}
		# --- DATA PROCESSING ---
		my %line;
		for my $i (0 .. $#header) {
			my $cell = $line[$i];
			# Strip quotes and handle un-escaping for data fields 
			if (defined $cell) {
				$cell =~ s/^\"|\"$//g;
				$cell =~ s/\"\"/\"/g;
				$cell =~ s/"$//;
				$cell =~ s/^"//;
			}
			# R-like behavior: Treat empty strings as 'NA' 
			$line{$header[$i]} = ($cell eq '') ? 'NA' : $cell;
		}
		if ($args{'output.type'} eq 'aoh') {
			push @data, \%line;
		} elsif ($args{'output.type'} eq 'hoa') {
			foreach my $col (@header) {
				push @{ $data{$col} }, $line{$col};
			}
		} elsif ($args{'output.type'} eq 'hoh') {
			
		}
	}
	close $txt;
	if ($args{'output.type'} eq 'aoh') {
		return \@data;
	} elsif ($args{'output.type'} =~ m/^(?:hoa|hoh)$/) {
		return \%data;
	}
}
my $t = read_table( 'HepatitisCdata.csv');
p $t;
$t = read_table( 'HepatitisCdata.csv', 'output.type' => 'hoa');
p $t;
