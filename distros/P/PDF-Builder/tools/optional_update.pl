#!/usr/bin/perl
use warnings;
use strict;

# a utility to select which optional prerequisites to remove from the
# "recommends" list in Makefile.PL, META.json, and META.yml before manually
# running Makefile.PL to build the product. 
 
# Makefile.PL and META.yml
#  delete an option by #-out the line
#  restore an option by removing #
# META.json (does not support comments)
#  delete an option by erasing the line
#  restore an option by adding line back in

# t/00-all-usable.t and lib/PDF/Builder.pm, while also making use of the
# optional prerequisites, do not need to exclude unused optionals.

our $VERSION = '3.024'; # VERSION
our $LAST_UPDATE = '3.024'; # manually update whenever code is changed

# master list of optional prerequisites:
# make sure that any updates to patterns etc. keep the same order
my %options = (
	'1' => ["Graphics::TIFF",     "19"   ],
	'2' => ["Image::PNG::Libpng", "0.57" ],
	'3' => ["HarfBuzz::Shaper",   "0.024"],
              );

print "\nHere are the available optional libraries. Select 0 or more of\n";
print "them by entering their key numbers 1,2,3, etc. in a one-line list,\n";
print "separated by commas and/or spaces. Enter all numbers for the normal\n";
print "default of ALL selected:\n";

my ($i, $j, @list);
my $numEntries = scalar keys %options;
for ($i=1; $i<=$numEntries; $i++) {
	print "$i  $options{$i}[0]  (version $options{$i}[1])\n";
}
print "\nEnter any (or all) numbers to use: ";
my $input = <>;
if (length($input)) {
	@list = split /[\s,]+/, $input;
	# valid entries?
	for ($j=0; $j<scalar @list; $j++) {
		if ($list[$j] =~ m/^\d+$/ && 
		    $list[$j] <= $numEntries && 
		    $list[$j] > 0) {
			# valid number
		} else {
			die "Invalid entry '$list[$j]'!\n";
                }
	}
	# too many entries?
	if (scalar @list > $numEntries) {
		die "Too many entries!\n";
	}
	# duplicate entries?
	for ($i=0; $i<scalar @list; $i++) {
		for ($j=0; $j<$i; $j++) {
			if ($list[$i] == $list[$j]) {
				die "Duplicate entry at position $i!\n";
			}
		}
	}
} else {
	@list = ();
}
print "list: @list\n";

update_Makefile();
update_META_json();
update_META_yml();

# in all cases, remove "recommends" if @list is empty
# Makefile.PL find line and # out if not in @list, remove any # if in @list
sub update_Makefile {
    # file should be ./Makefile.PL
    my @pattern = (
	           "(\"Graphics::TIFF\"\\s*=>\\s*)[\\d.]+,", 
	           "(\"Image::PNG::Libpng\"\\s*=>\\s*)[\\d.]+,",
                   "(\"HarfBuzz::Shaper\"\\s*=>\\s*)[\\d.]+,",
	          );

    my $infile = "Makefile.PL";
    my $outtemp = "xxxx.tmp";
    my ($IN, $OUT);
    unless (open($IN, "<", $infile)) {
	die "Unable to read $infile for update\n";
    }
    unless (open($OUT, ">", $outtemp)) {
	die "Unable to write temporary output file for $infile update\n";
    }

    my ($line, $i);
    my $flag = 0;
    while ($line = <$IN>) {
	# $line still has line-end \n
	 
        # no optionals requested? #-out "recommends" => { and },
        if (!scalar(@list)) {
	    if ($line =~ m/^[^#]\s+"recommends" => \{/) {
		$flag = 1;
		$line = '#'.$line;
	    }
	    if ($flag && $line =~ m/},/) {
		$flag = 0;
		$line = '#'.$line;
	    }
	}

	# if there ARE optionals, un-# "recommends" and }
        if (scalar(@list)) {
	    if ($line =~ m/^#\s+"recommends" => \{/) {
		$flag = 1;
		$line = substr($line, 1);
	    }
	    if ($flag && $line =~ m/^#\s+},?/) {
		$flag = 0;
		$line = substr($line, 1);
	    }
	}
	
	for ($i=0; $i<$numEntries; $i++) {
	    if ($line =~ m/$pattern[$i]/) {
		if (member_of($i+1, @list)) {
		    # is in list, remove any leading #
		    if ($line =~ m/^#/) {
			$line =~ s/^#//;
		    }
		} else {
		    # is not in list, comment-out unless already done so
		    if ($line !~ m/^#/) {
			$line = '#'.$line;
		    }
	        }
		last;
	    }
	}
	print $OUT $line;
    }

    close($IN);
    close($OUT);
    system("copy $outtemp $infile");
    unlink($outtemp);

    return;
} # end of update_Makefile()

