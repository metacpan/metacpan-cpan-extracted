package Net::Intermapper;
use strict;
use Moose;

# REST IO stuff here
use IO::Socket::SSL qw( SSL_VERIFY_NONE );
use LWP::UserAgent;

# Generics
use File::Path;
use URI::Escape;
use Text::CSV_XS;
use Data::Dumper;
use XML::Simple;

# Net::Intermapper::*
use Net::Intermapper::User;
use Net::Intermapper::Device;
use Net::Intermapper::Interface;
use Net::Intermapper::Map;
use Net::Intermapper::Vertice;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $ERROR %_CHANGED);
    $VERSION     = '0.04';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
	%_CHANGED = ();
	$ERROR = ""; # TODO: Document error properly!
}

# Moose!

has 'ssl_options' => (
	is => 'rw',
	isa => 'HashRef',
	default => sub { { 'SSL_verify_mode' => SSL_VERIFY_NONE, 'verify_hostname' => '0' } }
	);

has 'ssl' => (
	is => 'rw',
	isa => 'Str',
	default => '1',
	);

has 'hostname' => (
	is => 'rw',
	isa => 'Str',
	required => '1',
	); 

has 'port' => (
	is => 'rw',
	isa => 'Int',
	default => sub { 8181 },
	); 

has 'modifyport' => (
	is => 'rw',
	isa => 'Int',
	default => sub { 443 },
	); 
	
has 'username' => (
	is => 'rw',
	isa => 'Str',
	default => sub { "admin" },
);

has 'password' => (
	is => 'rw',
	isa => 'Str',
	default => sub { "nmsadmin" },
);
	
has 'format' => (
	is => 'rw',
	isa => 'Str',
	default => sub { "csv" },
); 

has 'cache' => (
	is => 'rw',
	isa => 'Int',
	default => sub { "1" }, # Cache any request
);

has 'mock' => (
	is => 'rw',
	isa => 'Int',
	default => sub { "0" },
);

sub users # No Moose here :(
{ my $self = shift;
  $ERROR = "";
  $_CHANGED{"users"} = !$self->{"Users"} ? 1 : $_CHANGED{"users"};
  if (@_)
  { #my %args = @_; 
	#$self->{"Users"} = $args{"users"}; 
	$self->{"Users"} = $_[0]; # Expect a hash ref to be passed
	# Yes, this code is slightly based of the Net::Cisco::ACS code so may be some of it is weird
	# Are you really reading the comments now?
    if ($self->mock())
    { return $self->{"Users"}; }
  } else
  { if (!$self->cache) # No caching? Always reload
	{ $self->{"Users"} = $self->query("users") unless $self->mock; }
	else
	{ if (!$self->mock)
      { $self->{"Users"} = $self->query("users") if $_CHANGED{"users"}; } # Only reload if changed
	} 
  }
  return wantarray ? % { $self->{"Users"} } : $self->{"Users"};
}	

sub devices # No Moose here :(
{ my $self = shift;
  $ERROR = "";
  $_CHANGED{"devices"} = !$self->{"Devices"} ? 1 : $_CHANGED{"devices"};
  if (@_)
  { #my %args = @_; 
    #$self->{"Devices"} = $args{"devices"}; 
	$self->{"Devices"} = $_[0]; # Expect a hash ref to be passed
  } else
  { if (!$self->cache) # No caching? Always reload
    { $self->{"Devices"} = $self->query("devices");  }
    else
    { $self->{"Devices"} = $self->query("devices") if $_CHANGED{"devices"}; # Only reload if changed
    } 
  }
  return wantarray ? % { $self->{"Devices"} } : $self->{"Devices"};  
}	

sub interfaces # No Moose here :(
{ my $self = shift;
  $ERROR = "";
  $_CHANGED{"interfaces"} = !$self->{"Interfaces"} ? 1 : $_CHANGED{"interfaces"};
  if (@_)
  { #my %args = @_; 
	#$self->{"Interfaces"} = $args{"interfaces"}; 
	$self->{"Interfaces"} = $_[0]; # Expect a hash ref to be passed
  } else
  { if (!$self->cache) # No caching? Always reload
	{ $self->{"Interfaces"} = $self->query("interfaces");  }
	else
	{ $self->{"Interfaces"} = $self->query("interfaces") if $_CHANGED{"interfaces"}; # Only reload if changed
	} 
  }
  return wantarray ? % { $self->{"Interfaces"} } : $self->{"Interfaces"};  
}	

