package Mirror::URI;

use 5.006;
use strict;
use Carp         ();
use File::Spec   ();
use Time::HiRes  ();
use Time::Local  ();
use URI          ();
use URI::file    ();
use URI::http    ();
use Params::Util qw{ _STRING _POSINT _ARRAY0 _INSTANCE };
use LWP::Simple  ();

# Time values have an extra 5 minute fudge factor
use constant ONE_DAY     => 86700;
use constant TWO_DAYS    => 172800;
use constant THIRTY_DAYS => 2592000;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.90';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Clean up params
	$self->{class} = $class;
	$self->{valid} = !! $self->valid;
	if ( $self->valid ) {
		if ( _STRING($self->master) ) {
			$self->{master} = URI->new( $self->master );
		}
		unless ( _INSTANCE($self->master, 'URI') ) {
			Carp::croak("Missing or invalid 'master' value");
		}
		if ( _STRING($self->{timestamp}) and ! _POSINT($self->{timestamp}) ) {
			unless ( $self->{timestamp} =~ /^(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)Z$/ ) {
				Carp::croak("Invalid timestamp format");
			}
			$self->{timestamp} = Time::Local::timegm( $6, $5, $4, $3, $2 - 1, $1 );
		}
		if ( $self->{filename} and $self->{filename} ne $self->filename ) {
			Carp::croak("Invalid or unsupported offset '$self->{filename}'");
		}
		my $mirrors = $self->{mirrors};
		unless ( _ARRAY0($mirrors) ) {
			croak("Invalid mirror list");
		}
		foreach my $i ( 0 .. $#$mirrors ) {
			next unless _STRING($mirrors->[$i]);
			$mirrors->[$i] = URI->new( $mirrors->[$i] );
		}
	}

	return $self;
}

sub filename {
	my $class = ref($_[0]) || $_[0];
	die("$class does not implement filename");
}

sub class {
	$_[0]->{class};
}

sub version {
	$_[0]->{version};
}

sub uri {
	$_[0]->{uri};
}

sub name {
	$_[0]->{name};
}

sub master {
	$_[0]->{master};
}

sub timestamp {
	$_[0]->{timestamp};
}

sub mirrors {
	return ( @{ $_[0]->{mirrors} } );
}

sub valid {
	$_[0]->{valid};
}

sub lastget {
	$_[0]->{lastget};
}

sub lag {
	$_[0]->{lag};
}

sub age {
	$_[0]->{lastget} - $_[0]->{timestamp};
}

sub as_string {
	$_[0]->uri->as_string;
}

sub is_cached {
	$_[0]->uri->isa('URI::file');
}

sub is_master {
	my $self = shift;
	return (
		! $self->valid 
		and
		$self->as_string eq $self->uri->as_string
	);
}





#####################################################################
# Load Methods

sub read {
	my $class = shift;

	# Check the file to read
	my $root = shift;
	unless ( defined _STRING($root) and -d $root ) {
		Carp::croak("Directory '$root' does not exist");
	}

	# Convert to a usable URI
	my $uri = URI::file->new(
		File::Spec->canonpath(
			File::Spec->rel2abs($root)
		)
	)->canonical;

	# In a URI a directory must have an explicit trailing slash
	$uri->path( $uri->path . '/' );

	# Hand off to the URI fetcher
	return $class->get( $uri, dir => $root, @_ );
}

sub get {
	my $class = shift;

	# Check the URI
	my $base = shift;
	unless ( _INSTANCE($base, 'URI') ) {
		Carp::croak("Missing or invalid URI");
	}
	unless ( $base->path =~ /\/$/ ) {
		Carp::croak("URI must have a trailing slash");
	}

	# Find the file within the root path
	my %self = (
		uri => URI->new($class->filename)->abs($base)->canonical,
	);

	# Pull the file and time it
	$self{lastget} = Time::HiRes::time;
	$self{string}  = LWP::Simple::get($self{uri});
	$self{lag}     = Time::HiRes::time - $self{lastget};
	unless ( defined $self{string} ) {
		return $class->new( %self, valid => 0 );
	}

	# Parse the file
	my $hash = $class->parse( $self{string} );
	unless ( ref $hash eq 'HASH' ) {
		return $class->new( %self, valid => 0 );
	}

	$class->new( %$hash, %self, valid => 1 );
}





#####################################################################
# Populate Elements

sub get_master {
	my $self = shift;
	if ( _INSTANCE($self->master, 'URI') ) {
		# Load the master
		my $master = $self->class->get($self->master);
		$self->{master} = $master;
	}
	return $self->master;
}

sub get_mirror {
	my $self = shift;
	my $i    = shift;
	my $uri  = $self->{mirrors}->[$i];
	unless ( defined $uri ) {
		Carp::croak("No mirror with index $i");
	}
	if ( _INSTANCE($uri, 'URI') ) {
		my $mirror = $self->class->get($uri);
		$self->{mirrors}->[$i] = $mirror;
	}
	return $self->{mirrors}->[$i];
}





#####################################################################
# High Level Methods

sub update {
	my $self = shift;

	# Handle various shortcuts
	unless ( $self->valid ) {
		Carp::croak("Cannot update invalid mirror");
	}
	if ( $self->is_master ) {
		return 1;
	}

	# Pull the master and overwrite ourself with it
	my $master = $self->get_master;
	unless ( _INSTANCE($master, $self->class) ) {
		Carp::croak("Failed to fetch master record");
	}

	# Overwrite the current version with the master
	foreach ( qw{
		version uri name lastget timestamp
		mirrors lag valid master
	} ) {
		$self->{$_} = delete $master->{$_};
	}

	return 1;
}

# Get all the mirrors
sub get_mirrors {
	my $self    = shift;
	my $mirrors = $self->{mirrors};
	foreach ( 0 .. $#$mirrors ) {
		$self->get_mirror($_);
	}
	return 1;
}

1;

__END__

=pod

=head1 NAME

Mirror::URI - Mirror Configuration and Auto-Discovery

=head1 DESCRIPTION

B<Mirror::URI> is an abstract base class for the mirror
auto-discovery modules L<Mirror::YAML> and L<Mirror::JSON>.

See their documentation for more details.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mirror-URI>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Mirror::YAML>, L<Mirror::JSON>, L<Mirror::CPAN>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
