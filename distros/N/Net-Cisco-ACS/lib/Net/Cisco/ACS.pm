package Net::Cisco::ACS;
use strict;
use Moose;

# REST IO stuff here
use IO::Socket::SSL qw( SSL_VERIFY_NONE );
use LWP::UserAgent;
use XML::Simple;

# Generics
use MIME::Base64;
use URI::Escape;
use Data::Dumper;

# Net::Cisco::ACS::*
use Net::Cisco::ACS::User;
use Net::Cisco::ACS::IdentityGroup;
use Net::Cisco::ACS::Device;
use Net::Cisco::ACS::DeviceGroup;
use Net::Cisco::ACS::Host;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $ERROR %actions);
    $VERSION     = '0.04';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
	
	$ERROR = ""; # TODO: Document error properly!
	%actions = ( 	"version" => "/Rest/Common/AcsVersion",
					"serviceLocation" => "/Rest/Common/ServiceLocation",
					"errorMessage" => "/Rest/Common/ErrorMessage",
				);
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

has 'mock' => (
	is => 'rw',
	isa => 'Str',
	default => '0',
	);    
    
sub users # No Moose here :(
{	my $self = shift;
    $ERROR = "";
	if (@_)
	{ my %args = @_; 
	  $self->{"Users"} = $args{"users"};
      if ($self->mock())
      { return $self->{"Users"}; }
      
	  if ($args{"name"})
	  { $self->{"Users"} = $self->query("User","name",$args{"name"}); }
	  if ($args{"id"})
	  { $self->{"Users"} = $self->query("User","id",$args{"id"}); }
	} else
	{ $self->{"Users"} = $self->query("User") unless $self->mock();
	}
	return $self->{"Users"};
}	

sub identitygroups # No Moose here :(
{	my $self = shift;
    $ERROR = "";
	if (@_)
	{ my %args = @_; 
	  $self->{"IdentityGroups"} = $args{"identitygroups"}; 
      if ($self->mock())
      { return $self->{"IdentityGroups"}; }

	  if ($args{"name"})
	  { $self->{"IdentityGroups"} = $self->query("IdentityGroup","name",$args{"name"}); }
	  if ($args{"id"})
	  { $self->{"IdentityGroups"} = $self->query("IdentityGroup","id",$args{"id"}); }
	} else
	{ $self->{"IdentityGroups"} = $self->query("IdentityGroup"); 
	}
	return $self->{"IdentityGroups"};
}	

sub devices # No Moose here :(
{	my $self = shift;
	$ERROR = "";
	if (@_)
	{ my %args = @_; 
	  $self->{"Devices"} = $args{"devices"};
      if ($self->mock())
      { return $self->{"Devices"}; }

	  if ($args{"name"})
	  { $self->{"Devices"} = $self->query("Device","name",$args{"name"}); }
	  if ($args{"id"})
	  { $self->{"Devices"} = $self->query("Device","id",$args{"id"}); }
	} else
	{ $self->{"Devices"} = $self->query("Device"); 
	}
	return $self->{"Devices"};
}	

sub devicegroups # No Moose here :(
{	my $self = shift;
	$ERROR = "";
	if (@_)
	{ my %args = @_; 
	  $self->{"DeviceGroups"} = $args{"devicegroups"};
      if ($self->mock())
      { return $self->{"DeviceGroups"}; }

	  if ($args{"name"})
	  { $self->{"DeviceGroups"} = $self->query("DeviceGroup","name",$args{"name"}); }
	  if ($args{"id"})
	  { $self->{"DeviceGroups"} = $self->query("DeviceGroup","id",$args{"id"}); }
	} else
	{ $self->{"DeviceGroups"} = $self->query("DeviceGroup"); 
	}
	return $self->{"DeviceGroups"};
}	

sub hosts # No Moose here :(
{	my $self = shift;
	$ERROR = "";
	if (@_)
	{ my %args = @_; 
	  $self->{"Hosts"} = $args{"hosts"};
      if ($self->mock())
      { return $self->{"Hosts"}; }

	  if ($args{"name"})
	  { $self->{"Hosts"} = $self->query("Host","name",$args{"name"}); }
	  if ($args{"id"})
	  { $self->{"Hosts"} = $self->query("Host","id",$args{"id"}); }
	} else
	{ $self->{"Hosts"} = $self->query("Host"); 
	}
	return $self->{"Hosts"};
}	
	
has 'username' => (
	is => 'rw',
	isa => 'Str',
	required => '1',
	);

has 'password' => (
	is => 'rw',
	isa => 'Str',
	required => '1',
	);

sub version # No Moose here :(
{	my $self = shift;
    $ERROR = "";
	unless ($self->{"Version"}) # Version is not going to magically change in one session
	{ $self->{"Version"} = $self->query("Version"); }
	return $self->{"Version"};
}	
	
sub servicelocation # No Moose here :(
{	my $self = shift;
    $ERROR = "";
	unless ($self->{"ServiceLocation"}) # serviceLocation is not going to magically change in one session
	{ $self->{"ServiceLocation"} = $self->query("ServiceLocation"); }
	return $self->{"ServiceLocation"};
}	

sub errormessage # No Moose here :(
{	my $self = shift;
    $ERROR = "";
	$self->{"ErrorMessage"} = $self->query("ErrorMessage"); 
	return $self->{"ErrorMessage"};
}	
	