sub maps # No Moose here :(
{ my $self = shift;
  $ERROR = "";
  $_CHANGED{"maps"} = !$self->{"Maps"} ? 1 : $_CHANGED{"maps"};
  if (@_)
  { #my %args = @_; 
    #$self->{"Maps"} = $args{"maps"}; 
	$self->{"Maps"} = $_[0]; # Expect a hash ref to be passed
  } else
  { if (!$self->cache) # No caching? Always reload
    { $self->{"Maps"} = $self->query("maps");  }
	else
	{ $self->{"Maps"} = $self->query("maps") if $_CHANGED{"maps"};  # Only reload if changed
	}
  }
  return wantarray ? % { $self->{"Maps"} } : $self->{"Maps"};
}	

sub vertices # No Moose here :(
{ my $self = shift;
  $ERROR = "";
  $_CHANGED{"vertices"} = !$self->{"Vertices"} ? 1 : $_CHANGED{"vertices"};
  if (@_)
  { #my %args = @_; 
    #$self->{"Vertices"} = $args{"vertices"}; 
	$self->{"Vertices"} = $_[0]; # Expect a hash ref to be passed
  } else
  { if (!$self->cache) # No caching? Always reload
	{ $self->{"Vertices"} = $self->query("vertices");  }
	else
	{ $self->{"Vertices"} = $self->query("vertices") if $_CHANGED{"vertices"}; # Only reload if changed
	} 
  }
  return wantarray ? % { $self->{"Vertices"} } : $self->{"Vertices"};  
}	

sub query 
{ my ($self, $type) = @_;
  my $hostname = $self->hostname;
  my $username = $self->username;
  my $password = $self->password;
  my $port = $self->port;
  my $format = $self->format;
  if ($self->ssl)
  { $hostname = "https://$username:$password\@$hostname:$port"; } else
  { $hostname = "http://$username:$password\@$hostname:$port"; }
  $hostname .= "/~export/$type.$format"; 
  my $request = HTTP::Request->new("GET" => $hostname);
  my $useragent = LWP::UserAgent->new (ssl_opts => $self->ssl_options);
  my $result = $useragent->request($request);
  if ($result->code eq "400") { $ERROR = "Bad Request - HTTP Status: 400"; }
  if ($result->code eq "410") { $ERROR = "Unknown $type queried by name or ID - HTTP Status: 410"; }  
  if ($self->format eq "csv")
  { $self->parse_csv($type, $result->decoded_content); 
  }
  if ($self->format eq "tab")
  { $self->parse_tab($type, $result->decoded_content); 
  }

  if ($self->format eq "xml")
  { #$self->parse_xml($type, $result->content); # XML seems to be broken?!?
    #warn Dumper $result->content;
	#This needs work!!
  }
  $_CHANGED{$type} = 0; 
  return $self->{"Users"} if $type eq "users";
  return $self->{"Devices"} if $type eq "devices";
  return $self->{"Interfaces"} if $type eq "interfaces";
  return $self->{"Maps"} if $type eq "maps";
  return $self->{"Vertices"} if $type eq "vertices";
}

