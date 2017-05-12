package Net::Intermapper::Map;
use strict;
use Moose;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS @HEADERS);
    $VERSION     = '0.04';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
	
	@HEADERS = qw(MapId MapName MapPath Status DeviceCount NetworkCount InterfaceCount DownCount CriticalCount AlarmCount WarningCount OkayCount DataRetentionPolicy IMID Enabled Layer2);
};

# MOOSE!

has 'MapId' => (
    is  => 'rw',
    isa => 'Str',
	default => sub { ""; },	  
  );

has 'MapName' => (
    is  => 'rw',
    isa => 'Str',
	default => sub { ""; },
  );

has 'MapPath' => (
    is  => 'rw',
    isa => 'Str',
	default => sub { "/"; },
  );

has 'Status' => (
    is  => 'rw',
    isa => 'Str',
	default => sub { ""; },	
  );

has 'DeviceCount' => (
    is  => 'ro',
	isa => 'Str',
  );

has 'NetworkCount' => (
    is  => 'ro',
    isa => 'Str',
  );

has 'InterfaceCount' => (
    is  => 'ro',
    isa => 'Str',
  );

has 'DownCount' => (
    is  => 'ro',
    isa => 'Str',
  );

has 'CriticalCount' => (
    is  => 'ro',
    isa => 'Str',
  );

has 'AlarmCount' => (
    is  => 'ro',
    isa => 'Str',
  );

has 'WarningCount' => (
    is  => 'ro',
    isa => 'Str',
  );

has 'OkayCount' => (
    is  => 'ro',
    isa => 'Str',
  );

has 'DataRetentionPolicy' => (
    is  => 'rw',
    isa => 'Str',
  );

has 'IMID' => (
    is  => 'rw',
    isa => 'Str',
  );

has 'Enabled' => (
    is  => 'rw',
    isa => 'Str',
	default => sub { ""; },
  );

has 'Layer2' => (
    is  => 'rw',
    isa => 'Str',
	);

# This methode is used for generating only wanted fields..
has 'mode' => ( # create, update, delete
	is => 'rw',
	isa => 'Str',
	default => sub { "create"; },
	);
	
# No Moose	
	
sub toXML
{ my $self = shift;
  my $id = $self->Id;
  my $result = "";
  my $mapid = $self->MapId;
  my $mapname = $self->MapName || "";
  my $mappath = $self->MapPath || "";
  my $status = $self->Status || "";
  my $devicecount = $self->DeviceCount || "";
  my $networkcount = $self->NetworkCount || "";
  my $interfacecount = $self->InterfaceCount || "";
  my $downcount = $self->DownCount || "";
  my $criticalcount = $self->CriticalCount || "";
  my $alarmcount = $self->AlarmCount || "";
  my $warningcount = $self->WarningCount || "";
  my $okaycount = $self->OkayCount || "";
  my $dataretentionpolicy = $self->DataRetentionPolicy || "";
  my $imid = $self->IMID || "";
  my $enabled = $self->Enabled || "";
  my $layer2 = $self->Layer2 || "";
  if ($id) { $result = "   <id>$id</id>\n"; }
return $result;
}

sub toCSV
{ my $self = shift;
  my $id = $self->MapId;
  my $result = "";
  my @attributes = $self->meta->get_all_attributes;
  my %attributes = ();
  for my $attribute (@attributes)
  { $attributes{$attribute->name} = $attribute->get_value($self) || "";
  }
  for my $key (@HEADERS)
  { if ($self->mode eq "create")
    { next if $key eq "MapId";
	  next if $key eq "Status";
	  next if $key eq "DeviceCount";
	  next if $key eq "NetworkCount";
	  next if $key eq "InterfaceCount";
	  next if $key eq "DownCount";
	  next if $key eq "CriticalCount";
	  next if $key eq "AlarmCount";
	  next if $key eq "WarningCount";
	  next if $key eq "OkayCount";
	  next if $key eq "DataRetentionPolicy";
	  next if $key eq "Enabled";
	  next if $key eq "Layer2";
	  next if $key eq "IMID";
      $result .= $attributes{$key}.","; }
  }
  chop $result; # Remove the comma of the last field
  $result =~ s/\s$//g;
  $result .= "\r\n";
  return $result;
}

