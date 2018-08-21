#!/usr/bin/perl
use warnings;
use strict;

use Test::More;

use File::Find;

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
my @win32_modules;
my @GT_modules;

foreach my $file (@files) {
    ($file) = $file =~ m|^lib/(.*)\.pm$|;
    $file =~ s|/|::|g;
    if ($file =~ /Win32/) {  # require Windows system to run
	                     # not currently under lib/ anyway
        push @win32_modules, $file;
        next;
    }
    if ($file =~ /_GT$/) {   # require Graphics::TIFF be installed
	                     # but rarely is on test platforms
        push @GT_modules, $file;
        next;
    }
    use_ok($file);
}

# special message and automatic pass for skipped-over modules
TODO: {
    local $TODO = q{Win32 modules currently die when "use"d on non-Win32 platforms, _GT modules die if no Graphics::TIFF installed};

    foreach my $file (@win32_modules) {
        ok($file);
    }
    foreach my $file (@GT_modules) {
        ok($file);
    }
}

1;
