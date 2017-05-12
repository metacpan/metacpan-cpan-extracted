##############################################################################
# This test file tests the functions found in the VM section.

use Test::Most qw( bail timeit );
use Test::NoWarnings;

use lib 't';
use MatchURL;

my $method = {
  changeServiceForVirtualMachine => {
    description =>
        "Changes the service offering for a virtual machine. The virtual machine must be in a \"Stopped\" state for this command to take effect.",
    isAsync => "false",
    level   => 15,
    request => {
      required => {
        id                => "The ID of the virtual machine",
        serviceofferingid => "the service offering ID to apply to the virtual machine",
      },
    },
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
    section => "VM",
  },
  deployVirtualMachine => {
    description =>
        "Creates and automatically starts a virtual machine based on a service offering, disk offering, and template.",
    isAsync => "true",
    level   => 15,
    request => {
      optional => {
        account => "an optional account for the virtual machine. Must be used with domainId.",
        diskofferingid =>
            "the ID of the disk offering for the virtual machine. If the template is of ISO format, the diskOfferingId is for the root disk volume. Otherwise this parameter is used to indicate the offering for the data disk volume. If the templateId parameter passed is from a Template object, the diskOfferingId refers to a DATA Disk Volume created. If the templateId parameter passed is from an ISO object, the diskOfferingId refers to a ROOT Disk Volume created.",
        displayname => "an optional user generated name for the virtual machine",
        domainid =>
            "an optional domainId for the virtual machine. If the account parameter is used, domainId must also be used.",
        group      => "an optional group for the virtual machine",
        hostid     => "destination Host ID to deploy the VM to - parameter available for root admin only",
        hypervisor => "the hypervisor on which to deploy the virtual machine",
        ipaddress  => "the ip address for default vm's network",
        iptonetworklist =>
            "ip to network mapping. Can't be specified with networkIds parameter. Example: iptonetworklist[0].ip=10.10.10.11&iptonetworklist[0].networkid=204 - requests to use ip 10.10.10.11 in network id=204",
        keyboard =>
            "an optional keyboard device type for the virtual machine. valid value can be one of de,de-ch,es,fi,fr,fr-be,fr-ch,is,it,jp,nl-be,no,pt,uk,us",
        keypair    => "name of the ssh key pair used to login to the virtual machine",
        name       => "host name for the virtual machine",
        networkids => "list of network ids used by virtual machine. Can't be specified with ipToNetworkList parameter",
        securitygroupids =>
            "comma separated list of security groups id that going to be applied to the virtual machine. Should be passed only when vm is created from a zone with Basic Network support. Mutually exclusive with securitygroupnames parameter",
        securitygroupnames =>
            "comma separated list of security groups names that going to be applied to the virtual machine. Should be passed only when vm is created from a zone with Basic Network support. Mutually exclusive with securitygroupids parameter",
        size => "the arbitrary size for the DATADISK volume. Mutually exclusive with diskOfferingId",
        userdata =>
            "an optional binary data that can be sent to the virtual machine upon a successful deployment. This binary data must be base64 encoded before adding it to the request. Currently only HTTP GET is supported. Using HTTP GET (via querystring), you can send up to 2KB of data after base64 encoding.",
      },
      required => {
        serviceofferingid => "the ID of the service offering for the virtual machine",
        templateid        => "the ID of the template for the virtual machine",
        zoneid            => "availability zone for the virtual machine",
      },
    },
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
    section => "VM",
  },
  destroyVirtualMachine => {
    description => "Destroys a virtual machine. Once destroyed, only the administrator can recover it.",
    isAsync     => "true",
    level       => 15,
    request     => { required => { id => "The ID of the virtual machine" } },
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
    section => "VM",
  },
  getVMPassword => {
    description => "Returns an encrypted password for the VM",
    isAsync     => "false",
    level       => 15,
    request     => { required => { id => "The ID of the virtual machine" } },
    response => { encryptedpassword => "The encrypted password of the VM" },
    section  => "VM",
  },
  listVirtualMachines => {
    description => "List the virtual machines owned by the account.",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        account => "account. Must be used with the domainId parameter.",
        domainid =>
            "the domain ID. If used with the account parameter, lists virtual machines for the specified account in this domain.",
        forvirtualnetwork => "list by network type; true if need to list vms using Virtual Network, false otherwise",
        groupid           => "the group ID",
        hostid            => "the host ID",
        hypervisor        => "the target hypervisor for the template",
        id                => "the ID of the virtual machine",
        isrecursive =>
            "Must be used with domainId parameter. Defaults to false, but if true, lists all vms from the parent specified by the domain id till leaves.",
        keyword   => "List by keyword",
        name      => "name of the virtual machine",
        networkid => "list by network id",
        page      => "no description",
        pagesize  => "no description",
        podid     => "the pod ID",
        state     => "state of the virtual machine",
        storageid => "the storage ID where vm's volumes belong to",
        zoneid    => "the availability zone ID",
      },
    },
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
    section => "VM",
  },
  migrateVirtualMachine => {
    description => "Attempts Migration of a user virtual machine to the host specified.",
    isAsync     => "true",
    level       => 1,
    request     => {
      required =>
          { hostid => "destination Host ID to migrate VM to", virtualmachineid => "the ID of the virtual machine", },
    },
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
    section => "VM",
  },
  rebootVirtualMachine => {
    description => "Reboots a virtual machine.",
    isAsync     => "true",
    level       => 15,
    request     => { required => { id => "The ID of the virtual machine" } },
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
    section => "VM",
  },
  recoverVirtualMachine => {
    description => "Recovers a virtual machine.",
    isAsync     => "false",
    level       => 7,
    request     => { required => { id => "The ID of the virtual machine" } },
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
    section => "VM",
  },
  resetPasswordForVirtualMachine => {
    description =>
        "Resets the password for virtual machine. The virtual machine must be in a \"Stopped\" state and the template must already support this feature for this command to take effect. [async]",
    isAsync  => "true",
    level    => 15,
    request  => { required => { id => "The ID of the virtual machine" } },
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
    section => "VM",
  },
  startVirtualMachine => {
    description => "Starts a virtual machine.",
    isAsync     => "true",
    level       => 15,
    request     => { required => { id => "The ID of the virtual machine" } },
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
    section => "VM",
  },
  stopVirtualMachine => {
    description => "Stops a virtual machine.",
    isAsync     => "true",
    level       => 15,
    request     => {
      optional => { forced => "Force stop the VM.  The caller knows the VM is stopped.", },
      required => { id     => "The ID of the virtual machine" },
    },
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
    section => "VM",
  },
  updateVirtualMachine => {
    description => "Updates parameters of a virtual machine.",
    isAsync     => "false",
    level       => 15,
    request     => {
      optional => {
        displayname => "user generated name",
        group       => "group of the virtual machine",
        haenable    => "true if high-availability is enabled for the virtual machine, false otherwise",
        ostypeid    => "the ID of the OS type that best represents this VM.",
        userdata =>
            "an optional binary data that can be sent to the virtual machine upon a successful deployment. This binary data must be base64 encoded before adding it to the request. Currently only HTTP GET is supported. Using HTTP GET (via querystring), you can send up to 2KB of data after base64 encoding.",
      },
      required => { id => "The ID of the virtual machine" },
    },
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
    section => "VM",
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
$tests++;       # Test loading of VM group
$tests++;       # Test object isa Net::CloudStack::API
$tests++;       # Test api object isa Net::CloudStack
$tests += ( keys %$method ) * 6;  # Methods to be checked--times the number of tests in the loop

plan( tests => $tests );          # We're going to run this many tests ...

timeit { ok( eval "use Net::CloudStack::API ':VM'; 1", 'use statement' ) } 'use took';
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
