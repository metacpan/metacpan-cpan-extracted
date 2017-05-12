##############################################################################
# This test file tests the functions found in the ISO section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  attachIso => {
    description => "Attaches an ISO to a virtual machine.",
    isAsync     => "true",
    level       => 15,
    request =>
        { required => { id => "the ID of the ISO file", virtualmachineid => "the ID of the virtual machine", }, },
    response => {
      "account"     => "the account associated with the virtual machine",
      "cpunumber"   => "the number of cpu this virtual machine is running with",
      "cpuspeed"    => "the speed of each cpu",
      "cpuused"     => "the amount of the vm's CPU currently used",
      "created"     => "the date when this virtual machine was created",
      "displayname" => "user generated name. The name of the virtual machine is returned if no displayname exists.",
      "domain"      => "the name of the domain in which the virtual machine exists",
      "domainid"    => "the ID of the domain in which the virtual machine exists",
      "forvirtualnetwork" => "the virtual network for the service offering",
      "group"             => "the group name of the virtual machine",
      "groupid"           => "the group ID of the virtual machine",
      "guestosid"         => "Os type ID of the virtual machine",
      "haenable"          => "true if high-availability is enabled, false otherwise",
      "hostid"            => "the ID of the host for the virtual machine",
      "hostname"          => "the name of the host for the virtual machine",
      "hypervisor"        => "the hypervisor on which the template runs",
      "id"                => "the ID of the virtual machine",
      "ipaddress"         => "the ip address of the virtual machine",
      "isodisplaytext"    => "an alternate display text of the ISO attached to the virtual machine",
      "isoid"             => "the ID of the ISO attached to the virtual machine",
      "isoname"           => "the name of the ISO attached to the virtual machine",
      "jobid" =>
          "shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine",
      "jobstatus"           => "shows the current pending asynchronous job status",
      "memory"              => "the memory allocated for the virtual machine",
      "name"                => "the name of the virtual machine",
      "networkkbsread"      => "the incoming network traffic on the vm",
      "networkkbswrite"     => "the outgoing network traffic on the host",
      "nic(*)"              => "the list of nics associated with vm",
      "password"            => "the password (if exists) of the virtual machine",
      "passwordenabled"     => "true if the password rest feature is enabled, false otherwise",
      "rootdeviceid"        => "device ID of the root volume",
      "rootdevicetype"      => "device type of the root volume",
      "securitygroup(*)"    => "list of security groups associated with the virtual machine",
      "serviceofferingid"   => "the ID of the service offering of the virtual machine",
      "serviceofferingname" => "the name of the service offering of the virtual machine",
      "state"               => "the state of the virtual machine",
      "templatedisplaytext" => "an alternate display text of the template for the virtual machine",
      "templateid" =>
          "the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.",
      "templatename" => "the name of the template for the virtual machine",
      "zoneid"       => "the ID of the availablility zone for the virtual machine",
      "zonename"     => "the name of the availability zone for the virtual machine",
    },
    section => "ISO",
  },
  copyIso => {
    description => "Copies a template from one zone to another.",
    isAsync     => "true",
    level       => 15,
    request     => {
      required => {
        destzoneid   => "ID of the zone the template is being copied to.",
        id           => "Template ID.",
        sourcezoneid => "ID of the zone the template is currently hosted on.",
      },
    },
    response => {
      account       => "the account name to which the template belongs",
      accountid     => "the account id to which the template belongs",
      bootable      => "true if the ISO is bootable, false otherwise",
      checksum      => "checksum of the template",
      created       => "the date this template was created",
      crossZones    => "true if the template is managed across all Zones, false otherwise",
      details       => "additional key/value details tied with template",
      displaytext   => "the template display text",
      domain        => "the name of the domain to which the template belongs",
      domainid      => "the ID of the domain to which the template belongs",
      format        => "the format of the template.",
      hostid        => "the ID of the secondary storage host for the template",
      hostname      => "the name of the secondary storage host for the template",
      hypervisor    => "the hypervisor on which the template runs",
      id            => "the template ID",
      isextractable => "true if the template is extractable, false otherwise",
      isfeatured    => "true if this template is a featured template, false otherwise",
      ispublic      => "true if this template is a public template, false otherwise",
      isready       => "true if the template is ready to be deployed from, false otherwise.",
      jobid =>
          "shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template",
      jobstatus        => "shows the current pending asynchronous job status",
      name             => "the template name",
      ostypeid         => "the ID of the OS type for this template.",
      ostypename       => "the name of the OS type for this template.",
      passwordenabled  => "true if the reset password feature is enabled, false otherwise",
      removed          => "the date this template was removed",
      size             => "the size of the template",
      sourcetemplateid => "the template ID of the parent template if present",
      status           => "the status of the template",
      templatetag      => "the tag of this template",
      templatetype     => "the type of the template",
      zoneid           => "the ID of the zone for this template",
      zonename         => "the name of the zone for this template",
    },
    section => "ISO",
  },
  deleteIso => {
    description => "Deletes an ISO file.",
    isAsync     => "true",
    level       => 15,
    request     => {
      optional => {
        zoneid => "the ID of the zone of the ISO file. If not specified, the ISO will be deleted from all the zones",
      },
      required => { id => "the ID of the ISO file" },
    },
    response => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "ISO",
  },
  detachIso => {
    description => "Detaches any ISO file (if any) currently attached to a virtual machine.",
    isAsync     => "true",
    level       => 15,
    request     => { required => { virtualmachineid => "The ID of the virtual machine" }, },
    response    => {
      "account"     => "the account associated with the virtual machine",
      "cpunumber"   => "the number of cpu this virtual machine is running with",
      "cpuspeed"    => "the speed of each cpu",
      "cpuused"     => "the amount of the vm's CPU currently used",
      "created"     => "the date when this virtual machine was created",
      "displayname" => "user generated name. The name of the virtual machine is returned if no displayname exists.",
      "domain"      => "the name of the domain in which the virtual machine exists",
      "domainid"    => "the ID of the domain in which the virtual machine exists",
      "forvirtualnetwork" => "the virtual network for the service offering",
      "group"             => "the group name of the virtual machine",
      "groupid"           => "the group ID of the virtual machine",
      "guestosid"         => "Os type ID of the virtual machine",
      "haenable"          => "true if high-availability is enabled, false otherwise",
      "hostid"            => "the ID of the host for the virtual machine",
      "hostname"          => "the name of the host for the virtual machine",
      "hypervisor"        => "the hypervisor on which the template runs",
      "id"                => "the ID of the virtual machine",
      "ipaddress"         => "the ip address of the virtual machine",
      "isodisplaytext"    => "an alternate display text of the ISO attached to the virtual machine",
      "isoid"             => "the ID of the ISO attached to the virtual machine",
      "isoname"           => "the name of the ISO attached to the virtual machine",
      "jobid" =>
          "shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine",
      "jobstatus"           => "shows the current pending asynchronous job status",
      "memory"              => "the memory allocated for the virtual machine",
      "name"                => "the name of the virtual machine",
      "networkkbsread"      => "the incoming network traffic on the vm",
      "networkkbswrite"     => "the outgoing network traffic on the host",
      "nic(*)"              => "the list of nics associated with vm",
      "password"            => "the password (if exists) of the virtual machine",
      "passwordenabled"     => "true if the password rest feature is enabled, false otherwise",
      "rootdeviceid"        => "device ID of the root volume",
      "rootdevicetype"      => "device type of the root volume",
      "securitygroup(*)"    => "list of security groups associated with the virtual machine",
      "serviceofferingid"   => "the ID of the service offering of the virtual machine",
      "serviceofferingname" => "the name of the service offering of the virtual machine",
      "state"               => "the state of the virtual machine",
      "templatedisplaytext" => "an alternate display text of the template for the virtual machine",
      "templateid" =>
          "the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.",
      "templatename" => "the name of the template for the virtual machine",
      "zoneid"       => "the ID of the availablility zone for the virtual machine",
      "zonename"     => "the name of the availability zone for the virtual machine",
    },
    section => "ISO",
  },
  extractIso => {
    description => "Extracts an ISO",
    isAsync     => "true",
    level       => 15,
    request     => {
      optional => { url => "the url to which the ISO would be extracted" },
      required => {
        id     => "the ID of the ISO file",
        mode   => "the mode of extraction - HTTP_DOWNLOAD or FTP_UPLOAD",
        zoneid => "the ID of the zone where the ISO is originally located",
      },
    },
    response => {
      accountid        => "the account id to which the extracted object belongs",
      created          => "the time and date the object was created",
      extractId        => "the upload id of extracted object",
      extractMode      => "the mode of extraction - upload or download",
      id               => "the id of extracted object",
      name             => "the name of the extracted object",
      state            => "the state of the extracted object",
      status           => "the status of the extraction",
      storagetype      => "type of the storage",
      uploadpercentage => "the percentage of the entity uploaded to the specified location",
      url =>
          "if mode = upload then url of the uploaded entity. if mode = download the url from which the entity can be downloaded",
      zoneid   => "zone ID the object was extracted from",
      zonename => "zone name the object was extracted from",
    },
    section => "ISO",
  },
  listIsoPermissions => {
    description => "List template visibility and all accounts that have permissions to view this template.",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account =>
            "List template visibility and permissions for the specified account. Must be used with the domainId parameter.",
        domainid =>
            "List template visibility and permissions by domain. If used with the account parameter, specifies in which domain the specified account exists.",
      },
      required => { id => "the template ID" },
    },
    response => {
      account  => "the list of accounts the template is available for",
      domainid => "the ID of the domain to which the template belongs",
      id       => "the template ID",
      ispublic => "true if this template is a public template, false otherwise",
    },
    section => "ISO",
  },
  listIsos => {
    description => "Lists all available ISO files.",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account  => "the account of the ISO file. Must be used with the domainId parameter.",
        bootable => "true if the ISO is bootable, false otherwise",
        domainid =>
            "lists all available ISO files by ID of a domain. If used with the account parameter, lists all available ISO files for the account in the ID of a domain.",
        hypervisor => "the hypervisor for which to restrict the search",
        id         => "list all isos by id",
        isofilter =>
            "possible values are \"featured\", \"self\", \"self-executable\",\"executable\", and \"community\". * featured-ISOs that are featured and are publicself-ISOs that have been registered/created by the owner. * selfexecutable-ISOs that have been registered/created by the owner that can be used to deploy a new VM. * executable-all ISOs that can be used to deploy a new VM * community-ISOs that are public.",
        ispublic => "true if the ISO is publicly available to all users, false otherwise.",
        isready  => "true if this ISO is ready to be deployed",
        keyword  => "List by keyword",
        name     => "list all isos by name",
        page     => "no description",
        pagesize => "no description",
        zoneid   => "the ID of the zone",
      },
    },
    response => {
      account       => "the account name to which the template belongs",
      accountid     => "the account id to which the template belongs",
      bootable      => "true if the ISO is bootable, false otherwise",
      checksum      => "checksum of the template",
      created       => "the date this template was created",
      crossZones    => "true if the template is managed across all Zones, false otherwise",
      details       => "additional key/value details tied with template",
      displaytext   => "the template display text",
      domain        => "the name of the domain to which the template belongs",
      domainid      => "the ID of the domain to which the template belongs",
      format        => "the format of the template.",
      hostid        => "the ID of the secondary storage host for the template",
      hostname      => "the name of the secondary storage host for the template",
      hypervisor    => "the hypervisor on which the template runs",
      id            => "the template ID",
      isextractable => "true if the template is extractable, false otherwise",
      isfeatured    => "true if this template is a featured template, false otherwise",
      ispublic      => "true if this template is a public template, false otherwise",
      isready       => "true if the template is ready to be deployed from, false otherwise.",
      jobid =>
          "shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template",
      jobstatus        => "shows the current pending asynchronous job status",
      name             => "the template name",
      ostypeid         => "the ID of the OS type for this template.",
      ostypename       => "the name of the OS type for this template.",
      passwordenabled  => "true if the reset password feature is enabled, false otherwise",
      removed          => "the date this template was removed",
      size             => "the size of the template",
      sourcetemplateid => "the template ID of the parent template if present",
      status           => "the status of the template",
      templatetag      => "the tag of this template",
      templatetype     => "the type of the template",
      zoneid           => "the ID of the zone for this template",
      zonename         => "the name of the zone for this template",
    },
    section => "ISO",
  },
  registerIso => {
    description => "Registers an existing ISO into the Cloud.com Cloud.",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account       => "an optional account name. Must be used with domainId.",
        bootable      => "true if this ISO is bootable",
        domainid      => "an optional domainId. If the account parameter is used, domainId must also be used.",
        isextractable => "true if the iso or its derivatives are extractable; default is false",
        isfeatured    => "true if you want this ISO to be featured",
        ispublic      => "true if you want to register the ISO to be publicly available to all users, false otherwise.",
        ostypeid      => "the ID of the OS Type that best represents the OS of this ISO",
      },
      required => {
        displaytext => "the display text of the ISO. This is usually used for display purposes.",
        name        => "the name of the ISO",
        url         => "the URL to where the ISO is currently being hosted",
        zoneid      => "the ID of the zone you wish to register the ISO to.",
      },
    },
    response => {
      account       => "the account name to which the template belongs",
      accountid     => "the account id to which the template belongs",
      bootable      => "true if the ISO is bootable, false otherwise",
      checksum      => "checksum of the template",
      created       => "the date this template was created",
      crossZones    => "true if the template is managed across all Zones, false otherwise",
      details       => "additional key/value details tied with template",
      displaytext   => "the template display text",
      domain        => "the name of the domain to which the template belongs",
      domainid      => "the ID of the domain to which the template belongs",
      format        => "the format of the template.",
      hostid        => "the ID of the secondary storage host for the template",
      hostname      => "the name of the secondary storage host for the template",
      hypervisor    => "the hypervisor on which the template runs",
      id            => "the template ID",
      isextractable => "true if the template is extractable, false otherwise",
      isfeatured    => "true if this template is a featured template, false otherwise",
      ispublic      => "true if this template is a public template, false otherwise",
      isready       => "true if the template is ready to be deployed from, false otherwise.",
      jobid =>
          "shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template",
      jobstatus        => "shows the current pending asynchronous job status",
      name             => "the template name",
      ostypeid         => "the ID of the OS type for this template.",
      ostypename       => "the name of the OS type for this template.",
      passwordenabled  => "true if the reset password feature is enabled, false otherwise",
      removed          => "the date this template was removed",
      size             => "the size of the template",
      sourcetemplateid => "the template ID of the parent template if present",
      status           => "the status of the template",
      templatetag      => "the tag of this template",
      templatetype     => "the type of the template",
      zoneid           => "the ID of the zone for this template",
      zonename         => "the name of the zone for this template",
    },
    section => "ISO",
  },
  updateIso => {
    description => "Updates an ISO file.",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        bootable        => "true if image is bootable, false otherwise",
        displaytext     => "the display text of the image",
        format          => "the format for the image",
        name            => "the name of the image file",
        ostypeid        => "the ID of the OS type that best represents the OS of this image.",
        passwordenabled => "true if the image supports the password reset feature; default is false",
      },
      required => { id => "the ID of the image file" },
    },
    response => {
      account       => "the account name to which the template belongs",
      accountid     => "the account id to which the template belongs",
      bootable      => "true if the ISO is bootable, false otherwise",
      checksum      => "checksum of the template",
      created       => "the date this template was created",
      crossZones    => "true if the template is managed across all Zones, false otherwise",
      details       => "additional key/value details tied with template",
      displaytext   => "the template display text",
      domain        => "the name of the domain to which the template belongs",
      domainid      => "the ID of the domain to which the template belongs",
      format        => "the format of the template.",
      hostid        => "the ID of the secondary storage host for the template",
      hostname      => "the name of the secondary storage host for the template",
      hypervisor    => "the hypervisor on which the template runs",
      id            => "the template ID",
      isextractable => "true if the template is extractable, false otherwise",
      isfeatured    => "true if this template is a featured template, false otherwise",
      ispublic      => "true if this template is a public template, false otherwise",
      isready       => "true if the template is ready to be deployed from, false otherwise.",
      jobid =>
          "shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template",
      jobstatus        => "shows the current pending asynchronous job status",
      name             => "the template name",
      ostypeid         => "the ID of the OS type for this template.",
      ostypename       => "the name of the OS type for this template.",
      passwordenabled  => "true if the reset password feature is enabled, false otherwise",
      removed          => "the date this template was removed",
      size             => "the size of the template",
      sourcetemplateid => "the template ID of the parent template if present",
      status           => "the status of the template",
      templatetag      => "the tag of this template",
      templatetype     => "the type of the template",
      zoneid           => "the ID of the zone for this template",
      zonename         => "the name of the zone for this template",
    },
    section => "ISO",
  },
  updateIsoPermissions => {
    description => "Updates iso permissions",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        accounts      => "a comma delimited list of accounts. If specified, \"op\" parameter has to be passed in.",
        isextractable => "true if the template/iso is extractable, false other wise. Can be set only by root admin",
        isfeatured    => "true for featured template/iso, false otherwise",
        ispublic      => "true for public template/iso, false for private templates/isos",
        op            => "permission operator (add, remove, reset)",
      },
      required => { id => "the template ID" },
    },
    response => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "ISO",
  },
};