# It seems that Maps and Interfaces cannot be created?
sub create
{ my $self = shift;
  my @entries = @_;
  return unless @entries;
  my $username = $self->username;
  my $password = $self->password;
  my $format = $self->format; # csv or xml (unsupported at this point)
  my $type = "";
  
  my $hostname = $self->hostname;
  my $port = $self->modifyport;
  if ($port ne "") { $port = ":$port"; }
  if ($self->ssl)
  { $hostname = "https://$username:$password\@$hostname$port/~import/file"; } else
  { $hostname = "http://$username:$password\@$hostname$port/~import/file"; }

  my $data = $entries[0]->header($format);
  $type = lc(ref($entries[0]));
  $type =~ s/^net\:\:intermapper\:\://; # Needed for the change flags@
  while(@entries)
  { my $entry = shift @entries; 
    if ($format eq "csv")
    { $data .= $entry->toCSV; }
    if ($format eq "tab")
    { $data .= $entry->toTAB; }
    $data =~ s/^\s*//g;
  }

  my $request = HTTP::Request->new(POST => "$hostname");
  my $useragent = LWP::UserAgent->new("ssl_opts" => $self->ssl_options);

  $request->content_type('application/x-www-form-urlencoded');
  $request->content($data);
  $request->header('Accept' => 'text/html');
  my $result = $useragent->request($request);
  $_CHANGED{$type} = 0; # Flag smart caching to force reload
  return $result; 
}

# This SHOULD be sufficient?
sub update
{ my $self = shift;
  my $entry = shift;
  $entry->mode("update");
  return $self->create($entry);
}

# This SHOULD be sufficient?
sub delete
{ my $self = shift;
  my $entry = shift;
  $entry->mode("delete");
  return $self->create($entry);
}

sub parse_xml # Broken!
{ my $self = shift;
  my $type = shift;
  my $xml_ref = shift;
  my $xmlsimple = XML::Simple->new();
  my $xmlout = $xmlsimple->XMLin($xml_ref);
  if ($type eq "users")
  { my $users_ref = $xmlout->{"users"};
    my %users = ();
    for my $key (@ {$users_ref})
    { my $user = Net::Intermapper::User->new(  @{ $key } );
      $users{$key} = $user;
    }
    $self->{"Users"} = \%users; #Not sure if this works with the 
	return $self->{"Users"};
  }
  
  if ($type eq "devices")
  { my $devices_ref = $xmlout->{"devices"};
    my %devices = ();
    for my $key (@ {$devices_ref})
    { my $device = Net::Intermapper::Device->new(  @{ $key } );
      $devices{$key} = $device;
    }
    $self->{"Devices"} = \%devices;
	return $self->{"Devices"};
  }
  
  if ($type eq "interfaces")
  { my $interfaces_ref = $xmlout->{"interfaces"};
    my %interfaces = ();
    for my $key (@ {$interfaces_ref})
    { my $interface = Net::Intermapper::Interface->new(  @{ $key } );
      $interfaces{$key} = $interface;
    }
    $self->{"Interfaces"} = \%interfaces;
	return $self->{"Interfaces"};
  }
  
  if ($type eq "maps")
  { my $maps_ref = $xmlout->{"maps"};
    my %maps = ();
    for my $key (@ {$maps_ref})
    { my $map = Net::Intermapper::Map->new(  @{ $key } );
      $maps{$key} = $map;
    }
    $self->{"Maps"} = \%maps;
	return $self->{"Maps"};
  }

  if ($type eq "vertices")
  { my $vertices_ref = $xmlout->{"vertices"};
    my %vertices = ();
    for my $key (@ {$vertices_ref})
    { my $vertice = Net::Intermapper::Vertice->new(  @{ $key } );
      $vertices{$key} = $vertice;
    }
    $self->{"Vertices"} = \%vertices;
	return $self->{"Vertices"};
  }
 
}

