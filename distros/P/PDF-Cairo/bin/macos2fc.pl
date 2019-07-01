#!/usr/bin/env perl
#
# create a directory full of symlinks and a fontconfig XML config file
# pointing to it, to support all active MacOS fonts, not just the ones
# in the short list of directories that Fontconfig typically searches.
# Run "fc-list | wc -l" before and after to confirm that it succeeded.

use strict;
use warnings;
use utf8::all;
use File::Path qw(make_path remove_tree);

my $DIR = "$ENV{HOME}/.config/fontconfig";
my $NAME = "mac-activated-fonts";
make_path($DIR);
chdir($DIR) or die "$0: $DIR: $!\n";
make_path("conf.d", "$NAME-new");

open(my $Out, ">", "conf.d/00-$NAME.conf-new");
print $Out <<EOF;
<?xml version='1.0'?>
<!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
<fontconfig>
 <dir>$DIR/$NAME</dir>
</fontconfig>
EOF
close($Out);

open(my $In, "-|", "/usr/sbin/system_profiler SPFontsDataType");
my @fonts;
my $currfont = {};
while (<$In>) {
	chomp;
	s/^( *)//;
	my $indent = length($1);
	if ($indent == 4) {
		# ignore resource-fork PS fonts with no file extension
		if ($currfont->{filename} and $currfont->{filename} =~ /^.+\./
				and $currfont->{location} !~ m(/Library/Fonts/)) {
			push(@fonts, $currfont);
		}
		s/:\s*$//;
		$currfont = { filename => $_ };
	}
	next unless $currfont->{filename};
	if ($indent == 6) {
		if (/^(Enabled: No|Kind: Bitmap)/) {
			$currfont = {};
			next;
		}
		if (/^Location: (.*)$/) {
			$currfont->{location} = $1;
		}elsif (/^Kind: (.*)$/) {
			$currfont->{kind} = $1;
		}
	}elsif ($indent == 8) {
		s/:\s*$//;
		$currfont->{fonts} = []
			unless ref $currfont->{fonts} eq "ARRAY";
		push(@{$currfont->{fonts}}, { name => $_});
	}elsif ($indent == 10) {
		my @tmp = @{$currfont->{fonts}};
		if (my ($key, $val) = /^(Full Name|Family|Style): (.*)$/) {
			$key =~ tr/ A-Z/_a-z/;
			$tmp[$#tmp]->{$key} = $val;
		}
	}else{
		next;
	}
}
close($In);
push(@fonts, $currfont);

open($Out, ">", "$NAME-new/README.txt")
	or die "$0: $DIR/$NAME-new/README.txt: $!";
print $Out "#\n#filename[,index]\tfull name\tfamily\tstyle\n#\n";
foreach my $file (sort { $a->{filename} cmp $b->{filename} } @fonts) {
	my $filename = $file->{filename};
	$filename =~ s/^\.//; # Adobe Typekit fonts have leading "."
	symlink($file->{location}, "$NAME-new/$filename");
	if (@{$file->{fonts}} == 1) {	
		my $font = $file->{fonts}->[0];
		print $Out join("\t", $filename, $font->{full_name},
			$font->{family}, $font->{style}), "\n";
	}else{
		# system_profiler does not report the contents of
		# a multi-font container in index order. For more
		# fun, Apple ships multi-font files with a .ttf
		# extension, where the index values are byte offsets
		# (ex: /Library/Fonts/Skia.ttf)
		open(my $In, "-|", qq(fc-scan -f '%{index}\t%{fullname}\t%{family}\t%{style}\t%{fullnamelang}\t%{familylang}\t%{stylelang}\n' $file->{location}));
		my @tmp;
		while (<$In>) {
			chomp;
			my ($index, $fullname, $family, $style, $fullnamelang, $familylang, $stylelang) = split(/\t/);
			# try to find the English names...
			if ($fullname =~ /,/) {
				my $i = 0;
				foreach my $lang (split(/,/, $fullnamelang)) {
					last if $lang eq 'en';
					$i++;
				}
				my @tmp = split(/,/, $fullname);
				$fullname = $tmp[$i];
			}
			if ($family =~ /,/) {
				my $i = 0;
				foreach my $lang (split(/,/, $familylang)) {
					last if $lang eq 'en';
					$i++;
				}
				my @tmp = split(/,/, $family);
				$family = $tmp[$i];
			}
			if ($style =~ /,/) {
				my $i = 0;
				foreach my $lang (split(/,/, $stylelang)) {
					last if $lang eq 'en';
					$i++;
				}
				my @tmp = split(/,/, $style);
				$style = $tmp[$i];
			}
			push(@tmp, {
				index => $index,
				full_name => $fullname,
				family => $family || "",
				style => $style || "",
			});
		}
		close($In);
		foreach my $font (sort { $a->{index} <=> $b->{index}} @tmp) {
			print $Out $filename;
			print $Out "," . $font->{index} if $font->{index} > 0;
			print $Out "\t", join("\t", $font->{full_name},
				$font->{family}, $font->{style}), "\n";
		}
	}
}
close($Out);

remove_tree("conf.d/00-$NAME.conf", "$NAME");
rename("$NAME-new", $NAME);
rename("conf.d/00-$NAME.conf-new", "conf.d/00-$NAME.conf");

exit 0;
