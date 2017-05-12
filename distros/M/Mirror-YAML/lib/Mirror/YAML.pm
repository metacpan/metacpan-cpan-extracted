package Mirror::YAML;

use 5.005;
use strict;
use Params::Util      qw{_STRING _POSINT _ARRAY0 _INSTANCE };
use YAML::Tiny        ();
use URI               ();
use Time::HiRes       ();
use Time::Local       ();
use LWP::Simple       ();
use Mirror::YAML::URI ();

use constant ONE_DAY     => 86700; # 1 day plus 5 minutes fudge factor
use constant TWO_DAYS    => 172800;
use constant THIRTY_DAYS => 2592000;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.03';
}





#####################################################################
# Wrapper for the YAML::Tiny methods

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	if ( _STRING($self->{uri}) ) {
		$self->{uri} = URI->new($self->{uri});
	}
	if ( _STRING($self->{timestamp}) and ! _POSINT($self->{timestamp}) ) {
		unless ( $self->{timestamp} =~ /^(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)Z$/ ) {
			return undef;
		}
		$self->{timestamp} = Time::Local::timegm( $6, $5, $4, $3, $2 - 1, $1 );
	}
	unless ( _ARRAY0($self->{mirrors}) ) {
		return undef;
	}
	foreach ( @{$self->{mirrors}} ) {
		if ( _STRING($_->{uri}) ) {
			$_->{uri} = URI->new($_->{uri});
			$_ = Mirror::YAML::URI->new( %$_ ) or return undef;
		}
	}
	return $self;
}

sub read {
	my $class = shift;
	my $yaml  = YAML::Tiny->read( @_ );
	$class->new( %{ $yaml->[0] } );
}

sub read_string {
	my $class = shift;
	my $yaml  = YAML::Tiny->read_string( @_ );
	$class->new( %{ $yaml->[0] } );
}

sub write {
	my $self = shift;
	$self->as_yaml_tiny->write( @_ );
}

sub write_string {
	my $self = shift;
	$self->as_yaml_tiny->write_string( @_ );
}

sub as_yaml_tiny {
	my $self = shift;
	my $yaml = YAML::Tiny->( { %$self } );
	if ( defined $yaml->{source} ) {
		$yaml->{source} = "$yaml->{source}";
	}
	$yaml;
}





#####################################################################
# Mirror::YAML Methods

sub name {
	$_[0]->{name};
}

sub uri {
	$_[0]->{uri};
}

sub timestamp {
	$_[0]->{timestamp};
}

sub age {
	$_[0]->{age} or time - $_[0]->{timestamp};
}

sub benchmark {
	$_[0]->{benchmark};
}

sub mirrors {
	@{ $_[0]->{mirrors} };
}





#####################################################################
# Main Methods

sub check_mirrors {
	my $self = shift;
	foreach my $mirror ( $self->mirrors ) {
		next if defined $mirror->{live};
		$mirror->get;
	}
	return 1;
}

# Does the mirror with the newest timestamp newer than ours
# have a different master? If so, update our master server.
# This lets us survive major reorgansations, as long as some
# of the existing mirrors are retained.
sub check_master {
	my $self = shift;

	# Make sure we have checked the mirrors
	$self->check_mirrors;

	# Anti-hijacking measure: Only do this if our current
	# age is more than 30 days. We can almost certainly
	# handle a 1 month changeover period, otherwise things
	# will only be bad for a month.
	if ( $self->age < THIRTY_DAYS ) {
		return 1;
	}

	# Find all the servers updated in the last 2 days.
	# All of them except 1 must agree (prevent hijacking,
	# and handle accidents or anti-update attack from older server)
	my %uri = ();
	map { $uri{$_->uri}++ } grep { $_->age >= 0 and $_->age < TWO_DAYS } $self->mirrors;
	my @uris = sort { $uri{$b} <=> $uri{$a} } keys %uri;
	unless ( scalar(@uris) <= 2 and $uris[0] and $uris[0] >= (scalar($self->mirrors) - 1) ) {
		# Data is weird or currupt
		return 1;
	}

	# Master has moved.
	# Pull the new master server mirror.yaml
	my $new_uri = Mirror::YAML::URI->new(
		uri => URI->new( $uris[0] ),
		) or return 1;
	$new_uri->get or return 1;

	# To avoid pulling a whole bunch of mirror.yml files again
	# copy any mirrors from our set to the new 
	my $new = $new_uri->yaml or return 1;
	my %old = map { $_->uri => $_ } $self->mirrors;
	foreach ( @{ $new->{mirrors} } ) {
		if ( $old{$_->uri} ) {
			$_ = $old{$_->uri};
		} else {
			$_->get;
		}
	}

	# Now overwrite ourself with the new one
	%$self = %$new;

	return 1;
}