sub parse_csv
{ my $self = shift;
  my $type = shift;
  my $csv_ref = shift;
  my @header = ();
  my %data = ();
  if ($type eq "users")
  { @header = @Net::Intermapper::User::HEADERS; }
  if ($type eq "devices")
  { @header = @Net::Intermapper::Device::HEADERS; }
  if ($type eq "interfaces")
  { @header = @Net::Intermapper::Interface::HEADERS; }
  if ($type eq "maps")
  { @header = @Net::Intermapper::Map::HEADERS; }
  if ($type eq "vertices")
  { @header = @Net::Intermapper::Vertice::HEADERS; }
  
  my @lines = split(/\r\n/,$csv_ref);
  my $csv = Text::CSV_XS->new ({ "auto_diag" => "1", "binary" => "1" });
  for my $line (@lines)
  { my $i = 0;
    my %fields = ();
    if ($csv->parse ($line)) 
    { my @fields = $csv->fields;
      for my $field (@fields)
      { $fields{$header[$i]} = $field;
	    $i++;
	  }
	  if ($type eq "users")
	  { my $user = Net::Intermapper::User->new( %fields );
        $data{$user->Name} = $user;
      }
  	  if ($type eq "devices")
	  { my $device = Net::Intermapper::Device->new( %fields );
        $data{$device->Id} = $device;
      }
  	  if ($type eq "interfaces")
	  { my $interface = Net::Intermapper::Interface->new( %fields );
        $data{$interface->InterfaceID} = $interface;
      }
   	  if ($type eq "maps")
	  { my $map = Net::Intermapper::Map->new( %fields );
        $data{$map->MapName} = $map;
      }
   	  if ($type eq "vertices")
	  { my $vertice = Net::Intermapper::Vertice->new( %fields );
        $data{$vertice->Id} = $vertice;
      }

	}
  }
  if ($type eq "users")
  { $self->{"Users"} = \%data;
    return $self->{"Users"};
  }
  if ($type eq "devices")
  { $self->{"Devices"} = \%data;
    return $self->{"Devices"};
  }
  if ($type eq "interfaces")
  { $self->{"Interfaces"} = \%data;
    return $self->{"Interfaces"};
  }
  if ($type eq "maps")
  { $self->{"Maps"} = \%data;
    return $self->{"Maps"};
  }
  if ($type eq "vertices")
  { $self->{"Vertices"} = \%data;
    return $self->{"Vertices"};
  }

}

sub parse_tab
{ my $self = shift;
  my $type = shift;
  my $tab_ref = shift;
  my @header = ();
  my %data = ();
  if ($type eq "users")
  { @header = @Net::Intermapper::User::HEADERS; }
  if ($type eq "devices")
  { @header = @Net::Intermapper::Device::HEADERS; }
  if ($type eq "interfaces")
  { @header = @Net::Intermapper::Interface::HEADERS; }
  if ($type eq "maps")
  { @header = @Net::Intermapper::Map::HEADERS; }
  if ($type eq "vertices")
  { @header = @Net::Intermapper::Vertice::HEADERS; }
  my $linecount = 0;
  my @lines = split(/[\r\n]{1,2}/,$tab_ref);
  for my $line (@lines)
  { my $i = 0;
    my %fields = ();
    my @fields = split(/\t/,$line);
    if (!$linecount) { $linecount++; next; } # Skip header line - KNOWN VALUES
    for my $field (@fields)
    { $fields{$header[$i]} = $field;
	  $i++;
	}
	if ($type eq "users")
	{ my $user = Net::Intermapper::User->new( %fields );
      $data{$user->Name} = $user;
    }
  	if ($type eq "devices")
	{ my $device = Net::Intermapper::Device->new( %fields );
      $data{$device->Id} = $device;
    }
  	if ($type eq "interfaces")
	{ my $interface = Net::Intermapper::Interface->new( %fields );
      $data{$interface->InterfaceID} = $interface;
    }
   	if ($type eq "maps")
	{ my $map = Net::Intermapper::Map->new( %fields );
      $data{$map->MapName} = $map;
    }
   	if ($type eq "vertices")
	{ my $vertice = Net::Intermapper::Vertice->new( %fields );
      $data{$vertice->Id} = $vertice;
    }
  }
  if ($type eq "users")
  { $self->{"Users"} = \%data;
    return $self->{"Users"};
  }
  if ($type eq "devices")
  { $self->{"Devices"} = \%data;
    return $self->{"Devices"};
  }
  if ($type eq "interfaces")
  { $self->{"Interfaces"} = \%data;
    return $self->{"Interfaces"};
  }
  if ($type eq "maps")
  { $self->{"Maps"} = \%data;
    return $self->{"Maps"};
  }
  if ($type eq "vertices")
  { $self->{"Vertices"} = \%data;
    return $self->{"Vertices"};
  }

}

=pod

=head1 NAME

Net::Intermapper - Interface with the HelpSystems Intermapper HTTP API

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