sub random_text {

  my @c = ( 'a' .. 'z', 'A' .. 'Z' );
  return join '', map { $c[ rand @c ] } 0 .. int( rand 16 ) + 8;

}

my $base_url   = 'http://somecloud.com';
my $api_path   = 'client/api?';
my $api_key    = random_text();
my $secret_key = random_text();

my $tests = 1;  # Start at 1 for Test::NoWarnings
$tests++;       # Test loading of ISO group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':ISO'; 1", 'use statement' ) } 'use took';
explain $@ if $@;

my $obj = Net::CloudStack::API->new;
isa_ok( $obj, 'Net::CloudStack::API' );

my $oo_api = $obj->api( {

    base_url   => $base_url,
    api_path   => $api_path,
    api_key    => $api_key,
    secret_key => $secret_key,

} );

isa_ok( $oo_api, 'Net::CloudStack' );

# MatchURL::match expects
# $check_url, $base_url, $api_path, $api_key, $secret_key, $cmd, $pairs (optional)
my @data = ( $base_url, $api_path, $api_key, $secret_key );

for my $m ( keys %$method ) {

  explain( "Working on $m method" );

  my $work = $method->{ $m };

  SKIP: {

    skip 'no required parameters', 2
        if ! exists $work->{ request }{ required };

    # Test call with no arguments
    my $check_regex = qr/Mandatory parameters? .*? missing in call/i;
    throws_ok { $obj->$m } $check_regex, 'caught missing required params (oo)';

    no strict 'refs';
    throws_ok { $m->() } $check_regex, 'caught missing required params (functional)';

  }

  my ( %args, @args );

  if ( exists $work->{ request }{ required } ) {
    for my $parm ( keys %{ $work->{ request }{ required } } ) {

      $args{ $parm } = random_text();
      push @args, [ $parm, $args{ $parm } ];

    }
  }

  my $check_url;
  ok( $check_url = $obj->$m( \%args ), 'check_url created (oo)' );
  ok( MatchURL::match( $check_url, @data, $m, \@args ), 'urls matched (oo)' );

  { no strict 'refs'; ok( $check_url = $m->( \%args ), 'check_url created (functional)' ) }
  ok( MatchURL::match( $check_url, @data, $m, \@args ), 'urls matched (functional)' );

} ## end for my $m ( keys %$method)
