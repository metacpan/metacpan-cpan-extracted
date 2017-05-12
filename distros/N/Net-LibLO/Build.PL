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

# Check for liblo
my $liblo_version = `$pkgconfig --modversion liblo`;
chomp($liblo_version);
if ($liblo_version !~ /^\d+\.\d+/) {
	print STDERR $liblo_version;
	exit -1;
} else {
	print "Found liblo library version $liblo_version.\n";
}

# Is it new enough ?
if ($liblo_version < 0.23) {
	die "Error: LibLO Version 0.23 or higher is required.\n";
}

# Get LibLO CFLAGS
my $LIBLO_CFLAGS = `$pkgconfig --cflags liblo`;
chomp( $LIBLO_CFLAGS );
print " LIBLO_CFLAGS = $LIBLO_CFLAGS\n";

# Get LibLO LIBS
my $LIBLO_LIBS = `$pkgconfig --libs liblo`;
chomp( $LIBLO_LIBS );
print " LIBLO_LIBS = $LIBLO_LIBS\n";





# Create the Build script
my $build = Module::Build->new
(
	module_name => 'Net::LibLO',
	license => 'gpl',
	build_requires => {
		'Module::Build' => '0.20'
	},
	
	create_makefile_pl => 'passthrough',
	
	requires => {
		'Test' => '1.00',
		'Test::More' => 0,
	},

        # Optional modules
	recommends => {
		'Test::Pod' => '1.00',
	},
	
	extra_compiler_flags => $LIBLO_CFLAGS,
	extra_linker_flags => $LIBLO_LIBS,
);

$build->create_build_script;


