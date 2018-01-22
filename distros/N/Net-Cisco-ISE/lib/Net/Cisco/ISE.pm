package Net::Cisco::ISE;
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

# Net::Cisco::ISE::*
use lib qw(.);
use Net::Cisco::ISE::InternalUser;
use Net::Cisco::ISE::IdentityGroup;
use Net::Cisco::ISE::NetworkDevice;
use Net::Cisco::ISE::NetworkDeviceGroup;
#use Net::Cisco::ISE::Endpoint;
#use Net::Cisco::ISE::EndpointCertificate;
#use Net::Cisco::ISE::EndpointIdentityGroup;
#use Net::Cisco::ISE::Portal;
#use Net::Cisco::ISE::Profile;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $ERROR %actions);
    $VERSION     = '0.06';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
	
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
	isa => 'Str',
    default => '9060'
	); 
        
has 'mock' => (
	is => 'rw',
	isa => 'Str',
	default => '0',
	);    

has 'debug' => (
    is => 'rw',
    isa => 'Str',
    default => '0',
);

has 'namespace3' => (
    is => 'rw',
    isa => 'Str',
    default => 'ns3:resources',
);
    
has 'namespace5' => (
    is => 'rw',
    isa => 'Str',
    default => 'ns5:resource',
);

sub internalusers # No Moose here :(
{	my $self = shift;
    $ERROR = "";
	if (@_)
	{ my %args = @_; 
	  $self->{"InternalUsers"} = $args{"internalusers"};
      if ($self->mock())
      { return $self->{"InternalUsers"}; }      
	  if ($args{"id"})
	  { $self->{"InternalUsers"} = $self->query("InternalUser","id",$args{"id"}); }
	} else
	{ $self->{"InternalUsers"} = $self->query("InternalUser");
	}
	return $self->{"InternalUsers"};
}	

sub identitygroups # No Moose here :(
{	my $self = shift;
    $ERROR = "";
	if (@_)
	{ my %args = @_; 
	  $self->{"IdentityGroups"} = $args{"identitygroups"}; 
      if ($self->mock())
      { return $self->{"IdentityGroups"}; }
	  if ($args{"id"})
	  { $self->{"IdentityGroups"} = $self->query("IdentityGroup","id",$args{"id"}); }
	} else
	{ $self->{"IdentityGroups"} = $self->query("IdentityGroup"); 
	}
	return $self->{"IdentityGroups"};
}	

sub endpointidentitygroups # No Moose here :(
{   my $self = shift;
    $ERROR = "";
    if (@_)
    { my %args = @_;
      $self->{"EndpointIdentityGroups"} = $args{"endpointidentitygroups"};
      if ($self->mock())
      { return $self->{"EndpointIdentityGroups"}; }
        if ($args{"id"})
        { $self->{"EndpointIdentityGroups"} = $self->query("EndpointIdentityGroup","id",$args{"id"}); }
      } else
      { $self->{"EndpointIdentityGroups"} = $self->query("EndpointIdentityGroup");
      }
      return $self->{"EndpointIdentityGroups"};
}

sub networkdevices # No Moose here :(
{	my $self = shift;
	$ERROR = "";
	if (@_)
	{ my %args = @_; 
	  $self->{"NetworkDevices"} = $args{"networkdevices"};
      if ($self->mock())
      { return $self->{"NetworkDevices"}; }
	  if ($args{"id"})
	  { $self->{"NetworkDevices"} = $self->query("NetworkDevice","id",$args{"id"}); }
	} else
	{ $self->{"NetworkDevices"} = $self->query("NetworkDevice"); 
	}
	return $self->{"NetworkDevices"};
}	

sub networkdevicegroups # No Moose here :(
{	my $self = shift;
	$ERROR = "";
	if (@_)
	{ my %args = @_; 
	  $self->{"NetworkDeviceGroups"} = $args{"networkdevicegroups"};
      if ($self->mock())
      { return $self->{"NetworkDeviceGroups"}; }
	  if ($args{"id"})
	  { $self->{"NetworkDeviceGroups"} = $self->query("NetworkDeviceGroup","id",$args{"id"}); }
	} else
	{ $self->{"NetworkDeviceGroups"} = $self->query("NetworkDeviceGroup"); 
	}
	return $self->{"NetworkDeviceGroups"};
}	

sub endpoints # No Moose here :(
{	my $self = shift;
	$ERROR = "";
	if (@_)
	{ my %args = @_; 
	  $self->{"Endpoints"} = $args{"endpoints"};
      if ($self->mock())
      { return $self->{"Endpoints"}; }
	  if ($args{"id"})
	  { $self->{"Endpoints"} = $self->query("Endpoint","id",$args{"id"}); }
	} else
	{ $self->{"Endpoints"} = $self->query("Endpoint"); 
	}
	return $self->{"Endpoints"};
}	
	
sub endpointcertificates # No Moose here :(
{   my $self = shift;
    $ERROR = "";
    if (@_)
    { my %args = @_;
      $self->{"EndpointCertificates"} = $args{"endpointcertificates"};
      if ($self->mock())
      { return $self->{"EndpointCertificates"}; }
      if ($args{"id"})
      { $self->{"EndpointCertificates"} = $self->query("EndpointCertificate","id",$args{"id"}); }
    } else
    { $self->{"EndpointCertificates"} = $self->query("EndpointCertificate");
    }
    return $self->{"EndpointCertificates"};
}

sub portals # No Moose here :(
{   my $self = shift;
    $ERROR = "";
    if (@_)
    { my %args = @_;
      $self->{"Portals"} = $args{"portals"};
      if ($self->mock())
      { return $self->{"Portals"}; }
      if ($args{"id"})
      { $self->{"Portals"} = $self->query("Portal","id",$args{"id"}); }
      } else
      { $self->{"Portals"} = $self->query("Portal");
    }
    return $self->{"Portals"};
}