# Non-Moose

sub query 
{ my ($self, $type, $key, $value) = @_;
  my $hostname = $self->hostname;
  my $credentials = encode_base64($self->username.":".$self->password);
  if ($self->ssl)
  { $hostname = "https://$hostname"; } else
  { $hostname = "http://$hostname"; }
  my $action = "";
  my $mode = "";
  $key ||= "";
  if ($type eq "User")
  { $action = $Net::Cisco::ACS::User::actions{"query"}; 
    $mode = "Users";
    if ($key eq "name")
	{ $action = $Net::Cisco::ACS::User::actions{"getByName"}.$value; 
	  $mode = "User";
	}
	if ($key eq "id")
	{ $action = $Net::Cisco::ACS::User::actions{"getById"}.$value; 
	  $mode = "User";
	}
  }
  if ($type eq "IdentityGroup")
  { $action = $Net::Cisco::ACS::IdentityGroup::actions{"query"}; 
    $mode = "IdentityGroups";
    if ($key eq "name")
	{ $action = $Net::Cisco::ACS::IdentityGroup::actions{"getByName"}.$value; 
	  $mode = "IdentityGroup";
	}
	if ($key eq "id")
	{ $action = $Net::Cisco::ACS::IdentityGroup::actions{"getById"}.$value; 
	  $mode = "IdentityGroup";
	}
  }
  if ($type eq "Device")
  { $action = $Net::Cisco::ACS::Device::actions{"query"}; 
    $mode = "Devices";
    if ($key eq "name")
	{ $action = $Net::Cisco::ACS::Device::actions{"getByName"}.$value; 
	  $mode = "Device";
	}
	if ($key eq "id")
	{ $action = $Net::Cisco::ACS::Device::actions{"getById"}.$value; 
	  $mode = "Device";
	}
  }
  if ($type eq "DeviceGroup")
  { $action = $Net::Cisco::ACS::DeviceGroup::actions{"query"}; 
    $mode = "DeviceGroups";
    if ($key eq "name")
	{ $action = $Net::Cisco::ACS::DeviceGroup::actions{"getByName"}.$value; 
	  $mode = "DeviceGroup";
	}
	if ($key eq "id")
	{ $action = $Net::Cisco::ACS::DeviceGroup::actions{"getById"}.$value; 
	  $mode = "DeviceGroup";
	}
  }
  if ($type eq "Host")
  { $action = $Net::Cisco::ACS::Host::actions{"query"}; 
    $mode = "Hosts";
    if ($key eq "macAddress")
	{ $action = $Net::Cisco::ACS::Host::actions{"getByName"}.$value; 
	  $mode = "Host";
	}
	if ($key eq "id")
	{ $action = $Net::Cisco::ACS::Host::actions{"getById"}.$value; 
	  $mode = "Host";
	}
  }

  if ($type eq "Version")
  { $action = $Net::Cisco::ACS::actions{"version"}; 
    $mode = "Version";
  }
  if ($type eq "ServiceLocation")
  { $action = $Net::Cisco::ACS::actions{"serviceLocation"}; 
    $mode = "ServiceLocation";
  }
  if ($type eq "ErrorMessage")
  { $action = $Net::Cisco::ACS::actions{"errorMessage"}; 
    $mode = "ErrorMessage";
  }
  
  $hostname = $hostname . $action;
  my $useragent = LWP::UserAgent->new (ssl_opts => $self->ssl_options);
  my $request = HTTP::Request->new(GET => $hostname );
  $request->header('Authorization' => "Basic $credentials");
  my $result = $useragent->request($request);
  if ($result->code eq "400") { $ERROR = "Bad Request - HTTP Status: 400"; }
  if ($result->code eq "410") { $ERROR = "Unknown $type queried by name or ID - HTTP Status: 410"; }  
  $self->parse_xml($mode, $result->content);
}

sub create 
{ my $self = shift;
  my @entries = @_;
  return unless @entries;
  my $hostname = $self->hostname;
  my $credentials = encode_base64($self->username.":".$self->password);
  if ($self->ssl)
  { $hostname = "https://$hostname"; } else
  { $hostname = "http://$hostname"; }
  my $action = "";
  my $data = "";
  my $first = $entries[0];
  while(@entries)
  { my $record = shift @entries; 
    if (ref($record) eq "Net::Cisco::ACS::User")
    { $action = $Net::Cisco::ACS::User::actions{"create"}; 
    }

    if (ref($record) eq "Net::Cisco::ACS::IdentityGroup")
    { $action = $Net::Cisco::ACS::IdentityGroup::actions{"create"}; 
    }

    if (ref($record) eq "Net::Cisco::ACS::Device")
    { $action = $Net::Cisco::ACS::Device::actions{"create"}; 
    }
  
    if (ref($record) eq "Net::Cisco::ACS::DeviceGroup")
    { $action = $Net::Cisco::ACS::DeviceGroup::actions{"create"}; 
    }

    if (ref($record) eq "Net::Cisco::ACS::Host")
    { $action = $Net::Cisco::ACS::Host::actions{"create"}; 
    }
    $data .= $record->toXML;
  }  
  
  $data = $first->header($data);
  $hostname = $hostname . $action;
  my $useragent = LWP::UserAgent->new (ssl_opts => $self->ssl_options);
  my $request = HTTP::Request->new(POST => $hostname );
  $request->content_type("application/xml");  
  $request->header("Authorization" => "Basic $credentials");
  $request->content($data);
  my $result = $useragent->request($request);
  my $result_ref = $self->parse_xml("result", $result->content);
  my $id = "";
  if ($result->code ne "200") 
  { $ERROR = $result_ref->{"errorCode"}." ".$result_ref->{"moreErrInfo"}." - HTTP Status: ".$result_ref->{"httpCode"};
  } else 
  { $id = $result_ref->{"newBornId"}; }
  return $id;
}