sub toTAB
{ my $self = shift;
  my $mapid = $self->MapId;
  my $result = "";
  my @attributes = $self->meta->get_all_attributes;
  my %attributes = ();
  for my $attribute (@attributes)
  { $attributes{$attribute->name} = $attribute->get_value($self) || "";
  }
  for my $key (@HEADERS)
  { if ($self->mode eq "create")
    { next if $key eq "MapId";
	  next if $key eq "Status";
	  next if $key eq "DeviceCount";
	  next if $key eq "NetworkCount";
	  next if $key eq "InterfaceCount";
	  next if $key eq "DownCount";
	  next if $key eq "CriticalCount";
	  next if $key eq "AlarmCount";
	  next if $key eq "WarningCount";
	  next if $key eq "OkayCount";
	  next if $key eq "DataRetentionPolicy";
	  next if $key eq "Enabled";
	  next if $key eq "Layer2";
	  next if $key eq "IMID";
      $result .= $attributes{$key}."\t"; 
	}
  }
  chop $result; # Remove the comma of the last field
  $result =~ s/\s$//g;
  $result .= "\r\n";
  return $result;
}

sub header
{ my $self = shift;
  my $format = shift || "";
  my $header = "# format=$format table=maps fields="; 
  for my $key (@HEADERS)
  { next if $key eq "MapId";
	next if $key eq "Status";
	next if $key eq "DeviceCount";
	next if $key eq "NetworkCount";
	next if $key eq "InterfaceCount";
	next if $key eq "DownCount";
	next if $key eq "CriticalCount";
	next if $key eq "AlarmCount";
	next if $key eq "WarningCount";
	next if $key eq "OkayCount";
	next if $key eq "DataRetentionPolicy";
	next if $key eq "Enabled";
	next if $key eq "Layer2";
	next if $key eq "IMID";
    $header .= $key."\t,"; 
  }
  chop $header;
  $header .= "\r\n";
  return $header;
}

=pod
	
=head1 NAME

Net::Intermapper::Map - Interface with the HelpSystems Intermapper HTTP API - Maps 

=head1 SYNOPSIS

  use Net::Intermapper;
  my $intermapper = Net::Intermapper->new(hostname=>"10.0.0.1", username=>"admin", password=>"nmsadmin");
  # Options:
  # hostname - IP or hostname of Intermapper 5.x and 6.x server
  # username - Username of Administrator user
  # password - Password of user
  # ssl - SSL enabled (1 - default) or disabled (0)
  # port - TCP port for querying information. Defaults to 8181
  # modifyport - TCP port for modifying information. Default to 443
  # cache - Boolean to enable smart caching or force network queries

  my %users = $intermapper->users;
  my $users_ref = $intermapper->users;
  # Retrieve all users from Intermapper, Net::Intermapper::User instances
  # Returns hash or hashref, depending on context
  
  my %devices = $intermapper->devices;
  my $devices_ref = $intermapper->devices;
  # Retrieve all devices from Intermapper, Net::Intermapper::Device instances
  # Returns hash or hashref, depending on context

  my %maps = $intermapper->maps;
  my $maps_ref = $intermapper->maps;
  # Retrieve all maps from Intermapper, Net::Intermapper::Map instances
  # Returns hash or hashref, depending on context

  my %interfaces = $intermapper->interfaces;
  my $interfaces_ref = $intermapper->interfaces;
  # Retrieve all interfaces from Intermapper, Net::Intermapper::Interface instances
  # Returns hash or hashref, depending on context

  my %vertices = $intermapper->vertices;
  my $vertices_ref = $intermapper->vertices;
  # Retrieve all vertices from Intermapper, Net::Intermapper::Vertice instances
  # Returns hash or hashref, depending on context

  my $user = $intermapper->users->{"admin"};
  
  # Each class will generate specific header. These are typically only for internal use but are compliant to the import format Intermapper uses.
  print $user->header; 
  print $device->header;
  print $map->header;
  print $interface->header;
  print $vertice->header;

  print $user->toTAB;
  print $device->toXML; # This one is broken still!
  print $map->toCSV;
  # Works on ALL subclasses
  # Produce human-readable output of each record in the formats Intermapper supports
  
  my $user = Net::Intermapper::User->new(Name=>"testuser", Password=>"Test12345");
  my $response = $intermapper->create($user);
  # Create new user
  # Return value is HTTP::Response object
  
  my $device = Net::Intermapper::Device->new(Name=>"testDevice", MapName=>"TestMap", MapPath=>"/TestMap", Address=>"10.0.0.1");
  my $response = $intermapper->create($device);
  # Create new device
  # Return value is HTTP::Response object

  $user->Password("Foobar123");
  my $response = $intermapper->update($user);
  # Update existing user
  # Return value is HTTP::Response object

  my $user = $intermapper->users->{"bob"};
  my $response = $intermapper->delete($user);
  # Delete existing user
  # Return value is HTTP::Response object

  my $device = $intermapper->devices->{"UniqueDeviceID"};
  my $response = $intermapper->delete($device);
  # Delete existing device
  # Return value is HTTP::Response object

  my $users = { "Tom" => $tom_user, "Bob" => $bob_user };
  $intermapper->users($users);
  # At this point, there is no real reason to do this as update, create and delete work with explicit arguments.
  # But it can be done with users, devices, interfaces, maps and vertices
  # Pass a hashref to each method. This will NOT affect the smart-caching (only explicit calls to create, update and delete do this - for now).

