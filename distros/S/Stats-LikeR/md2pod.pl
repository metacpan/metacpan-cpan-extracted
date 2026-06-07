#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Markdown::To::POD 'markdown_to_pod';
use List::MoreUtils 'first_index';

sub file2string ($file) {
	open my $fh, '<', $file;
	return do { local $/; <$fh> };
}

# Helper to build an HTML table from extracted Markdown rows
sub table_to_html {
	my ($header, $sep, $body_ref) = @_;
	my $html = "<table>\n";

	# Process header
	$html .= "<thead>\n<tr>\n";
	my @headers = split /\|/, $header;
	# Clean empty elements if the row was wrapped in leading/trailing pipes
	shift @headers if @headers && $headers[0] =~ /^\s*$/ && $header =~ /^\s*\|/;
	pop @headers   if @headers && $headers[-1] =~ /^\s*$/ && $header =~ /\|\s*$/;
	for my $h (@headers) {
	  $h =~ s/^\s+|\s+$//g;
	  $html .= "  <th>$h</th>\n";
	}
	$html .= "</tr>\n</thead>\n<tbody>\n";
	# Process body
	for my $row (@$body_ref) {
		$html .= "<tr>\n";
		my @cells = split /\|/, $row;
		shift @cells if @cells && $cells[0] =~ /^\s*$/ && $row =~ /^\s*\|/;
		pop @cells   if @cells && $cells[-1] =~ /^\s*$/ && $row =~ /\|\s*$/;

		for my $c (@cells) {
			$c =~ s/^\s+|\s+$//g;
			# Convert Markdown inline formatting so it renders correctly inside the HTML block
			$c =~ s/`([^`]+)`/<code>$1<\/code>/g;
			$c =~ s/\*\*([^\*]+)\*\*/<b>$1<\/b>/g;
			$c =~ s/\*([^\*]+)\*/<i>$1<\/i>/g;
			$html .= "  <td>$c</td>\n";
		}

		# Pad with empty cells if a row was missing trailing pipes
		while (@cells < @headers) {
			$html .= "  <td></td>\n";
			push @cells, "";
		}
		$html .= "</tr>\n";
	}
	$html .= "</tbody>\n</table>\n";

	# Ensure blank lines around the =begin and =end directives for valid POD
	return "\n\n=begin html\n\n$html\n=end html\n\n";
}

# Pre-processor to extract GFM tables and replace them with alphanumeric placeholders
sub extract_and_convert_tables {
	my ($text) = @_;
	my @lines = split /\n/, $text;
	my @out;
	my @saved_tables;
	my $i = 0;

	while ($i < @lines) {
	  # Look for a table header followed by a standard GFM separator row
	  if ($i + 1 < @lines &&
		   $lines[$i] =~ /\|/ &&
		   $lines[$i+1] =~ /^[ \t]*\|?[ \t]*:?-+[-: \t]*\|/) {

		   my $header = $lines[$i];
		   my $sep = $lines[$i+1];
		   my @body;
		   $i += 2;

		   # Consume consecutive data rows (must contain at least one pipe)
		   while ($i < @lines && $lines[$i] =~ /\|/) {
		       push @body, $lines[$i];
		       $i++;
		   }

		   my $html = table_to_html($header, $sep, \@body);
		   push @saved_tables, $html;
		   # Use an alphanumeric placeholder to prevent Markdown parser interference
		   push @out, "\n\nHTMLTABLEPLACEHOLDER" . ($#saved_tables) . "\n\n";
	  } else {
		   push @out, $lines[$i];
		   $i++;
	  }
	}
	return (join("\n", @out), \@saved_tables);
}

my $md = file2string('README.md');

# 1. Pre-process the Markdown to convert GFM tables into POD HTML blocks
my ($md_processed, $tables_ref) = extract_and_convert_tables($md);

# 2. Convert standard markdown to POD
my $pod = markdown_to_pod($md_processed);

# 3. Restore the HTML tables back into the generated POD
for my $idx (0 .. $#$tables_ref) {
	my $table_html = $tables_ref->[$idx];
	# Anchor the end of the number with \b: without it the /g replace for a
	# short index (e.g. 1) also matches the prefix of longer placeholders
	# (HTMLTABLEPLACEHOLDER10, ...11), dropping the wrong table there and
	# leaving a stray leftover digit. \b stops after the last digit, so
	# HTMLTABLEPLACEHOLDER1 no longer matches inside HTMLTABLEPLACEHOLDER10.
	$pod =~ s/HTMLTABLEPLACEHOLDER${idx}\b/$table_html/g;
}

my @pod = split /\n/, $pod;
unshift @pod, "=encoding utf8\n";

say 'Writing read.me.pod from README.md, which must be copied into lib/Stats/LikeR.pm';
open my $fh, '>', 'read.me.pod';
say $fh join ("\n", @pod);
close $fh;

my $lib = file2string('lib/Stats/LikeR.pm');
my @lib = split /\n/, $lib;
my $line = first_index {$_ eq '1;'} @lib;
if ($line == -1) {
	die 'Could not find correct line index';
}

# Trim everything after `1;` to prep for new POD insertion
splice @lib, 1-(scalar @lib - $line);
push @lib, @pod; 

open my $out_fh, '>', 'lib/Stats/LikeR.pm';
say $out_fh join ("\n", @lib);
close $out_fh;
