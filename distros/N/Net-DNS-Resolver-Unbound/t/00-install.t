#!/usr/bin/perl
#

use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Find;
use File::Spec;
use IO::File;
use Test::More;


my %manifest;
my $handle = IO::File->new( 'MANIFEST', '<' ) or BAIL_OUT("MANIFEST: $!");
while (<$handle>) {
	my ($filename) = split;
	$manifest{$filename}++;
}
close $handle;

plan skip_all => 'No versions from git checkouts' if -e '.git';

plan skip_all => 'Not sure how to parse versions.' unless eval { MM->can('parse_version') };

plan tests => scalar keys %manifest;


foreach ( sort keys %manifest ) {				# reconcile files with MANIFEST
	next unless ok( -f $_, "file exists\t$_" );
	next unless /\.pm$/;
	next unless /^lib/;

	my $module = File::Spec->catfile( 'blib', $_ );		# library component
	diag("Missing module: $module") unless -f $module;

	my $version = MM->parse_version($_);			# module version
	diag("\$VERSION = $version\t$_") unless $version =~ /^\d/;
}


my @files;							# flag MANIFEST omissions
find( sub { push( @files, $File::Find::name ) if /\.pm$/ }, 'lib' );
foreach ( sort @files ) {
	diag("Filename not in MANIFEST: $_") unless $manifest{$_};
}


exit;

__END__