sub update 
{ my $self = shift;
  my @entries = @_;
  my $hostname = $self->hostname;
  my $credentials = encode_base64($self->username.":".$self->password);
  if ($self->ssl)
  { $hostname = "https://$hostname"; } else
  { $hostname = "http://$hostname"; }
  my $action = "";
  my $data = "";
  my $first = $entries[0];
  while(@entries)
  { my $record = shift @entries; 
    if (ref($record) eq "Net::Cisco::ACS::User")
    { $action = $Net::Cisco::ACS::User::actions{"update"}; 
    }

    if (ref($record) eq "Net::Cisco::ACS::IdentityGroup")
    { $action = $Net::Cisco::ACS::IdentityGroup::actions{"update"}; 
    }

    if (ref($record) eq "Net::Cisco::ACS::Device")
    { $action = $Net::Cisco::ACS::Device::actions{"update"}; 
    }
  
    if (ref($record) eq "Net::Cisco::ACS::DeviceGroup")
    { $action = $Net::Cisco::ACS::DeviceGroup::actions{"update"}; 
    }

    if (ref($record) eq "Net::Cisco::ACS::Host")
    { $action = $Net::Cisco::ACS::Host::actions{"update"}; 
    }
    $data .= $record->toXML;
  }  

  $data = $first->header($data);  
  $hostname = $hostname . $action;
  my $useragent = LWP::UserAgent->new (ssl_opts => $self->ssl_options);
  my $request = HTTP::Request->new(PUT => $hostname );
  $request->content_type("application/xml");  
  $request->header("Authorization" => "Basic $credentials");
  $request->content($data);
  my $result = $useragent->request($request);
  my $result_ref = undef;
  $result_ref = $self->parse_xml("result", $result->content) if $result_ref;
  $result_ref = {} unless $result_ref;
  my $id = "";
  if ($result->code ne "200" && $result_ref->{"errorCode"}) 
  { $ERROR = $result_ref->{"errorCode"}." ".$result_ref->{"moreErrInfo"}." - HTTP Status: ".$result_ref->{"httpCode"};
  } else 
  { $id = $result_ref->{"newBornId"}; }
  return $id;
}

sub delete 
{ my $self = shift;
  my $record = shift;
  my $hostname = $self->hostname;
  my $credentials = encode_base64($self->username.":".$self->password);
  if ($self->ssl)
  { $hostname = "https://$hostname"; } else
  { $hostname = "http://$hostname"; }
  my $action = "";
  my $type = "";
  
  if (ref($record) eq "ARRAY") { $record = $record->[0]; }
  if (ref($record) eq "Net::Cisco::ACS::User")
  { $action = $Net::Cisco::ACS::User::actions{"getById"}; 
    $type = "User";
  }

  if (ref($record) eq "Net::Cisco::ACS::IdentityGroup")
  { $action = $Net::Cisco::ACS::IdentityGroup::actions{"getById"}; 
    $type = "IdentityGroup";
  }
  
  if (ref($record) eq "Net::Cisco::ACS::Device")
  { $action = $Net::Cisco::ACS::Device::actions{"getById"}; 
    $type = "Device";
  }
  
  if (ref($record) eq "Net::Cisco::ACS::DeviceGroup")
  { $action = $Net::Cisco::ACS::DeviceGroup::actions{"getById"}; 
    $type = "DeviceGroup";
  }

  if (ref($record) eq "Net::Cisco::ACS::Host")
  { $action = $Net::Cisco::ACS::Host::actions{"getById"}; 
    $type = "Host";
  }
  
  my $data = $record->header($record->toXML);
  $hostname = $hostname . $action.$record->id;
  my $useragent = LWP::UserAgent->new (ssl_opts => $self->ssl_options);
  my $request = HTTP::Request->new(DELETE => $hostname );
  $request->content_type("application/xml");  
  $request->header("Authorization" => "Basic $credentials");
  $request->content($data);
  my $result = $useragent->request($request);
  my $result_ref = undef;
  $result_ref = $self->parse_xml("result", $result->content) if $result_ref;
  $result_ref = {} unless $result_ref;  
  my $id = "";
  if ($result->code ne "200" && $result_ref->{"errorCode"}) 
  { $ERROR = $result_ref->{"errorCode"}." ".$result_ref->{"moreErrInfo"}." - HTTP Status: ".$result_ref->{"httpCode"};
  }
}