Net::Intermapper is a perl wrapper around the HelpSystems Intermapper API provided through HTTP/HTTPS for access to user accounts, device information, maps, interfaces and graphical elements.

All calls are handled through an instance of the L<Net::Intermapper> class.

  use Net::Intermapper;
  my $intermapper = Net::Intermapper->new(hostname => '10.0.0.1', username => 'admin', password => 'nmsadmin');

=over 3

=item new

Class constructor. Returns object of Net::Intermapper on succes. Required fields are:

=over 5

=item hostname

=item username

=item password

=back

Optional fields are

=over 5

=item ssl

=item ssl_options

=item port

=item modifyport

=item cache

=back

=item hostname

IP or hostname of Intermapper server. This is a required value in the constructor but can be redefined afterwards. 

=item username

Username of Administrator user. This is a required value in the constructor but can be redefined afterwards.
As the API is used a different mechanism to query information than it uses to update, this needs to be changed when switching. Typically, the built-in C<admin> user is used for modifying a record. 
This value is not automatically changed when running C<create> or C<update>. 

=item password

Password of user. This is a required value in the constructor but can be redefined afterwards.
As the API is used a different mechanism to query information than it uses to update, this needs to be changed when switching. Typically, the built-in C<admin> user is used for modifying a record. 
This value is not automatically changed when running C<create> or C<update>.

=item ssl

SSL enabled (1 - default) or disabled (0). 

=item ssl_options

Value is passed directly to L<LWP::UserAgent> as C<ssl_opt>. Default value (hash-ref) is

  { 'SSL_verify_mode' => SSL_VERIFY_NONE, 'verify_hostname' => '0' }

This is an optional value in the constructor and can be redefined afterwards.   
  
=item port

TCP port used for queries. This is an optional value in the constructor and can be redefined afterwards. By default, this is set to 8181.
As the API is used a different mechanism to query information than it uses to update, the C<port> value is used for queries only and is automatically switched. Set this ONLY if you have customized Intermapper to listen to a different port.

=item modifyport

TCP port used for modifying values. This is an optional value in the constructor and can be redefined afterwards. By default, this is set to 443.
As the API is used a different mechanism to modify (create and update) information than it uses to query, the C<modifyport> value is used for modifying only and is automatically switched. Set this ONLY if you have customized Intermapper to listen to a different port.

=item cache

Set to true (default) to use in-memory dataset to avoid unnecessary queries. Dataset are always queries when changes are made (after delete, create or update), per type. Changes to users dataset will not affect the devices dataset. This is a required value in the constructor but can be redefined afterwards. 

  $intermapper->cache(0);
  $intermapper->update($user);
  # Users have changed. 
  my $users = $intermapper->users;
  # This will trigger network traffic
  my $devices = $intermapper->devices
  # This will NOT trigger network traffic

=back

From the class instance, call the different methods for retrieving values.

=over 3

=item users

Returns all users

  my %users = $intermapper->users(); 
  my $user = $users{"Bob"};
  print $user->Password;
	
The returned hash contains instances of L<Net::Intermapper::User>, using the username as the hash key. In scalar context, will return hashref. This method will typically trigger a network connection, depending on caching.

Modify the in-memory users dataset:

  my $users = { "Tom" => $tom_user, "Bob" => $bob_user };
  $intermapper->users($users);
  # At this point, there is no real reason to do this as update, create and delete work with explicit arguments.
  # But it can be done with users, devices, interfaces, maps and vertices
  # Pass a hashref to each method. This will NOT affect the smart-caching (only explicit calls to create, update and delete do this - for now).
  
=item devices

returns all devices
  
  my %devices = $intermapper->devices(); 
  my $device = $devices{"UniqueDeviceID"};
  print $device->Address;

The returned hash contains instances of L<Net::Intermapper::Device>, using the device ID as the hash key. In scalar context, will return hashref. This method will typically trigger a network connection, depending on caching.

Modify the in-memory users dataset:

  my $devices = { "MainRouter1" => $main1, "MainRouter2" => $main2 };
  $intermapper->devices($devices);
  # At this point, there is no real reason to do this as update, create and delete work with explicit arguments.
  # But it can be done with users, devices, interfaces, maps and vertices
  # Pass a hashref to each method. This will NOT affect the smart-caching (only explicit calls to create, update and delete do this - for now).
  
