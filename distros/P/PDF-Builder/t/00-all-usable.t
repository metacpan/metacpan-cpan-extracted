#!/usr/bin/perl
use warnings;
use strict;

use Test::More;
use File::Find;

my $GrTFversion = 16;    # minimum version of Graphics::TIFF
my $LpngVersion = 0.57;  # minimum version of Image::PNG::Libpng

# Test all of the modules to make sure that a simple "use Module"
# won't result in a crash.

# first, build files list of all .pm under lib/
my @files;
find(\&add_to_files, 'lib');

sub add_to_files {
    return unless -f $_;
    return unless $_ =~ /\.pm$/;
    push @files, $File::Find::name;
    return;
}

plan tests => scalar @files;

# test each one, skipping over certain name patterns
my @opt_modules;

foreach my $file (@files) {
    ($file) = $file =~ m|^lib/(.*)\.pm$|;
    $file =~ s|/|::|g;
    if ($file =~ /Win32/) {  # require Windows system to run
	                     # not currently under lib/ anyway
#	"SKIP Windows module(s) not currently used"
#       next;
    }
    if ($file =~ /_GT$/) {   # require Graphics::TIFF be installed
	                     # but rarely is on test platforms
	# check for Graphics::TIFF installed, and if so, run use test
        my $rc = eval {
        	require Graphics::TIFF;
        	1;
    	};
    	if (!defined $rc) { $rc = 0; }  # else is 1
    	if ($rc) {
                if ($Graphics::TIFF::VERSION < $GrTFversion) { 
			# installed, but back-level... skip
			push @opt_modules, $file; 
			next; 
		}
		# fall through to use test
	} else {
		push @opt_modules, $file;
 		next;
	}
    }
    if ($file =~ /_IPL$/) {  # require Image::PNG::Libpng be installed
	                     # but rarely is on test platforms
	# check for Image::PNG::Libpng installed, and if so, run use test
        my $rc = eval {
        	require Image::PNG::Libpng;
        	1;
    	};
    	if (!defined $rc) { $rc = 0; }  # else is 1
    	if ($rc) {
                if ($Image::PNG::Libpng::VERSION < $LpngVersion) { 
			# installed, but back-level... skip
			push @opt_modules, $file; 
			next; 
		}
		# fall through to use test
	} else {
		push @opt_modules, $file;
 		next;
	}
    }
    # HarfBuzz::Shaper is built into Content.pm, doesn't have its own module
    use_ok($file);
}

# special message and automatic pass for skipped-over modules
TODO: {
    local $TODO = q{skipped due to optional library not installed};

    foreach my $file (@opt_modules) {
	    ok(1, $file);
    }
}

1;