sub parse_xml
{ my $self = shift;
  my $type = shift;
  my $xml_ref = shift;
  my $xmlsimple = XML::Simple->new(SuppressEmpty => 1);
  my $xmlout = $xmlsimple->XMLin($xml_ref);
  if ($type eq "Users")
  { my $users_ref = $xmlout->{"User"};
    my %users = ();
    for my $key (keys % {$users_ref})
    { my $user = Net::Cisco::ACS::User->new( name => $key, %{ $users_ref->{$key} } );
      $users{$key} = $user;
    }
    $self->{"Users"} = \%users;
	return $self->{"Users"};
  }
  if ($type eq "User") # userByName and userById DO NOT return hash but a single instance of Net::Cisco::ACS::User
  { my %user_hash = %{ $xmlout };
    my $user = Net::Cisco::ACS::User->new( %user_hash );
	$self->{"Users"} = $user ;
	return $self->{"Users"};
  }

  if ($type eq "IdentityGroups")
  { my $identitygroups_ref = $xmlout->{"IdentityGroup"};
    my %identitygroups = ();
    for my $key (keys % {$identitygroups_ref})
    { my $identitygroup = Net::Cisco::ACS::IdentityGroup->new( name => $key, %{ $identitygroups_ref->{$key} } );
      $identitygroups{$key} = $identitygroup;
    }
    $self->{"IdentityGroups"} = \%identitygroups;
	return $self->{"IdentityGroups"};
  }
  if ($type eq "IdentityGroup") # ByName and ById DO NOT return hash but a single instance of Net::Cisco::ACS::IdentityGroup
  { my %identitygroup_hash = %{ $xmlout };
    my $identitygroup = Net::Cisco::ACS::IdentityGroup->new( %identitygroup_hash );
	$self->{"IdentityGroups"} = $identitygroup;
	return $self->{"IdentityGroups"};
  }
  
  if ($type eq "Devices")
  { my $device_ref = $xmlout->{"Device"};
    my %devices = ();
	for my $key (keys % {$device_ref})
    { my $device = Net::Cisco::ACS::Device->new( name => $key, %{ $device_ref->{$key} } );
      $devices{$key} = $device;
    }
	$self->{"Devices"} = \%devices;
	return $self->{"Devices"};
  }
  if ($type eq "Device") # deviceByName and deviceById DO NOT return hash but a single instance of Net::Cisco::ACS::Device
  { my %device_hash = %{ $xmlout };
    my $device = Net::Cisco::ACS::Device->new( %device_hash );
	$self->{"Devices"} = $device;
	return $self->{"Devices"};
  }

  if ($type eq "DeviceGroups")
  { my $devicegroup_ref = $xmlout->{"DeviceGroup"};
    my %devicegroups = ();
	for my $key (keys % {$devicegroup_ref})
    { my $devicegroup = Net::Cisco::ACS::DeviceGroup->new( name => $key, %{ $devicegroup_ref->{$key} } );
      $devicegroups{$key} = $devicegroup;
    }
	$self->{"DeviceGroups"} = \%devicegroups;
	return $self->{"DeviceGroups"};
  }
  if ($type eq "DeviceGroup") # deviceGroupByName and deviceGroupById DO NOT return hash but a single instance of Net::Cisco::ACS::DeviceGroup
  { my %devicegroup_hash = %{ $xmlout };
    my $devicegroup = Net::Cisco::ACS::DeviceGroup->new( %devicegroup_hash );
	$self->{"DeviceGroups"} = $devicegroup;
	return $self->{"DeviceGroups"};
  }
  
  if ($type eq "Hosts")
  { my $host_ref = $xmlout->{"Host"};
    my %hosts = ();
	for my $key (keys % {$host_ref})
    { my $host = Net::Cisco::ACS::Host->new( macAddress => $key, %{ $host_ref->{$key} } );
      $hosts{$key} = $host;
    }
	$self->{"Hosts"} = \%hosts;
	return $self->{"Hosts"};
  }
  if ($type eq "Host") # ByName and ById DO NOT return hash but a single instance of Net::Cisco::ACS::Host
  { my %host_hash = %{ $xmlout };
    my $host = Net::Cisco::ACS::Host->new( %host_hash );
	$self->{"Hosts"} = $host;
	return $self->{"Hosts"};
  }
  
  if ($type eq "result")
  { my %result_hash = %{ $xmlout };
    return \%result_hash;
  }
  if ($type eq "Version")
  { my %version_hash = %{ $xmlout };
    return \%version_hash;
  }
  if ($type eq "ServiceLocation")
  { my %servicelocation_hash = %{ $xmlout };
    return \%servicelocation_hash;
  }
  if ($type eq "ErrorMessage")
  { my %errormessage_hash = %{ $xmlout };
    return \%errormessage_hash;
  }

}

=head1 NAME

Net::Cisco::ACS - Access Cisco ACS functionality through REST API