=head1 DESCRIPTION

Net::Intermapper::Device is a perl wrapper around the HelpSystems Intermapper API provided through HTTP/HTTPS for access to map information.

All calls are handled through an instance of the L<Net::Intermapper> class.

  use Net::Intermapper;
  my $intermapper = Net::Intermapper->new(hostname => '10.0.0.1', username => 'admin', password => 'nmsadmin');

=head1 USAGE
  
=over 3

=item new

Class constructor. Returns object of Net::Intermapper::Map on succes. Attributes are:

=over 5

=item MapId (read-only)

A unique, persistant identifier for this map instance.

=item MapName (read-only). This value is used for lookups in the C<users> method in L<Net::Intermapper>.

Name of the map.

=item MapPath (read-only)

Full path of the map, including the name of the map.

=item Status (read-only)

Status of the map (e.g. down, critical, alarm, warning, okay).

=item DeviceCount (read-only)

Number of devices in the map.

=item NetworkCount (read-only)

Number of networks in the map.

=item InterfaceCount (read-only)

Number of interfaces in the map.

=item DownCount (read-only)

Number of devices that are down.

=item CriticalCount (read-only)

Number of devices in critical status.

=item AlarmCount (read-only)

Number of devices in alarm status.

=item WarningCount (read-only)

Number of devices in warning status.

=item OkayCount (read-only)

Number of okay devices.

=item DataRetentionPolicy (read-only)

Database retention policy.

=item IMID (read-only)

Identifier of the map in the IMID format.

=item Enabled (read-only)

True if the map is currently running.

=item Layer2 (read-only)

True if the map is enabled for layer 2 polling.

=back

=over 3

=item header

Returns the C<directive> aka data header required by the Intermapper API to perform CRUD actions. This is handled through the C<create>, C<update> and C<delete> method and should not really be used.

=back

=over 3 

=item toTAB

Returns the object data formatted in TAB delimited format. Used in combination with the C<header> and the C<format> method in L<Net::Intermapper> to perform CRUD actions. This is handled through the C<create>, C<update> and C<delete> method and should not really be used.

=back

=over 3

=item toCSV

Returns the object data formatted in Comma Separated delimited format. Used in combination with the C<header> and the C<format> method in L<Net::Intermapper> to perform CRUD actions. This is handled through the C<create>, C<update> and C<delete> method and should not really be used.

=back

=over 3

=item toXML

Returns the object data formatted in XML format. Used in combination with the C<header> and the C<format> method in L<Net::Intermapper> to perform CRUD actions. This is handled through the C<create>, C<update> and C<delete> method and should not really be used.

=back

=over 3

=item mode

Internal method to properly format the data and header for CRUD actions. Typically not used.

=back

=item $ERROR

NEEDS TO BE ADDED

This variable will contain detailed error information.	
	
=back

=head1 REQUIREMENTS

For this library to work, you need an instance with Intermapper (obviously) or a simulator like L<Net::Intermapper::Mock>. 

=over 3

=item L<Moose>

=item L<IO::Socket::SSL>

=item L<LWP::UserAgent>

=item L<XML::Simple>

=item L<MIME::Base64>

=item L<URI::Escape>

=item L<Text::CSV_XS>

=back

=head1 BUGS

None yet

=head1 SUPPORT

None yet :)

=head1 AUTHOR

    Hendrik Van Belleghem
    CPAN ID: BEATNIK
    hendrik.vanbelleghem@gmail.com

=head1 COPYRIGHT

This program is free software licensed under the...

	The General Public License (GPL)
	Version 2, June 1991

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<http://download.intermapper.com/docs/UserGuide/Content/09-Reference/09-05-Advanced_Importing/the_directive_line.htm> 
L<http://download.intermapper.com/schema/imserverschema.html>

=cut

#################### main pod documentation end ###################
__PACKAGE__->meta->make_immutable();

1;
# The preceding line will help the module return a true value