# Select the "best" mirrors
sub select_mirrors {
	my $self   = shift;
	my $wanted = _POSINT(shift) || 3;

	# Check the mirrors
	$self->check_mirrors;

	# Start with the list of all live mirrors, and create
	# some interesting subsets.
	my @live    = sort { $a->lag <=> $b->lag     }
	              grep { $_->live                } $self->mirrors;
	my @current = grep { $_->yaml->age < ONE_DAY } @live;
	my @ideal   = grep { $_->lag < 2             } @current;

	# If there are enough fast and up-to-date mirrors
	# (which should be common for many people) return them.
	if ( @ideal >= $wanted ) {
		return map { $_->uri } @ideal[0 .. $wanted];
	}

	# If there are enough up-to-date mirrors
	# (which should be common) return them.
	if ( @current >= $wanted ) {
		return map { $_->uri } @current[0 .. $wanted];
	}

	# Are there ANY that are up to date
	if ( @current ) {
		return map { $_->uri } @current;
	}

	# Something is weird, just use the master site
	return ( $self->uri );
}

1;

__END__

=pod

=head1 NAME

Mirror::YAML - Mirror Configuration and Auto-Discovery

=head1 DESCRIPTION

A C<mirror.yml> file is used to allow a repository client to reliably and
robustly locate, identify, validate and age a repository.

It contains a timestamp for when the repository was last updated, the URI
for the master repository, and a list of all the current mirrors at the
time the repository was last updated.

B<Mirror::YAML> contains all the functionality requires to both create
and read the F<mirror.yml> files, and the logic to select one or more
mirrors entirely automatically.

It currently scales cleanly for a dozen or so mirrors, but may be slow
when used with very large repositories with a hundred or more mirrors.

=head2 Methodology

A variety of simple individual mechanisms are combined to provide a
completely robust discovery and validation system.

B<URI Validation>

The F<mirror.yml> file should exist in a standard location, typically at
the root of the repository. The file is very small (no more than a few
kilobytes at most) so the overhead of fetching one (or several) of them
is negligable.

The file is pulled via FTP or HTTP. Once pulled, the first three
characters are examined to validate it is a YAML file and not a
login page for a "captured hotspot" such as at hotels and airports.

The shorter ".yml" is used in the file name to allow for Mirror::YAML
to be used even in the rare situation of mirrors that must work
on operating systems with (now relatively rare) 8.3 filesystems.

B<Responsiveness>

Because the F<mirror.yml> file is small (in simple cases only one or two
packets) the download time can be used to measure the responsiveness of
that mirror.

By pulling the files from several mirrors, the comparative download
times can be used as part of the process of selecting the fastest mirror.

B<Timestamp>

The mirror.yml file contains a timestamp that records the last update time
for the repository. This timestamp should be updated every repository
update cycle, even if there are no actual changes to the repository.

Once a F<mirror.yml> file has been fetched correctly, the timestamp can
then be used to verify the age of the mirror. Whereas a perfectly up to
date mirror will show an age of less than an hour (assuming that the
repository master updates every hour) a repository that has stopped
updating will show an age that is greater than the longest mirror rate
plus the update cycle time.

Thus, any mirror that as "gone stale" can be filter out of the potential
mirrors to use.

For portability, the timestamp is recording in ISO format Zulu time.

B<Master Repository URI>

The F<mirror.yml> file contains a link to the master repository.

If the L<Mirror::YAML> client has an out-of-date current state at some
point, it will use the master repository URI in the current state to 
pull a fresh F<mirror.yml> from the master repository.

This solves the most-simple case, but other cases require a little
more complexity (which we'll address later).

B<Mirror URI List>

The F<mirror.yml> file contains a simple list of all mirror URIs.

Apart from filtering the list to try and find the best mirror to use,
the mirror list allows the B<Mirror::YAML> client to have backup
options for locating the master repository if it moves, or the
bootstrap F<mirror.yml> file has gotten old.

If the client can't find the master repository (because it has moved)
the client will scan the list of mirrors to try to find the location
of the updated repository.

B<The Bootstrap mirror.yml>

To bootstrap the client, it should come with a default bootstrap
F<mirror.yml> file built into it. When the client starts up for the
first time, it will attempt to fetch an updated mirror.yml from the
master repository, and if that doesn't exist will pull from the
default list of mirrors until it can find more than one up to date
mirror that agrees on the real location of the master server.

B<Anti-Hijacking Functionality>

On top of the straight forward mirror discovery functionality, the
client algorithm contains additional logic to deal with either a
mirror or the master server goes bad. While likely not 100% secure
it heads off several attack scenarios to prevent anyone trying them,
and provides as much as can be expected without resorting to cryto
and certificates.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mirror-YAML>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<YAML::Tiny>

=head1 COPYRIGHT

Copyright 2007 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
