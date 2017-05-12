package Perl::Dist::Asset;

# Convenience base class for Perl::Dist assets

use 5.006;
use strict;
use warnings;
use Carp             'croak';
use File::Spec       ();
use File::Spec::Unix ();
use File::ShareDir   ();
use URI::file        ();
use Params::Util     qw{ _STRING _CODELIKE };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.16';
}

use Object::Tiny qw{
	parent
	file
	url
	share
	dist
};





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	unless ( $self->url ) {
		if ( $self->share ) {
			# Map share to url vis File::ShareDir
			my ($dist, $name) = split /\s+/, $self->share;
			$self->trace("Finding $name in $dist... ");
			my $file = File::Spec->rel2abs(
				File::ShareDir::dist_file( $dist, $name )
			);
			unless ( -f $file ) {
				croak("Failed to find $file");
			}
			$self->{url} = URI::file->new($file)->as_string;
			$self->trace(" found\n");

		} elsif ( $self->dist ) {
			# Map CPAN dist path to url
			my $dist = $self->dist;
			$self->trace("Using distribution path $dist\n");
			my $one  = substr( $self->dist, 0, 1 );
			my $two  = substr( $self->dist, 1, 1 );
			my $path = File::Spec::Unix->catfile(
				'authors', 'id', $one, "$one$two", $dist,
			);
			$self->{url} = URI->new_abs( $path, $self->cpan )->as_string;

		} elsif ( $self->can('name') and $self->name ) {
			# Map name to URL via the default package path
			$self->{url} = $self->parent->binary_url($self->name);
		}
	}

	# Check params
	unless ( _STRING($self->url) ) {
		croak("Missing or invalid url param");
	}

	# Create the filename from the url
	$self->{file} = $self->url;
	$self->{file} =~ s|.+/||;
	unless ( $self->file and length $self->file ) {
		croak("Missing or invalid file");
	}

	return $self;
}

sub cpan {
	$_[0]->parent->cpan;
}





#####################################################################
# Support Methods

sub trace {
	my $self = shift;
	if ( _CODELIKE($self->{trace}) ) {
		$self->{trace}->(@_);
	} else {
		print $_[0];
	}
}

1;
