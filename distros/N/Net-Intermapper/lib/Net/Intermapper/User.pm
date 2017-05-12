package Net::Intermapper::User;
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
	
	@HEADERS = qw(Id Name Password Guest External Groups);
};

# MOOSE!
		   
has 'Id' => (
    is  => 'rw',
    isa => 'Str',
	default => sub { ""; },
  );

has 'Groups' => ( 
	is => 'rw',
	isa => 'Str',
	default => sub { "Read_Only"; },
	);

has 'Name' => (
	is => 'rw',
	isa => 'Str',
	);

has 'Password' => (
	is => 'rw',
	isa => 'Str',
	default => sub { "&#0;"; },
	);

has 'Guest' => (
	is => 'rw',
	isa => 'Str',
	default => sub { ""; },
	);

has 'External' => (
	is => 'rw',
	isa => 'Str',
	default => sub { "false"; },
	);

has 'mode' => ( # create, update, delete
	is => 'rw',
	isa => 'Str',
	default => sub { "create"; },
	);
	
# No Moose	
	
sub toXML
{ my $self = shift;
  my $id = $self->Id;
  my $name = $self->Name || "";
  my $groups = $self->Groups || "Read_only";  
  my $external = $self->External || "false";
  my $guest = $self->Guest || ""; 
  my $password = $self->Password || "&#0;";
  my $result = "";
  # Need to build the XML formatting!!
  if ($id) { $result = "   <id>$id</id>\n"; }
return $result;
}

sub toCSV
{ my $self = shift;
  my $id = $self->Id;
  my $result = "";
  my @attributes = $self->meta->get_all_attributes;
  my %attributes = ();
  for my $attribute (@attributes)
  { $attributes{$attribute->name} = $attribute->get_value($self) || "";
  }
  for my $key (@HEADERS)
  { if ($self->mode eq "create")
    { next if $key eq "Id";
	  next if $key eq "mode";
      next unless $attributes{$key};
      $result .= $attributes{$key}.","; 
	}
	if ($self->mode eq "update")
    { next if $key eq "mode";
      next unless $attributes{$key};
	  $result .= $attributes{$key}.","; 
	}
	if ($self->mode eq "delete")
    { next if $key eq "mode";
      next unless $attributes{$key};
	  next unless $attributes{$key};
	  $result .= $attributes{$key}.","; 
	}
	
  }
  chop $result; # Remove the comma of the last field
  $result =~ s/\s$//g;
  $result .= "\r\n";
  return $result;
}

sub toTAB
{ my $self = shift;
  my $id = $self->Id;
  my $result = "";
  my @attributes = $self->meta->get_all_attributes;
  my %attributes = ();
  for my $attribute (@attributes)
  { $attributes{$attribute->name} = $attribute->get_value($self) || "";
  }
  for my $key (@HEADERS)
  { if ($self->mode eq "create")
    { next if $key eq "Id";
	  next if $key eq "mode";
	  next unless $attributes{$key};
	  $result .= $attributes{$key}."\t"; 
	}
	if ($self->mode eq "update")
    { next if $key eq "mode";
	  next unless $attributes{$key};
	  $result .= $attributes{$key}."\t"; 
	}
	if ($self->mode eq "delete")
    { next if $key eq "mode";
	  next unless $attributes{$key};
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
  my $header = "# format=$format table=users fields="; 
  my @attributes = $self->meta->get_all_attributes;
  my %attributes = ();
  for my $attribute (@attributes)
  { $attributes{$attribute->name} = $attribute->get_value($self) || "";
  }
  for my $key (@HEADERS)
  { if ($self->mode eq "create")
    { next if $key eq "Id";
	  next unless $attributes{$key};	
	  $header .= $key.","; 
	}
	if ($self->mode eq "update")
    { next unless $attributes{$key};
	  $header .= $key.","; 
	}
	if ($self->mode eq "delete")
    { next if $key eq "mode";
	  next unless $attributes{$key};
      $header .= $key.","; 
	}
  }
  if ($self->mode eq "delete")
  { $header .= " delete=Id,Name "; } # These 3 fields are used for filtering
  chop $header; 
  $header .= "\r\n";
  return $header;
}
	
=pod

=head1 NAME

Net::Intermapper::User - Interface with the HelpSystems Intermapper HTTP API - Users 

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

Net::Intermapper::User is a perl wrapper around the HelpSystems Intermapper API provided through HTTP/HTTPS for access to user information.

All calls are handled through an instance of the L<Net::Intermapper> class.

  use Net::Intermapper;
  my $intermapper = Net::Intermapper->new(hostname => '10.0.0.1', username => 'admin', password => 'nmsadmin');

=head1 USAGE  
  
=over 3

=item new

Class constructor. Returns object of Net::Intermapper::User on succes. Attributes are:

=over 5

=item Id (read-only)

A unique, persistent identifier for this user.

=item Name (read-write)

Login name of the user. This value is used for lookups in the C<users> method in L<Net::Intermapper>.

=item Password (read-write)

If the user is to be validated locally, the user's password.

=item Guest (read-write)

The user's autologin properties.

=item External (read-write)

Indicates user is to be validated by an auth server.

=item Groups (read-write)

Comma-separated list of groups to which to add user. Values are ordered alphabetically.
Intermapper does not support removing an existing group but does support deleting a user. 
  
  my $user = $intermapper->users->{"bob"};
  my $groups = $user->Groups;
  my @groups = split(/\,/,$groups);
  shift @groups; # Remove first, just as an example
  $groups = join(",",@groups);
  $intermapper->delete($user);
  $user->groups($groups);
  $intermapper->create($user);

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

