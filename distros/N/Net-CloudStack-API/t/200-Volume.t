##############################################################################
# This test file tests the functions found in the Volume section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  attachVolume => {
    description => "Attaches a disk volume to a virtual machine.",
    isAsync     => "true",
    level       => 15,
    request     => {
      optional => {
        deviceid =>
            "the ID of the device to map the volume to within the guest OS. If no deviceId is passed in, the next available deviceId will be chosen. Possible values for a Linux OS are:* 1 - /dev/xvdb* 2 - /dev/xvdc* 4 - /dev/xvde* 5 - /dev/xvdf* 6 - /dev/xvdg* 7 - /dev/xvdh* 8 - /dev/xvdi* 9 - /dev/xvdj",
      },
      required => { id => "the ID of the disk volume", virtualmachineid => "the ID of the virtual machine", },
    },
    response => {
      account   => "the account associated with the disk volume",
      attached  => "the date the volume was attached to a VM instance",
      created   => "the date the disk volume was created",
      destroyed => "the boolean state of whether the volume is destroyed or not",
      deviceid =>
          "the ID of the device on user vm the volume is attahed to. This tag is not returned when the volume is detached.",
      diskofferingdisplaytext => "the display text of the disk offering",
      diskofferingid          => "ID of the disk offering",
      diskofferingname        => "name of the disk offering",
      domain                  => "the domain associated with the disk volume",
      domainid                => "the ID of the domain associated with the disk volume",
      hypervisor              => "Hypervisor the volume belongs to",
      id                      => "ID of the disk volume",
      isextractable           => "true if the volume is extractable, false otherwise",
      jobid =>
          "shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume",
      jobstatus                  => "shows the current pending asynchronous job status",
      name                       => "name of the disk volume",
      serviceofferingdisplaytext => "the display text of the service offering for root disk",
      serviceofferingid          => "ID of the service offering for root disk",
      serviceofferingname        => "name of the service offering for root disk",
      size                       => "size of the disk volume",
      snapshotid                 => "ID of the snapshot from which this volume was created",
      state                      => "the state of the disk volume",
      storage                    => "name of the primary storage hosting the disk volume",
      storagetype                => "shared or local storage",
      type                       => "type of the disk volume (ROOT or DATADISK)",
      virtualmachineid           => "id of the virtual machine",
      vmdisplayname              => "display name of the virtual machine",
      vmname                     => "name of the virtual machine",
      vmstate                    => "state of the virtual machine",
      zoneid                     => "ID of the availability zone",
      zonename                   => "name of the availability zone",
    },
    section => "Volume",
  },
  createVolume => {
    description =>
        "Creates a disk volume from a disk offering. This disk volume must still be attached to a virtual machine to make use of it.",
    isAsync => "true",
    level   => 15,
    request => {
      optional => {
        account        => "the account associated with the disk volume. Must be used with the domainId parameter.",
        diskofferingid => "the ID of the disk offering. Either diskOfferingId or snapshotId must be passed in.",
        domainid =>
            "the domain ID associated with the disk offering. If used with the account parameter returns the disk volume associated with the account for the specified domain.",
        size       => "Arbitrary volume size",
        snapshotid => "the snapshot ID for the disk volume. Either diskOfferingId or snapshotId must be passed in.",
        zoneid     => "the ID of the availability zone",
      },
      required => { name => "the name of the disk volume" },
    },
    response => {
      account   => "the account associated with the disk volume",
      attached  => "the date the volume was attached to a VM instance",
      created   => "the date the disk volume was created",
      destroyed => "the boolean state of whether the volume is destroyed or not",
      deviceid =>
          "the ID of the device on user vm the volume is attahed to. This tag is not returned when the volume is detached.",
      diskofferingdisplaytext => "the display text of the disk offering",
      diskofferingid          => "ID of the disk offering",
      diskofferingname        => "name of the disk offering",
      domain                  => "the domain associated with the disk volume",
      domainid                => "the ID of the domain associated with the disk volume",
      hypervisor              => "Hypervisor the volume belongs to",
      id                      => "ID of the disk volume",
      isextractable           => "true if the volume is extractable, false otherwise",
      jobid =>
          "shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume",
      jobstatus                  => "shows the current pending asynchronous job status",
      name                       => "name of the disk volume",
      serviceofferingdisplaytext => "the display text of the service offering for root disk",
      serviceofferingid          => "ID of the service offering for root disk",
      serviceofferingname        => "name of the service offering for root disk",
      size                       => "size of the disk volume",
      snapshotid                 => "ID of the snapshot from which this volume was created",
      state                      => "the state of the disk volume",
      storage                    => "name of the primary storage hosting the disk volume",
      storagetype                => "shared or local storage",
      type                       => "type of the disk volume (ROOT or DATADISK)",
      virtualmachineid           => "id of the virtual machine",
      vmdisplayname              => "display name of the virtual machine",
      vmname                     => "name of the virtual machine",
      vmstate                    => "state of the virtual machine",
      zoneid                     => "ID of the availability zone",
      zonename                   => "name of the availability zone",
    },
    section => "Volume",
  },
  deleteVolume => {
    description => "Deletes a detached disk volume.",
    isAsync     => "false",
    level       => 15,
    request     => { required => { id => "The ID of the disk volume" } },
    response    => {
      displaytext => "any text associated with the success or failure",
      success     => "true if operation is executed successfully",
    },
    section => "Volume",
  },
  detachVolume => {
    description => "Detaches a disk volume from a virtual machine.",
    isAsync     => "true",
    level       => 15,
    request     => {
      optional => {
        deviceid         => "the device ID on the virtual machine where volume is detached from",
        id               => "the ID of the disk volume",
        virtualmachineid => "the ID of the virtual machine where the volume is detached from",
      },
    },
    response => {
      account   => "the account associated with the disk volume",
      attached  => "the date the volume was attached to a VM instance",
      created   => "the date the disk volume was created",
      destroyed => "the boolean state of whether the volume is destroyed or not",
      deviceid =>
          "the ID of the device on user vm the volume is attahed to. This tag is not returned when the volume is detached.",
      diskofferingdisplaytext => "the display text of the disk offering",
      diskofferingid          => "ID of the disk offering",
      diskofferingname        => "name of the disk offering",
      domain                  => "the domain associated with the disk volume",
      domainid                => "the ID of the domain associated with the disk volume",
      hypervisor              => "Hypervisor the volume belongs to",
      id                      => "ID of the disk volume",
      isextractable           => "true if the volume is extractable, false otherwise",
      jobid =>
          "shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume",
      jobstatus                  => "shows the current pending asynchronous job status",
      name                       => "name of the disk volume",
      serviceofferingdisplaytext => "the display text of the service offering for root disk",
      serviceofferingid          => "ID of the service offering for root disk",
      serviceofferingname        => "name of the service offering for root disk",
      size                       => "size of the disk volume",
      snapshotid                 => "ID of the snapshot from which this volume was created",
      state                      => "the state of the disk volume",
      storage                    => "name of the primary storage hosting the disk volume",
      storagetype                => "shared or local storage",
      type                       => "type of the disk volume (ROOT or DATADISK)",
      virtualmachineid           => "id of the virtual machine",
      vmdisplayname              => "display name of the virtual machine",
      vmname                     => "name of the virtual machine",
      vmstate                    => "state of the virtual machine",
      zoneid                     => "ID of the availability zone",
      zonename                   => "name of the availability zone",
    },
    section => "Volume",
  },
  extractVolume => {
    description => "Extracts volume",
    isAsync     => "true",
    level       => 15,
    request     => {
      optional => { url => "the url to which the volume would be extracted" },
      required => {
        id     => "the ID of the volume",
        mode   => "the mode of extraction - HTTP_DOWNLOAD or FTP_UPLOAD",
        zoneid => "the ID of the zone where the volume is located",
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
    section => "Volume",
  },
  listVolumes => {
    description => "Lists all volumes.",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account => "the account associated with the disk volume. Must be used with the domainId parameter.",
        domainid =>
            "Lists all disk volumes for the specified domain ID. If used with the account parameter, returns all disk volumes for an account in the specified domain ID.",
        hostid => "list volumes on specified host",
        id     => "the ID of the disk volume",
        isrecursive =>
            "defaults to false, but if true, lists all volumes from the parent specified by the domain id till leaves.",
        keyword          => "List by keyword",
        name             => "the name of the disk volume",
        page             => "no description",
        pagesize         => "no description",
        podid            => "the pod id the disk volume belongs to",
        type             => "the type of disk volume",
        virtualmachineid => "the ID of the virtual machine",
        zoneid           => "the ID of the availability zone",
      },
    },
    response => {
      account   => "the account associated with the disk volume",
      attached  => "the date the volume was attached to a VM instance",
      created   => "the date the disk volume was created",
      destroyed => "the boolean state of whether the volume is destroyed or not",
      deviceid =>
          "the ID of the device on user vm the volume is attahed to. This tag is not returned when the volume is detached.",
      diskofferingdisplaytext => "the display text of the disk offering",
      diskofferingid          => "ID of the disk offering",
      diskofferingname        => "name of the disk offering",
      domain                  => "the domain associated with the disk volume",
      domainid                => "the ID of the domain associated with the disk volume",
      hypervisor              => "Hypervisor the volume belongs to",
      id                      => "ID of the disk volume",
      isextractable           => "true if the volume is extractable, false otherwise",
      jobid =>
          "shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume",
      jobstatus                  => "shows the current pending asynchronous job status",
      name                       => "name of the disk volume",
      serviceofferingdisplaytext => "the display text of the service offering for root disk",
      serviceofferingid          => "ID of the service offering for root disk",
      serviceofferingname        => "name of the service offering for root disk",
      size                       => "size of the disk volume",
      snapshotid                 => "ID of the snapshot from which this volume was created",
      state                      => "the state of the disk volume",
      storage                    => "name of the primary storage hosting the disk volume",
      storagetype                => "shared or local storage",
      type                       => "type of the disk volume (ROOT or DATADISK)",
      virtualmachineid           => "id of the virtual machine",
      vmdisplayname              => "display name of the virtual machine",
      vmname                     => "name of the virtual machine",
      vmstate                    => "state of the virtual machine",
      zoneid                     => "ID of the availability zone",
      zonename                   => "name of the availability zone",
    },
    section => "Volume",
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
$tests++;       # Test loading of Volume group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':Volume'; 1", 'use statement' ) } 'use took';
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
