package Palm::Magellan::NavCompanion::Record;
use strict;

use warnings;
no warnings;

use vars qw( $AUTOLOAD );

=head1 NAME

Palm::Magellan::NavCompanion - access the Magellan GPS Companion waypoints file

=head1 SYNOPSIS

	use Palm::Magellan::NavCompanion;

	my $pdb = Palm::Magellan::NavCompanion->new;
	$pdb->Load( $file );

	my $waypoints = $pdb->{records};

	$, = ", ";
	foreach my $wp ( @$waypoints )
		{
		print $wp->name, $wp->latitude, $wp->longitude;
		print "\n";
		}

=head1 DESCRIPTION

This module gives you access to the waypoints in the Magellan's GPS
Companion "Companion Waypoints.pdb" file.  You have to be able to load
that file, which probably means that you have it on your computer
rather than your Palm.  On my machine, this file shows up in the Palm
directory as C< Palm/Users/..user../Backups/Companion Waypoints.pdb >.

Behind-the-scenes, Palm::PDB does all the work, so this module has
part of its interface and data structure.  For instance, the Load()
method accesses and parses the file and returns the general data
structure that Palm::PDB creates.  The interesting bits (the
waypoints) is an anonymous array which is the value for the key
C<records>.

	# an anonymous array
	my $waypoints = $pdb->{records};

Each element in C< @{ $waypoints } > is an object of class
C<Palm::Magellan::NavCompanion::Record>, which is really just a class
of accessor methods (for now).

=head2 Methods

=over 4

=item new

Create a new object. This method takes no arguments

=item Load( FILENAME )

Load a file in Palm Database format

=item name

The description.  The format allows up to 20
characters.

=item description

The description.  The format allows up to 32
characters.

=item elevation

The altitude, in meters

=item latitude

The latitude, as a decimal number.  Positive numbers are north latitude
and negative numbers are south latitude.

=item longitude

The longitude, as a decimal number.  Positive numbers are east longitude
and negative numbers are west longitude.

=item creation_date

The creation date of the waypoint, in the format MM/DD/YYYY.
This comprises the individual elements found in the database
format, which are also available individually.

=item creation_time

The creation time of the waypoint, in the format HH:MM.ss
This comprises the individual elements found in the database
format, which are also available individually.

=item creation_sec

The second the waypoint was created.

=item creation_min

The minute the waypoint was created.

=item creation_hour

The hour the waypoint was created.

=item creation_day

The day the waypoint was created.

=item creation_mon

The month the waypoint was created.

=item creation_year

The year the waypoint was created.  It includes the century.

=back

=head1 TO DO

* write records too

=head1 SEE ALSO

L<Palm::PDB>

=head1 SOURCE AVAILABILITY

This source is in GitHub:

	https://github.com/CPAN-Adopt-Me/Palm-Magellan-NavCompanion

=head1 AUTHOR

Now this module has no maintainer. You can takeover maintenance by
writing to modules@perl.org.

brian d foy C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2008 brian d foy.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use Carp qw(carp);
use UNIVERSAL;

my %Allowed = map { $_, 1 } qw(
	name
	description
	latitude
	longitude
	elevation
	creation_date
	creation_time
	creation_sec
	creation_min
	creation_hour
	creation_day
	creation_mon
	creation_year
	);

sub AUTOLOAD {
	my $self   = shift;
	my $method = $AUTOLOAD;
	$method =~ s/.*:://;

	if( exists $Allowed{ $method } )
		{
		$self->{$method}
		}
	else
		{
		carp( "Unknown method call [$method]" )
		}
	}

sub DESTROY { 1 };

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
 # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
package Palm::Magellan::NavCompanion;

use strict;

use base qw(Palm::StdAppInfo Palm::Raw Exporter);

use vars qw($VERSION);

use Palm::Raw;
use Palm::StdAppInfo();

$VERSION = '0.54';

our $Creator = "MGtz";
our $Type    = "Twpt";

sub import
	{
	&Palm::PDB::RegisterPDBHandlers( __PACKAGE__,
		[ $Creator, $Type ] );
	}

sub new
	{
	my $class	= shift;
	my $self	= $class->SUPER::new(@_);
			# Create a generic PDB. No need to rebless it,
			# though.

	$self->{name}    = "MagNavDB";	# Default
	$self->{creator} = $Creator;
	$self->{type}    = $Type;

	$self->{attributes}{resource} = 0;
				# The PDB is not a resource database by
				# default, but it's worth emphasizing,
				# since MemoDB is explicitly not a PRC.

	# Initialize the AppInfo block
	$self->{appinfo} = {
		sortOrder	=> undef,	# XXX - ?
	};

	# Add the standard AppInfo block stuff
	&Palm::StdAppInfo::seed_StdAppInfo($self->{appinfo});

	# Give the PDB a blank sort block
	$self->{sort} = undef;

	# Give the PDB an empty list of records
	$self->{records} = [];

	return $self;
	}

sub new_Record
	{
	my $class = shift;
	my $hash = $class->SUPER::new_Record(@_);

	$hash->{data} = "";

	return $hash;
	}

# ParseAppInfoBlock
# Parse the AppInfo block for Memo databases.
sub ParseAppInfoBlock
	{
	my $self = shift;
	my $data = shift;
	my $sortOrder;
	my $i;
	my $appinfo = {};
	my $std_len;

	# Get the standard parts of the AppInfo block
	$std_len = &Palm::StdAppInfo::parse_StdAppInfo($appinfo, $data);

	$data = $appinfo->{other};		# Look at the non-category part

	return $appinfo;
	}

sub PackAppInfoBlock
	{
	my $self = shift;
	my $retval;
	my $i;

	# Pack the non-category part of the AppInfo block
	$self->{appinfo}{other} =
		pack("x4 C x1", $self->{appinfo}{sortOrder});

	# Pack the AppInfo block
	$retval = &Palm::StdAppInfo::pack_StdAppInfo($self->{appinfo});

	return $retval;
	}

sub PackSortBlock
	{
	return undef;
	}

sub ParseRecord
	{
	my $self = shift;
	my %record = @_;

	my @created = ();
	my @unk_time = ();
	my( $latitude, $longitude, $elevation, $plot, $name );

	( @created[0..5], undef, @unk_time[0..5], undef,
		@record{ qw(latitude longitude elevation plot ) },
		undef,
		) = unpack 's6 s s6 s l l l C C', $record{data};

	@record{ qw(name description) } = split /\000/, substr( $record{data}, 42 );

	@record{ qw(creation_sec  creation_min creation_hour) }
		= @created[2,1,0];
	@record{ qw(creation_date creation_mon creation_year) }
		= @created[3,4,5];

	$record{'creation_time'} = sprintf "%d:%02d.%02d", @created[2,1,0];
	$record{'creation_date'} = sprintf "%d/%d/%04d",   @created[3,4,5];

	@record{ qw(latitude longitude) } = map { $_ / 1e5 }
		@record{ qw(latitude longitude) };

	foreach my $key ( qw(data offset id category) )
		{
		delete $record{ $key };
		}

	#require Data::Dumper;
	#print STDERR Data::Dumper::Dumper( \%record );

	return bless \%record, 'Palm::Magellan::NavCompanion::Record';
	}

sub PackRecord
	{
	my $self   = shift;
	my $record = shift;

	die "Writing records not implemented";

	return $record->{data} . "\0";	# Add the trailing NUL
	}


1;

__END__
