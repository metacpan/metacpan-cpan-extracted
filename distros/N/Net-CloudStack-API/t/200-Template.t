##############################################################################
# This test file tests the functions found in the Template section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  copyTemplate => {
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
    section => "Template",
  },
  createTemplate => {
    description =>
        "Creates a template of a virtual machine. The virtual machine must be in a STOPPED state. A template created from this command is automatically designated as a private template visible to the account that created it.",
    isAsync => "true",
    level   => 15,
    request => {
      optional => {
        bits            => "32 or 64 bit",
        details         => "Template details in key/value pairs.",
        isfeatured      => "true if this template is a featured template, false otherwise",
        ispublic        => "true if this template is a public template, false otherwise",
        passwordenabled => "true if the template supports the password reset feature; default is false",
        requireshvm     => "true if the template requres HVM, false otherwise",
        snapshotid =>
            "the ID of the snapshot the template is being created from. Either this parameter, or volumeId has to be passed in",
        templatetag => "the tag for this template.",
        url => "Optional, only for baremetal hypervisor. The directory name where template stored on CIFS server",
        virtualmachineid =>
            "Optional, VM ID. If this presents, it is going to create a baremetal template for VM this ID refers to. This is only for VM whose hypervisor type is BareMetal",
        volumeid =>
            "the ID of the disk volume the template is being created from. Either this parameter, or snapshotId has to be passed in",
      },
      required => {
        displaytext => "the display text of the template. This is usually used for display purposes.",
        name        => "the name of the template",
        ostypeid    => "the ID of the OS Type that best represents the OS of this template.",
      },
    },
    response => {
      clusterid         => "the ID of the cluster for the storage pool",
      clustername       => "the name of the cluster for the storage pool",
      created           => "the date and time the storage pool was created",
      disksizeallocated => "the host's currently allocated disk size",
      disksizetotal     => "the total disk size of the storage pool",
      id                => "the ID of the storage pool",
      ipaddress         => "the IP address of the storage pool",
      jobid =>
          "shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the storage pool",
      jobstatus => "shows the current pending asynchronous job status",
      name      => "the name of the storage pool",
      path      => "the storage pool path",
      podid     => "the Pod ID of the storage pool",
      podname   => "the Pod name of the storage pool",
      state     => "the state of the storage pool",
      tags      => "the tags for the storage pool",
      type      => "the storage pool type",
      zoneid    => "the Zone ID of the storage pool",
      zonename  => "the Zone name of the storage pool",
    },
    section => "Template",
  },
  deleteTemplate => {
    description =>
        "Deletes a template from the system. All virtual machines using the deleted template will not be affected.",
    isAsync => "true",
    level   => 15,
    request =>
        { optional => { zoneid => "the ID of zone of the template" }, required => { id => "the ID of the template" }, },
    response => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "Template",
  },
  extractTemplate => {
    description => "Extracts a template",
    isAsync     => "true",
    level       => 15,
    request     => {
      optional => { url => "the url to which the ISO would be extracted" },
      required => {
        id     => "the ID of the template",
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
    section => "Template",
  },
  listTemplatePermissions => {
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
    section => "Template",
  },
  listTemplates => {
    description => "List all public, private, and privileged templates.",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account => "list template by account. Must be used with the domainId parameter.",
        domainid =>
            "list all templates in specified domain. If used with the account parameter, lists all templates for an account in the specified domain.",
        hypervisor => "the hypervisor for which to restrict the search",
        id         => "the template ID",
        keyword    => "List by keyword",
        name       => "the template name",
        page       => "no description",
        pagesize   => "no description",
        zoneid     => "list templates by zoneId",
      },
      required => {
        templatefilter =>
            "possible values are \"featured\", \"self\", \"self-executable\", \"executable\", and \"community\".* featured-templates that are featured and are public* self-templates that have been registered/created by the owner* selfexecutable-templates that have been registered/created by the owner that can be used to deploy a new VM* executable-all templates that can be used to deploy a new VM* community-templates that are public.",
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
    section => "Template",
  },
  prepareTemplate => {
    description => "load template into primary storage",
    isAsync     => "false",
    level       => 1,
    request     => {
      required => {
        templateid => "template ID of the template to be prepared in primary storage(s).",
        zoneid     => "zone ID of the template to be prepared in primary storage(s).",
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
    section => "Template",
  },
  registerTemplate => {
    description => "Registers an existing template into the Cloud.com cloud.",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account         => "an optional accountName. Must be used with domainId.",
        bits            => "32 or 64 bits support. 64 by default",
        checksum        => "the MD5 checksum value of this template",
        details         => "Template details in key/value pairs.",
        domainid        => "an optional domainId. If the account parameter is used, domainId must also be used.",
        isextractable   => "true if the template or its derivatives are extractable; default is false",
        isfeatured      => "true if this template is a featured template, false otherwise",
        ispublic        => "true if the template is available to all accounts; default is true",
        passwordenabled => "true if the template supports the password reset feature; default is false",
        requireshvm     => "true if this template requires HVM",
        templatetag     => "the tag for this template.",
      },
      required => {
        displaytext => "the display text of the template. This is usually used for display purposes.",
        format      => "the format for the template. Possible values include QCOW2, RAW, and VHD.",
        hypervisor  => "the target hypervisor for the template",
        name        => "the name of the template",
        ostypeid    => "the ID of the OS Type that best represents the OS of this template.",
        url         => "the URL of where the template is hosted. Possible URL include http:// and https://",
        zoneid      => "the ID of the zone the template is to be hosted on",
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
    section => "Template",
  },
  updateTemplate => {
    description => "Updates attributes of a template.",
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
    section => "Template",
  },
  updateTemplatePermissions => {
    description =>
        "Updates a template visibility permissions. A public template is visible to all accounts within the same domain. A private template is visible only to the owner of the template. A priviledged template is a private template with account permissions added. Only accounts specified under the template permissions are visible to them.",
    isAsync => "false",
    level   => 15,
    request => {
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
    section => "Template",
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
$tests++;       # Test loading of Template group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':Template'; 1", 'use statement' ) } 'use took';
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
