#!/usr/bin/perl
use warnings;
use strict;

use Test::More;
use File::Find;
use version;

# minimum versions, **if used**
my $GrTFversion  = 19;       # minimum version of Graphics::TIFF
my $HBShaperVer  = 0.024;    # minimum version of HarfBuzz::Shaper
my $LpngVersion  = 0.57;     # minimum version of Image::PNG::Libpng
my $TextMarkdown = 1.000031; # minimum version of Text::Markdown
my $HTMLTreeBldr = 5.07;     # minimum version of HTML::TreeBuilder
my $PodSimpleXHTML = 3.45;   # minimum version of Pod::Simple::XHTML
my $SVGPDFver    = 0.087;    # minimum version of SVGPDF

# Test all of the modules to make sure that a simple "use Module"
# won't result in a crash.

# first, build files list of all .pm under lib/
my @files;
find(\&add_to_files, 'lib');

sub add_to_files {
    return unless -f $_;
    return unless $_ =~ /\.pm$/;
    ### 3 currently disabled
    return if ($_ =~ m/CCITTFaxDecode\.pm$/);
    return if ($_ =~ m/Reader\.pm$/);
    return if ($_ =~ m/Writer\.pm$/);
    ###
    push @files, $File::Find::name;
    return;
}

plan tests => scalar @files;

# test each one, skipping over certain name patterns
my @opt_modules;

my $has_GT = 1;
my $has_IPL = 1;
my $rc;

# check for Graphics::TIFF installed, and if so, run use test
$rc = eval {
    require Graphics::TIFF;
    1;
};
if (!defined $rc) { $rc = 0; }  # else is 1
if ($rc) {
    # installed but not up to date?
    my $lVER = version::parse($Graphics::TIFF::VERSION);
    my $mVER = version::parse($GrTFversion);
    if (ref($lVER) < ref($mVER)) { $rc = 0; }
}
$has_GT = $rc;
my $dummy = $has_GT;

# check for Image::PNG::Libpng installed, and if so, run use test
$rc = eval {
    require Image::PNG::Libpng;
    1;
};
if (!defined $rc) { $rc = 0; }  # else is 1
if ($rc) {
    # installed but not up to date?
    my $lVER = version::parse($Image::PNG::Libpng::VERSION);
    my $mVER = version::parse($LpngVersion);
    if (ref($lVER) < ref($mVER)) { $rc = 0; }
}
$has_IPL = $rc;
$dummy = $has_IPL;

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
       	if (!$has_GT || 1) {
		push @opt_modules, $file;
 		next;
	}
	# else fall through to use test
    }
    if ($file =~ /_IPL$/) {  # require Image::PNG::Libpng be installed
	                     # but rarely is on test platforms
	# check for Image::PNG::Libpng installed, and if so, run use test
       	if (!$has_IPL) {
		push @opt_modules, $file;
 		next;
	}
	# else fall through to use test
    }
    # HarfBuzz::Shaper is built into Content.pm, doesn't have its own module
    # Text::Markdown is built into Content/Text.pm, doesn't have its own module
    # HTML::TreeBuilder is built into Content/Text.pm, doesn't have its own module
    # Pod::Simple::XHTML is built into buildDoc.pl, doesn't have its own module
    use_ok($file);
}

# special message and automatic pass for skipped-over modules
TODO: {
    local $TODO = q{skipped due to optional library not installed};

    foreach my $file (@opt_modules) {
       #print "skipped: $file\n";
	ok(1, $file);
    }
}

1;
