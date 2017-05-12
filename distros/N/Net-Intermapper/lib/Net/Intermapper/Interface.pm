package Net::Intermapper::Interface;
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
	
	@HEADERS = qw(MapName InterfaceID DeviceID NetworkID Index IntegerIndex Description Name Alias PhysAddress Type MTU Address SubnetMask SubnetList SubnetPrefixList Speed PreferredSpeed ReportedSPeed LastChange
	Status Enabled MapId IMID TypeInt RecvSpeed StatusInt CustomerNameReference DataRetentionPolicy Duplex VLANs NatVLAN);
	
};

# MOOSE!
		   
has 'MapName' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'InterfaceID' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'DeviceID' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'NetworkID' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'Index' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'IntegerIndex' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'Description' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'Name' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'Alias' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'PhysAddress' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'Type' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'MTU' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'Address' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'SubnetMask' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'SubnetList' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'SubnetPrefixList' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'Speed' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'PreferredSpeed' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'ReportedSPeed' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'LastChange' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'Status' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'Enabled' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'MapId' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'IMID' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'TypeInt' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'RecvSpeed' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'StatusInt' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'CustomerNameReference' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'DataRetentionPolicy' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'Duplex' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'VLANs' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'NatVLAN' => (
      is  => 'rw',
      isa => 'Str',
  );

# No Moose	
	
sub toXML
{ my $self = shift;
  my $id = $self->Id;
  my $result = "";
  
  if ($id) { $result = "   <id>$id</id>\n"; }
return $result;
}

sub toCSV
{ my $self = shift;
  my $id = $self->IMID; # Hopefully this is unique enough
  my $result = "";
  my @attributes = $self->meta->get_all_attributes;
  my %attributes = ();
  for my $attribute (@attributes)
  { $attributes{$attribute->name} = $attribute->get_value($self) || "";
  }
  for my $key (@HEADERS)
  { $result .= $attributes{$key}.","; }
  chop $result; # Remove the comma of the last field
  $result .= "\r\n";
  return $result;
}

sub header
{ my $self = shift;
  my $format = shift || "";
  my $header = "# format=$format table=interfaces fields="; 
  for my $key (@HEADERS)
  { $header .= $key.","; }
  $header .= "\r\n";
  return $header;
}

=pod
	
=head1 NAME

Net::Intermapper::Interface - Interface with the HelpSystems Intermapper HTTP API - Interfaces 

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

Net::Intermapper::Interface is a perl wrapper around the HelpSystems Intermapper API provided through HTTP/HTTPS for access to interface information.

All calls are handled through an instance of the L<Net::Intermapper> class.

  use Net::Intermapper;
  my $intermapper = Net::Intermapper->new(hostname => '10.0.0.1', username => 'admin', password => 'nmsadmin');

=head1 USAGE  

=over 3

=item new

Class constructor. Returns object of Net::Intermapper::Interface on succes. Attributes are:

=over 5

=item MapName (read-only)

The name of the map to which the interface belongs.

=item InterfaceID (read-only)

A unique persistent identifier for this interface instance. This value is used for lookups in the C<users> method in L<Net::Intermapper>.

=item DeviceID (read-only)

The unique persistent identifier for the adjacent device.

=item NetworkID (read-only)

The unique persistent identifier for the adjacent network.

=item Index (read-only)

The interface index (i.e. ifIndex) of the interface.

=item IntegerIndex (read-only)

The interface index (i.e. ifIndex) of the interface, as an integer.

=item Description (read-only)

The interface description (i.e. ifDescr).

=item Name (read-only)

The interface name (i.e. ifName).

=item Alias (read-only)

The interface alias (i.e. ifAlias).

=item PhysAddress (read-only)

The interface's data-link layer address (i.e. ifPhysAddr) .

=item Type (read-only)

The interface type as a human-readable string (i.e. ifType).

=item MTU (read-only)

The interface MTU (i.e. ifMTU).

=item Address (read-only)

The interface's first network-layer address.

=item SubnetMask (read-only)

The subnet mask associated with Address.

=item SubnetList (read-only)

A comma-separated list of addresses/masks on this interface.

=item SubnetPrefixList (read-only)

A comma-separated list of addresses/prefixes on this interface.

=item Speed (read-only)

The interface's speed in bits per second. (Derived from preferred speed and reported speed.)

=item PreferredSpeed (read-write)

The preferred speed of the interface as set by the customer.

=item ReportedSpeed (read-only)

The speed of the interface as reported by the interface.

=item LastChange (read-only)

The timestamp when the interface last changed status.

=item Status (read-only)

The status of the interface (e.g. UP, DOWN, or ADMIN-DOWN).

=item Enabled (read-write)

Flag which indicates whether the interface is enabled or not.

=item MapId (read-only)

The unique persistent identifier for the map to which the interface belongs.

=item IMID (read-only)

Identifier of the interface in the IMID format.

=item TypeInt (read-only)

The interface type as a number.

=item RecvSpeed (read-write)

Unsigned 64-bit integer. 0 means baseband; speed in Speed.

=item StatusInt (read-only)

The status of the interface as integer. Values correspond to {UP, DOWN, ADMIN-DOWN, DOWN but locally acked}.

=item CustomerNameReference (read-only)

Customer-supplied name, for referencing an external database.

=item DataRetentionPolicy (read-only)

Database data retention policy.

=item Duplex (read-only)

Interface Duplex status.

=item VLANs (read-only)

Comma-separated list of this interface's VLANs.

=item NatVLAN (read-write)

Native VLAN. Signed integer (0-4093). 0 means none.

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

None so far

=head1 SUPPORT

None so far :)

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