=item maps

returns all maps
  
  my %maps = $intermapper->maps(); 
  my $map = $maps{"MainMap"};
  print $map->Name;

The returned hash contains instances of L<Net::Intermapper::Map>, using the map name as the hash key. In scalar context, will return hashref. This method will typically trigger a network connection, depending on caching.

Modify the in-memory users dataset:

  my $maps = { "MainMap" => $main1, "Layer2" => $main2 };
  $intermapper->maps($maps);
  # At this point, there is no real reason to do this as update, create and delete work with explicit arguments.
  # But it can be done with users, devices, interfaces, maps and vertices
  # Pass a hashref to each method. This will NOT affect the smart-caching (only explicit calls to create, update and delete do this - for now).
 
=item interfaces

returns all interfaces
  
  my %interfaces = $intermapper->interfaces(); 
  my $interface = $devices{"UniqueInterfaceID"}; 
  print $interface->Address;

The returned hash contains instances of L<Net::Intermapper::Interface>, using the interface ID (generated by Intermapper) as the hash key. In scalar context, will return hashref. This method will typically trigger a network connection, depending on caching.

Modify the in-memory users dataset:

  my $interfaces = { "UniqueKey1" => $iface1, "UniqueKey2" => $iface2 };
  $intermapper->interfaces($interfaces);
  # At this point, there is no real reason to do this as update, create and delete work with explicit arguments.
  # But it can be done with users, devices, interfaces, maps and vertices
  # Pass a hashref to each method. This will NOT affect the smart-caching (only explicit calls to create, update and delete do this - for now).
  
=item vertices

returns all vertices
  
  my %vertices = $intermapper->vertices(); 
  my $vertice = $vertices{"ID"}; # Unique Vertex ID
  print $vertice->Shape;

The returned hash contains instances of L<Net::Intermapper::Vertice>, using the vertex ID as the hash key. In scalar context, will return hashref. This method will typically trigger a network connection, depending on caching.

Modify the in-memory users dataset:

  my $vertices = { "UniqueVertexID1" => $vid1, "UniqueVertexID2" => $vid2 };
  $intermapper->vertices($vertices);
  # At this point, there is no real reason to do this as update, create and delete work with explicit arguments.
  # But it can be done with users, devices, interfaces, maps and vertices
  # Pass a hashref to each method. This will NOT affect the smart-caching (only explicit calls to create, update and delete do this - for now).
  
=item create

This method created a new entry in Intermapper, depending on the argument passed. Record type is detected automatically.

  $intermapper->username("admin");
  $intermapper->password("nmsadmin");
  my $user = Net::Intermapper::User->new(Name=>"testuser", Password=>"Test12345");
  my $response = $intermapper->create($user); 
  # Error checking needs to be added
  # print $Net::Intermapper::ERROR unless $id; 
  # $Net::Intermapper::ERROR contains details about failure

  # Add more examples
  # Interfaces and maps cannot be explicitly created!
  
=item update

This method updates an existing entry in Intermapper, depending on the argument passed. Record type is detected automatically. 

  my $user = $intermapper->users->{"testuser"};
  $user->Password("TopSecret"); # Change password. Password policies will be enforced!
  my $response = $intermapper->update($user);
  # Error checking needs to be added
  # Update user based on Net::Intermapper::User instance
  # print $Net::Intermapper::ERROR unless $id;
  # $Net::Intermapper::ERROR contains details about failure

=item delete

This method deletes an existing entry in Intermapper, depending on the argument passed. Record type is detected automatically.

  my $user = $intermapper->users->{"bob"};
  my $response = $intermapper->delete($user);
  # Delete existing user

  my $device = $intermapper->devices->{"UniqueDeviceID"}; # This key is generated by Intermapper
  $intermapper->delete($device);
  # Delete existing device
  
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

=head1 TODO

=over 3

=item Filtering should be added (match= keyword in Intermapper documentation)

=item XML input and output needs to be completed!

=item $ERROR variable needs to actually contain error message!

=back

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