sub profiles # No Moose here :(
{   my $self = shift;
    $ERROR = "";
    if (@_)
    { my %args = @_;
      $self->{"Profiles"} = $args{"profiles"};
      if ($self->mock())
      { return $self->{"Profiles"}; }
        if ($args{"id"})
        { $self->{"Profiles"} = $self->query("Profile","id",$args{"id"}); }
    } else
    { $self->{"Profiles"} = $self->query("Profile");
    }
    return $self->{"Profiles"};
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
	
# Non-Moose

sub query 
{ my ($self, $type, $key, $value) = @_;
  my $hostname = $self->hostname;
  my $credentials = encode_base64($self->username.":".$self->password);
  if ($self->ssl)
  { $hostname = "https://$hostname"; } else
  { $hostname = "http://$hostname"; }
  $hostname .= ":".$self->port if $self->port;
  my $action = "";
  my $mode = "";
  my $accepttype ="";
  $key ||= "";
  if ($type eq "InternalUser")
  { $action = $Net::Cisco::ISE::InternalUser::actions{"query"}; 
    $mode = "InternalUsers";
    $accepttype = "identity.internaluser.1.0";
	if ($key eq "id")
	{ $action = $Net::Cisco::ISE::InternalUser::actions{"getById"}.$value; 
	  $mode = "InternalUser";
	}
  }
  if ($type eq "IdentityGroup")
  { $action = $Net::Cisco::ISE::IdentityGroup::actions{"query"}; 
    $mode = "IdentityGroups";
    $accepttype = "identity.identitygroup.1.0";
	if ($key eq "id")
	{ $action = $Net::Cisco::ISE::IdentityGroup::actions{"getById"}.$value; 
	  $mode = "IdentityGroup";
	}
  }

  if ($type eq "EndpointIdentityGroup")
  { #$action = $Net::Cisco::ISE::EndpointIdentityGroup::actions{"query"};
    $mode = "EndpointIdentityGroups";
    $accepttype = "identity.endpointgroup.1.0";
    if ($key eq "id")
    { #$action = $Net::Cisco::ISE::EndpointIdentityGroup::actions{"getById"}.$value;
      $mode = "EndpointIdentityGroup";
    }
  }
  if ($type eq "NetworkDevice")
  { $action = $Net::Cisco::ISE::NetworkDevice::actions{"query"}; 
    $mode = "NetworkDevices";
    $accepttype = "network.networkdevice.1.1";
	if ($key eq "id")
	{ $action = $Net::Cisco::ISE::NetworkDevice::actions{"getById"}.$value; 
	  $mode = "NetworkDevice";
	}
  }
  if ($type eq "NetworkDeviceGroup")
  { $action = $Net::Cisco::ISE::NetworkDeviceGroup::actions{"query"}; 
    $mode = "NetworkDeviceGroups";
    $accepttype = "network.networkdevicegroup.1.1";
	if ($key eq "id")
	{ $action = $Net::Cisco::ISE::NetworkDeviceGroup::actions{"getById"}.$value; 
	  $mode = "NetworkDeviceGroup";
	}
  }
  if ($type eq "Endpoint")
  { #$action = $Net::Cisco::ISE::Endpoint::actions{"query"}; 
    $mode = "Endpoints";
    $accepttype = "identity.endpoint.1.0";
	if ($key eq "id")
	{ #$action = $Net::Cisco::ISE::Endpoint::actions{"getById"}.$value; 
	  $mode = "Endpoint";
	}
  }
  if ($type eq "EndpointCertificate")
  { #$action = $Net::Cisco::ISE::EndpointCertificate::actions{"query"};
    $mode = "EndpointCertificates";
    $accepttype = "ca.endpointcert.1.0";
    if ($key eq "id")
    { #$action = $Net::Cisco::ISE::EndpointCertificate::actions{"getById"}.$value;
      $mode = "EndpointCertificate";
    }
  }

  if ($type eq "Portal")
  { #$action = $Net::Cisco::ISE::Portal::actions{"query"};
    $mode = "Portals";
    $accepttype = "identity.portal.1.0";
    if ($key eq "id")
    { #$action = $Net::Cisco::ISE::Portal::actions{"getById"}.$value;
      $mode = "Portal";
    }
  }
  if ($type eq "Profile")
  { #$action = $Net::Cisco::ISE::Profile::actions{"query"};
    $mode = "Profiles";
    $accepttype = "identity.profilerprofile.1.0";
    if ($key eq "id")
    { #$action = $Net::Cisco::ISE::Profile::actions{"getById"}.$value;
      $mode = "Profile";
    }
  }

  $hostname = $hostname . $action;
  my $useragent = LWP::UserAgent->new (ssl_opts => $self->ssl_options);
  my $request = HTTP::Request->new(GET => $hostname );
  $request->header('Authorization' => "Basic $credentials", Accept => "application/vnd.com.cisco.ise.$accepttype+xml");
  my $result = $useragent->request($request);
  if ($result->code eq "400") { $ERROR = "Bad Request - HTTP Status: 400"; }
  if ($result->code eq "410") { $ERROR = "Unknown $type queried by name or ID - HTTP Status: 410"; }
  warn Dumper $result->content if $self->debug;
  $result = $self->parse_xml($mode, $result->content);
  warn Dumper $result if $self->debug;
  return $result;
}

sub create 
{ my $self = shift;
  my $record = shift;
  return unless $record;
  my $hostname = $self->hostname;
  my $credentials = encode_base64($self->username.":".$self->password);
  if ($self->ssl)
  { $hostname = "https://$hostname"; } else
  { $hostname = "http://$hostname"; }
  $hostname .= ":".$self->port if $self->port;
  my $action = "";
  my $data = "";
  my $accepttype = "";
  if (ref($record) eq "Net::Cisco::ISE::InternalUser")
  { $action = $Net::Cisco::ISE::InternalUser::actions{"create"}; 
    $accepttype = "identity.internaluser.1.0";
  }

  if (ref($record) eq "Net::Cisco::ISE::IdentityGroup")
  { #$action = $Net::Cisco::ISE::IdentityGroup::actions{"create"}; 
    #$accepttype = "identity.identitygroup.1.0";
    # ISE does not support creating Identity Groups through the API. No idea why this is!
  }

  if (ref($record) eq "Net::Cisco::ISE::NetworkDevice")
  { $action = $Net::Cisco::ISE::NetworkDevice::actions{"create"}; 
    $accepttype = "network.networkdevice.1.1";
  }
  
  if (ref($record) eq "Net::Cisco::ISE::NetworkDeviceGroup")
  { $action = $Net::Cisco::ISE::NetworkDeviceGroup::actions{"create"}; 
    $accepttype = "network.networkdevicegroup.1.1";
  }

  if (ref($record) eq "Net::Cisco::ISE::Endpoint")
  { #$action = $Net::Cisco::ISE::Endpoint::actions{"create"}; 
    $accepttype = "identity.endpoint.1.0";
  }
  if (ref($record) eq "Net::Cisco::ISE::EndpointCertificate")
  { #$action = $Net::Cisco::ISE::EndpointCertificate::actions{"create"};
    $accepttype = "ca.endpointcert.1.0";
  }
  if (ref($record) eq "Net::Cisco::ISE::EndpointIdentityGroup")
  { #$action = $Net::Cisco::ISE::EndpointIdentityGroup::actions{"create"};
    $accepttype = "identity.endpointgroup.1.0";
  }
  if (ref($record) eq "Net::Cisco::ISE::Portal")
  { #$action = $Net::Cisco::ISE::Portal::actions{"create"};
    $accepttype = "identity.portal.1.0";
  }
  if (ref($record) eq "Net::Cisco::ISE::Profile")
  { #$action = $Net::Cisco::ISE::Profile::actions{"create"};
    $accepttype = "identity.profilerprofile.1.0";
  }

  $data .= $record->toXML;
  $data = $record->header($data,$record);
  $hostname = $hostname . $action;
  my $useragent = LWP::UserAgent->new (ssl_opts => $self->ssl_options);
  my $request = HTTP::Request->new(POST => $hostname );
  $request->content_type("application/xml");  
  $request->header("Authorization" => "Basic $credentials",  "Content-Type" => "application/vnd.com.cisco.ise.$accepttype+xml; charset=utf-8", Accept => "application/vnd.com.cisco.ise.$accepttype+xml");
  $request->content($data);
  my $result = $useragent->request($request);
  my $id = "";
  if ($result->code ne "201") 
  { my $result_ref = $self->parse_xml("messages", $result->content); 
    $ERROR = $result_ref->{"messages"}{"message"}{"type"}.":".$result_ref->{"messages"}{"message"}{"code"}." - ".$result_ref->{"messages"}{"message"}{"title"}." "." - HTTP Status: ".$result->code;
  } else 
  { my $location = $result->header("location"); 
    ($id) = $location =~ /^.*\/([^\/]*)$/;
  }
  return $id;
}

sub update 
{ my $self = shift;
  my $record = shift;
  return unless $record;
  my $hostname = $self->hostname;
  my $credentials = encode_base64($self->username.":".$self->password);
  if ($self->ssl)
  { $hostname = "https://$hostname"; } else
  { $hostname = "http://$hostname"; }
  $hostname .= ":".$self->port if $self->port;
  my $action = "";
  my $data = "";
  my $accepttype = "";
  if (ref($record) eq "Net::Cisco::ISE::InternalUser")
  { $action = $Net::Cisco::ISE::InternalUser::actions{"update"}; 
    $accepttype = "identity.internaluser.1.0";
  }

  if (ref($record) eq "Net::Cisco::ISE::IdentityGroup")
  { $action = $Net::Cisco::ISE::IdentityGroup::actions{"update"}; 
    $accepttype = "identity.identitygroup.1.0";
  }

  if (ref($record) eq "Net::Cisco::ISE::NetworkDevice")
  { $action = $Net::Cisco::ISE::NetworkDevice::actions{"update"}; 
    $accepttype = "network.networkdevice.1.1";
  }
  
  if (ref($record) eq "Net::Cisco::ISE::NetworkDeviceGroup")
  { $action = $Net::Cisco::ISE::NetworkDeviceGroup::actions{"update"}; 
    $accepttype = "network.networkdevicegroup.1.1";
  }

  if (ref($record) eq "Net::Cisco::ISE::Endpoint")
  { #$action = $Net::Cisco::ISE::Endpoint::actions{"update"}; 
    $accepttype = "identity.endpoint.1.0";
  }

  if (ref($record) eq "Net::Cisco::ISE::EndpointCertificate")
  { #$action = $Net::Cisco::ISE::EndpointCertificate::actions{"update"};
    $accepttype = "ca.endpointcert.1.0";
  }

  if (ref($record) eq "Net::Cisco::ISE::EndpointIdentityGroup")
  { #$action = $Net::Cisco::ISE::EndpointIdentityGroup::actions{"update"};
    $accepttype = "identity.endpointgroup.1.0";
  }

  if (ref($record) eq "Net::Cisco::ISE::Portal")
  { #$action = $Net::Cisco::ISE::Portal::actions{"update"};
    $accepttype = "identity.portal.1.0";
  }

  if (ref($record) eq "Net::Cisco::ISE::Profile")
  { #$action = $Net::Cisco::ISE::Profile::actions{"update"};
    $accepttype = "identity.profilerprofile.1.0";
  }

  $data .= $record->toXML;

  $data = $record->header($data, $record);  
  $hostname = $hostname . $action.$record->id;
  my $useragent = LWP::UserAgent->new (ssl_opts => $self->ssl_options);
  my $request = HTTP::Request->new(PUT => $hostname );
  $request->content_type("application/xml");  
  $request->header("Authorization" => "Basic $credentials", "Content-Type" => "application/vnd.com.cisco.ise.$accepttype+xml");
  $request->content($data);
  warn Dumper $request if $self->debug;
  my $result = $useragent->request($request);
  my $id = "";
  if ($result->code ne "200")
  { my $result_ref = $self->parse_xml("messages", $result->content);
    $ERROR = $result_ref->{"messages"}{"message"}{"type"}.":".$result_ref->{"messages"}{"message"}{"code"}." - ".$result_ref->{"messages"}{"message"}{"title"}." "." - HTTP Status: ".$result->code;
  } else
  { my $location = $result->header("location");
    ($id) = $location =~ /^.*\/([^\/]*)$/;
  }
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
  $hostname .= ":".$self->port if $self->port;
  my $action = "";
  my $type = "";
  my $accepttype = "";
  
  if (ref($record) eq "ARRAY") { $record = $record->[0]; }
  if (ref($record) eq "Net::Cisco::ISE::InternalUser")
  { $action = $Net::Cisco::ISE::InternalUser::actions{"getById"}; 
    $type = "InternalUser";
    $accepttype = "identity.internaluser.1.0";
  }

  if (ref($record) eq "Net::Cisco::ISE::IdentityGroup")
  { $action = $Net::Cisco::ISE::IdentityGroup::actions{"getById"}; 
    $type = "IdentityGroup";
    $accepttype = "identity.identitygroup.1.0";
  }

  if (ref($record) eq "Net::Cisco::ISE::NetworkDevice")
  { $action = $Net::Cisco::ISE::NetworkDevice::actions{"getById"}; 
    $type = "NetworkDevice";
    $accepttype = "network.networkdevice.1.1";
  }
  
  if (ref($record) eq "Net::Cisco::ISE::NetworkDeviceGroup")
  { $action = $Net::Cisco::ISE::NetworkDeviceGroup::actions{"getById"}; 
    $type = "NetworkDeviceGroup";
    $accepttype = "network.networkdevicegroup.1.1";
  }

  if (ref($record) eq "Net::Cisco::ISE::Endpoint")
  { #$action = $Net::Cisco::ISE::Endpoint::actions{"getById"}; 
    $type = "Endpoint";
    $accepttype = "identity.endpoint.1.0";
  }

  # Not sure Endpoint Certificates can be deleted 
  if (ref($record) eq "Net::Cisco::ISE::EndpointCertificate")
  { #$action = $Net::Cisco::ISE::EndpointCertificate::actions{"getById"};
    $type = "EndpointCertificate";
    $accepttype = "ca.endpointcert.1.0";
  }

  if (ref($record) eq "Net::Cisco::ISE::EndpointIdentityGroup")
  { #$action = $Net::Cisco::ISE::EndpointIdentityGroup::actions{"getById"};
    $type = "EndpointIdentityGroup";
    $accepttype = "identity.endpointgroup.1.0";
  }

  if (ref($record) eq "Net::Cisco::ISE::Portal")
  { #$action = $Net::Cisco::ISE::Portal::actions{"getById"};
    $type = "Portal";
    $accepttype = "identity.portal.1.0";
  }

  if (ref($record) eq "Net::Cisco::ISE::Profile")
  { #$action = $Net::Cisco::ISE::Profile::actions{"getById"};
    $type = "Profile";
    $accepttype = "identity.profilerprofile.1.0";
  }

 
  $hostname = $hostname . $action.$record->id;
  my $useragent = LWP::UserAgent->new (ssl_opts => $self->ssl_options);
  my $request = HTTP::Request->new(DELETE => $hostname );
  $request->content_type("application/xml");  
  $request->header("Authorization" => "Basic $credentials", Accept => "application/vnd.com.cisco.ise.$accepttype+xml");
  my $result = $useragent->request($request);
  my $id = "";
  if ($result->code ne "204") 
  { $ERROR = $result->{"code"};
  }
}

sub parse_xml
{ my $self = shift;
  my $type = shift;
  my $xml_ref = shift;
  my $xmlsimple = XML::Simple->new(SuppressEmpty => 1);
  my $xmlout = $xmlsimple->XMLin($xml_ref);
  my $namespace3 = $self->namespace3;
  my $namespace5 = $self->namespace5;
  if ($type eq "InternalUsers")
  { #my $users_ref = $xmlout->{"InternalUser"};
    my $users_ref = $xmlout->{$namespace3}{$namespace5};
    my %users = ();
    for my $key (keys % {$users_ref})
    { my $user = Net::Cisco::ISE::InternalUser->new( name => $key, %{ $users_ref->{$key} } );
      $users{$key} = $user;
    }
    $self->{"InternalUsers"} = \%users;
	return $self->{"InternalUsers"};
  }
  if ($type eq "InternalUser") # userByName and userById DO NOT return hash but a single instance of Net::Cisco::ISE::InternalUser
  { my %user_hash = %{ $xmlout };
    my $user = Net::Cisco::ISE::InternalUser->new( %user_hash );
	$self->{"InternalUsers"} = $user ;
	return $self->{"InternalUsers"};
  }

  if ($type eq "IdentityGroups")
  { my $identitygroups_ref = $xmlout->{$namespace3}{$namespace5};
    my %identitygroups = ();
    # With Single entry, this approach will break!!!
    # !!BUG!!
    for my $key (keys % {$identitygroups_ref})
    { my $identitygroup = Net::Cisco::ISE::IdentityGroup->new( name => $key, %{ $identitygroups_ref->{$key} } );
      $identitygroups{$key} = $identitygroup;
    }
    $self->{"IdentityGroups"} = \%identitygroups;
	return $self->{"IdentityGroups"};
  }
  if ($type eq "IdentityGroup") # ByName and ById DO NOT return hash but a single instance of Net::Cisco::ISE::IdentityGroup
  { my %identitygroup_hash = %{ $xmlout };
    my $identitygroup = Net::Cisco::ISE::IdentityGroup->new( %identitygroup_hash );
	$self->{"IdentityGroups"} = $identitygroup;
	return $self->{"IdentityGroups"};
  }
  
  if ($type eq "NetworkDevices")
  { my $device_ref = $xmlout->{$namespace3}{$namespace5};
    my %devices = (); 
    warn Dumper $xml_ref if $self->debug;
    for my $key (keys % {$device_ref})
    { my $device = Net::Cisco::ISE::NetworkDevice->new( name => $key, id => $device_ref->{$key}{"id"} );
      $devices{$key} = $device;
    }
    $self->{"NetworkDevices"} = \%devices;
    return $self->{"NetworkDevices"};
  }
  if ($type eq "NetworkDevice") # deviceByName and deviceById DO NOT return hash but a single instance of Net::Cisco::ISE::NetworkDevice
  { my %device_hash = %{ $xmlout };
    my $device = Net::Cisco::ISE::NetworkDevice->new( %device_hash );
	$self->{"NetworkDevices"} = $device;
	return $self->{"NetworkDevices"};
  }

  if ($type eq "NetworkDeviceGroups")
  { my $devicegroup_ref = $xmlout->{$namespace3}{$namespace5};
    my %devicegroups = ();
	for my $key (keys % {$devicegroup_ref})
    { my $devicegroup = Net::Cisco::ISE::NetworkDeviceGroup->new( name => $key, %{ $devicegroup_ref->{$key} } );
      $devicegroups{$key} = $devicegroup;
    }
	$self->{"NetworkDeviceGroups"} = \%devicegroups;
	return $self->{"NetworkDeviceGroups"};
  }
  if ($type eq "NetworkDeviceGroup") # deviceGroupByName and deviceGroupById DO NOT return hash but a single instance of Net::Cisco::ISE::NetworkDeviceGroup
  { my %devicegroup_hash = %{ $xmlout };
    my $devicegroup = Net::Cisco::ISE::NetworkDeviceGroup->new( %devicegroup_hash );
	$self->{"NetworkDeviceGroups"} = $devicegroup;
	return $self->{"NetworkDeviceGroups"};
  }
  
  if ($type eq "Endpoints")
  { my $host_ref = $xmlout->{$namespace3}{$namespace5};
    my %hosts = ();
	for my $key (keys % {$host_ref})
    { #my $host = Net::Cisco::ISE::Endpoint->new( macAddress => $key, %{ $host_ref->{$key} } );
      #$hosts{$key} = $host;
    }
	$self->{"Endpoints"} = \%hosts;
	return $self->{"Endpoints"};
  }
  if ($type eq "Endpoint") # ByName and ById DO NOT return hash but a single instance of Net::Cisco::ISE::Endpoint
  { my %host_hash = %{ $xmlout };
    #my $host = Net::Cisco::ISE::Endpoint->new( %host_hash );
	#$self->{"Endpoints"} = $host;
	return $self->{"Endpoints"};
  }
 
  if ($type eq "EndpointCertificates")
  { my $host_ref = $xmlout->{$namespace3}{$namespace5};
    my %hosts = ();
    for my $key (keys % {$host_ref})
    { #my $host = Net::Cisco::ISE::EndpointCertificate->new( name => $key, %{ $host_ref->{$key} } );
      #$hosts{$key} = $host;
    }
    $self->{"EndpointCertificates"} = \%hosts;
    return $self->{"EndpointCertificates"};
  }
  if ($type eq "EndpointCertificate") # ByName and ById DO NOT return hash but a single instance of Net::Cisco::ISE::Endpoint
  { my %host_hash = %{ $xmlout };
    #my $host = Net::Cisco::ISE::EndpointCertificate->new( %host_hash );
    #$self->{"EndpointCertificates"} = $host;
    return $self->{"EndpointCertificates"};
  }

  if ($type eq "EndpointIdentityGroups")
  { my $host_ref = $xmlout->{$namespace3}{$namespace5};
    my %hosts = ();
    for my $key (keys % {$host_ref})
    { #my $host = Net::Cisco::ISE::EndpointIdentityGroup->new( name => $key, %{ $host_ref->{$key} } );
      #$hosts{$key} = $host;
    }
    $self->{"EndpointIdentityGroups"} = \%hosts;
    return $self->{"EndpointIdentityGroups"};
  }
  if ($type eq "EndpointIdentityGroup") # ByName and ById DO NOT return hash but a single instance of Net::Cisco::ISE::Endpoint
  { my %host_hash = %{ $xmlout };
    #my $host = Net::Cisco::ISE::EndpointIdentityGroup->new( %host_hash );
    #$self->{"EndpointIdentityGroups"} = $host;
    return $self->{"EndpointIdentityGroups"};
  }

  if ($type eq "Portals")
  { my $host_ref = $xmlout->{$namespace3}{$namespace5};
    my %hosts = ();
    for my $key (keys % {$host_ref})
    { #my $host = Net::Cisco::ISE::Portal->new( name => $key, %{ $host_ref->{$key} } );
      #$hosts{$key} = $host;
    }
    $self->{"Portals"} = \%hosts;
    return $self->{"Portals"};
  }
  if ($type eq "Portal") # ByName and ById DO NOT return hash but a single instance of Net::Cisco::ISE::Endpoint
  { my %host_hash = %{ $xmlout };
    #my $host = Net::Cisco::ISE::Portal->new( %host_hash );
    #$self->{"Portals"} = $host;
    return $self->{"Portals"};
  }

  if ($type eq "Profiles")
  { my $host_ref = $xmlout->{$namespace3}{$namespace5};
    my %hosts = ();
    for my $key (keys % {$host_ref})
    { #my $host = Net::Cisco::ISE::Profile->new( name => $key, %{ $host_ref->{$key} } );
      #$hosts{$key} = $host;
    }
    $self->{"Profiles"} = \%hosts;
    return $self->{"Profiles"};
  }
  if ($type eq "Profile") # ByName and ById DO NOT return hash but a single instance of Net::Cisco::ISE::Endpoint
  { my %host_hash = %{ $xmlout };
    #my $host = Net::Cisco::ISE::Profile->new( %host_hash );
    #$self->{"Profiles"} = $host;
    return $self->{"Profiles"};
  }

  if ($type eq "result")
  { my %result_hash = %{ $xmlout };
    return \%result_hash;
  }
  if ($type eq "messages")
  { my %result_hash = %{ $xmlout };
    return \%result_hash;
  }
}

=head1 NAME

Net::Cisco::ISE - Access Cisco ISE functionality through REST API

=head1 SYNOPSIS

	use Net::Cisco::ISE;
	my $ise = Net::Cisco::ISE->new(hostname => '10.0.0.1', username => 'admin', password => 'testPassword');
	# Options:
	# hostname - IP or hostname of Cisco ISE 5.x server
	# username - Username of Administrator user
	# password - Password of user
	# port - TCP port 9060 by default
	# ssl - SSL enabled (1 - default) or disabled (0)
		
	my %users = $ise->internalusers;
	# Retrieve all users from ISE
	# Returns hash with username / Net::Cisco::ISE::InternalUser pairs
	
	print $ise->internalusers->{"admin"}->toXML;
	# Dump in XML format (used by ISE for API calls)
	
	my $user = $ise->internalusers("name","admin");
	# Faster call to request specific user information by name

	my $user = $ise->internalusers("id","b74a0ef2-b29c-40e3-a0d1-4c0dfb51ace9");
	# Faster call to request specific user information by ID (assigned by ISE, present in Net::Cisco::ISE::InternalUser)

	my %identitygroups = $ise->identitygroups;
	# Retrieve all identitygroups from ISE
	# Returns hash with name / Net::Cisco::ISE::IdentityGroup pairs
	
	print $ise->identitygroups->{"All Groups"}->toXML;
	# Dump in XML format (used by ISE for API calls)
	
	my $identitygroup = $ise->identitygroups("name","All Groups");
	# Faster call to request specific identity group information by name

	my $identitygroup = $ise->identitygroups("id","4fffc260-9b96-11e6-93fb-005056ad1454");
	# Faster call to request specific identity group information by ID (assigned by ISE, present in Net::Cisco::ISE::IdentityGroup)

	my $device = $ise->networkdevices("name","MAIN_Router");
	# Faster call to request specific device information by name

	my $device = $ise->networkdevices("id","250");
	# Faster call to request specific device information by ID (assigned by ISE, present in Net::Cisco::ISE::NetworkDevice)
	
	$user->id(0); # Required for new user!
	my $id = $ise->create($user);
	# Create new user based on Net::Cisco::ISE::InternalUser instance
	# Return value is ID generated by ISE
	print "Record ID is $id" if $id;
	print $Net::Cisco::ISE::ERROR unless $id;
	# $Net::Cisco::ISE::ERROR contains details about failure

	my $id = $ise->create(@users); # Still requires nullified ID!
	# Create new users based on Net::Cisco::ISE::InternalUser instances in arguments
	# Return value is not guaranteed in this case!
	# print "Record ID is $id" if $id;
	# print $Net::Cisco::ISE::ERROR unless $id;
	# $Net::Cisco::ISE::ERROR contains details about failure    
    
	$identitygroup->id(0); # Required for new record!
	my $id = $ise->create($identitygroup);
	# Create new identity group based on Net::Cisco::ISE::IdentityGroup instance
	# Return value is ID generated by ISE
	print "Record ID is $id" if $id;
	print $Net::Cisco::ISE::ERROR unless $id;
	# $Net::Cisco::ISE::ERROR contains details about failure

    # Cisco ISE does not support modifying an identity group through the API
	
	my $id = $ise->update($user);
	# Update existing user based on Net::Cisco::ISE::InternalUser instance
	# Return value is ID generated by ISE
	print "Record ID is $id" if $id;
	print $Net::Cisco::ISE::ERROR unless $id;
	# $Net::Cisco::ISE::ERROR contains details about failure

	my $id = $ise->update(@users);
	# Update existing users based on Net::Cisco::ISE::InternalUser instances in arguments
	# Return value is not guaranteed in this case!
	# print "Record ID is $id" if $id;
	# print $Net::Cisco::ISE::ERROR unless $id;
	# $Net::Cisco::ISE::ERROR contains details about failure        
        
	$ise->delete($user);
	# Delete existing user based on Net::Cisco::ISE::InternalUser instance
	
=head1 DESCRIPTION

Net::Cisco::ISE is an implementation of the Cisco Identity Services Engine (ISE) REST API. Cisco ISE is a application / appliance that can be used for network access policy control. In short, it allows configuration of access policies for specific users onto specific devices and applications (either using RADIUS or TACISE+ authentication). Net::Cisco::ISE currently supports InternalUser and IdentityGroup.

=head1 USAGE

All calls are handled through an instance of the L<Net::Cisco::ISE> class.

	use Net::Cisco::ISE;
	my $ise = Net::Cisco::ISE->new(hostname => '10.0.0.1', username => 'admin', password => 'testPassword');

=over 3

=item new

Class constructor. Returns object of Net::Cisco::ISE on succes. Required fields are:

=over 5

=item hostname

=item username

=item password

=back

Optional fields are

=over 5

=item ssl

=item ssl_options

=item debug

=item namespace3

=item namespace5

=back

=item hostname

IP or hostname of Cisco ISE 2.x server. This is a required value in the constructor but can be redefined afterwards.

=item username

Username of Administrator user. This is a required value in the constructor but can be redefined afterwards.

=item password

Password of user. This is a required value in the constructor but can be redefined afterwards.

=item ssl

SSL enabled (1 - default) or disabled (0). 

=item ssl_options

Value is passed directly to LWP::UserAGent as ssl_opt. Default value (hash-ref) is

	{ 'SSL_verify_mode' => SSL_VERIFY_NONE, 'verify_hostname' => '0' }

=item debug

Set to true to enable debugging messages. This can be useful for troubleshooting.

=item namespace3

By default set to ns3:resources. This is used in the XML parsing. May be needed for tweaking. 

=item namespace5

By default set to ns5:resource. This is used in the XML parsing. May be needed for tweaking.

=back

From the class instance, call the different methods for retrieving values.

=over 3

=item internalusers

Returns hash or single instance, depending on context.

	my %users = $ise->internalusers(); # Slow
	my $user = $ise->internalusers()->{"admin"};
	print $user->name;
	
The returned hash contains instances of L<Net::Cisco::ISE::InternalUser>, using name (typically the username) as the hash key. Using a call to C<users> with no arguments will retrieve all users and can take quite a few seconds (depending on the size of your database). When you know the username or ID, use the L<users> call with arguments as listed below.
	
	my $user = $ise->internalusers("name","admin"); # Faster
	# or
	my $user = $ise->internalusers("id","b74a0ef2-b29c-40e3-a0d1-4c0dfb51ace9"); # Faster
	print $user->name;

	The ID is typically generated by Cisco ISE when the entry is created. It can be retrieved by calling the C<id> method on the object.

	print $user->id;

=item identitygroups

Returns hash or single instance, depending on context.

	my %identitygroups = $ise->identitygroups(); # Slow
	my $identitygroup = $ise->identitygroups()->{"All Groups"};
	print $identitgroup->name;
	
The returned hash contains instances of L<Net::Cisco::ISE::IdentityGroup>, using name (typically the username) as the hash key. Using a call to C<identitygroup> with no arguments will retrieve all identitygroups and can take quite a few seconds (depending on the size of your database). When you know the group name or ID, use the L<identitygroups> call with arguments as listed below.
	
	my $identitygroup = $ise->identitygroups("name","All Groups"); # Faster
	# or
	my $identitygroup = $ise->identitygroups("id","4fffc260-9b96-11e6-93fb-005056ad1454"); # Faster
	print $identitygroup->name;

	The ID is typically generated by Cisco ISE when the entry is created. It can be retrieved by calling the C<id> method on the object.

	print $identitygroup->id;
	
=item networkdevices

Returns hash or single instance, depending on context.

	my %devices = $ise->networkdevices(); # Slow
	my $device = $ise->networkdevices()->{"Main_Router"};
	print $device->name;
	
The returned hash contains instances of L<Net::Cisco::ISE::NetworkDevice>, using name (typically the sysname) as the hash key. Using a call to C<device> with no arguments will retrieve all devices and can take quite a few seconds (depending on the size of your database). When you know the hostname or ID, use the L<devices> call with arguments as listed below.
	
	my $device = $ise->networkdevices("name","Main_Router"); # Faster
	# or
	my $device = $ise->networkdevices("id","123"); # Faster
	print $device->name;

	The ID is typically generated by Cisco ISE when the entry is created. It can be retrieved by calling the C<id> method on the object.

	print $device->id;

=item networkdevicegroups

Returns hash or single instance, depending on context.

	my %devicegroups = $ise->networkdevicegroups(); # Slow
	my $devicegroup = $ise->networkdevicegroups()->{"All Locations:Main Site"};
	print $devicegroup->name;

The returned hash contains instances of L<Net::Cisco::ISE::NetworkDeviceGroup>, using name (typically the device group name) as the hash key. Using a call to C<devicegroups> with no arguments will retrieve all device groups and can take quite a few seconds (depending on the size of your database). When you know the device group or ID, use the L<devicegroups> call with arguments as listed below.
	
	my $devicegroup = $ise->networkdevicegroups("name","All Locations::Main Site"); # Faster
	# or
	my $devicegroup = $ise->networkdevicegroups("id","123"); # Faster
	print $devicegroup->name;

The ID is typically generated by Cisco ISE when the entry is created. It can be retrieved by calling the C<id> method on the object.

	print $devicegroup->id;

=item create

This method created a new entry in Cisco ISE, depending on the argument passed. Record type is detected automatically. For all record types, the ID value must be set to 0.

	my $user = $ise->internalusers("name","admin");
	$user->id(0); # Required for new user!
	$user->name("altadmin"); # Required field
	$user->password("TopSecret"); # Password policies will be enforced!
	$user->description("Alternate Admin"); 
	my $id = $ise->create($user); 
	# Create new user based on Net::Cisco::ISE::InternalUser instance
	# Return value is ID generated by ISE
	print "Record ID is $id" if $id;
	print $Net::Cisco::ISE::ERROR unless $id;
	# $Net::Cisco::ISE::ERROR contains details about failure

	my $device = $ise->networkdevices("name","Main_Router");
	$device->name("AltRouter"); # Required field
	$device->description("Standby Router"); 
	$device->ips([{netMask => "32", ipAddress=>"10.0.0.2"}]); # Change IP address! Overlap check is enforced!
	$device->id(0); # Required for new device!
	my $id = $ise->create($device);
	# Create new device based on Net::Cisco::ISE::NetworkDevice instance
	# Return value is ID generated by ISE
	print "Record ID is $id" if $id;
	print $Net::Cisco::ISE::ERROR unless $id;
	# $Net::Cisco::ISE::ERROR contains details about failure

Multiple instances can be passed as an argument. Objects will be created in bulk (one transaction). The returned ID is not guaranteed to be the IDs of the created objects.

	my $user = $ise->internalusers("name","admin");
	$user->id(0); # Required for new user!
	$user->name("altadmin"); # Required field
	$user->password("TopSecret"); # Password policies will be enforced!
	$user->description("Alternate Admin"); 

	my $user2 = $ise->internalusers("name","admin");
	$user2->id(0); # Required for new user!
	$user2->name("altadmin"); # Required field
	$user2->password("TopSecret"); # Password policies will be enforced!
	$user2->description("Alternate Admin"); 

	my $id = $ise->create($user,$user2); 
	# Create new users based on Net::Cisco::ISE::InternalUser instances in argument.
	# Return value is ID generated by ISE but not guaranteed.
	# print "Record ID is $id" if $id;
	# print $Net::Cisco::ISE::ERROR unless $id;
	# $Net::Cisco::ISE::ERROR contains details about failure
    
=item update

This method updates an existing entry in Cisco ISE, depending on the argument passed. Record type is detected automatically. 

	my $user = $ise->internalusers("name","admin");
	$user->password("TopSecret"); # Change password. Password policies will be enforced!
	my $id = $ise->update($user);
	# Update user based on Net::Cisco::ISE::InternalUser instance
	# Return value is ID generated by ISE
	print "Record ID is $id" if $id;
	print $Net::Cisco::ISE::ERROR unless $id;
	# $Net::Cisco::ISE::ERROR contains details about failure

	my $device = $ise->networkdevices("name","Main_Router");
	$user->description("To be ceased"); # Change description
	$device->ips([{netMask => "32", ipAddress=>"10.0.0.2"}]); # or Change IP address. Overlap check is enforced!
	my $id = $ise->update($device);
	# Create new device based on Net::Cisco::ISE::NetworkDevice instance
	# Return value is ID generated by ISE
	print "Record ID is $id" if $id;
	print $Net::Cisco::ISE::ERROR unless $id;
	# $Net::Cisco::ISE::ERROR contains details about failure

Multiple instances can be passed as an argument. Objects will be updated in bulk (one transaction). The returned ID is not guaranteed to be the IDs of the created objects.

	my $user = $ise->internalusers("name","admin");
	$user->id(0); # Required for new user!
	$user->password("TopSecret"); # Password policies will be enforced!

	my $user2 = $ise->internalusers("name","admin2");
	$user2->password("TopSecret"); # Password policies will be enforced!

	my $id = $ise->update($user,$user2); 
	# Update users based on Net::Cisco::ISE::InternalUser instances in arguments
	# Return value is ID generated by ISE but not guaranteed.
	# print "Record ID is $id" if $id;
	# print $Net::Cisco::ISE::ERROR unless $id;
	# $Net::Cisco::ISE::ERROR contains details about failure

	my $device = $ise->networkdevices("name","Main_Router");
	$device->description("Main Router"); 
	$device->ips([{netMask => "32", ipAddress=>"10.0.0.1"}]); # Change IP address! Overlap check is enforced!

	my $device2 = $ise->networkdevices("name","Alt_Router");
	$device2->description("Standby Router"); 
	$device2->ips([{netMask => "32", ipAddress=>"10.0.0.2"}]); # Change IP address! Overlap check is enforced!
	
        my $id = $ise->create($device,$device2);
	# Update devices based on Net::Cisco::ISE::NetworkDevice instances in arguments
	# Return value is ID generated by ISE but not guaranteed.
	# print "Record ID is $id" if $id;
	# print $Net::Cisco::ISE::ERROR unless $id;
	# $Net::Cisco::ISE::ERROR contains details about failure    
    
=item delete

This method deletes an existing entry in Cisco ISE, depending on the argument passed. Record type is detected automatically. 

	my $user = $ise->internalusers("name","admin");
	$ise->delete($user);

=item $ERROR

This variable will contain detailed error information, based on the REST API answer. This value is reset during every call to C<internalusers> and C<identitygroups>.
	
=back

=head1 REQUIREMENTS

For this library to work, you need an instance with Cisco ISE (obviously) or a simulator like L<Net::Cisco::ISE::Mock>. 

Instructions on enabling Cisco ISE for API access will be added later.

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

Certain API calls are not support from Cisco ISE 5.0 onwards. The current supported versions of Cisco ISE (by Cisco) are 5.6, 5.7 and 5.8 (Active). 

=head1 SEE ALSO

=over 3

See L<Net::Cisco::ISE::InternalUser> for more information on User management.

See L<Net::Cisco::ISE::IdentityGroup> for more information on User Group management.

See L<Net::Cisco::ISE::NetworkDevice> for more information on Device management.

See L<Net::Cisco::ISE::NetworkDeviceGroup> for more information on Device Group management.

See the L<Cisco ISE product page|http://www.cisco.com/c/en/us/products/security/identity-services-engine/index.html> for more information.

L<Net::Cisco::ISE> relies on L<Moose>. 

=back

=cut

#################### main pod documentation end ###################

__PACKAGE__->meta->make_immutable();

1;
# The preceding line will help the module return a true value


