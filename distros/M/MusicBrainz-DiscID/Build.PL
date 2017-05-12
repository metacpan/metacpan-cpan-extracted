#!/usr/bin/perl
#

use Module::Build;
use strict;


# Check for pkg-config
my $pkgconfig = `which pkg-config`;
chomp($pkgconfig);
if ($pkgconfig !~ /pkg-config/ or 
    $pkgconfig =~ /not found/i)
{
	die "Error: pkgconfig is not available on your system\n".
	    "It is available from http://pkgconfig.freedesktop.org/\n";
} else {
	my $pkgconfig_version = `$pkgconfig --version`;
	chomp( $pkgconfig_version );
	print "Found pkg-config version $pkgconfig_version.\n";
}

# Display libdiscid version
my $libdiscid_version = `$pkgconfig --modversion libdiscid`;
chomp($libdiscid_version);
if ($libdiscid_version =~ /^\d+\.\d+/) {
	print "Found libdiscid library version $libdiscid_version.\n";
}

# Check libdiscid is new enough
my $status = system("$pkgconfig --atleast-version=0.2.2 libdiscid");
if ($status != 0) {
	die "Error: libdiscid version 0.2.2 or higher is required.\n";
}

# Get libdiscid CFLAGS
my $LIBDISCID_CFLAGS = `$pkgconfig --cflags libdiscid`;
chomp( $LIBDISCID_CFLAGS );
print " LIBDISCID_CFLAGS = $LIBDISCID_CFLAGS\n";

# Get libdiscid LIBS
my $LIBDISCID_LIBS = `$pkgconfig --libs libdiscid`;
chomp( $LIBDISCID_LIBS );
print " LIBDISCID_LIBS = $LIBDISCID_LIBS\n";




# Create the Build script
my $build = Module::Build->new
(
	module_name => 'MusicBrainz::DiscID',
	license => 'gpl',
	build_requires => {
		'Module::Build' => '0.20'
	},
	
	requires => {
		'Test' => '1.00',
		'Test::More' => 0,
	},

  # Optional modules
	recommends => {
		'Test::Pod' => '1.00',
	},
	
	extra_compiler_flags => $LIBDISCID_CFLAGS,
	extra_linker_flags => $LIBDISCID_LIBS,
);

$build->create_build_script;