=head1 SYNOPSIS

	use Net::Cisco::ACS;
	my $acs = Net::Cisco::ACS->new(hostname => '10.0.0.1', username => 'acsadmin', password => 'testPassword');
	# Options:
	# hostname - IP or hostname of Cisco ACS 5.x server
	# username - Username of Administrator user
	# password - Password of user
	# ssl - SSL enabled (1 - default) or disabled (0)
		
	my %users = $acs->users;
	# Retrieve all users from ACS
	# Returns hash with username / Net::Cisco::ACS::User pairs
	
	print $acs->users->{"acsadmin"}->toXML;
	# Dump in XML format (used by ACS for API calls)
	
	my $user = $acs->users("name","acsadmin");
	# Faster call to request specific user information by name

	my $user = $acs->users("id","150");
	# Faster call to request specific user information by ID (assigned by ACS, present in Net::Cisco::ACS::User)

	my %identitygroups = $acs->identitygroups;
	# Retrieve all identitygroups from ACS
	# Returns hash with name / Net::Cisco::ACS::IdentityGroup pairs
	
	print $acs->identitygroups->{"All Groups"}->toXML;
	# Dump in XML format (used by ACS for API calls)
	
	my $identitygroup = $acs->identitygroups("name","All Groups");
	# Faster call to request specific identity group information by name

	my $identitygroup = $acs->identitygroups("id","150");
	# Faster call to request specific identity group information by ID (assigned by ACS, present in Net::Cisco::ACS::IdentityGroup)
	
	my %devices = $acs->devices;
	# Retrieve all devices from ACS
	# Returns hash with device name / Net::Cisco::ACS::Device pairs

	print $acs->devices->{"MAIN_Router"}->toXML;
	# Dump in XML format (used by ACS for API calls)
	
	my $device = $acs->devices("name","MAIN_Router");
	# Faster call to request specific device information by name

	my $device = $acs->devices("id","250");
	# Faster call to request specific device information by ID (assigned by ACS, present in Net::Cisco::ACS::Device)

	my %devicegroups = $acs->devicegroups;
	# Retrieve all device groups from ACS
	# Returns hash with device name / Net::Cisco::ACS::DeviceGroup pairs

	print $acs->devicegroups->{"All Locations"}->toXML;
	# Dump in XML format (used by ACS for API calls)
	
	my $device = $acs->devicegroups("name","All Locations");
	# Faster call to request specific device group information by name

	my $devicegroup = $acs->devicegroups("id","250");
	# Faster call to request specific device group information by ID (assigned by ACS, present in Net::Cisco::ACS::DeviceGroup)

	my %hosts = $acs->hosts;
	# Retrieve all hosts from ACS
	# Returns hash with host name / Net::Cisco::ACS::Host pairs

	print $acs->hosts->{"1234"}->toXML;
	# Dump in XML format (used by ACS for API calls)
	
	my $host = $acs->hosts("name","1234");
	# Faster call to request specific host information by name

	my $host = $acs->hosts("id","250");
	# Faster call to request specific hosts information by ID (assigned by ACS, present in Net::Cisco::ACS::Host)
	
	$user->id(0); # Required for new user!
	my $id = $acs->create($user);
	# Create new user based on Net::Cisco::ACS::User instance
	# Return value is ID generated by ACS
	print "Record ID is $id" if $id;
	print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure

	my $id = $acs->create(@users); # Still requires nullified ID!
	# Create new users based on Net::Cisco::ACS::User instances in arguments
	# Return value is not guaranteed in this case!
	# print "Record ID is $id" if $id;
	# print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure    
    
	$identitygroup->id(0); # Required for new record!
	my $id = $acs->create($identitygroup);
	# Create new identity group based on Net::Cisco::ACS::IdentityGroup instance
	# Return value is ID generated by ACS
	print "Record ID is $id" if $id;
	print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure

	my $id = $acs->create(@identitygroups); # Still requires nullified ID!
	# Create new identitygroups based on Net::Cisco::ACS::IdentityGroup instances in arguments
	# Return value is not guaranteed in this case!
	# print "Record ID is $id" if $id;
	# print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure    
		
	$device->id(0); # Required for new device!
	my $id = $acs->create($device);
	# Create new device based on Net::Cisco::ACS::Device instance
	# Return value is ID generated by ACS
	print "Record ID is $id" if $id;
	print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure

   	my $id = $acs->create(@devices); # Still requires nullified ID!
	# Create new devices based on Net::Cisco::ACS::Device instances in arguments
	# Return value is not guaranteed in this case!
	# print "Record ID is $id" if $id;
	# print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure    

	$devicegroup->id(0); # Required for new device group!
	my $id = $acs->create($devicegroup);
	# Create new device group based on Net::Cisco::ACS::DeviceGroup instance
	# Return value is ID generated by ACS
	print "Record ID is $id" if $id;
	print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure

	my $id = $acs->create(@devicegroups); # Still requires nullified ID!
	# Create new devicegroups based on Net::Cisco::ACS::DeviceGroup instances in arguments
	# Return value is not guaranteed in this case!
	# print "Record ID is $id" if $id;
	# print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure        
    
	$host->id(0); # Required for new host!
	my $id = $acs->create($host);
	# Create new host based on Net::Cisco::ACS::Host instance
	# Return value is ID generated by ACS
	print "Record ID is $id" if $id;
	print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure

	my $id = $acs->create(@hosts); # Still requires nullified ID!
	# Create new hosts based on Net::Cisco::ACS::Host instances in arguments
	# Return value is not guaranteed in this case!
	# print "Record ID is $id" if $id;
	# print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure    
	
	my $id = $acs->update($user);
	# Update existing user based on Net::Cisco::ACS::User instance
	# Return value is ID generated by ACS
	print "Record ID is $id" if $id;
	print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure

	my $id = $acs->update(@users);
	# Update existing users based on Net::Cisco::ACS::User instances in arguments
	# Return value is not guaranteed in this case!
	# print "Record ID is $id" if $id;
	# print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure    
    
	my $id = $acs->update($identitygroup);
	# Update existing identitygroup based on Net::Cisco::ACS::IdentityGroup instance
	# Return value is ID generated by ACS
	print "Record ID is $id" if $id;
	print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure

	my $id = $acs->update(@identitygroups);
	# Update existing identitygroups based on Net::Cisco::ACS::IdentityGroups instances in arguments
	# Return value is not guaranteed in this case!
	# print "Record ID is $id" if $id;
	# print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure    
	
	my $id = $acs->update($device);
	# Update existing device based on Net::Cisco::ACS::Device instance
	# Return value is ID generated by ACS
	print "Record ID is $id" if $id;
	print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure

	my $id = $acs->update(@devices);
	# Update existing devices based on Net::Cisco::ACS::Device instances in arguments
	# Return value is not guaranteed in this case!
	# print "Record ID is $id" if $id;
	# print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure    
        
	my $id = $acs->update($devicegroup);
	# Update existing device based on Net::Cisco::ACS::DeviceGroup instance
	# Return value is ID generated by ACS
	print "Record ID is $id" if $id;
	print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure
   
	my $id = $acs->update(@devicegroups);
	# Update existing devicegroups based on Net::Cisco::ACS::DeviceGroup instances in arguments
	# Return value is not guaranteed in this case!
	# print "Record ID is $id" if $id;
	# print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure    
        
	my $id = $acs->update($host);
	# Update existing device based on Net::Cisco::ACS::Host instance
	# Return value is ID generated by ACS
	print "Record ID is $id" if $id;
	print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure

	my $id = $acs->update(@hosts);
	# Update existing hosts based on Net::Cisco::ACS::Host instances in arguments
	# Return value is not guaranteed in this case!
	# print "Record ID is $id" if $id;
	# print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure    
        
	$acs->delete($user);
	# Delete existing user based on Net::Cisco::ACS::User instance

	$acs->delete($identitygroup);
	# Delete existing identity group based on Net::Cisco::ACS::IdentityGroup instance
	
	$acs->delete($device);
	# Delete existing device based on Net::Cisco::ACS::Device instance

	$acs->delete($devicegroup);
	# Delete existing device based on Net::Cisco::ACS::DeviceGroup instance

	$acs->delete($host);
	# Delete existing host based on Net::Cisco::ACS::Host instance
	
	$acs->version
	# Return version information for the connected server *HASHREF*

	$acs->serviceLocation
	# Return ACS instance that serves as primary and the ACS instance that provide Monitoring and Troubleshooting Viewer. *HASHREF*
	
	$acs->errorMessage
	# Return all ACS message codes and message texts that are used on the REST Interface. *HASHREF*

	
