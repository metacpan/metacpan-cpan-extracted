# perl
# rename_subs.pl --- 
# Author:  <peiner@duelx83.ad.ree.renesas.com>
# Created: 14 May 2014
# Version: 0.01

use warnings;
use strict;

use v5.10;

use FileHandle;

use File::Path qw(make_path);

my $file = 'rename_subs.txt';
my $dir  = 'Report';

my @files;

# push (@files, `find $dir -type f -print`;
# push (@files, `find $dir -name "*.p[lm]" -print`);
# push (@files, `find $dir -name "*.t" -print`);
# push (@files, `find $dir -name "*.bat" -print`);
# push (@files, `find $dir -name "*.sh" -print`);
push (@files, `find $dir -name "*.html" -print`);
# print join ("\n", 

require 'rename_list.pl';

my %sub_replacement = get_converter();

sub replace_name {
	my $name = shift;

	return $sub_replacement{$name} if defined $sub_replacement{$name};

	return $name;
}

foreach my $file (@files) {
	chomp $file;
	my $fh_inp = new FileHandle($file);

	unless ($fh_inp) {
		say "# can't read file $file: $!";
		next;
	}

	my $out_file = "converted_files/$file";

	my $new_path = $out_file;
	$new_path =~ s/[^\/]+$//o;
	say "$new_path";
	make_path($new_path) unless -d $new_path;

	my $fh_outp = new FileHandle(">$out_file");

	unless ($fh_outp) {
		say "# can't write file $out_file: $!";
		next;
	}

	say "# Convert file $file -------------------------------------- ";
	
	#my $contents = do { local $/; <$fh> };

	foreach (<$fh_inp>) {
		my $line = $_;
		$line =~ s/(\w+)/replace_name($1)/eog;
		# print $line;
		print $fh_outp $line;
	}

	next;
}