# META.json find line and remove if not in @list, add back in if in @list
sub update_META_json {
    # file should be ./META.json
    my @pattern = (
	           "(\"Graphics::TIFF\"\\s*:\\s*)\"[\\d.]+\"", 
	           "(\"Image::PNG::Libpng\"\\s*:\\s*)\"[\\d.]+\"",
                   "(\"HarfBuzz::Shaper\"\\s*:\\s*)\"[\\d.]+\"",
	          );

    my $infile = "META.json";
    my $outtemp = "xxxx.tmp";
    my ($IN, $OUT);
    unless (open($IN, "<", $infile)) {
	die "Unable to read $infile for update\n";
    }
    unless (open($OUT, ">", $outtemp)) {
	die "Unable to write temporary output file for $infile update\n";
    }

    my ($line, $i);
    my $flag = 0;
    while ($line = <$IN>) {
	# $line still has line-end \n
	 
	# NOTE: my understanding is that an empty { } is legal
        # remove lines in-between "recommends" and }[,] 
	# re-insert desired ones
	if ($line =~ m/"recommends"\s*:/) {
	    $flag = 1;
	} elsif ($flag && $line =~ m/},?/) {
	    $flag = 0;
	    # re-insert desired options before closing },
	    # $line still has }, in it waiting to be output
	    my $count = 0;
	    for ($i=1; $i<=$numEntries; $i++) {
		# is $i in @list? replace in file
		if (member_of($i, @list)) {
		    print $OUT "            \"$options{$i}[0]\" : \"$options{$i}[1]\"";
		    if (++$count == scalar(@list)) {
		        # last one, no comma
		        print $OUT "\n";
		    } else {
		        # not last one, add comma
		        print $OUT ",\n";
	            }
	        }
	    }
	} elsif ($flag) {
	    # erase this entry (all optional entries will be erased)
	    next;
	}
	print $OUT $line;
    }

    close($IN);
    close($OUT);
    system("copy $outtemp $infile");
    unlink($outtemp);

    return;
} # end of update_META_json()

# META.yml find line and # out if not in @list, remove any # if in @list
sub update_META_yml {
    # file should be ./Makefile.PL
    my @pattern = (
	           "(Graphics::TIFF:\\s*)'[\\d.]+'", 
	           "(Image::PNG::Libpng:\\s*)'[\\d.]+'",
                   "(HarfBuzz::Shaper:\\s*)'[\\d.]+'",
	          );

    my $infile = "META.yml";
    my $outtemp = "xxxx.tmp";
    my ($IN, $OUT);
    unless (open($IN, "<", $infile)) {
	die "Unable to read $infile for update\n";
    }
    unless (open($OUT, ">", $outtemp)) {
	die "Unable to write temporary output file for $infile update\n";
    }

    my ($line, $i);
    while ($line = <$IN>) {
	# $line still has line-end \n
	 
        # no optionals requested? #-out recommends:
        if (!scalar(@list)) {
	    if ($line =~ m/^[^#]\s*recommends:/) {
		$line = '#'.$line;
	    }
	}

	for ($i=0; $i<$numEntries; $i++) {
	    if ($line =~ m/$pattern[$i]/) {
		if (member_of($i+1, @list)) {
		    # is in list, remove any leading #
		    if ($line =~ m/^#/) {
			$line =~ s/^#//;
		    }
		} else {
		    # is not in list, comment-out unless already done so
		    if ($line !~ m/^#/) {
			$line = '#'.$line;
		    }
	        }
		last;
	    }
	}
	print $OUT $line;
    }

    close($IN);
    close($OUT);
    system("copy $outtemp $infile");
    unlink($outtemp);

    return;
} # end of update_META_yml()

sub member_of {
    my ($member, @list) = @_;

    if ($member ~~ @list) {
	return 1;
    } else {
	return 0;
    }
}