=head1 DESCRIPTION

Net::Cisco::ACS is an implementation of the Cisco Secure Access Control System (ACS) REST API. Cisco ACS is a application / appliance that can be used for network access policy control. In short, it allows configuration of access policies for specific users onto specific devices and applications (either using RADIUS or TACACS+ authentication). Net::Cisco::ACS currently supports Device, Device Group, Host, User, Identity Group and generic information.

=head1 USAGE

All calls are handled through an instance of the L<Net::Cisco::ACS> class.

	use Net::Cisco::ACS;
	my $acs = Net::Cisco::ACS->new(hostname => '10.0.0.1', username => 'acsadmin', password => 'testPassword');

=over 3

=item new

Class constructor. Returns object of Net::Cisco::ACS on succes. Required fields are:

=over 5

=item hostname

=item username

=item password

=back

Optional fields are

=over 5

=item ssl

=item ssl_options

=back

=item hostname

IP or hostname of Cisco ACS 5.x server. This is a required value in the constructor but can be redefined afterwards.

=item username

Username of Administrator user. This is a required value in the constructor but can be redefined afterwards.

=item password

Password of user. This is a required value in the constructor but can be redefined afterwards.

=item ssl

SSL enabled (1 - default) or disabled (0). 

=item ssl_options

Value is passed directly to LWP::UserAGent as ssl_opt. Default value (hash-ref) is

	{ 'SSL_verify_mode' => SSL_VERIFY_NONE, 'verify_hostname' => '0' }

=back

From the class instance, call the different methods for retrieving values.

=over 3

=item users

Returns hash or single instance, depending on context.

	my %users = $acs->users(); # Slow
	my $user = $acs->users()->{"acsadmin"};
	print $user->name;
	
The returned hash contains instances of L<Net::Cisco::ACS::User>, using name (typically the username) as the hash key. Using a call to C<users> with no arguments will retrieve all users and can take quite a few seconds (depending on the size of your database). When you know the username or ID, use the L<users> call with arguments as listed below.
	
	my $user = $acs->users("name","acsadmin"); # Faster
	# or
	my $user = $acs->users("id","123"); # Faster
	print $user->name;

	The ID is typically generated by Cisco ACS when the entry is created. It can be retrieved by calling the C<id> method on the object.

	print $user->id;

=item identitygroups

Returns hash or single instance, depending on context.

	my %identitygroups = $acs->identitygroups(); # Slow
	my $identitygroup = $acs->identitygroups()->{"All Groups"};
	print $identitgroup->name;
	
The returned hash contains instances of L<Net::Cisco::ACS::IdentityGroup>, using name (typically the username) as the hash key. Using a call to C<identitygroup> with no arguments will retrieve all identitygroups and can take quite a few seconds (depending on the size of your database). When you know the group name or ID, use the L<identitygroups> call with arguments as listed below.
	
	my $identitygroup = $acs->identitygroups("name","All Groups"); # Faster
	# or
	my $identitygroup = $acs->identitygroups("id","123"); # Faster
	print $identitygroup->name;

	The ID is typically generated by Cisco ACS when the entry is created. It can be retrieved by calling the C<id> method on the object.

	print $identitygroup->id;
	
