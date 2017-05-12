package PITA::Host;

# Implements a single PITA Testing Host.
# Responsible for managing images and processing Requests

use 5.008;
use strict;
use Carp             ();
use File::Spec       ();
use File::Remove     ();
use File::Find::Rule ();
use Archive::Extract ();

use constant FFR => 'File::Find::Rule';

our $VERSION = '0.60';





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check we have a long term image storage
	my $image_store = $self->image_store;
	unless ( $image_store ) {
		Carp::croak("No image_store provided for PITA::Host");
	}
	unless ( -d $image_store and -w _ ) {
		Carp::croak("No image_store '$image_store' found, or insufficient permissions");
	}

	# Check we have a short term expanded image cache.
	# This is also where the live images are.
	my $image_cache = $self->image_cache;
	unless ( $image_cache ) {
		Carp::croak("No image_cache provided for PITA::Host");
	}
	unless ( -d $image_cache and -w _ ) {
		Carp::croak("No image_cache '$image_cache' found, or insufficient permissions");
	}

	# Check the quote for the cache
	$self->{image_cache_quota} = 2048 unless $self->image_cache_quota; # 2 gig default
	unless ( _POSINT($self->image_cache_quota) ) {
		Carp::croak("Invalid image_cache_quota. Not a positive integer");
	}

	$self;
}

sub image_store {
	$_[0]->{image_store};
}

sub image_cache {
	$_[0]->{image_cache};
}

sub image_cache_quota {
	$_[0]->{image_cache_quota};
}





#####################################################################
# Image and Cache Management

sub image_extract {
	my $self = shift;
	my $name = shift;

	# What are we extracting to where
	my $from = File::Spec->catfile(
		$self->image_store, "$name.img.gz",
	);
	my $to = File::Spec->catfile(
		$self->image_cache, "$name.img",
	);

	# Extract the compressed image
	local $Archive::Extract::PREFER_BIN = 1;
	my $archive = Archive::Extract->new( archive => $from, type => 'gz' );
	unless ( $archive ) {
		Carp::croak("Failed to create Archive::Extract for $from");
	}
	unless ( $archive->extract( to => $to ) ) {
		Carp::croak("Failed to extract archive to $to");
	}

	1;
}

sub image_cache_clear {
	my $self = shift;

	# Find all image files
	my @files = FFR->file
	               ->name( '*.img' )
	               ->in( $self->image_cache );

	# Delete all image files
	foreach my $file ( @files ) {
		File::Remove::remove( $file )
			or Carp::croak("Failed to delete $file");
	}

	1;
}

sub image_cache_apply_quota {
	my $self = shift;

	# Find the list of expanded files (recent to oldest)
	my @files = FFR->file
	               ->name( '*.img' )
	               ->in( $self->image_cache );
	@files = map { [ stat($_), $_ ] } @files;
	@files = sort { $a->[8] <=> $b->[8] } @files;

	# Keep files from youngest to oldest, and then
	# kill the rest.
	my $quota = $self->image_cache_quota;
	foreach my $file ( @files ) {
		$quota -= $file->[7];
		next if $quota >= 0;
		File::Remove::remove($file->[-1])
			or Carp::croak("Failed to delete $file->[-1]");
	}

	1;
}

1;
