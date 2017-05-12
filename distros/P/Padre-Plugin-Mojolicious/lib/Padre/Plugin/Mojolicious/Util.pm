package Padre::Plugin::Mojolicious::Util;

# ABSTRACT: Some code used all around the Plugin

use 5.008;
use strict;
use warnings;
use Cwd            ();
use File::Spec     ();
use File::Basename ();

our $VERSION = '0.06';

# get the Mojolicious project name, so we can
# figure out the development server's name
# TODO: make this code suck less
sub get_mojolicious_project_name {
	my $project_dir = shift;
	return unless $project_dir;

	require File::Spec;
	my @dirs         = File::Spec->splitdir($project_dir);
	my $project_name = lc( $dirs[-1] );
	$project_name =~ tr{-}{_};

	return $project_name;
}

sub find_file_from_output {
	my $filename    = shift;
	my $output_text = shift;

	$filename .= '.pm';

	if ( $output_text =~ m{\[write\] (.+$filename)} ) {
		return $1;
	} else {
		return; # sorry, not found
	}
}

sub get_document_base_dir {
	my $main     = Padre->ide->wx->main;
	my $doc      = $main->current->document;
	my $filename = $doc->filename;

	return unless $filename;

	# check for potential relative path on filename
	if ( $filename =~ m{\.\.} ) {
		require Cwd;
		$filename = Cwd::realpath($filename);
	}
	my $olddir = File::Basename::dirname($filename);
	my $dir    = $olddir;
	while (1) {

		# those are the test cases for a Mojolicious directory
		if (   -d File::Spec->catfile( $dir, 'script' )
			&& -d File::Spec->catfile( $dir, 'lib' )
			&& -d File::Spec->catfile( $dir, 'log' )
			&& -d File::Spec->catfile( $dir, 'public' )
			&& -d File::Spec->catfile( $dir, 't' )
			&& -d File::Spec->catfile( $dir, 'templates' ) )
		{
			return $dir;
		}
		$olddir = $dir;
		$dir    = File::Basename::dirname($dir);

		last if $olddir eq $dir;
	}
	return;
}

1;