=item devices

Returns hash or single instance, depending on context.

	my %devices = $acs->devices(); # Slow
	my $device = $acs->devices()->{"Main_Router"};
	print $device->name;
	
The returned hash contains instances of L<Net::Cisco::ACS::Device>, using name (typically the sysname) as the hash key. Using a call to C<device> with no arguments will retrieve all devices and can take quite a few seconds (depending on the size of your database). When you know the hostname or ID, use the L<devices> call with arguments as listed below.
	
	my $device = $acs->device("name","Main_Router"); # Faster
	# or
	my $device = $acs->device("id","123"); # Faster
	print $device->name;

	The ID is typically generated by Cisco ACS when the entry is created. It can be retrieved by calling the C<id> method on the object.

	print $device->id;

=item devicegroups

Returns hash or single instance, depending on context.

	my %devicegroups = $acs->devicegroups(); # Slow
	my $devicegroup = $acs->devicegroups()->{"All Locations:Main Site"};
	print $devicegroup->name;

The returned hash contains instances of L<Net::Cisco::ACS::DeviceGroup>, using name (typically the device group name) as the hash key. Using a call to C<devicegroups> with no arguments will retrieve all device groups and can take quite a few seconds (depending on the size of your database). When you know the device group or ID, use the L<devicegroups> call with arguments as listed below.
	
	my $devicegroup = $acs->devicegroups("name","All Locations::Main Site"); # Faster
	# or
	my $devicegroup = $acs->devicegroups("id","123"); # Faster
	print $devicegroup->name;

The ID is typically generated by Cisco ACS when the entry is created. It can be retrieved by calling the C<id> method on the object.

	print $devicegroup->id;

=item hosts

Returns hash or single instance, depending on context.

	my %hosts = $acs->hosts(); # Slow
	my $host = $acs->hosts()->{"12345"};
	print $host->name;
	
The returned hash contains instances of L<Net::Cisco::ACS::Host>, using name as the hash key. Using a call to C<hosts> with no arguments will retrieve all hosts and can take quite a few seconds (depending on the size of your database). When you know the name or ID, use the L<hosts> call with arguments as listed below.
	
	my $host = $acs->host("name","12345"); # Faster
	# or
	my $host = $acs->device("id","123"); # Faster
	print $host->name;

	The ID is typically generated by Cisco ACS when the entry is created. It can be retrieved by calling the C<id> method on the object.

	print $host->id;
	
=item version

This method returns version specific information about the Cisco ACS instance you're connected to. Values are returned in a hash reference.

	use Data::Dumper;
	# ... 
	print Dumper $acs->version;

=item servicelocation

This method returns information about the ACS instance that serves as primary and the ACS instance that provide Monitoring and Troubleshooting Viewer. Values are returned in a hash reference.

	use Data::Dumper;
	# ... 
	print Dumper $acs->servicelocation;

=item errormessage

This method returns all ACS message codes and message texts that are used on the REST Interface. Values are returned in a hash reference. See also C<$Net::Cisco::ACS::ERROR>.

	use Data::Dumper;
	# ... 
	print Dumper $acs->errormessage;

=item create

This method created a new entry in Cisco ACS, depending on the argument passed. Record type is detected automatically. For all record types, the ID value must be set to 0.

	my $user = $acs->users("name","acsadmin");
	$user->id(0); # Required for new user!
	$user->name("altadmin"); # Required field
	$user->password("TopSecret"); # Password policies will be enforced!
	$user->description("Alternate Admin"); 
	my $id = $acs->create($user); 
	# Create new user based on Net::Cisco::ACS::User instance
	# Return value is ID generated by ACS
	print "Record ID is $id" if $id;
	print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure

	my $device = $acs->devices("name","Main_Router");
	$device->name("AltRouter"); # Required field
	$device->description("Standby Router"); 
	$device->ips([{netMask => "32", ipAddress=>"10.0.0.2"}]); # Change IP address! Overlap check is enforced!
	$device->id(0); # Required for new device!
	my $id = $acs->create($device);
	# Create new device based on Net::Cisco::ACS::Device instance
	# Return value is ID generated by ACS
	print "Record ID is $id" if $id;
	print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure

Multiple instances can be passed as an argument. Objects will be created in bulk (one transaction). The returned ID is not guaranteed to be the IDs of the created objects.

	my $user = $acs->users("name","acsadmin");
	$user->id(0); # Required for new user!
	$user->name("altadmin"); # Required field
	$user->password("TopSecret"); # Password policies will be enforced!
	$user->description("Alternate Admin"); 

	my $user2 = $acs->users("name","acsadmin");
	$user2->id(0); # Required for new user!
	$user2->name("altadmin"); # Required field
	$user2->password("TopSecret"); # Password policies will be enforced!
	$user2->description("Alternate Admin"); 

	my $id = $acs->create($user,$user2); 
	# Create new users based on Net::Cisco::ACS::User instances in argument.
	# Return value is ID generated by ACS but not guaranteed.
	# print "Record ID is $id" if $id;
	# print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure

	my $device = $acs->devices("name","Main_Router");
	$device->name("MainRouter"); # Required field
	$device->description("Main Router"); 
	$device->ips([{netMask => "32", ipAddress=>"10.0.0.1"}]); # Change IP address! Overlap check is enforced!
	$device->id(0); # Required for new device!

	my $device2 = $acs->devices("name","Alt_Router");
	$device2->name("AltRouter"); # Required field
	$device2->description("Standby Router"); 
	$device2->ips([{netMask => "32", ipAddress=>"10.0.0.2"}]); # Change IP address! Overlap check is enforced!
	$device2->id(0); # Required for new device!
	
    my $id = $acs->create($device,$device2);
	# Create new device based on Net::Cisco::ACS::Device instance
	# Return value is ID generated by ACS but not guaranteed.
	# print "Record ID is $id" if $id;
	# print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure
    
=item update

This method updates an existing entry in Cisco ACS, depending on the argument passed. Record type is detected automatically. 

	my $user = $acs->users("name","acsadmin");
	$user->password("TopSecret"); # Change password. Password policies will be enforced!
	my $id = $acs->update($user);
	# Update user based on Net::Cisco::ACS::User instance
	# Return value is ID generated by ACS
	print "Record ID is $id" if $id;
	print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure

	my $device = $acs->devices("name","Main_Router");
	$user->description("To be ceased"); # Change description
	$device->ips([{netMask => "32", ipAddress=>"10.0.0.2"}]); # or Change IP address. Overlap check is enforced!
	my $id = $acs->update($device);
	# Create new device based on Net::Cisco::ACS::Device instance
	# Return value is ID generated by ACS
	print "Record ID is $id" if $id;
	print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure

Multiple instances can be passed as an argument. Objects will be updated in bulk (one transaction). The returned ID is not guaranteed to be the IDs of the created objects.

	my $user = $acs->users("name","acsadmin");
	$user->id(0); # Required for new user!
	$user->password("TopSecret"); # Password policies will be enforced!

	my $user2 = $acs->users("name","acsadmin2");
	$user2->password("TopSecret"); # Password policies will be enforced!

	my $id = $acs->update($user,$user2); 
	# Update users based on Net::Cisco::ACS::User instances in arguments
	# Return value is ID generated by ACS but not guaranteed.
	# print "Record ID is $id" if $id;
	# print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure

	my $device = $acs->devices("name","Main_Router");
	$device->description("Main Router"); 
	$device->ips([{netMask => "32", ipAddress=>"10.0.0.1"}]); # Change IP address! Overlap check is enforced!

	my $device2 = $acs->devices("name","Alt_Router");
	$device2->description("Standby Router"); 
	$device2->ips([{netMask => "32", ipAddress=>"10.0.0.2"}]); # Change IP address! Overlap check is enforced!
	
    my $id = $acs->create($device,$device2);
	# Update devices based on Net::Cisco::ACS::Device instances in arguments
	# Return value is ID generated by ACS but not guaranteed.
	# print "Record ID is $id" if $id;
	# print $Net::Cisco::ACS::ERROR unless $id;
	# $Net::Cisco::ACS::ERROR contains details about failure    
    
=item delete

This method deletes an existing entry in Cisco ACS, depending on the argument passed. Record type is detected automatically. 

	my $user = $acs->users("name","acsadmin");
	$acs->delete($user);

	my $device = $acs->users("name","Main_Router");
	$acs->delete($device);

=item $ERROR

This variable will contain detailed error information, based on the REST API answer. This value is reset during every call to C<users>, C<devices> and C<devicegroups>.	
	
=back

=head1 REQUIREMENTS

For this library to work, you need an instance with Cisco ACS (obviously) or a simulator like L<Net::Cisco::ACS::Mock>. 

To enable the Cisco ACS REST API, you will need to run the command below from the Cisco ACS console:

	acs config-web-interface rest enable 

You will also need an administrator-role account, typically NOT associated with a device-access account. Configure the account through the GUI.

		System Administration > Administrators > Accounts

You will need more than generic privileges (SuperAdmin is ideal, suspected that UserAdmin and NetworkDeviceAdmin are sufficient).

You will also need

=over 3

=item L<Moose>

=item L<IO::Socket::SSL>

=item L<LWP::UserAgent>

=item L<XML::Simple>

=item L<MIME::Base64>

=item L<URI::Escape>

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

=head1 COMPATIBILITY

Certain API calls are not support from Cisco ACS 5.0 onwards. The current supported versions of Cisco ACS (by Cisco) are 5.6, 5.7 and 5.8 (Active). 

=head1 SEE ALSO

=over 3

See L<Net::Cisco::ACS::User> for more information on User management.

See L<Net::Cisco::ACS::IdentityGroup> for more information on User Group management.

See L<Net::Cisco::ACS::Device> for more information on Device management.

See L<Net::Cisco::ACS::DeviceGroup> for more information on Device Group management.

See L<Net::Cisco::ACS::Host> for more information on Host management.

See the L<Cisco ACS product page|http://www.cisco.com/c/en/us/products/security/secure-access-control-system/index.html> for more information.

L<Net::Cisco::ACS> relies on L<Moose>. 

=back

=cut

#################### main pod documentation end ###################

__PACKAGE__->meta->make_immutable();

1;
# The preceding line will help the module return a true value

