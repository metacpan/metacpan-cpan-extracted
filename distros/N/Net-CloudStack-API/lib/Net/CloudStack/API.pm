package Net::CloudStack::API;

# ABSTRACT: Basic request and response handling for calls to a CloudStack service.

## no critic qw( ValuesAndExpressions::RestrictLongStrings ClassHierarchies::ProhibitAutoloading )
## no critic qw( ValuesAndExpressions::ProhibitAccessOfPrivateData )


use 5.006;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.02'; # VERSION

use Carp;
use Net::CloudStack;
use Params::Validate ':all';
use Scalar::Util 'blessed';
use Sub::Exporter;

{  # Begin general hiding

##############################################################################
  # Base structure

  my $command = {
    addCluster => {
      description => 'Adds a new cluster',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          allocationstate => 'Allocation state of this cluster for allocation of new resources',
          password        => 'the password for the host',
          podid           => 'the Pod ID for the host',
          url             => 'the URL',
          username        => 'the username for the cluster',
        },
        required => {
          clustername => 'the cluster name',
          clustertype => 'type of the cluster: CloudManaged, ExternalManaged',
          hypervisor  => 'hypervisor type of the cluster: XenServer,KVM,VMware,Hyperv,BareMetal,Simulator',
          zoneid      => 'the Zone ID for the cluster',
        },
      },
      response => {
        allocationstate => 'the allocation state of the cluster',
        clustertype     => 'the type of the cluster',
        hypervisortype  => 'the hypervisor type of the cluster',
        id              => 'the cluster ID',
        managedstate    => 'whether this cluster is managed by cloudstack',
        name            => 'the cluster name',
        podid           => 'the Pod ID of the cluster',
        podname         => 'the Pod name of the cluster',
        zoneid          => 'the Zone ID of the cluster',
        zonename        => 'the Zone name of the cluster',
      },
      section => 'Host',
    },
    addExternalFirewall => {
      description => 'Adds an external firewall appliance',
      isAsync     => 'false',
      level       => 1,
      request     => {
        required => {
          password => 'Password of the external firewall appliance.',
          url      => 'URL of the external firewall appliance.',
          username => 'Username of the external firewall appliance.',
          zoneid   => 'Zone in which to add the external firewall appliance.',
        },
      },
      response => {
        id               => 'the ID of the external firewall',
        ipaddress        => 'the management IP address of the external firewall',
        numretries       => 'the number of times to retry requests to the external firewall',
        privateinterface => 'the private interface of the external firewall',
        privatezone      => 'the private security zone of the external firewall',
        publicinterface  => 'the public interface of the external firewall',
        publiczone       => 'the public security zone of the external firewall',
        timeout          => 'the timeout (in seconds) for requests to the external firewall',
        usageinterface   => 'the usage interface of the external firewall',
        username         => 'the username that\'s used to log in to the external firewall',
        zoneid           => 'the zone ID of the external firewall',
      },
      section => 'ExternalFirewall',
    },
    addExternalLoadBalancer => {
      description => 'Adds an external load balancer appliance.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        required => {
          password => 'Password of the external load balancer appliance.',
          url      => 'URL of the external load balancer appliance.',
          username => 'Username of the external load balancer appliance.',
          zoneid   => 'Zone in which to add the external load balancer appliance.',
        },
      },
      response => {
        id               => 'the ID of the external load balancer',
        inline           => 'configures the external load balancer to be inline with an external firewall',
        ipaddress        => 'the management IP address of the external load balancer',
        numretries       => 'the number of times to retry requests to the external load balancer',
        privateinterface => 'the private interface of the external load balancer',
        publicinterface  => 'the public interface of the external load balancer',
        username         => 'the username that\'s used to log in to the external load balancer',
        zoneid           => 'the zone ID of the external load balancer',
      },
      section => 'ExternalLoadBalancer',
    },
    addHost => {
      description => 'Adds a new host.',
      isAsync     => 'false',
      level       => 3,
      request     => {
        optional => {
          allocationstate => 'Allocation state of this Host for allocation of new resources',
          clusterid       => 'the cluster ID for the host',
          clustername     => 'the cluster name for the host',
          hosttags        => 'list of tags to be added to the host',
          podid           => 'the Pod ID for the host',
        },
        required => {
          hypervisor => 'hypervisor type of the host',
          password   => 'the password for the host',
          url        => 'the host URL',
          username   => 'the username for the host',
          zoneid     => 'the Zone ID for the host',
        },
      },
      response => {
        allocationstate         => 'the allocation state of the host',
        averageload             => 'the cpu average load on the host',
        capabilities            => 'capabilities of the host',
        clusterid               => 'the cluster ID of the host',
        clustername             => 'the cluster name of the host',
        clustertype             => 'the cluster type of the cluster that host belongs to',
        cpuallocated            => 'the amount of the host\'s CPU currently allocated',
        cpunumber               => 'the CPU number of the host',
        cpuspeed                => 'the CPU speed of the host',
        cpuused                 => 'the amount of the host\'s CPU currently used',
        cpuwithoverprovisioning => 'the amount of the host\'s CPU after applying the cpu.overprovisioning.factor',
        created                 => 'the date and time the host was created',
        disconnected            => 'true if the host is disconnected. False otherwise.',
        disksizeallocated       => 'the host\'s currently allocated disk size',
        disksizetotal           => 'the total disk size of the host',
        events                  => 'events available for the host',
        hasEnoughCapacity => 'true if this host has enough CPU and RAM capacity to migrate a VM to it, false otherwise',
        hosttags          => 'comma-separated list of tags for the host',
        hypervisor        => 'the host hypervisor',
        id                => 'the ID of the host',
        ipaddress         => 'the IP address of the host',
        islocalstorageactive => 'true if local storage is active, false otherwise',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the host',
        jobstatus          => 'shows the current pending asynchronous job status',
        lastpinged         => 'the date and time the host was last pinged',
        managementserverid => 'the management server ID of the host',
        memoryallocated    => 'the amount of the host\'s memory currently allocated',
        memorytotal        => 'the memory total of the host',
        memoryused         => 'the amount of the host\'s memory currently used',
        name               => 'the name of the host',
        networkkbsread     => 'the incoming network traffic on the host',
        networkkbswrite    => 'the outgoing network traffic on the host',
        oscategoryid       => 'the OS category ID of the host',
        oscategoryname     => 'the OS category name of the host',
        podid              => 'the Pod ID of the host',
        podname            => 'the Pod name of the host',
        removed            => 'the date and time the host was removed',
        state              => 'the state of the host',
        type               => 'the host type',
        version            => 'the host version',
        zoneid             => 'the Zone ID of the host',
        zonename           => 'the Zone name of the host',
      },
      section => 'Host',
    },
    addNetworkDevice => {
      description => 'List external load balancer appliances.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          networkdeviceparameterlist => 'parameters for network device',
          networkdevicetype =>
              'Network device type, now supports ExternalDhcp, ExternalFirewall, ExternalLoadBalancer, PxeServer',
        },
      },
      response => { id => 'the ID of the network device' },
      section  => 'NetworkDevices',
    },
    addSecondaryStorage => {
      description => 'Adds secondary storage.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => { zoneid => 'the Zone ID for the secondary storage' },
        required => { url    => 'the URL for the secondary storage' },
      },
      response => {
        allocationstate         => 'the allocation state of the host',
        averageload             => 'the cpu average load on the host',
        capabilities            => 'capabilities of the host',
        clusterid               => 'the cluster ID of the host',
        clustername             => 'the cluster name of the host',
        clustertype             => 'the cluster type of the cluster that host belongs to',
        cpuallocated            => 'the amount of the host\'s CPU currently allocated',
        cpunumber               => 'the CPU number of the host',
        cpuspeed                => 'the CPU speed of the host',
        cpuused                 => 'the amount of the host\'s CPU currently used',
        cpuwithoverprovisioning => 'the amount of the host\'s CPU after applying the cpu.overprovisioning.factor',
        created                 => 'the date and time the host was created',
        disconnected            => 'true if the host is disconnected. False otherwise.',
        disksizeallocated       => 'the host\'s currently allocated disk size',
        disksizetotal           => 'the total disk size of the host',
        events                  => 'events available for the host',
        hasEnoughCapacity => 'true if this host has enough CPU and RAM capacity to migrate a VM to it, false otherwise',
        hosttags          => 'comma-separated list of tags for the host',
        hypervisor        => 'the host hypervisor',
        id                => 'the ID of the host',
        ipaddress         => 'the IP address of the host',
        islocalstorageactive => 'true if local storage is active, false otherwise',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the host',
        jobstatus          => 'shows the current pending asynchronous job status',
        lastpinged         => 'the date and time the host was last pinged',
        managementserverid => 'the management server ID of the host',
        memoryallocated    => 'the amount of the host\'s memory currently allocated',
        memorytotal        => 'the memory total of the host',
        memoryused         => 'the amount of the host\'s memory currently used',
        name               => 'the name of the host',
        networkkbsread     => 'the incoming network traffic on the host',
        networkkbswrite    => 'the outgoing network traffic on the host',
        oscategoryid       => 'the OS category ID of the host',
        oscategoryname     => 'the OS category name of the host',
        podid              => 'the Pod ID of the host',
        podname            => 'the Pod name of the host',
        removed            => 'the date and time the host was removed',
        state              => 'the state of the host',
        type               => 'the host type',
        version            => 'the host version',
        zoneid             => 'the Zone ID of the host',
        zonename           => 'the Zone name of the host',
      },
      section => 'Host',
    },
    addTrafficMonitor => {
      description => 'Adds Traffic Monitor Host for Direct Network Usage',
      isAsync     => 'false',
      level       => 1,
      request     => {
        required => {
          url    => 'URL of the traffic monitor Host',
          zoneid => 'Zone in which to add the external firewall appliance.',
        },
      },
      response => {
        id               => 'the ID of the external firewall',
        ipaddress        => 'the management IP address of the external firewall',
        numretries       => 'the number of times to retry requests to the external firewall',
        privateinterface => 'the private interface of the external firewall',
        privatezone      => 'the private security zone of the external firewall',
        publicinterface  => 'the public interface of the external firewall',
        publiczone       => 'the public security zone of the external firewall',
        timeout          => 'the timeout (in seconds) for requests to the external firewall',
        usageinterface   => 'the usage interface of the external firewall',
        username         => 'the username that\'s used to log in to the external firewall',
        zoneid           => 'the zone ID of the external firewall',
      },
      section => 'TrafficMonitor',
    },
    addVpnUser => {
      description => 'Adds vpn users',
      isAsync     => 'true',
      level       => 15,
      request     => {
        optional => {
          account => 'an optional account for the vpn user. Must be used with domainId.',
          domainid =>
              'an optional domainId for the vpn user. If the account parameter is used, domainId must also be used.',
        },
        required => { password => 'password for the username', username => 'username for the vpn user', },
      },
      response => {
        account    => 'the account of the remote access vpn',
        domainid   => 'the domain id of the account of the remote access vpn',
        domainname => 'the domain name of the account of the remote access vpn',
        id         => 'the vpn userID',
        username   => 'the username of the vpn user',
      },
      section => 'VPN',
    },
    assignToLoadBalancerRule => {
      description => 'Assigns virtual machine or a list of virtual machines to a load balancer rule.',
      isAsync     => 'true',
      level       => 15,
      request     => {
        required => {
          id => 'the ID of the load balancer rule',
          virtualmachineids =>
              'the list of IDs of the virtual machine that are being assigned to the load balancer rule(i.e. virtualMachineIds=1,2,3)',
        },
      },
      response => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'LoadBalancer',
    },
    associateIpAddress => {
      description => 'Acquires and associates a public IP to an account.',
      isAsync     => 'true',
      level       => 15,
      request     => {
        optional => {
          account   => 'the account to associate with this IP address',
          domainid  => 'the ID of the domain to associate with this IP address',
          networkid => 'The network this ip address should be associated to.',
        },
        required => { zoneid => 'the ID of the availability zone you want to acquire an public IP address from', },
      },
      response => {
        account             => 'the account the public IP address is associated with',
        allocated           => 'date the public IP address was acquired',
        associatednetworkid => 'the ID of the Network associated with the IP address',
        domain              => 'the domain the public IP address is associated with',
        domainid            => 'the domain ID the public IP address is associated with',
        forvirtualnetwork   => 'the virtual network for the IP address',
        id                  => 'public IP address id',
        ipaddress           => 'public IP address',
        issourcenat         => 'true if the IP address is a source nat address, false otherwise',
        isstaticnat         => 'true if this ip is for static nat, false otherwise',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume',
        jobstatus => 'shows the current pending asynchronous job status',
        networkid => 'the ID of the Network where ip belongs to',
        state     => 'State of the ip address. Can be: Allocatin, Allocated and Releasing',
        virtualmachinedisplayname =>
            'virutal machine display name the ip address is assigned to (not null only for static nat Ip)',
        virtualmachineid   => 'virutal machine id the ip address is assigned to (not null only for static nat Ip)',
        virtualmachinename => 'virutal machine name the ip address is assigned to (not null only for static nat Ip)',
        vlanid             => 'the ID of the VLAN associated with the IP address',
        vlanname           => 'the VLAN associated with the IP address',
        zoneid             => 'the ID of the zone the public IP address belongs to',
        zonename           => 'the name of the zone the public IP address belongs to',
      },
      section => 'Address',
    },
    associateLun => {
      description => 'Associate a LUN with a guest IQN',
      isAsync     => 'false',
      level       => 15,
      request     => { required => { iqn => 'Guest IQN to which the LUN associate.', name => 'LUN name.' }, },
      response    => { id => 'the LUN id', ipaddress => 'the IP address of', targetiqn => 'the target IQN', },
      section     => 'NetAppIntegration',
    },
    attachIso => {
      description => 'Attaches an ISO to a virtual machine.',
      isAsync     => 'true',
      level       => 15,
      request =>
          { required => { id => 'the ID of the ISO file', virtualmachineid => 'the ID of the virtual machine', }, },
      response => {
        'account'     => 'the account associated with the virtual machine',
        'cpunumber'   => 'the number of cpu this virtual machine is running with',
        'cpuspeed'    => 'the speed of each cpu',
        'cpuused'     => 'the amount of the vm\'s CPU currently used',
        'created'     => 'the date when this virtual machine was created',
        'displayname' => 'user generated name. The name of the virtual machine is returned if no displayname exists.',
        'domain'      => 'the name of the domain in which the virtual machine exists',
        'domainid'    => 'the ID of the domain in which the virtual machine exists',
        'forvirtualnetwork' => 'the virtual network for the service offering',
        'group'             => 'the group name of the virtual machine',
        'groupid'           => 'the group ID of the virtual machine',
        'guestosid'         => 'Os type ID of the virtual machine',
        'haenable'          => 'true if high-availability is enabled, false otherwise',
        'hostid'            => 'the ID of the host for the virtual machine',
        'hostname'          => 'the name of the host for the virtual machine',
        'hypervisor'        => 'the hypervisor on which the template runs',
        'id'                => 'the ID of the virtual machine',
        'ipaddress'         => 'the ip address of the virtual machine',
        'isodisplaytext'    => 'an alternate display text of the ISO attached to the virtual machine',
        'isoid'             => 'the ID of the ISO attached to the virtual machine',
        'isoname'           => 'the name of the ISO attached to the virtual machine',
        'jobid' =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine',
        'jobstatus'           => 'shows the current pending asynchronous job status',
        'memory'              => 'the memory allocated for the virtual machine',
        'name'                => 'the name of the virtual machine',
        'networkkbsread'      => 'the incoming network traffic on the vm',
        'networkkbswrite'     => 'the outgoing network traffic on the host',
        'nic(*)'              => 'the list of nics associated with vm',
        'password'            => 'the password (if exists) of the virtual machine',
        'passwordenabled'     => 'true if the password rest feature is enabled, false otherwise',
        'rootdeviceid'        => 'device ID of the root volume',
        'rootdevicetype'      => 'device type of the root volume',
        'securitygroup(*)'    => 'list of security groups associated with the virtual machine',
        'serviceofferingid'   => 'the ID of the service offering of the virtual machine',
        'serviceofferingname' => 'the name of the service offering of the virtual machine',
        'state'               => 'the state of the virtual machine',
        'templatedisplaytext' => 'an alternate display text of the template for the virtual machine',
        'templateid' =>
            'the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.',
        'templatename' => 'the name of the template for the virtual machine',
        'zoneid'       => 'the ID of the availablility zone for the virtual machine',
        'zonename'     => 'the name of the availability zone for the virtual machine',
      },
      section => 'ISO',
    },
    attachVolume => {
      description => 'Attaches a disk volume to a virtual machine.',
      isAsync     => 'true',
      level       => 15,
      request     => {
        optional => {
          deviceid =>
              'the ID of the device to map the volume to within the guest OS. If no deviceId is passed in, the next available deviceId will be chosen. Possible values for a Linux OS are:* 1 - /dev/xvdb* 2 - /dev/xvdc* 4 - /dev/xvde* 5 - /dev/xvdf* 6 - /dev/xvdg* 7 - /dev/xvdh* 8 - /dev/xvdi* 9 - /dev/xvdj',
        },
        required => { id => 'the ID of the disk volume', virtualmachineid => 'the ID of the virtual machine', },
      },
      response => {
        account   => 'the account associated with the disk volume',
        attached  => 'the date the volume was attached to a VM instance',
        created   => 'the date the disk volume was created',
        destroyed => 'the boolean state of whether the volume is destroyed or not',
        deviceid =>
            'the ID of the device on user vm the volume is attahed to. This tag is not returned when the volume is detached.',
        diskofferingdisplaytext => 'the display text of the disk offering',
        diskofferingid          => 'ID of the disk offering',
        diskofferingname        => 'name of the disk offering',
        domain                  => 'the domain associated with the disk volume',
        domainid                => 'the ID of the domain associated with the disk volume',
        hypervisor              => 'Hypervisor the volume belongs to',
        id                      => 'ID of the disk volume',
        isextractable           => 'true if the volume is extractable, false otherwise',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume',
        jobstatus                  => 'shows the current pending asynchronous job status',
        name                       => 'name of the disk volume',
        serviceofferingdisplaytext => 'the display text of the service offering for root disk',
        serviceofferingid          => 'ID of the service offering for root disk',
        serviceofferingname        => 'name of the service offering for root disk',
        size                       => 'size of the disk volume',
        snapshotid                 => 'ID of the snapshot from which this volume was created',
        state                      => 'the state of the disk volume',
        storage                    => 'name of the primary storage hosting the disk volume',
        storagetype                => 'shared or local storage',
        type                       => 'type of the disk volume (ROOT or DATADISK)',
        virtualmachineid           => 'id of the virtual machine',
        vmdisplayname              => 'display name of the virtual machine',
        vmname                     => 'name of the virtual machine',
        vmstate                    => 'state of the virtual machine',
        zoneid                     => 'ID of the availability zone',
        zonename                   => 'name of the availability zone',
      },
      section => 'Volume',
    },
    authorizeSecurityGroupIngress => {
      description => 'Authorizes a particular ingress rule for this security group',
      isAsync     => 'true',
      level       => 15,
      request     => {
        optional => {
          account  => 'an optional account for the virtual machine. Must be used with domainId.',
          cidrlist => 'the cidr list associated',
          domainid =>
              'an optional domainId for the security group. If the account parameter is used, domainId must also be used.',
          endport           => 'end port for this ingress rule',
          icmpcode          => 'error code for this icmp message',
          icmptype          => 'type of the icmp message being sent',
          protocol          => 'TCP is default. UDP is the other supported protocol',
          securitygroupid   => 'The ID of the security group. Mutually exclusive with securityGroupName parameter',
          securitygroupname => 'The name of the security group. Mutually exclusive with securityGroupName parameter',
          startport         => 'start port for this ingress rule',
          usersecuritygrouplist => 'user to security group mapping',
        },
      },
      response => {
        account           => 'account owning the ingress rule',
        cidr              => 'the CIDR notation for the base IP address of the ingress rule',
        endport           => 'the ending IP of the ingress rule',
        icmpcode          => 'the code for the ICMP message response',
        icmptype          => 'the type of the ICMP message response',
        protocol          => 'the protocol of the ingress rule',
        ruleid            => 'the id of the ingress rule',
        securitygroupname => 'security group name',
        startport         => 'the starting IP of the ingress rule',
      },
      section => 'SecurityGroup',
    },
    cancelHostMaintenance => {
      description => 'Cancels host maintenance.',
      isAsync     => 'true',
      level       => 1,
      request     => { required => { id => 'the host ID' } },
      response    => {
        allocationstate         => 'the allocation state of the host',
        averageload             => 'the cpu average load on the host',
        capabilities            => 'capabilities of the host',
        clusterid               => 'the cluster ID of the host',
        clustername             => 'the cluster name of the host',
        clustertype             => 'the cluster type of the cluster that host belongs to',
        cpuallocated            => 'the amount of the host\'s CPU currently allocated',
        cpunumber               => 'the CPU number of the host',
        cpuspeed                => 'the CPU speed of the host',
        cpuused                 => 'the amount of the host\'s CPU currently used',
        cpuwithoverprovisioning => 'the amount of the host\'s CPU after applying the cpu.overprovisioning.factor',
        created                 => 'the date and time the host was created',
        disconnected            => 'true if the host is disconnected. False otherwise.',
        disksizeallocated       => 'the host\'s currently allocated disk size',
        disksizetotal           => 'the total disk size of the host',
        events                  => 'events available for the host',
        hasEnoughCapacity => 'true if this host has enough CPU and RAM capacity to migrate a VM to it, false otherwise',
        hosttags          => 'comma-separated list of tags for the host',
        hypervisor        => 'the host hypervisor',
        id                => 'the ID of the host',
        ipaddress         => 'the IP address of the host',
        islocalstorageactive => 'true if local storage is active, false otherwise',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the host',
        jobstatus          => 'shows the current pending asynchronous job status',
        lastpinged         => 'the date and time the host was last pinged',
        managementserverid => 'the management server ID of the host',
        memoryallocated    => 'the amount of the host\'s memory currently allocated',
        memorytotal        => 'the memory total of the host',
        memoryused         => 'the amount of the host\'s memory currently used',
        name               => 'the name of the host',
        networkkbsread     => 'the incoming network traffic on the host',
        networkkbswrite    => 'the outgoing network traffic on the host',
        oscategoryid       => 'the OS category ID of the host',
        oscategoryname     => 'the OS category name of the host',
        podid              => 'the Pod ID of the host',
        podname            => 'the Pod name of the host',
        removed            => 'the date and time the host was removed',
        state              => 'the state of the host',
        type               => 'the host type',
        version            => 'the host version',
        zoneid             => 'the Zone ID of the host',
        zonename           => 'the Zone name of the host',
      },
      section => 'Host',
    },
    cancelStorageMaintenance => {
      description => 'Cancels maintenance for primary storage',
      isAsync     => 'true',
      level       => 1,
      request     => { required => { id => 'the primary storage ID' } },
      response    => {
        clusterid         => 'the ID of the cluster for the storage pool',
        clustername       => 'the name of the cluster for the storage pool',
        created           => 'the date and time the storage pool was created',
        disksizeallocated => 'the host\'s currently allocated disk size',
        disksizetotal     => 'the total disk size of the storage pool',
        id                => 'the ID of the storage pool',
        ipaddress         => 'the IP address of the storage pool',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the storage pool',
        jobstatus => 'shows the current pending asynchronous job status',
        name      => 'the name of the storage pool',
        path      => 'the storage pool path',
        podid     => 'the Pod ID of the storage pool',
        podname   => 'the Pod name of the storage pool',
        state     => 'the state of the storage pool',
        tags      => 'the tags for the storage pool',
        type      => 'the storage pool type',
        zoneid    => 'the Zone ID of the storage pool',
        zonename  => 'the Zone name of the storage pool',
      },
      section => 'StoragePools',
    },
    changeServiceForRouter => {
      description => 'Upgrades domain router to a new service offering',
      isAsync     => 'false',
      level       => 7,
      request     => {
        required => {
          id                => 'The ID of the router',
          serviceofferingid => 'the service offering ID to apply to the domain router',
        },
      },
      response => {
        account             => 'the account associated with the router',
        created             => 'the date and time the router was created',
        dns1                => 'the first DNS for the router',
        dns2                => 'the second DNS for the router',
        domain              => 'the domain associated with the router',
        domainid            => 'the domain ID associated with the router',
        gateway             => 'the gateway for the router',
        guestipaddress      => 'the guest IP address for the router',
        guestmacaddress     => 'the guest MAC address for the router',
        guestnetmask        => 'the guest netmask for the router',
        guestnetworkid      => 'the ID of the corresponding guest network',
        hostid              => 'the host ID for the router',
        hostname            => 'the hostname for the router',
        id                  => 'the id of the router',
        isredundantrouter   => 'if this router is an redundant virtual router',
        linklocalip         => 'the link local IP address for the router',
        linklocalmacaddress => 'the link local MAC address for the router',
        linklocalnetmask    => 'the link local netmask for the router',
        linklocalnetworkid  => 'the ID of the corresponding link local network',
        name                => 'the name of the router',
        networkdomain       => 'the network domain for the router',
        podid               => 'the Pod ID for the router',
        publicip            => 'the public IP address for the router',
        publicmacaddress    => 'the public MAC address for the router',
        publicnetmask       => 'the public netmask for the router',
        publicnetworkid     => 'the ID of the corresponding public network',
        redundantstate      => 'the state of redundant virtual router',
        serviceofferingid   => 'the ID of the service offering of the virtual machine',
        serviceofferingname => 'the name of the service offering of the virtual machine',
        state               => 'the state of the router',
        templateid          => 'the template ID for the router',
        zoneid              => 'the Zone ID for the router',
        zonename            => 'the Zone name for the router',
      },
      section => 'Router',
    },
    changeServiceForVirtualMachine => {
      description =>
          'Changes the service offering for a virtual machine. The virtual machine must be in a \'Stopped\' state for this command to take effect.',
      isAsync => 'false',
      level   => 15,
      request => {
        required => {
          id                => 'The ID of the virtual machine',
          serviceofferingid => 'the service offering ID to apply to the virtual machine',
        },
      },
      response => {
        'account'     => 'the account associated with the virtual machine',
        'cpunumber'   => 'the number of cpu this virtual machine is running with',
        'cpuspeed'    => 'the speed of each cpu',
        'cpuused'     => 'the amount of the vm\'s CPU currently used',
        'created'     => 'the date when this virtual machine was created',
        'displayname' => 'user generated name. The name of the virtual machine is returned if no displayname exists.',
        'domain'      => 'the name of the domain in which the virtual machine exists',
        'domainid'    => 'the ID of the domain in which the virtual machine exists',
        'forvirtualnetwork' => 'the virtual network for the service offering',
        'group'             => 'the group name of the virtual machine',
        'groupid'           => 'the group ID of the virtual machine',
        'guestosid'         => 'Os type ID of the virtual machine',
        'haenable'          => 'true if high-availability is enabled, false otherwise',
        'hostid'            => 'the ID of the host for the virtual machine',
        'hostname'          => 'the name of the host for the virtual machine',
        'hypervisor'        => 'the hypervisor on which the template runs',
        'id'                => 'the ID of the virtual machine',
        'ipaddress'         => 'the ip address of the virtual machine',
        'isodisplaytext'    => 'an alternate display text of the ISO attached to the virtual machine',
        'isoid'             => 'the ID of the ISO attached to the virtual machine',
        'isoname'           => 'the name of the ISO attached to the virtual machine',
        'jobid' =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine',
        'jobstatus'           => 'shows the current pending asynchronous job status',
        'memory'              => 'the memory allocated for the virtual machine',
        'name'                => 'the name of the virtual machine',
        'networkkbsread'      => 'the incoming network traffic on the vm',
        'networkkbswrite'     => 'the outgoing network traffic on the host',
        'nic(*)'              => 'the list of nics associated with vm',
        'password'            => 'the password (if exists) of the virtual machine',
        'passwordenabled'     => 'true if the password rest feature is enabled, false otherwise',
        'rootdeviceid'        => 'device ID of the root volume',
        'rootdevicetype'      => 'device type of the root volume',
        'securitygroup(*)'    => 'list of security groups associated with the virtual machine',
        'serviceofferingid'   => 'the ID of the service offering of the virtual machine',
        'serviceofferingname' => 'the name of the service offering of the virtual machine',
        'state'               => 'the state of the virtual machine',
        'templatedisplaytext' => 'an alternate display text of the template for the virtual machine',
        'templateid' =>
            'the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.',
        'templatename' => 'the name of the template for the virtual machine',
        'zoneid'       => 'the ID of the availablility zone for the virtual machine',
        'zonename'     => 'the name of the availability zone for the virtual machine',
      },
      section => 'VM',
    },
    copyIso => {
      description => 'Copies a template from one zone to another.',
      isAsync     => 'true',
      level       => 15,
      request     => {
        required => {
          destzoneid   => 'ID of the zone the template is being copied to.',
          id           => 'Template ID.',
          sourcezoneid => 'ID of the zone the template is currently hosted on.',
        },
      },
      response => {
        account       => 'the account name to which the template belongs',
        accountid     => 'the account id to which the template belongs',
        bootable      => 'true if the ISO is bootable, false otherwise',
        checksum      => 'checksum of the template',
        created       => 'the date this template was created',
        crossZones    => 'true if the template is managed across all Zones, false otherwise',
        details       => 'additional key/value details tied with template',
        displaytext   => 'the template display text',
        domain        => 'the name of the domain to which the template belongs',
        domainid      => 'the ID of the domain to which the template belongs',
        format        => 'the format of the template.',
        hostid        => 'the ID of the secondary storage host for the template',
        hostname      => 'the name of the secondary storage host for the template',
        hypervisor    => 'the hypervisor on which the template runs',
        id            => 'the template ID',
        isextractable => 'true if the template is extractable, false otherwise',
        isfeatured    => 'true if this template is a featured template, false otherwise',
        ispublic      => 'true if this template is a public template, false otherwise',
        isready       => 'true if the template is ready to be deployed from, false otherwise.',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template',
        jobstatus        => 'shows the current pending asynchronous job status',
        name             => 'the template name',
        ostypeid         => 'the ID of the OS type for this template.',
        ostypename       => 'the name of the OS type for this template.',
        passwordenabled  => 'true if the reset password feature is enabled, false otherwise',
        removed          => 'the date this template was removed',
        size             => 'the size of the template',
        sourcetemplateid => 'the template ID of the parent template if present',
        status           => 'the status of the template',
        templatetag      => 'the tag of this template',
        templatetype     => 'the type of the template',
        zoneid           => 'the ID of the zone for this template',
        zonename         => 'the name of the zone for this template',
      },
      section => 'ISO',
    },
    copyTemplate => {
      description => 'Copies a template from one zone to another.',
      isAsync     => 'true',
      level       => 15,
      request     => {
        required => {
          destzoneid   => 'ID of the zone the template is being copied to.',
          id           => 'Template ID.',
          sourcezoneid => 'ID of the zone the template is currently hosted on.',
        },
      },
      response => {
        account       => 'the account name to which the template belongs',
        accountid     => 'the account id to which the template belongs',
        bootable      => 'true if the ISO is bootable, false otherwise',
        checksum      => 'checksum of the template',
        created       => 'the date this template was created',
        crossZones    => 'true if the template is managed across all Zones, false otherwise',
        details       => 'additional key/value details tied with template',
        displaytext   => 'the template display text',
        domain        => 'the name of the domain to which the template belongs',
        domainid      => 'the ID of the domain to which the template belongs',
        format        => 'the format of the template.',
        hostid        => 'the ID of the secondary storage host for the template',
        hostname      => 'the name of the secondary storage host for the template',
        hypervisor    => 'the hypervisor on which the template runs',
        id            => 'the template ID',
        isextractable => 'true if the template is extractable, false otherwise',
        isfeatured    => 'true if this template is a featured template, false otherwise',
        ispublic      => 'true if this template is a public template, false otherwise',
        isready       => 'true if the template is ready to be deployed from, false otherwise.',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template',
        jobstatus        => 'shows the current pending asynchronous job status',
        name             => 'the template name',
        ostypeid         => 'the ID of the OS type for this template.',
        ostypename       => 'the name of the OS type for this template.',
        passwordenabled  => 'true if the reset password feature is enabled, false otherwise',
        removed          => 'the date this template was removed',
        size             => 'the size of the template',
        sourcetemplateid => 'the template ID of the parent template if present',
        status           => 'the status of the template',
        templatetag      => 'the tag of this template',
        templatetype     => 'the type of the template',
        zoneid           => 'the ID of the zone for this template',
        zonename         => 'the name of the zone for this template',
      },
      section => 'Template',
    },
    createAccount => {
      description => 'Creates an account',
      isAsync     => 'false',
      level       => 3,
      request     => {
        optional => {
          account =>
              'Creates the user under the specified account. If no account is specified, the username will be used as the account name.',
          domainid      => 'Creates the user under the specified domain.',
          networkdomain => 'Network domain for the account\'s networks',
          timezone =>
              'Specifies a timezone for this command. For more information on the timezone parameter, see Time Zone Format.',
        },
        required => {
          accounttype => 'Type of the account.  Specify 0 for user, 1 for root admin, and 2 for domain admin',
          email       => 'email',
          firstname   => 'firstname',
          lastname    => 'lastname',
          password =>
              'Hashed password (Default is MD5). If you wish to use any other hashing algorithm, you would need to write a custom authentication adapter See Docs section.',
          username => 'Unique username.',
        },
      },
      response => {
        account     => 'the account name of the user',
        accounttype => 'the account type of the user',
        apikey      => 'the api key of the user',
        created     => 'the date and time the user account was created',
        domain      => 'the domain name of the user',
        domainid    => 'the domain ID of the user',
        email       => 'the user email address',
        firstname   => 'the user firstname',
        id          => 'the user ID',
        lastname    => 'the user lastname',
        secretkey   => 'the secret key of the user',
        state       => 'the user state',
        timezone    => 'the timezone user was created in',
        username    => 'the user name',
      },
      section => 'Account',
    },
    createConfiguration => {
      description => 'Adds configuration value',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional =>
            { description => 'the description of the configuration', value => 'the value of the configuration', },
        required => {
          category  => 'component\'s category',
          component => 'the component of the configuration',
          instance  => 'the instance of the configuration',
          name      => 'the name of the configuration',
        },
      },
      response => {
        category    => 'the category of the configuration',
        description => 'the description of the configuration',
        name        => 'the name of the configuration',
        value       => 'the value of the configuration',
      },
      section => 'Configuration',
    },
    createDiskOffering => {
      description => 'Creates a disk offering.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          customized => 'whether disk offering is custom or not',
          disksize   => 'size of the disk offering in GB',
          domainid   => 'the ID of the containing domain, null for public offerings',
          tags       => 'tags for the disk offering',
        },
        required =>
            { displaytext => 'alternate display text of the disk offering', name => 'name of the disk offering', },
      },
      response => {
        created     => 'the date this disk offering was created',
        disksize    => 'the size of the disk offering in GB',
        displaytext => 'an alternate display text of the disk offering.',
        domain =>
            'the domain name this disk offering belongs to. Ignore this information as it is not currently applicable.',
        domainid =>
            'the domain ID this disk offering belongs to. Ignore this information as it is not currently applicable.',
        id           => 'unique ID of the disk offering',
        iscustomized => 'true if disk offering uses custom size, false otherwise',
        name         => 'the name of the disk offering',
        tags         => 'the tags for the disk offering',
      },
      section => 'DiskOffering',
    },
    createDomain => {
      description => 'Creates a domain',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          networkdomain => 'Network domain for networks in the domain',
          parentdomainid =>
              'assigns new domain a parent domain by domain ID of the parent.  If no parent domain is specied, the ROOT domain is assumed.',
        },
        required => { name => 'creates domain with this name' },
      },
      response => {
        haschild         => 'whether the domain has one or more sub-domains',
        id               => 'the ID of the domain',
        level            => 'the level of the domain',
        name             => 'the name of the domain',
        networkdomain    => 'the network domain',
        parentdomainid   => 'the domain ID of the parent domain',
        parentdomainname => 'the domain name of the parent domain',
        path             => 'the path of the domain',
      },
      section => 'Domain',
    },
    createFirewallRule => {
      description => 'Creates a firewall rule for a given ip address',
      isAsync     => 'true',
      level       => 15,
      request     => {
        optional => {
          cidrlist  => 'the cidr list to forward traffic from',
          endport   => 'the ending port of firewall rule',
          icmpcode  => 'error code for this icmp message',
          icmptype  => 'type of the icmp message being sent',
          startport => 'the starting port of firewall rule',
        },
        required => {
          ipaddressid => 'the IP address id of the port forwarding rule',
          protocol    => 'the protocol for the firewall rule. Valid values are TCP/UDP/ICMP.',
        },
      },
      response => {
        cidrlist    => 'the cidr list to forward traffic from',
        endport     => 'the ending port of firewall rule\'s port range',
        icmpcode    => 'error code for this icmp message',
        icmptype    => 'type of the icmp message being sent',
        id          => 'the ID of the firewall rule',
        ipaddress   => 'the public ip address for the port forwarding rule',
        ipaddressid => 'the public ip address id for the port forwarding rule',
        protocol    => 'the protocol of the firewall rule',
        startport   => 'the starting port of firewall rule\'s port range',
        state       => 'the state of the rule',
      },
      section => 'Firewall',
    },
    createInstanceGroup => {
      description => 'Creates a vm group',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account =>
              'the account of the instance group. The account parameter must be used with the domainId parameter.',
          domainid => 'the domain ID of account owning the instance group',
        },
        required => { name => 'the name of the instance group' },
      },
      response => {
        account  => 'the account owning the instance group',
        created  => 'time and date the instance group was created',
        domain   => 'the domain name of the instance group',
        domainid => 'the domain ID of the instance group',
        id       => 'the id of the instance group',
        name     => 'the name of the instance group',
      },
      section => 'VMGroup',
    },
    createIpForwardingRule => {
      description => 'Creates an ip forwarding rule',
      isAsync     => 'true',
      level       => 15,
      request     => {
        optional => {
          cidrlist => 'the cidr list to forward traffic from',
          endport  => 'the end port for the rule',
          openfirewall =>
              'if true, firewall rule for source/end pubic port is automatically created; if false - firewall rule has to be created explicitely. Has value true by default',
        },
        required => {
          ipaddressid => 'the public IP address id of the forwarding rule, already associated via associateIp',
          protocol    => 'the protocol for the rule. Valid values are TCP or UDP.',
          startport   => 'the start port for the rule',
        },
      },
      response => {
        cidrlist                  => 'the cidr list to forward traffic from',
        id                        => 'the ID of the port forwarding rule',
        ipaddress                 => 'the public ip address for the port forwarding rule',
        ipaddressid               => 'the public ip address id for the port forwarding rule',
        privateendport            => 'the ending port of port forwarding rule\'s private port range',
        privateport               => 'the starting port of port forwarding rule\'s private port range',
        protocol                  => 'the protocol of the port forwarding rule',
        publicendport             => 'the ending port of port forwarding rule\'s private port range',
        publicport                => 'the starting port of port forwarding rule\'s public port range',
        state                     => 'the state of the rule',
        virtualmachinedisplayname => 'the VM display name for the port forwarding rule',
        virtualmachineid          => 'the VM ID for the port forwarding rule',
        virtualmachinename        => 'the VM name for the port forwarding rule',
      },
      section => 'NAT',
    },
    createLoadBalancerRule => {
      description => 'Creates a load balancer rule',
      isAsync     => 'true',
      level       => 15,
      request     => {
        optional => {
          account     => 'the account associated with the load balancer. Must be used with the domainId parameter.',
          cidrlist    => 'the cidr list to forward traffic from',
          description => 'the description of the load balancer rule',
          domainid    => 'the domain ID associated with the load balancer',
          openfirewall =>
              'if true, firewall rule for source/end pubic port is automatically created; if false - firewall rule has to be created explicitely. Has value true by default',
          publicipid => 'public ip address id from where the network traffic will be load balanced from',
          zoneid     => 'public ip address id from where the network traffic will be load balanced from',
        },
        required => {
          algorithm => 'load balancer algorithm (source, roundrobin, leastconn)',
          name      => 'name of the load balancer rule',
          privateport =>
              'the private port of the private ip address/virtual machine where the network traffic will be load balanced to',
          publicport => 'the public port from where the network traffic will be load balanced from',
        },
      },
      response => {
        account     => 'the account of the load balancer rule',
        algorithm   => 'the load balancer algorithm (source, roundrobin, leastconn)',
        cidrlist    => 'the cidr list to forward traffic from',
        description => 'the description of the load balancer',
        domain      => 'the domain of the load balancer rule',
        domainid    => 'the domain ID of the load balancer rule',
        id          => 'the load balancer rule ID',
        name        => 'the name of the load balancer',
        privateport => 'the private port',
        publicip    => 'the public ip address',
        publicipid  => 'the public ip address id',
        publicport  => 'the public port',
        state       => 'the state of the rule',
        zoneid      => 'the id of the zone the rule belongs to',
      },
      section => 'LoadBalancer',
    },
    createLunOnFiler => {
      description => 'Create a LUN from a pool',
      isAsync     => 'false',
      level       => 15,
      request     => { required => { name => 'pool name.', size => 'LUN size.' } },
      response    => { ipaddress => 'ip address', iqn => 'iqn', path => 'pool path' },
      section     => 'NetAppIntegration',
    },
    createNetwork => {
      description => 'Creates a network',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account   => 'account who will own the network',
          domainid  => 'domain ID of the account owning a network',
          endip     => 'the ending IP address in the network IP range. If not specified, will be defaulted to startIP',
          gateway   => 'the gateway of the network',
          isdefault => 'true if network is default, false otherwise',
          isshared  => 'true is network is shared across accounts in the Zone',
          netmask   => 'the netmask of the network',
          networkdomain => 'network domain',
          startip       => 'the beginning IP address in the network IP range',
          tags          => 'Tag the network',
          vlan          => 'the ID or VID of the network',
        },
        required => {
          displaytext       => 'the display text of the network',
          name              => 'the name of the network',
          networkofferingid => 'the network offering id',
          zoneid            => 'the Zone ID for the network',
        },
      },
      response => {
        'account'                     => 'the owner of the network',
        'broadcastdomaintype'         => 'Broadcast domain type of the network',
        'broadcasturi'                => 'broadcast uri of the network',
        'displaytext'                 => 'the displaytext of the network',
        'dns1'                        => 'the first DNS for the network',
        'dns2'                        => 'the second DNS for the network',
        'domain'                      => 'the domain name of the network owner',
        'domainid'                    => 'the domain id of the network owner',
        'endip'                       => 'the end ip of the network',
        'gateway'                     => 'the network\'s gateway',
        'id'                          => 'the id of the network',
        'isdefault'                   => 'true if network is default, false otherwise',
        'isshared'                    => 'true if network is shared, false otherwise',
        'issystem'                    => 'true if network is system, false otherwise',
        'name'                        => 'the name of the network',
        'netmask'                     => 'the network\'s netmask',
        'networkdomain'               => 'the network domain',
        'networkofferingavailability' => 'availability of the network offering the network is created from',
        'networkofferingdisplaytext'  => 'display text of the network offering the network is created from',
        'networkofferingid'           => 'network offering id the network is created from',
        'networkofferingname'         => 'name of the network offering the network is created from',
        'related'                     => 'related to what other network configuration',
        'securitygroupenabled'        => 'true if security group is enabled, false otherwise',
        'service(*)'                  => 'the list of services',
        'startip'                     => 'the start ip of the network',
        'state'                       => 'state of the network',
        'tags'                        => 'comma separated tag',
        'traffictype'                 => 'the traffic type of the network',
        'type'                        => 'the type of the network',
        'vlan'                        => 'the vlan of the network',
        'zoneid'                      => 'zone id of the network',
      },
      section => 'Network',
    },
    createPod => {
      description => 'Creates a new Pod.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          allocationstate => 'Allocation state of this Pod for allocation of new resources',
          endip           => 'the ending IP address for the Pod',
        },
        required => {
          gateway => 'the gateway for the Pod',
          name    => 'the name of the Pod',
          netmask => 'the netmask for the Pod',
          startip => 'the starting IP address for the Pod',
          zoneid  => 'the Zone ID in which the Pod will be created',
        },
      },
      response => {
        allocationstate => 'the allocation state of the cluster',
        endip           => 'the ending IP for the Pod',
        gateway         => 'the gateway of the Pod',
        id              => 'the ID of the Pod',
        name            => 'the name of the Pod',
        netmask         => 'the netmask of the Pod',
        startip         => 'the starting IP for the Pod',
        zoneid          => 'the Zone ID of the Pod',
        zonename        => 'the Zone name of the Pod',
      },
      section => 'Pod',
    },
    createPool => {
      description => 'Create a pool',
      isAsync     => 'false',
      level       => 15,
      request     => { required => { algorithm => 'algorithm.', name => 'pool name.' } },
      response    => undef,
      section     => 'NetAppIntegration',
    },
    createPortForwardingRule => {
      description => 'Creates a port forwarding rule',
      isAsync     => 'true',
      level       => 15,
      request     => {
        optional => {
          cidrlist => 'the cidr list to forward traffic from',
          openfirewall =>
              'if true, firewall rule for source/end pubic port is automatically created; if false - firewall rule has to be created explicitely. Has value true by default',
          privateendport => 'the ending port of port forwarding rule\'s private port range',
          publicendport  => 'the ending port of port forwarding rule\'s private port range',
        },
        required => {
          ipaddressid      => 'the IP address id of the port forwarding rule',
          privateport      => 'the starting port of port forwarding rule\'s private port range',
          protocol         => 'the protocol for the port fowarding rule. Valid values are TCP or UDP.',
          publicport       => 'the starting port of port forwarding rule\'s public port range',
          virtualmachineid => 'the ID of the virtual machine for the port forwarding rule',
        },
      },
      response => {
        cidrlist                  => 'the cidr list to forward traffic from',
        id                        => 'the ID of the port forwarding rule',
        ipaddress                 => 'the public ip address for the port forwarding rule',
        ipaddressid               => 'the public ip address id for the port forwarding rule',
        privateendport            => 'the ending port of port forwarding rule\'s private port range',
        privateport               => 'the starting port of port forwarding rule\'s private port range',
        protocol                  => 'the protocol of the port forwarding rule',
        publicendport             => 'the ending port of port forwarding rule\'s private port range',
        publicport                => 'the starting port of port forwarding rule\'s public port range',
        state                     => 'the state of the rule',
        virtualmachinedisplayname => 'the VM display name for the port forwarding rule',
        virtualmachineid          => 'the VM ID for the port forwarding rule',
        virtualmachinename        => 'the VM name for the port forwarding rule',
      },
      section => 'Firewall',
    },
    createRemoteAccessVpn => {
      description => 'Creates a l2tp/ipsec remote access vpn',
      isAsync     => 'true',
      level       => 15,
      request     => {
        optional => {
          account  => 'an optional account for the VPN. Must be used with domainId.',
          domainid => 'an optional domainId for the VPN. If the account parameter is used, domainId must also be used.',
          iprange =>
              'the range of ip addresses to allocate to vpn clients. The first ip in the range will be taken by the vpn server',
          openfirewall =>
              'if true, firewall rule for source/end pubic port is automatically created; if false - firewall rule has to be created explicitely. Has value true by default',
        },
        required => { publicipid => 'public ip address id of the vpn server' },
      },
      response => {
        account      => 'the account of the remote access vpn',
        domainid     => 'the domain id of the account of the remote access vpn',
        domainname   => 'the domain name of the account of the remote access vpn',
        iprange      => 'the range of ips to allocate to the clients',
        presharedkey => 'the ipsec preshared key',
        publicip     => 'the public ip address of the vpn server',
        publicipid   => 'the public ip address of the vpn server',
        state        => 'the state of the rule',
      },
      section => 'VPN',
    },
    createSecurityGroup => {
      description => 'Creates a security group',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account     => 'an optional account for the security group. Must be used with domainId.',
          description => 'the description of the security group',
          domainid =>
              'an optional domainId for the security group. If the account parameter is used, domainId must also be used.',
        },
        required => { name => 'name of the security group' },
      },
      response => {
        'account'        => 'the account owning the security group',
        'description'    => 'the description of the security group',
        'domain'         => 'the domain name of the security group',
        'domainid'       => 'the domain ID of the security group',
        'id'             => 'the ID of the security group',
        'ingressrule(*)' => 'the list of ingress rules associated with the security group',
        'jobid' =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume',
        'jobstatus' => 'shows the current pending asynchronous job status',
        'name'      => 'the name of the security group',
      },
      section => 'SecurityGroup',
    },
    createServiceOffering => {
      description => 'Creates a service offering.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          domainid    => 'the ID of the containing domain, null for public offerings',
          hosttags    => 'the host tag for this service offering.',
          issystem    => 'is this a system vm offering',
          limitcpuuse => 'restrict the CPU usage to committed service offering',
          networkrate =>
              'data transfer rate in megabits per second allowed. Supported only for non-System offering and system offerings having \'domainrouter\' systemvmtype',
          offerha     => 'the HA for the service offering',
          storagetype => 'the storage type of the service offering. Values are local and shared.',
          systemvmtype =>
              'the system VM type. Possible types are \'domainrouter\', \'consoleproxy\' and \'secondarystoragevm\'.',
          tags => 'the tags for this service offering.',
        },
        required => {
          cpunumber   => 'the CPU number of the service offering',
          cpuspeed    => 'the CPU speed of the service offering in MHz.',
          displaytext => 'the display text of the service offering',
          memory      => 'the total memory of the service offering in MB',
          name        => 'the name of the service offering',
        },
      },
      response => {
        cpunumber    => 'the number of CPU',
        cpuspeed     => 'the clock rate CPU speed in Mhz',
        created      => 'the date this service offering was created',
        defaultuse   => 'is this a  default system vm offering',
        displaytext  => 'an alternate display text of the service offering.',
        domain       => 'Domain name for the offering',
        domainid     => 'the domain id of the service offering',
        hosttags     => 'the host tag for the service offering',
        id           => 'the id of the service offering',
        issystem     => 'is this a system vm offering',
        limitcpuuse  => 'restrict the CPU usage to committed service offering',
        memory       => 'the memory in MB',
        name         => 'the name of the service offering',
        networkrate  => 'data transfer rate in megabits per second allowed.',
        offerha      => 'the ha support in the service offering',
        storagetype  => 'the storage type for this service offering',
        systemvmtype => 'is this a the systemvm type for system vm offering',
        tags         => 'the tags for the service offering',
      },
      section => 'ServiceOffering',
    },
    createSnapshot => {
      description => 'Creates an instant snapshot of a volume.',
      isAsync     => 'true',
      level       => 15,
      request     => {
        optional => {
          account => 'The account of the snapshot. The account parameter must be used with the domainId parameter.',
          domainid =>
              'The domain ID of the snapshot. If used with the account parameter, specifies a domain for the account associated with the disk volume.',
          policyid => 'policy id of the snapshot, if this is null, then use MANUAL_POLICY.',
        },
        required => { volumeid => 'The ID of the disk volume' },
      },
      response => {
        account      => 'the account associated with the snapshot',
        created      => 'the date the snapshot was created',
        domain       => 'the domain name of the snapshot\'s account',
        domainid     => 'the domain ID of the snapshot\'s account',
        id           => 'ID of the snapshot',
        intervaltype => 'valid types are hourly, daily, weekly, monthy, template, and none.',
        jobid =>
            'the job ID associated with the snapshot. This is only displayed if the snapshot listed is part of a currently running asynchronous job.',
        jobstatus =>
            'the job status associated with the snapshot.  This is only displayed if the snapshot listed is part of a currently running asynchronous job.',
        name         => 'name of the snapshot',
        snapshottype => 'the type of the snapshot',
        state =>
            'the state of the snapshot. BackedUp means that snapshot is ready to be used; Creating - the snapshot is being allocated on the primary storage; BackingUp - the snapshot is being backed up on secondary storage',
        volumeid   => 'ID of the disk volume',
        volumename => 'name of the disk volume',
        volumetype => 'type of the disk volume',
      },
      section => 'Snapshot',
    },
    createSnapshotPolicy => {
      description => 'Creates a snapshot policy for the account.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        required => {
          intervaltype => 'valid values are HOURLY, DAILY, WEEKLY, and MONTHLY',
          maxsnaps     => 'maximum number of snapshots to retain',
          schedule =>
              'time the snapshot is scheduled to be taken. Format is:* if HOURLY, MM* if DAILY, MM:HH* if WEEKLY, MM:HH:DD (1-7)* if MONTHLY, MM:HH:DD (1-28)',
          timezone =>
              'Specifies a timezone for this command. For more information on the timezone parameter, see Time Zone Format.',
          volumeid => 'the ID of the disk volume',
        },
      },
      response => {
        id           => 'the ID of the snapshot policy',
        intervaltype => 'the interval type of the snapshot policy',
        maxsnaps     => 'maximum number of snapshots retained',
        schedule     => 'time the snapshot is scheduled to be taken.',
        timezone     => 'the time zone of the snapshot policy',
        volumeid     => 'the ID of the disk volume',
      },
      section => 'Snapshot',
    },
    createSSHKeyPair => {
      description => 'Create a new keypair and returns the private key',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account => 'an optional account for the ssh key. Must be used with domainId.',
          domainid =>
              'an optional domainId for the ssh key. If the account parameter is used, domainId must also be used.',
        },
        required => { name => 'Name of the keypair' },
      },
      response => {
        fingerprint => 'Fingerprint of the public key',
        name        => 'Name of the keypair',
        privatekey  => 'Private key',
      },
      section => 'SSHKeyPair',
    },
    createStoragePool => {
      description => 'Creates a storage pool.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          clusterid => 'the cluster ID for the storage pool',
          details   => 'the details for the storage pool',
          podid     => 'the Pod ID for the storage pool',
          tags      => 'the tags for the storage pool',
        },
        required => {
          name   => 'the name for the storage pool',
          url    => 'the URL of the storage pool',
          zoneid => 'the Zone ID for the storage pool',
        },
      },
      response => {
        clusterid         => 'the ID of the cluster for the storage pool',
        clustername       => 'the name of the cluster for the storage pool',
        created           => 'the date and time the storage pool was created',
        disksizeallocated => 'the host\'s currently allocated disk size',
        disksizetotal     => 'the total disk size of the storage pool',
        id                => 'the ID of the storage pool',
        ipaddress         => 'the IP address of the storage pool',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the storage pool',
        jobstatus => 'shows the current pending asynchronous job status',
        name      => 'the name of the storage pool',
        path      => 'the storage pool path',
        podid     => 'the Pod ID of the storage pool',
        podname   => 'the Pod name of the storage pool',
        state     => 'the state of the storage pool',
        tags      => 'the tags for the storage pool',
        type      => 'the storage pool type',
        zoneid    => 'the Zone ID of the storage pool',
        zonename  => 'the Zone name of the storage pool',
      },
      section => 'StoragePools',
    },
    createTemplate => {
      description =>
          'Creates a template of a virtual machine. The virtual machine must be in a STOPPED state. A template created from this command is automatically designated as a private template visible to the account that created it.',
      isAsync => 'true',
      level   => 15,
      request => {
        optional => {
          bits            => '32 or 64 bit',
          details         => 'Template details in key/value pairs.',
          isfeatured      => 'true if this template is a featured template, false otherwise',
          ispublic        => 'true if this template is a public template, false otherwise',
          passwordenabled => 'true if the template supports the password reset feature; default is false',
          requireshvm     => 'true if the template requres HVM, false otherwise',
          snapshotid =>
              'the ID of the snapshot the template is being created from. Either this parameter, or volumeId has to be passed in',
          templatetag => 'the tag for this template.',
          url => 'Optional, only for baremetal hypervisor. The directory name where template stored on CIFS server',
          virtualmachineid =>
              'Optional, VM ID. If this presents, it is going to create a baremetal template for VM this ID refers to. This is only for VM whose hypervisor type is BareMetal',
          volumeid =>
              'the ID of the disk volume the template is being created from. Either this parameter, or snapshotId has to be passed in',
        },
        required => {
          displaytext => 'the display text of the template. This is usually used for display purposes.',
          name        => 'the name of the template',
          ostypeid    => 'the ID of the OS Type that best represents the OS of this template.',
        },
      },
      response => {
        clusterid         => 'the ID of the cluster for the storage pool',
        clustername       => 'the name of the cluster for the storage pool',
        created           => 'the date and time the storage pool was created',
        disksizeallocated => 'the host\'s currently allocated disk size',
        disksizetotal     => 'the total disk size of the storage pool',
        id                => 'the ID of the storage pool',
        ipaddress         => 'the IP address of the storage pool',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the storage pool',
        jobstatus => 'shows the current pending asynchronous job status',
        name      => 'the name of the storage pool',
        path      => 'the storage pool path',
        podid     => 'the Pod ID of the storage pool',
        podname   => 'the Pod name of the storage pool',
        state     => 'the state of the storage pool',
        tags      => 'the tags for the storage pool',
        type      => 'the storage pool type',
        zoneid    => 'the Zone ID of the storage pool',
        zonename  => 'the Zone name of the storage pool',
      },
      section => 'Template',
    },
    createUser => {
      description => 'Creates a user for an account that already exists',
      isAsync     => 'false',
      level       => 3,
      request     => {
        optional => {
          domainid => 'Creates the user under the specified domain. Has to be accompanied with the account parameter',
          timezone =>
              'Specifies a timezone for this command. For more information on the timezone parameter, see Time Zone Format.',
        },
        required => {
          account =>
              'Creates the user under the specified account. If no account is specified, the username will be used as the account name.',
          email     => 'email',
          firstname => 'firstname',
          lastname  => 'lastname',
          password =>
              'Hashed password (Default is MD5). If you wish to use any other hashing algorithm, you would need to write a custom authentication adapter See Docs section.',
          username => 'Unique username.',
        },
      },
      response => {
        account     => 'the account name of the user',
        accounttype => 'the account type of the user',
        apikey      => 'the api key of the user',
        created     => 'the date and time the user account was created',
        domain      => 'the domain name of the user',
        domainid    => 'the domain ID of the user',
        email       => 'the user email address',
        firstname   => 'the user firstname',
        id          => 'the user ID',
        lastname    => 'the user lastname',
        secretkey   => 'the secret key of the user',
        state       => 'the user state',
        timezone    => 'the timezone user was created in',
        username    => 'the user name',
      },
      section => 'User',
    },
    createVlanIpRange => {
      description => 'Creates a VLAN IP range.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          account           => 'account who will own the VLAN. If VLAN is Zone wide, this parameter should be ommited',
          domainid          => 'domain ID of the account owning a VLAN',
          endip             => 'the ending IP address in the VLAN IP range',
          forvirtualnetwork => 'true if VLAN is of Virtual type, false if Direct',
          gateway           => 'the gateway of the VLAN IP range',
          netmask           => 'the netmask of the VLAN IP range',
          networkid         => 'the network id',
          podid             => 'optional parameter. Have to be specified for Direct Untagged vlan only.',
          vlan              => 'the ID or VID of the VLAN. Default is an \'untagged\' VLAN.',
          zoneid            => 'the Zone ID of the VLAN IP range',
        },
        required => { startip => 'the beginning IP address in the VLAN IP range' },
      },
      response => {
        account           => 'the account of the VLAN IP range',
        description       => 'the description of the VLAN IP range',
        domain            => 'the domain name of the VLAN IP range',
        domainid          => 'the domain ID of the VLAN IP range',
        endip             => 'the end ip of the VLAN IP range',
        forvirtualnetwork => 'the virtual network for the VLAN IP range',
        gateway           => 'the gateway of the VLAN IP range',
        id                => 'the ID of the VLAN IP range',
        netmask           => 'the netmask of the VLAN IP range',
        networkid         => 'the network id of vlan range',
        podid             => 'the Pod ID for the VLAN IP range',
        podname           => 'the Pod name for the VLAN IP range',
        startip           => 'the start ip of the VLAN IP range',
        vlan              => 'the ID or VID of the VLAN.',
        zoneid            => 'the Zone ID of the VLAN IP range',
      },
      section => 'VLAN',
    },
    createVolume => {
      description =>
          'Creates a disk volume from a disk offering. This disk volume must still be attached to a virtual machine to make use of it.',
      isAsync => 'true',
      level   => 15,
      request => {
        optional => {
          account        => 'the account associated with the disk volume. Must be used with the domainId parameter.',
          diskofferingid => 'the ID of the disk offering. Either diskOfferingId or snapshotId must be passed in.',
          domainid =>
              'the domain ID associated with the disk offering. If used with the account parameter returns the disk volume associated with the account for the specified domain.',
          size       => 'Arbitrary volume size',
          snapshotid => 'the snapshot ID for the disk volume. Either diskOfferingId or snapshotId must be passed in.',
          zoneid     => 'the ID of the availability zone',
        },
        required => { name => 'the name of the disk volume' },
      },
      response => {
        account   => 'the account associated with the disk volume',
        attached  => 'the date the volume was attached to a VM instance',
        created   => 'the date the disk volume was created',
        destroyed => 'the boolean state of whether the volume is destroyed or not',
        deviceid =>
            'the ID of the device on user vm the volume is attahed to. This tag is not returned when the volume is detached.',
        diskofferingdisplaytext => 'the display text of the disk offering',
        diskofferingid          => 'ID of the disk offering',
        diskofferingname        => 'name of the disk offering',
        domain                  => 'the domain associated with the disk volume',
        domainid                => 'the ID of the domain associated with the disk volume',
        hypervisor              => 'Hypervisor the volume belongs to',
        id                      => 'ID of the disk volume',
        isextractable           => 'true if the volume is extractable, false otherwise',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume',
        jobstatus                  => 'shows the current pending asynchronous job status',
        name                       => 'name of the disk volume',
        serviceofferingdisplaytext => 'the display text of the service offering for root disk',
        serviceofferingid          => 'ID of the service offering for root disk',
        serviceofferingname        => 'name of the service offering for root disk',
        size                       => 'size of the disk volume',
        snapshotid                 => 'ID of the snapshot from which this volume was created',
        state                      => 'the state of the disk volume',
        storage                    => 'name of the primary storage hosting the disk volume',
        storagetype                => 'shared or local storage',
        type                       => 'type of the disk volume (ROOT or DATADISK)',
        virtualmachineid           => 'id of the virtual machine',
        vmdisplayname              => 'display name of the virtual machine',
        vmname                     => 'name of the virtual machine',
        vmstate                    => 'state of the virtual machine',
        zoneid                     => 'ID of the availability zone',
        zonename                   => 'name of the availability zone',
      },
      section => 'Volume',
    },
    createVolumeOnFiler => {
      description => 'Create a volume',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => { snapshotpolicy => 'snapshot policy.', snapshotreservation => 'snapshot reservation.', },
        required => {
          aggregatename => 'aggregate name.',
          ipaddress     => 'ip address.',
          password      => 'password.',
          poolname      => 'pool name.',
          size          => 'volume size.',
          username      => 'user name.',
          volumename    => 'volume name.',
        },
      },
      response => undef,
      section  => 'NetAppIntegration',
    },
    createZone => {
      description => 'Creates a Zone.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          allocationstate      => 'Allocation state of this Zone for allocation of new resources',
          dns2                 => 'the second DNS for the Zone',
          domain               => 'Network domain name for the networks in the zone',
          domainid             => 'the ID of the containing domain, null for public zones',
          guestcidraddress     => 'the guest CIDR address for the Zone',
          internaldns2         => 'the second internal DNS for the Zone',
          securitygroupenabled => 'true if network is security group enabled, false otherwise',
          vlan                 => 'the VLAN for the Zone',
        },
        required => {
          dns1         => 'the first DNS for the Zone',
          internaldns1 => 'the first internal DNS for the Zone',
          name         => 'the name of the Zone',
          networktype  => 'network type of the zone, can be Basic or Advanced',
        },
      },
      response => {
        allocationstate       => 'the allocation state of the cluster',
        description           => 'Zone description',
        dhcpprovider          => 'the dhcp Provider for the Zone',
        displaytext           => 'the display text of the zone',
        dns1                  => 'the first DNS for the Zone',
        dns2                  => 'the second DNS for the Zone',
        domain                => 'Network domain name for the networks in the zone',
        domainid              => 'the ID of the containing domain, null for public zones',
        guestcidraddress      => 'the guest CIDR address for the Zone',
        id                    => 'Zone id',
        internaldns1          => 'the first internal DNS for the Zone',
        internaldns2          => 'the second internal DNS for the Zone',
        name                  => 'Zone name',
        networktype           => 'the network type of the zone; can be Basic or Advanced',
        securitygroupsenabled => 'true if security groups support is enabled, false otherwise',
        vlan                  => 'the vlan range of the zone',
        zonetoken             => 'Zone Token',
      },
      section => 'Zone',
    },
    deleteAccount => {
      description => 'Deletes a account, and all users associated with this account',
      isAsync     => 'true',
      level       => 3,
      request     => { required => { id => 'Account id' } },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'Account',
    },
    deleteCluster => {
      description => 'Deletes a cluster.',
      isAsync     => 'false',
      level       => 1,
      request     => { required => { id => 'the cluster ID' } },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'Host',
    },
    deleteDiskOffering => {
      description => 'Updates a disk offering.',
      isAsync     => 'false',
      level       => 1,
      request     => { required => { id => 'ID of the disk offering' } },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'DiskOffering',
    },
    deleteDomain => {
      description => 'Deletes a specified domain',
      isAsync     => 'true',
      level       => 1,
      request     => {
        optional => {
          cleanup => 'true if all domain resources (child domains, accounts) have to be cleaned up, false otherwise',
        },
        required => { id => 'ID of domain to delete' },
      },
      response => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'Domain',
    },
    deleteExternalFirewall => {
      description => 'Deletes an external firewall appliance.',
      isAsync     => 'false',
      level       => 1,
      request     => { required => { id => 'Id of the external firewall appliance.' } },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'ExternalFirewall',
    },
    deleteExternalLoadBalancer => {
      description => 'Deletes an external load balancer appliance.',
      isAsync     => 'false',
      level       => 1,
      request     => { required => { id => 'Id of the external loadbalancer appliance.' }, },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'ExternalLoadBalancer',
    },
    deleteFirewallRule => {
      description => 'Deletes a firewall rule',
      isAsync     => 'true',
      level       => 15,
      request     => { required => { id => 'the ID of the firewall rule' } },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'Firewall',
    },
    deleteHost => {
      description => 'Deletes a host.',
      isAsync     => 'false',
      level       => 3,
      request     => {
        optional => {
          forced =>
              'Force delete the host. All HA enabled vms running on the host will be put to HA; HA disabled ones will be stopped',
          forcedestroylocalstorage =>
              'Force destroy local storage on this host. All VMs created on this local storage will be destroyed',
        },
        required => { id => 'the host ID' },
      },
      response => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'Host',
    },
    deleteInstanceGroup => {
      description => 'Deletes a vm group',
      isAsync     => 'false',
      level       => 15,
      request     => { required => { id => 'the ID of the instance group' } },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'VMGroup',
    },
    deleteIpForwardingRule => {
      description => 'Deletes an ip forwarding rule',
      isAsync     => 'true',
      level       => 15,
      request     => { required => { id => 'the id of the forwarding rule' } },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'NAT',
    },
    deleteIso => {
      description => 'Deletes an ISO file.',
      isAsync     => 'true',
      level       => 15,
      request     => {
        optional => {
          zoneid => 'the ID of the zone of the ISO file. If not specified, the ISO will be deleted from all the zones',
        },
        required => { id => 'the ID of the ISO file' },
      },
      response => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'ISO',
    },
    deleteLoadBalancerRule => {
      description => 'Deletes a load balancer rule.',
      isAsync     => 'true',
      level       => 15,
      request     => { required => { id => 'the ID of the load balancer rule' } },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'LoadBalancer',
    },
    deleteNetwork => {
      description => 'Deletes a network',
      isAsync     => 'true',
      level       => 15,
      request     => { required => { id => 'the ID of the network' } },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'Network',
    },
    deleteNetworkDevice => {
      description => 'Delete network device.',
      isAsync     => 'false',
      level       => 1,
      request     => { optional => { id => 'Id of network device to delete' } },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'NetworkDevices',
    },
    deletePod => {
      description => 'Deletes a Pod.',
      isAsync     => 'false',
      level       => 1,
      request     => { required => { id => 'the ID of the Pod' } },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'Pod',
    },
    deletePool => {
      description => 'Delete a pool',
      isAsync     => 'false',
      level       => 15,
      request     => { required => { poolname => 'pool name.' } },
      response    => undef,
      section     => 'NetAppIntegration',
    },
    deletePortForwardingRule => {
      description => 'Deletes a port forwarding rule',
      isAsync     => 'true',
      level       => 15,
      request     => { required => { id => 'the ID of the port forwarding rule' } },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'Firewall',
    },
    deleteRemoteAccessVpn => {
      description => 'Destroys a l2tp/ipsec remote access vpn',
      isAsync     => 'true',
      level       => 15,
      request     => { required => { publicipid => 'public ip address id of the vpn server' }, },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'VPN',
    },
    deleteSecurityGroup => {
      description => 'Deletes security group',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account  => 'the account of the security group. Must be specified with domain ID',
          domainid => 'the domain ID of account owning the security group',
          id       => 'The ID of the security group. Mutually exclusive with name parameter',
          name     => 'The ID of the security group. Mutually exclusive with id parameter',
        },
      },
      response => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'SecurityGroup',
    },
    deleteServiceOffering => {
      description => 'Deletes a service offering.',
      isAsync     => 'false',
      level       => 1,
      request     => { required => { id => 'the ID of the service offering' } },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'ServiceOffering',
    },
    deleteSnapshot => {
      description => 'Deletes a snapshot of a disk volume.',
      isAsync     => 'true',
      level       => 15,
      request     => { required => { id => 'The ID of the snapshot' } },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'Snapshot',
    },
    deleteSnapshotPolicies => {
      description => 'Deletes snapshot policies for the account.',
      isAsync     => 'false',
      level       => 15,
      request =>
          { optional => { id => 'the Id of the snapshot', ids => 'list of snapshots IDs separated by comma', }, },
      response => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'Snapshot',
    },
    deleteSSHKeyPair => {
      description => 'Deletes a keypair by name',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account  => 'the account associated with the keypair. Must be used with the domainId parameter.',
          domainid => 'the domain ID associated with the keypair',
        },
        required => { name => 'Name of the keypair' },
      },
      response => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'SSHKeyPair',
    },
    deleteStoragePool => {
      description => 'Deletes a storage pool.',
      isAsync     => 'false',
      level       => 1,
      request     => { required => { id => 'Storage pool id' } },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'StoragePools',
    },
    deleteTemplate => {
      description =>
          'Deletes a template from the system. All virtual machines using the deleted template will not be affected.',
      isAsync => 'true',
      level   => 15,
      request => {
        optional => { zoneid => 'the ID of zone of the template' },
        required => { id     => 'the ID of the template' },
      },
      response => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'Template',
    },
    deleteTrafficMonitor => {
      description => 'Deletes an traffic monitor host.',
      isAsync     => 'false',
      level       => 1,
      request     => { required => { id => 'Id of the Traffic Monitor Host.' } },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'TrafficMonitor',
    },
    deleteUser => {
      description => 'Creates a user for an account',
      isAsync     => 'false',
      level       => 3,
      request     => { required => { id => 'Deletes a user' } },
      response    => {
        account     => 'the account name of the user',
        accounttype => 'the account type of the user',
        apikey      => 'the api key of the user',
        created     => 'the date and time the user account was created',
        domain      => 'the domain name of the user',
        domainid    => 'the domain ID of the user',
        email       => 'the user email address',
        firstname   => 'the user firstname',
        id          => 'the user ID',
        lastname    => 'the user lastname',
        secretkey   => 'the secret key of the user',
        state       => 'the user state',
        timezone    => 'the timezone user was created in',
        username    => 'the user name',
      },
      section => 'User',
    },
    deleteVlanIpRange => {
      description => 'Creates a VLAN IP range.',
      isAsync     => 'false',
      level       => 1,
      request     => { required => { id => 'the id of the VLAN IP range' } },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'VLAN',
    },
    deleteVolume => {
      description => 'Deletes a detached disk volume.',
      isAsync     => 'false',
      level       => 15,
      request     => { required => { id => 'The ID of the disk volume' } },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'Volume',
    },
    deleteZone => {
      description => 'Deletes a Zone.',
      isAsync     => 'false',
      level       => 1,
      request     => { required => { id => 'the ID of the Zone' } },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'Zone',
    },
    deployVirtualMachine => {
      description =>
          'Creates and automatically starts a virtual machine based on a service offering, disk offering, and template.',
      isAsync => 'true',
      level   => 15,
      request => {
        optional => {
          account => 'an optional account for the virtual machine. Must be used with domainId.',
          diskofferingid =>
              'the ID of the disk offering for the virtual machine. If the template is of ISO format, the diskOfferingId is for the root disk volume. Otherwise this parameter is used to indicate the offering for the data disk volume. If the templateId parameter passed is from a Template object, the diskOfferingId refers to a DATA Disk Volume created. If the templateId parameter passed is from an ISO object, the diskOfferingId refers to a ROOT Disk Volume created.',
          displayname => 'an optional user generated name for the virtual machine',
          domainid =>
              'an optional domainId for the virtual machine. If the account parameter is used, domainId must also be used.',
          group      => 'an optional group for the virtual machine',
          hostid     => 'destination Host ID to deploy the VM to - parameter available for root admin only',
          hypervisor => 'the hypervisor on which to deploy the virtual machine',
          ipaddress  => 'the ip address for default vm\'s network',
          iptonetworklist =>
              'ip to network mapping. Can\'t be specified with networkIds parameter. Example: iptonetworklist[0].ip=10.10.10.11&iptonetworklist[0].networkid=204 - requests to use ip 10.10.10.11 in network id=204',
          keyboard =>
              'an optional keyboard device type for the virtual machine. valid value can be one of de,de-ch,es,fi,fr,fr-be,fr-ch,is,it,jp,nl-be,no,pt,uk,us',
          keypair => 'name of the ssh key pair used to login to the virtual machine',
          name    => 'host name for the virtual machine',
          networkids =>
              'list of network ids used by virtual machine. Can\'t be specified with ipToNetworkList parameter',
          securitygroupids =>
              'comma separated list of security groups id that going to be applied to the virtual machine. Should be passed only when vm is created from a zone with Basic Network support. Mutually exclusive with securitygroupnames parameter',
          securitygroupnames =>
              'comma separated list of security groups names that going to be applied to the virtual machine. Should be passed only when vm is created from a zone with Basic Network support. Mutually exclusive with securitygroupids parameter',
          size => 'the arbitrary size for the DATADISK volume. Mutually exclusive with diskOfferingId',
          userdata =>
              'an optional binary data that can be sent to the virtual machine upon a successful deployment. This binary data must be base64 encoded before adding it to the request. Currently only HTTP GET is supported. Using HTTP GET (via querystring), you can send up to 2KB of data after base64 encoding.',
        },
        required => {
          serviceofferingid => 'the ID of the service offering for the virtual machine',
          templateid        => 'the ID of the template for the virtual machine',
          zoneid            => 'availability zone for the virtual machine',
        },
      },
      response => {
        'account'     => 'the account associated with the virtual machine',
        'cpunumber'   => 'the number of cpu this virtual machine is running with',
        'cpuspeed'    => 'the speed of each cpu',
        'cpuused'     => 'the amount of the vm\'s CPU currently used',
        'created'     => 'the date when this virtual machine was created',
        'displayname' => 'user generated name. The name of the virtual machine is returned if no displayname exists.',
        'domain'      => 'the name of the domain in which the virtual machine exists',
        'domainid'    => 'the ID of the domain in which the virtual machine exists',
        'forvirtualnetwork' => 'the virtual network for the service offering',
        'group'             => 'the group name of the virtual machine',
        'groupid'           => 'the group ID of the virtual machine',
        'guestosid'         => 'Os type ID of the virtual machine',
        'haenable'          => 'true if high-availability is enabled, false otherwise',
        'hostid'            => 'the ID of the host for the virtual machine',
        'hostname'          => 'the name of the host for the virtual machine',
        'hypervisor'        => 'the hypervisor on which the template runs',
        'id'                => 'the ID of the virtual machine',
        'ipaddress'         => 'the ip address of the virtual machine',
        'isodisplaytext'    => 'an alternate display text of the ISO attached to the virtual machine',
        'isoid'             => 'the ID of the ISO attached to the virtual machine',
        'isoname'           => 'the name of the ISO attached to the virtual machine',
        'jobid' =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine',
        'jobstatus'           => 'shows the current pending asynchronous job status',
        'memory'              => 'the memory allocated for the virtual machine',
        'name'                => 'the name of the virtual machine',
        'networkkbsread'      => 'the incoming network traffic on the vm',
        'networkkbswrite'     => 'the outgoing network traffic on the host',
        'nic(*)'              => 'the list of nics associated with vm',
        'password'            => 'the password (if exists) of the virtual machine',
        'passwordenabled'     => 'true if the password rest feature is enabled, false otherwise',
        'rootdeviceid'        => 'device ID of the root volume',
        'rootdevicetype'      => 'device type of the root volume',
        'securitygroup(*)'    => 'list of security groups associated with the virtual machine',
        'serviceofferingid'   => 'the ID of the service offering of the virtual machine',
        'serviceofferingname' => 'the name of the service offering of the virtual machine',
        'state'               => 'the state of the virtual machine',
        'templatedisplaytext' => 'an alternate display text of the template for the virtual machine',
        'templateid' =>
            'the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.',
        'templatename' => 'the name of the template for the virtual machine',
        'zoneid'       => 'the ID of the availablility zone for the virtual machine',
        'zonename'     => 'the name of the availability zone for the virtual machine',
      },
      section => 'VM',
    },
    destroyLunOnFiler => {
      description => 'Destroy a LUN',
      isAsync     => 'false',
      level       => 15,
      request     => { required => { path => 'LUN path.' } },
      response    => undef,
      section     => 'NetAppIntegration',
    },
    destroyRouter => {
      description => 'Destroys a router.',
      isAsync     => 'true',
      level       => 7,
      request     => { required => { id => 'the ID of the router' } },
      response    => {
        account             => 'the account associated with the router',
        created             => 'the date and time the router was created',
        dns1                => 'the first DNS for the router',
        dns2                => 'the second DNS for the router',
        domain              => 'the domain associated with the router',
        domainid            => 'the domain ID associated with the router',
        gateway             => 'the gateway for the router',
        guestipaddress      => 'the guest IP address for the router',
        guestmacaddress     => 'the guest MAC address for the router',
        guestnetmask        => 'the guest netmask for the router',
        guestnetworkid      => 'the ID of the corresponding guest network',
        hostid              => 'the host ID for the router',
        hostname            => 'the hostname for the router',
        id                  => 'the id of the router',
        isredundantrouter   => 'if this router is an redundant virtual router',
        linklocalip         => 'the link local IP address for the router',
        linklocalmacaddress => 'the link local MAC address for the router',
        linklocalnetmask    => 'the link local netmask for the router',
        linklocalnetworkid  => 'the ID of the corresponding link local network',
        name                => 'the name of the router',
        networkdomain       => 'the network domain for the router',
        podid               => 'the Pod ID for the router',
        publicip            => 'the public IP address for the router',
        publicmacaddress    => 'the public MAC address for the router',
        publicnetmask       => 'the public netmask for the router',
        publicnetworkid     => 'the ID of the corresponding public network',
        redundantstate      => 'the state of redundant virtual router',
        serviceofferingid   => 'the ID of the service offering of the virtual machine',
        serviceofferingname => 'the name of the service offering of the virtual machine',
        state               => 'the state of the router',
        templateid          => 'the template ID for the router',
        zoneid              => 'the Zone ID for the router',
        zonename            => 'the Zone name for the router',
      },
      section => 'Router',
    },
    destroySystemVm => {
      description => 'Destroyes a system virtual machine.',
      isAsync     => 'true',
      level       => 1,
      request     => { required => { id => 'The ID of the system virtual machine' } },
      response    => {
        activeviewersessions => 'the number of active console sessions for the console proxy system vm',
        created              => 'the date and time the system VM was created',
        dns1                 => 'the first DNS for the system VM',
        dns2                 => 'the second DNS for the system VM',
        gateway              => 'the gateway for the system VM',
        hostid               => 'the host ID for the system VM',
        hostname             => 'the hostname for the system VM',
        id                   => 'the ID of the system VM',
        jobid =>
            'the job ID associated with the system VM. This is only displayed if the router listed is part of a currently running asynchronous job.',
        jobstatus =>
            'the job status associated with the system VM.  This is only displayed if the router listed is part of a currently running asynchronous job.',
        linklocalip         => 'the link local IP address for the system vm',
        linklocalmacaddress => 'the link local MAC address for the system vm',
        linklocalnetmask    => 'the link local netmask for the system vm',
        name                => 'the name of the system VM',
        networkdomain       => 'the network domain for the system VM',
        podid               => 'the Pod ID for the system VM',
        privateip           => 'the private IP address for the system VM',
        privatemacaddress   => 'the private MAC address for the system VM',
        privatenetmask      => 'the private netmask for the system VM',
        publicip            => 'the public IP address for the system VM',
        publicmacaddress    => 'the public MAC address for the system VM',
        publicnetmask       => 'the public netmask for the system VM',
        state               => 'the state of the system VM',
        systemvmtype        => 'the system VM type',
        templateid          => 'the template ID for the system VM',
        zoneid              => 'the Zone ID for the system VM',
        zonename            => 'the Zone name for the system VM',
      },
      section => 'SystemVM',
    },
    destroyVirtualMachine => {
      description => 'Destroys a virtual machine. Once destroyed, only the administrator can recover it.',
      isAsync     => 'true',
      level       => 15,
      request     => { required => { id => 'The ID of the virtual machine' } },
      response    => {
        'account'     => 'the account associated with the virtual machine',
        'cpunumber'   => 'the number of cpu this virtual machine is running with',
        'cpuspeed'    => 'the speed of each cpu',
        'cpuused'     => 'the amount of the vm\'s CPU currently used',
        'created'     => 'the date when this virtual machine was created',
        'displayname' => 'user generated name. The name of the virtual machine is returned if no displayname exists.',
        'domain'      => 'the name of the domain in which the virtual machine exists',
        'domainid'    => 'the ID of the domain in which the virtual machine exists',
        'forvirtualnetwork' => 'the virtual network for the service offering',
        'group'             => 'the group name of the virtual machine',
        'groupid'           => 'the group ID of the virtual machine',
        'guestosid'         => 'Os type ID of the virtual machine',
        'haenable'          => 'true if high-availability is enabled, false otherwise',
        'hostid'            => 'the ID of the host for the virtual machine',
        'hostname'          => 'the name of the host for the virtual machine',
        'hypervisor'        => 'the hypervisor on which the template runs',
        'id'                => 'the ID of the virtual machine',
        'ipaddress'         => 'the ip address of the virtual machine',
        'isodisplaytext'    => 'an alternate display text of the ISO attached to the virtual machine',
        'isoid'             => 'the ID of the ISO attached to the virtual machine',
        'isoname'           => 'the name of the ISO attached to the virtual machine',
        'jobid' =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine',
        'jobstatus'           => 'shows the current pending asynchronous job status',
        'memory'              => 'the memory allocated for the virtual machine',
        'name'                => 'the name of the virtual machine',
        'networkkbsread'      => 'the incoming network traffic on the vm',
        'networkkbswrite'     => 'the outgoing network traffic on the host',
        'nic(*)'              => 'the list of nics associated with vm',
        'password'            => 'the password (if exists) of the virtual machine',
        'passwordenabled'     => 'true if the password rest feature is enabled, false otherwise',
        'rootdeviceid'        => 'device ID of the root volume',
        'rootdevicetype'      => 'device type of the root volume',
        'securitygroup(*)'    => 'list of security groups associated with the virtual machine',
        'serviceofferingid'   => 'the ID of the service offering of the virtual machine',
        'serviceofferingname' => 'the name of the service offering of the virtual machine',
        'state'               => 'the state of the virtual machine',
        'templatedisplaytext' => 'an alternate display text of the template for the virtual machine',
        'templateid' =>
            'the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.',
        'templatename' => 'the name of the template for the virtual machine',
        'zoneid'       => 'the ID of the availablility zone for the virtual machine',
        'zonename'     => 'the name of the availability zone for the virtual machine',
      },
      section => 'VM',
    },
    destroyVolumeOnFiler => {
      description => 'Destroy a Volume',
      isAsync     => 'false',
      level       => 15,
      request     => {
        required => { aggregatename => 'aggregate name.', ipaddress => 'ip address.', volumename => 'volume name.', },
      },
      response => undef,
      section  => 'NetAppIntegration',
    },
    detachIso => {
      description => 'Detaches any ISO file (if any) currently attached to a virtual machine.',
      isAsync     => 'true',
      level       => 15,
      request     => { required => { virtualmachineid => 'The ID of the virtual machine' }, },
      response    => {
        'account'     => 'the account associated with the virtual machine',
        'cpunumber'   => 'the number of cpu this virtual machine is running with',
        'cpuspeed'    => 'the speed of each cpu',
        'cpuused'     => 'the amount of the vm\'s CPU currently used',
        'created'     => 'the date when this virtual machine was created',
        'displayname' => 'user generated name. The name of the virtual machine is returned if no displayname exists.',
        'domain'      => 'the name of the domain in which the virtual machine exists',
        'domainid'    => 'the ID of the domain in which the virtual machine exists',
        'forvirtualnetwork' => 'the virtual network for the service offering',
        'group'             => 'the group name of the virtual machine',
        'groupid'           => 'the group ID of the virtual machine',
        'guestosid'         => 'Os type ID of the virtual machine',
        'haenable'          => 'true if high-availability is enabled, false otherwise',
        'hostid'            => 'the ID of the host for the virtual machine',
        'hostname'          => 'the name of the host for the virtual machine',
        'hypervisor'        => 'the hypervisor on which the template runs',
        'id'                => 'the ID of the virtual machine',
        'ipaddress'         => 'the ip address of the virtual machine',
        'isodisplaytext'    => 'an alternate display text of the ISO attached to the virtual machine',
        'isoid'             => 'the ID of the ISO attached to the virtual machine',
        'isoname'           => 'the name of the ISO attached to the virtual machine',
        'jobid' =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine',
        'jobstatus'           => 'shows the current pending asynchronous job status',
        'memory'              => 'the memory allocated for the virtual machine',
        'name'                => 'the name of the virtual machine',
        'networkkbsread'      => 'the incoming network traffic on the vm',
        'networkkbswrite'     => 'the outgoing network traffic on the host',
        'nic(*)'              => 'the list of nics associated with vm',
        'password'            => 'the password (if exists) of the virtual machine',
        'passwordenabled'     => 'true if the password rest feature is enabled, false otherwise',
        'rootdeviceid'        => 'device ID of the root volume',
        'rootdevicetype'      => 'device type of the root volume',
        'securitygroup(*)'    => 'list of security groups associated with the virtual machine',
        'serviceofferingid'   => 'the ID of the service offering of the virtual machine',
        'serviceofferingname' => 'the name of the service offering of the virtual machine',
        'state'               => 'the state of the virtual machine',
        'templatedisplaytext' => 'an alternate display text of the template for the virtual machine',
        'templateid' =>
            'the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.',
        'templatename' => 'the name of the template for the virtual machine',
        'zoneid'       => 'the ID of the availablility zone for the virtual machine',
        'zonename'     => 'the name of the availability zone for the virtual machine',
      },
      section => 'ISO',
    },
    detachVolume => {
      description => 'Detaches a disk volume from a virtual machine.',
      isAsync     => 'true',
      level       => 15,
      request     => {
        optional => {
          deviceid         => 'the device ID on the virtual machine where volume is detached from',
          id               => 'the ID of the disk volume',
          virtualmachineid => 'the ID of the virtual machine where the volume is detached from',
        },
      },
      response => {
        account   => 'the account associated with the disk volume',
        attached  => 'the date the volume was attached to a VM instance',
        created   => 'the date the disk volume was created',
        destroyed => 'the boolean state of whether the volume is destroyed or not',
        deviceid =>
            'the ID of the device on user vm the volume is attahed to. This tag is not returned when the volume is detached.',
        diskofferingdisplaytext => 'the display text of the disk offering',
        diskofferingid          => 'ID of the disk offering',
        diskofferingname        => 'name of the disk offering',
        domain                  => 'the domain associated with the disk volume',
        domainid                => 'the ID of the domain associated with the disk volume',
        hypervisor              => 'Hypervisor the volume belongs to',
        id                      => 'ID of the disk volume',
        isextractable           => 'true if the volume is extractable, false otherwise',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume',
        jobstatus                  => 'shows the current pending asynchronous job status',
        name                       => 'name of the disk volume',
        serviceofferingdisplaytext => 'the display text of the service offering for root disk',
        serviceofferingid          => 'ID of the service offering for root disk',
        serviceofferingname        => 'name of the service offering for root disk',
        size                       => 'size of the disk volume',
        snapshotid                 => 'ID of the snapshot from which this volume was created',
        state                      => 'the state of the disk volume',
        storage                    => 'name of the primary storage hosting the disk volume',
        storagetype                => 'shared or local storage',
        type                       => 'type of the disk volume (ROOT or DATADISK)',
        virtualmachineid           => 'id of the virtual machine',
        vmdisplayname              => 'display name of the virtual machine',
        vmname                     => 'name of the virtual machine',
        vmstate                    => 'state of the virtual machine',
        zoneid                     => 'ID of the availability zone',
        zonename                   => 'name of the availability zone',
      },
      section => 'Volume',
    },
    disableAccount => {
      description => 'Disables an account',
      isAsync     => 'true',
      level       => 7,
      request     => {
        required => {
          account  => 'Disables specified account.',
          domainid => 'Disables specified account in this domain.',
          lock     => 'If true, only lock the account; else disable the account',
        },
      },
      response => {
        'accounttype'       => 'account type (admin, domain-admin, user)',
        'domain'            => 'name of the Domain the account belongs too',
        'domainid'          => 'id of the Domain the account belongs too',
        'id'                => 'the id of the account',
        'ipavailable'       => 'the total number of public ip addresses available for this account to acquire',
        'iplimit'           => 'the total number of public ip addresses this account can acquire',
        'iptotal'           => 'the total number of public ip addresses allocated for this account',
        'iscleanuprequired' => 'true if the account requires cleanup',
        'name'              => 'the name of the account',
        'networkdomain'     => 'the network domain',
        'receivedbytes'     => 'the total number of network traffic bytes received',
        'sentbytes'         => 'the total number of network traffic bytes sent',
        'snapshotavailable' => 'the total number of snapshots available for this account',
        'snapshotlimit'     => 'the total number of snapshots which can be stored by this account',
        'snapshottotal'     => 'the total number of snapshots stored by this account',
        'state'             => 'the state of the account',
        'templateavailable' => 'the total number of templates available to be created by this account',
        'templatelimit'     => 'the total number of templates which can be created by this account',
        'templatetotal'     => 'the total number of templates which have been created by this account',
        'user(*)'           => 'the list of users associated with account',
        'vmavailable'       => 'the total number of virtual machines available for this account to acquire',
        'vmlimit'           => 'the total number of virtual machines that can be deployed by this account',
        'vmrunning'         => 'the total number of virtual machines running for this account',
        'vmstopped'         => 'the total number of virtual machines stopped for this account',
        'vmtotal'           => 'the total number of virtual machines deployed by this account',
        'volumeavailable'   => 'the total volume available for this account',
        'volumelimit'       => 'the total volume which can be used by this account',
        'volumetotal'       => 'the total volume being used by this account',
      },
      section => 'Account',
    },
    disableStaticNat => {
      description => 'Disables static rule for given ip address',
      isAsync     => 'true',
      level       => 15,
      request     => {
        required => { ipaddressid => 'the public IP address id for which static nat feature is being disableed', },
      },
      response => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'NAT',
    },
    disableUser => {
      description => 'Disables a user account',
      isAsync     => 'true',
      level       => 7,
      request     => { required => { id => 'Disables user by user ID.' } },
      response    => {
        account     => 'the account name of the user',
        accounttype => 'the account type of the user',
        apikey      => 'the api key of the user',
        created     => 'the date and time the user account was created',
        domain      => 'the domain name of the user',
        domainid    => 'the domain ID of the user',
        email       => 'the user email address',
        firstname   => 'the user firstname',
        id          => 'the user ID',
        lastname    => 'the user lastname',
        secretkey   => 'the secret key of the user',
        state       => 'the user state',
        timezone    => 'the timezone user was created in',
        username    => 'the user name',
      },
      section => 'User',
    },
    disassociateIpAddress => {
      description => 'Disassociates an ip address from the account.',
      isAsync     => 'true',
      level       => 15,
      request     => { required => { id => 'the id of the public ip address to disassociate' }, },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'Address',
    },
    dissociateLun => {
      description => 'Dissociate a LUN',
      isAsync     => 'false',
      level       => 15,
      request     => { required => { iqn => 'Guest IQN.', path => 'LUN path.' } },
      response    => undef,
      section     => 'NetAppIntegration',
    },
    enableAccount => {
      description => 'Enables an account',
      isAsync     => 'false',
      level       => 7,
      request     => {
        required =>
            { account => 'Enables specified account.', domainid => 'Enables specified account in this domain.', },
      },
      response => {
        'accounttype'       => 'account type (admin, domain-admin, user)',
        'domain'            => 'name of the Domain the account belongs too',
        'domainid'          => 'id of the Domain the account belongs too',
        'id'                => 'the id of the account',
        'ipavailable'       => 'the total number of public ip addresses available for this account to acquire',
        'iplimit'           => 'the total number of public ip addresses this account can acquire',
        'iptotal'           => 'the total number of public ip addresses allocated for this account',
        'iscleanuprequired' => 'true if the account requires cleanup',
        'name'              => 'the name of the account',
        'networkdomain'     => 'the network domain',
        'receivedbytes'     => 'the total number of network traffic bytes received',
        'sentbytes'         => 'the total number of network traffic bytes sent',
        'snapshotavailable' => 'the total number of snapshots available for this account',
        'snapshotlimit'     => 'the total number of snapshots which can be stored by this account',
        'snapshottotal'     => 'the total number of snapshots stored by this account',
        'state'             => 'the state of the account',
        'templateavailable' => 'the total number of templates available to be created by this account',
        'templatelimit'     => 'the total number of templates which can be created by this account',
        'templatetotal'     => 'the total number of templates which have been created by this account',
        'user(*)'           => 'the list of users associated with account',
        'vmavailable'       => 'the total number of virtual machines available for this account to acquire',
        'vmlimit'           => 'the total number of virtual machines that can be deployed by this account',
        'vmrunning'         => 'the total number of virtual machines running for this account',
        'vmstopped'         => 'the total number of virtual machines stopped for this account',
        'vmtotal'           => 'the total number of virtual machines deployed by this account',
        'volumeavailable'   => 'the total volume available for this account',
        'volumelimit'       => 'the total volume which can be used by this account',
        'volumetotal'       => 'the total volume being used by this account',
      },
      section => 'Account',
    },
    enableStaticNat => {
      description => 'Enables static nat for given ip address',
      isAsync     => 'false',
      level       => 15,
      request     => {
        required => {
          ipaddressid      => 'the public IP address id for which static nat feature is being enabled',
          virtualmachineid => 'the ID of the virtual machine for enabling static nat feature',
        },
      },
      response => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'NAT',
    },
    enableStorageMaintenance => {
      description => 'Puts storage pool into maintenance state',
      isAsync     => 'true',
      level       => 1,
      request     => { required => { id => 'Primary storage ID' } },
      response    => {
        clusterid         => 'the ID of the cluster for the storage pool',
        clustername       => 'the name of the cluster for the storage pool',
        created           => 'the date and time the storage pool was created',
        disksizeallocated => 'the host\'s currently allocated disk size',
        disksizetotal     => 'the total disk size of the storage pool',
        id                => 'the ID of the storage pool',
        ipaddress         => 'the IP address of the storage pool',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the storage pool',
        jobstatus => 'shows the current pending asynchronous job status',
        name      => 'the name of the storage pool',
        path      => 'the storage pool path',
        podid     => 'the Pod ID of the storage pool',
        podname   => 'the Pod name of the storage pool',
        state     => 'the state of the storage pool',
        tags      => 'the tags for the storage pool',
        type      => 'the storage pool type',
        zoneid    => 'the Zone ID of the storage pool',
        zonename  => 'the Zone name of the storage pool',
      },
      section => 'StoragePools',
    },
    enableUser => {
      description => 'Enables a user account',
      isAsync     => 'false',
      level       => 7,
      request     => { required => { id => 'Enables user by user ID.' } },
      response    => {
        account     => 'the account name of the user',
        accounttype => 'the account type of the user',
        apikey      => 'the api key of the user',
        created     => 'the date and time the user account was created',
        domain      => 'the domain name of the user',
        domainid    => 'the domain ID of the user',
        email       => 'the user email address',
        firstname   => 'the user firstname',
        id          => 'the user ID',
        lastname    => 'the user lastname',
        secretkey   => 'the secret key of the user',
        state       => 'the user state',
        timezone    => 'the timezone user was created in',
        username    => 'the user name',
      },
      section => 'User',
    },
    extractIso => {
      description => 'Extracts an ISO',
      isAsync     => 'true',
      level       => 15,
      request     => {
        optional => { url => 'the url to which the ISO would be extracted' },
        required => {
          id     => 'the ID of the ISO file',
          mode   => 'the mode of extraction - HTTP_DOWNLOAD or FTP_UPLOAD',
          zoneid => 'the ID of the zone where the ISO is originally located',
        },
      },
      response => {
        accountid        => 'the account id to which the extracted object belongs',
        created          => 'the time and date the object was created',
        extractId        => 'the upload id of extracted object',
        extractMode      => 'the mode of extraction - upload or download',
        id               => 'the id of extracted object',
        name             => 'the name of the extracted object',
        state            => 'the state of the extracted object',
        status           => 'the status of the extraction',
        storagetype      => 'type of the storage',
        uploadpercentage => 'the percentage of the entity uploaded to the specified location',
        url =>
            'if mode = upload then url of the uploaded entity. if mode = download the url from which the entity can be downloaded',
        zoneid   => 'zone ID the object was extracted from',
        zonename => 'zone name the object was extracted from',
      },
      section => 'ISO',
    },
    extractTemplate => {
      description => 'Extracts a template',
      isAsync     => 'true',
      level       => 15,
      request     => {
        optional => { url => 'the url to which the ISO would be extracted' },
        required => {
          id     => 'the ID of the template',
          mode   => 'the mode of extraction - HTTP_DOWNLOAD or FTP_UPLOAD',
          zoneid => 'the ID of the zone where the ISO is originally located',
        },
      },
      response => {
        accountid        => 'the account id to which the extracted object belongs',
        created          => 'the time and date the object was created',
        extractId        => 'the upload id of extracted object',
        extractMode      => 'the mode of extraction - upload or download',
        id               => 'the id of extracted object',
        name             => 'the name of the extracted object',
        state            => 'the state of the extracted object',
        status           => 'the status of the extraction',
        storagetype      => 'type of the storage',
        uploadpercentage => 'the percentage of the entity uploaded to the specified location',
        url =>
            'if mode = upload then url of the uploaded entity. if mode = download the url from which the entity can be downloaded',
        zoneid   => 'zone ID the object was extracted from',
        zonename => 'zone name the object was extracted from',
      },
      section => 'Template',
    },
    extractVolume => {
      description => 'Extracts volume',
      isAsync     => 'true',
      level       => 15,
      request     => {
        optional => { url => 'the url to which the volume would be extracted' },
        required => {
          id     => 'the ID of the volume',
          mode   => 'the mode of extraction - HTTP_DOWNLOAD or FTP_UPLOAD',
          zoneid => 'the ID of the zone where the volume is located',
        },
      },
      response => {
        accountid        => 'the account id to which the extracted object belongs',
        created          => 'the time and date the object was created',
        extractId        => 'the upload id of extracted object',
        extractMode      => 'the mode of extraction - upload or download',
        id               => 'the id of extracted object',
        name             => 'the name of the extracted object',
        state            => 'the state of the extracted object',
        status           => 'the status of the extraction',
        storagetype      => 'type of the storage',
        uploadpercentage => 'the percentage of the entity uploaded to the specified location',
        url =>
            'if mode = upload then url of the uploaded entity. if mode = download the url from which the entity can be downloaded',
        zoneid   => 'zone ID the object was extracted from',
        zonename => 'zone name the object was extracted from',
      },
      section => 'Volume',
    },
    generateUsageRecords => {
      description => 'Generates usage records',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => { domainid => 'List events for the specified domain.' },
        required => {
          enddate =>
              'End date range for usage record query. Use yyyy-MM-dd as the date format, e.g. startDate=2009-06-03.',
          startdate =>
              'Start date range for usage record query. Use yyyy-MM-dd as the date format, e.g. startDate=2009-06-01.',
        },
      },
      response => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'Usage',
    },
    getCloudIdentifier => {
      description => 'Retrieves a cloud identifier.',
      isAsync     => 'false',
      level       => 15,
      request     => { required => { userid => 'the user ID for the cloud identifier' }, },
      response    => {
        cloudidentifier => 'the cloud identifier',
        signature       => 'the signed response for the cloud identifier',
        userid          => 'the user ID for the cloud identifier',
      },
      section => 'CloudIdentifier',
    },
    getVMPassword => {
      description => 'Returns an encrypted password for the VM',
      isAsync     => 'false',
      level       => 15,
      request     => { required => { id => 'The ID of the virtual machine' } },
      response => { encryptedpassword => 'The encrypted password of the VM' },
      section  => 'VM',
    },
    listAccounts => {
      description => 'Lists accounts and provides detailed account information for listed accounts',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          accounttype =>
              'list accounts by account type. Valid account types are 1 (admin), 2 (domain-admin), and 0 (user).',
          domainid =>
              'list all accounts in specified domain. If used with the name parameter, retrieves account information for the account with specified name in specified domain.',
          id                => 'list account by account ID',
          iscleanuprequired => 'list accounts by cleanuprequred attribute (values are true or false)',
          isrecursive =>
              'defaults to false, but if true, lists all accounts from the parent specified by the domain id till leaves.',
          keyword  => 'List by keyword',
          name     => 'list account by account name',
          page     => 'no description',
          pagesize => 'no description',
          state    => 'list accounts by state. Valid states are enabled, disabled, and locked.',
        },
      },
      response => {
        'accounttype'       => 'account type (admin, domain-admin, user)',
        'domain'            => 'name of the Domain the account belongs too',
        'domainid'          => 'id of the Domain the account belongs too',
        'id'                => 'the id of the account',
        'ipavailable'       => 'the total number of public ip addresses available for this account to acquire',
        'iplimit'           => 'the total number of public ip addresses this account can acquire',
        'iptotal'           => 'the total number of public ip addresses allocated for this account',
        'iscleanuprequired' => 'true if the account requires cleanup',
        'name'              => 'the name of the account',
        'networkdomain'     => 'the network domain',
        'receivedbytes'     => 'the total number of network traffic bytes received',
        'sentbytes'         => 'the total number of network traffic bytes sent',
        'snapshotavailable' => 'the total number of snapshots available for this account',
        'snapshotlimit'     => 'the total number of snapshots which can be stored by this account',
        'snapshottotal'     => 'the total number of snapshots stored by this account',
        'state'             => 'the state of the account',
        'templateavailable' => 'the total number of templates available to be created by this account',
        'templatelimit'     => 'the total number of templates which can be created by this account',
        'templatetotal'     => 'the total number of templates which have been created by this account',
        'user(*)'           => 'the list of users associated with account',
        'vmavailable'       => 'the total number of virtual machines available for this account to acquire',
        'vmlimit'           => 'the total number of virtual machines that can be deployed by this account',
        'vmrunning'         => 'the total number of virtual machines running for this account',
        'vmstopped'         => 'the total number of virtual machines stopped for this account',
        'vmtotal'           => 'the total number of virtual machines deployed by this account',
        'volumeavailable'   => 'the total volume available for this account',
        'volumelimit'       => 'the total volume which can be used by this account',
        'volumetotal'       => 'the total volume being used by this account',
      },
      section => 'Account',
    },
    listAlerts => {
      description => 'Lists all alerts.',
      isAsync     => 'false',
      level       => 3,
      request     => {
        optional => {
          id       => 'the ID of the alert',
          keyword  => 'List by keyword',
          page     => 'no description',
          pagesize => 'no description',
          type     => 'list by alert type',
        },
      },
      response => {
        description => 'description of the alert',
        id          => 'the id of the alert',
        sent        => 'the date and time the alert was sent',
        type        => 'the alert type',
      },
      section => 'Alerts',
    },
    listAsyncJobs => {
      description => 'Lists all pending asynchronous jobs for the account.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account => 'the account associated with the async job. Must be used with the domainId parameter.',
          domainid =>
              'the domain ID associated with the async job.  If used with the account parameter, returns async jobs for the account in the specified domain.',
          keyword   => 'List by keyword',
          page      => 'no description',
          pagesize  => 'no description',
          startdate => 'the start date of the async job',
        },
      },
      response => {
        accountid       => 'the account that executed the async command',
        cmd             => 'the async command executed',
        created         => 'the created date of the job',
        jobid           => 'async job ID',
        jobinstanceid   => 'the unique ID of the instance/entity object related to the job',
        jobinstancetype => 'the instance/entity object related to the job',
        jobprocstatus   => 'the progress information of the PENDING job',
        jobresult       => 'the result reason',
        jobresultcode   => 'the result code for the job',
        jobresulttype   => 'the result type',
        jobstatus       => 'the current job status-should be 0 for PENDING',
        userid          => 'the user that executed the async command',
      },
      section => 'AsyncQuery',
    },
    listCapabilities => {
      description => 'Lists capabilities',
      isAsync     => 'false',
      level       => 15,
      request     => undef,
      response    => {
        cloudstackversion         => 'version of the cloud stack',
        firewallRuleUiEnabled     => 'true if the firewall rule UI is enabled',
        securitygroupsenabled     => 'true if security groups support is enabled, false otherwise',
        supportELB                => 'true if region supports elastic load balancer on basic zones',
        userpublictemplateenabled => 'true if user and domain admins can set templates to be shared, false otherwise',
      },
      section => 'Configuration',
    },
    listCapacity => {
      description => 'Lists capacity.',
      isAsync     => 'false',
      level       => 3,
      request     => {
        optional => {
          hostid   => 'lists capacity by the Host ID',
          keyword  => 'List by keyword',
          page     => 'no description',
          pagesize => 'no description',
          podid    => 'lists capacity by the Pod ID',
          type =>
              'lists capacity by type* CAPACITY_TYPE_MEMORY = 0* CAPACITY_TYPE_CPU = 1* CAPACITY_TYPE_STORAGE = 2* CAPACITY_TYPE_STORAGE_ALLOCATED = 3* CAPACITY_TYPE_PUBLIC_IP = 4* CAPACITY_TYPE_PRIVATE_IP = 5* CAPACITY_TYPE_SECONDARY_STORAGE = 6',
          zoneid => 'lists capacity by the Zone ID',
        },
      },
      response => {
        capacitytotal => 'the total capacity available',
        capacityused  => 'the capacity currently in use',
        percentused   => 'the percentage of capacity currently in use',
        podid         => 'the Pod ID',
        podname       => 'the Pod name',
        type          => 'the capacity type',
        zoneid        => 'the Zone ID',
        zonename      => 'the Zone name',
      },
      section => 'SystemCapacity',
    },
    listClusters => {
      description => 'Lists clusters.',
      isAsync     => 'false',
      level       => 3,
      request     => {
        optional => {
          allocationstate => 'lists clusters by allocation state',
          clustertype     => 'lists clusters by cluster type',
          hypervisor      => 'lists clusters by hypervisor type',
          id              => 'lists clusters by the cluster ID',
          keyword         => 'List by keyword',
          managedstate    => 'whether this cluster is managed by cloudstack',
          name            => 'lists clusters by the cluster name',
          page            => 'no description',
          pagesize        => 'no description',
          podid           => 'lists clusters by Pod ID',
          zoneid          => 'lists clusters by Zone ID',
        },
      },
      response => {
        allocationstate => 'the allocation state of the cluster',
        clustertype     => 'the type of the cluster',
        hypervisortype  => 'the hypervisor type of the cluster',
        id              => 'the cluster ID',
        managedstate    => 'whether this cluster is managed by cloudstack',
        name            => 'the cluster name',
        podid           => 'the Pod ID of the cluster',
        podname         => 'the Pod name of the cluster',
        zoneid          => 'the Zone ID of the cluster',
        zonename        => 'the Zone name of the cluster',
      },
      section => 'StoragePools',
    },
    listConfigurations => {
      description => 'Lists all configurations.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          category => 'lists configurations by category',
          keyword  => 'List by keyword',
          name     => 'lists configuration by name',
          page     => 'no description',
          pagesize => 'no description',
        },
      },
      response => {
        category    => 'the category of the configuration',
        description => 'the description of the configuration',
        name        => 'the name of the configuration',
        value       => 'the value of the configuration',
      },
      section => 'Configuration',
    },
    listDiskOfferings => {
      description => 'Lists all available disk offerings.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          domainid => 'the ID of the domain of the disk offering.',
          id       => 'ID of the disk offering',
          keyword  => 'List by keyword',
          name     => 'name of the disk offering',
          page     => 'no description',
          pagesize => 'no description',
        },
      },
      response => {
        created     => 'the date this disk offering was created',
        disksize    => 'the size of the disk offering in GB',
        displaytext => 'an alternate display text of the disk offering.',
        domain =>
            'the domain name this disk offering belongs to. Ignore this information as it is not currently applicable.',
        domainid =>
            'the domain ID this disk offering belongs to. Ignore this information as it is not currently applicable.',
        id           => 'unique ID of the disk offering',
        iscustomized => 'true if disk offering uses custom size, false otherwise',
        name         => 'the name of the disk offering',
        tags         => 'the tags for the disk offering',
      },
      section => 'DiskOffering',
    },
    listDomainChildren => {
      description => 'Lists all children domains belonging to a specified domain',
      isAsync     => 'false',
      level       => 7,
      request     => {
        optional => {
          id => 'list children domain by parent domain ID.',
          isrecursive =>
              'to return the entire tree, use the value \'true\'. To return the first level children, use the value \'false\'.',
          keyword  => 'List by keyword',
          name     => 'list children domains by name',
          page     => 'no description',
          pagesize => 'no description',
        },
      },
      response => {
        haschild         => 'whether the domain has one or more sub-domains',
        id               => 'the ID of the domain',
        level            => 'the level of the domain',
        name             => 'the name of the domain',
        networkdomain    => 'the network domain',
        parentdomainid   => 'the domain ID of the parent domain',
        parentdomainname => 'the domain name of the parent domain',
        path             => 'the path of the domain',
      },
      section => 'Domain',
    },
    listDomains => {
      description => 'Lists domains and provides detailed information for listed domains',
      isAsync     => 'false',
      level       => 7,
      request     => {
        optional => {
          id       => 'List domain by domain ID.',
          keyword  => 'List by keyword',
          level    => 'List domains by domain level.',
          name     => 'List domain by domain name.',
          page     => 'no description',
          pagesize => 'no description',
        },
      },
      response => {
        haschild         => 'whether the domain has one or more sub-domains',
        id               => 'the ID of the domain',
        level            => 'the level of the domain',
        name             => 'the name of the domain',
        networkdomain    => 'the network domain',
        parentdomainid   => 'the domain ID of the parent domain',
        parentdomainname => 'the domain name of the parent domain',
        path             => 'the path of the domain',
      },
      section => 'Domain',
    },
    listEvents => {
      description => 'A command to list events.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account => 'the account for the event. Must be used with the domainId parameter.',
          domainid =>
              'the domain ID for the event. If used with the account parameter, returns all events for an account in the specified domain ID.',
          duration => 'the duration of the event',
          enddate =>
              'the end date range of the list you want to retrieve (use format \'yyyy-MM-dd\' or the new format \'yyyy-MM-dd HH:mm:ss\')',
          entrytime => 'the time the event was entered',
          id        => 'the ID of the event',
          keyword   => 'List by keyword',
          level     => 'the event level (INFO, WARN, ERROR)',
          page      => 'no description',
          pagesize  => 'no description',
          startdate =>
              'the start date range of the list you want to retrieve (use format \'yyyy-MM-dd\' or the new format \'yyyy-MM-dd HH:mm:ss\')',
          type => 'the event type (see event types)',
        },
      },
      response => {
        account =>
            'the account name for the account that owns the object being acted on in the event (e.g. the owner of the virtual machine, ip address, or security group)',
        created     => 'the date the event was created',
        description => 'a brief description of the event',
        domain      => 'the name of the account\'s domain',
        domainid    => 'the id of the account\'s domain',
        id          => 'the ID of the event',
        level       => 'the event level (INFO, WARN, ERROR)',
        parentid    => 'whether the event is parented',
        state       => 'the state of the event',
        type        => 'the type of the event (see event types)',
        username =>
            'the name of the user who performed the action (can be different from the account if an admin is performing an action for a user, e.g. starting/stopping a user\'s virtual machine)',
      },
      section => 'Events',
    },
    listEventTypes => {
      description => 'List Event Types',
      isAsync     => 'false',
      level       => 15,
      request     => undef,
      response    => { name => 'Event Type' },
      section     => 'Events',
    },
    listExternalFirewalls => {
      description => 'List external firewall appliances.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => { keyword => 'List by keyword', page => 'no description', pagesize => 'no description', },
        required => { zoneid  => 'zone Id' },
      },
      response => {
        id               => 'the ID of the external firewall',
        ipaddress        => 'the management IP address of the external firewall',
        numretries       => 'the number of times to retry requests to the external firewall',
        privateinterface => 'the private interface of the external firewall',
        privatezone      => 'the private security zone of the external firewall',
        publicinterface  => 'the public interface of the external firewall',
        publiczone       => 'the public security zone of the external firewall',
        timeout          => 'the timeout (in seconds) for requests to the external firewall',
        usageinterface   => 'the usage interface of the external firewall',
        username         => 'the username that\'s used to log in to the external firewall',
        zoneid           => 'the zone ID of the external firewall',
      },
      section => 'ExternalFirewall',
    },
    listExternalLoadBalancers => {
      description => 'List external load balancer appliances.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          keyword  => 'List by keyword',
          page     => 'no description',
          pagesize => 'no description',
          zoneid   => 'zone Id',
        },
      },
      response => {
        allocationstate         => 'the allocation state of the host',
        averageload             => 'the cpu average load on the host',
        capabilities            => 'capabilities of the host',
        clusterid               => 'the cluster ID of the host',
        clustername             => 'the cluster name of the host',
        clustertype             => 'the cluster type of the cluster that host belongs to',
        cpuallocated            => 'the amount of the host\'s CPU currently allocated',
        cpunumber               => 'the CPU number of the host',
        cpuspeed                => 'the CPU speed of the host',
        cpuused                 => 'the amount of the host\'s CPU currently used',
        cpuwithoverprovisioning => 'the amount of the host\'s CPU after applying the cpu.overprovisioning.factor',
        created                 => 'the date and time the host was created',
        disconnected            => 'true if the host is disconnected. False otherwise.',
        disksizeallocated       => 'the host\'s currently allocated disk size',
        disksizetotal           => 'the total disk size of the host',
        events                  => 'events available for the host',
        hasEnoughCapacity => 'true if this host has enough CPU and RAM capacity to migrate a VM to it, false otherwise',
        hosttags          => 'comma-separated list of tags for the host',
        hypervisor        => 'the host hypervisor',
        id                => 'the ID of the host',
        ipaddress         => 'the IP address of the host',
        islocalstorageactive => 'true if local storage is active, false otherwise',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the host',
        jobstatus          => 'shows the current pending asynchronous job status',
        lastpinged         => 'the date and time the host was last pinged',
        managementserverid => 'the management server ID of the host',
        memoryallocated    => 'the amount of the host\'s memory currently allocated',
        memorytotal        => 'the memory total of the host',
        memoryused         => 'the amount of the host\'s memory currently used',
        name               => 'the name of the host',
        networkkbsread     => 'the incoming network traffic on the host',
        networkkbswrite    => 'the outgoing network traffic on the host',
        oscategoryid       => 'the OS category ID of the host',
        oscategoryname     => 'the OS category name of the host',
        podid              => 'the Pod ID of the host',
        podname            => 'the Pod name of the host',
        removed            => 'the date and time the host was removed',
        state              => 'the state of the host',
        type               => 'the host type',
        version            => 'the host version',
        zoneid             => 'the Zone ID of the host',
        zonename           => 'the Zone name of the host',
      },
      section => 'ExternalLoadBalancer',
    },
    listFirewallRules => {
      description => 'Lists all firewall rules for an IP address.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account => 'account. Must be used with the domainId parameter.',
          domainid =>
              'the domain ID. If used with the account parameter, lists firewall rules for the specified account in this domain.',
          id          => 'Lists rule with the specified ID.',
          ipaddressid => 'the id of IP address of the firwall services',
          keyword     => 'List by keyword',
          page        => 'no description',
          pagesize    => 'no description',
        },
      },
      response => {
        cidrlist    => 'the cidr list to forward traffic from',
        endport     => 'the ending port of firewall rule\'s port range',
        icmpcode    => 'error code for this icmp message',
        icmptype    => 'type of the icmp message being sent',
        id          => 'the ID of the firewall rule',
        ipaddress   => 'the public ip address for the port forwarding rule',
        ipaddressid => 'the public ip address id for the port forwarding rule',
        protocol    => 'the protocol of the firewall rule',
        startport   => 'the starting port of firewall rule\'s port range',
        state       => 'the state of the rule',
      },
      section => 'Firewall',
    },
    listHosts => {
      description => 'Lists hosts.',
      isAsync     => 'false',
      level       => 3,
      request     => {
        optional => {
          allocationstate => 'list hosts by allocation state',
          clusterid       => 'lists hosts existing in particular cluster',
          details =>
              'give details.  1 = minimal; 2 = include static info; 3 = include events; 4 = include allocation and statistics',
          id       => 'the id of the host',
          keyword  => 'List by keyword',
          name     => 'the name of the host',
          page     => 'no description',
          pagesize => 'no description',
          podid    => 'the Pod ID for the host',
          state    => 'the state of the host',
          type     => 'the host type',
          virtualmachineid =>
              'lists hosts in the same cluster as this VM and flag hosts with enough CPU/RAm to host this VM',
          zoneid => 'the Zone ID for the host',
        },
      },
      response => {
        allocationstate         => 'the allocation state of the host',
        averageload             => 'the cpu average load on the host',
        capabilities            => 'capabilities of the host',
        clusterid               => 'the cluster ID of the host',
        clustername             => 'the cluster name of the host',
        clustertype             => 'the cluster type of the cluster that host belongs to',
        cpuallocated            => 'the amount of the host\'s CPU currently allocated',
        cpunumber               => 'the CPU number of the host',
        cpuspeed                => 'the CPU speed of the host',
        cpuused                 => 'the amount of the host\'s CPU currently used',
        cpuwithoverprovisioning => 'the amount of the host\'s CPU after applying the cpu.overprovisioning.factor',
        created                 => 'the date and time the host was created',
        disconnected            => 'true if the host is disconnected. False otherwise.',
        disksizeallocated       => 'the host\'s currently allocated disk size',
        disksizetotal           => 'the total disk size of the host',
        events                  => 'events available for the host',
        hasEnoughCapacity => 'true if this host has enough CPU and RAM capacity to migrate a VM to it, false otherwise',
        hosttags          => 'comma-separated list of tags for the host',
        hypervisor        => 'the host hypervisor',
        id                => 'the ID of the host',
        ipaddress         => 'the IP address of the host',
        islocalstorageactive => 'true if local storage is active, false otherwise',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the host',
        jobstatus          => 'shows the current pending asynchronous job status',
        lastpinged         => 'the date and time the host was last pinged',
        managementserverid => 'the management server ID of the host',
        memoryallocated    => 'the amount of the host\'s memory currently allocated',
        memorytotal        => 'the memory total of the host',
        memoryused         => 'the amount of the host\'s memory currently used',
        name               => 'the name of the host',
        networkkbsread     => 'the incoming network traffic on the host',
        networkkbswrite    => 'the outgoing network traffic on the host',
        oscategoryid       => 'the OS category ID of the host',
        oscategoryname     => 'the OS category name of the host',
        podid              => 'the Pod ID of the host',
        podname            => 'the Pod name of the host',
        removed            => 'the date and time the host was removed',
        state              => 'the state of the host',
        type               => 'the host type',
        version            => 'the host version',
        zoneid             => 'the Zone ID of the host',
        zonename           => 'the Zone name of the host',
      },
      section => 'Host',
    },
    listHypervisors => {
      description => 'List hypervisors',
      isAsync     => 'false',
      level       => 15,
      request     => { optional => { zoneid => 'the zone id for listing hypervisors.' }, },
      response => { name => 'Hypervisor name' },
      section  => 'Other',
    },
    listInstanceGroups => {
      description => 'Lists vm groups',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account => 'list instance group belonging to the specified account. Must be used with domainid parameter',
          domainid =>
              'the domain ID. If used with the account parameter, lists virtual machines for the specified account in this domain.',
          id       => 'list instance groups by ID',
          keyword  => 'List by keyword',
          name     => 'list instance groups by name',
          page     => 'no description',
          pagesize => 'no description',
        },
      },
      response => {
        account  => 'the account owning the instance group',
        created  => 'time and date the instance group was created',
        domain   => 'the domain name of the instance group',
        domainid => 'the domain ID of the instance group',
        id       => 'the id of the instance group',
        name     => 'the name of the instance group',
      },
      section => 'VMGroup',
    },
    listIpForwardingRules => {
      description => 'List the ip forwarding rules',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account => 'the account associated with the ip forwarding rule. Must be used with the domainId parameter.',
          domainid =>
              'Lists all rules for this id. If used with the account parameter, returns all rules for an account in the specified domain ID.',
          id               => 'Lists rule with the specified ID.',
          ipaddressid      => 'list the rule belonging to this public ip address',
          keyword          => 'List by keyword',
          page             => 'no description',
          pagesize         => 'no description',
          virtualmachineid => 'Lists all rules applied to the specified Vm.',
        },
      },
      response => {
        cidrlist                  => 'the cidr list to forward traffic from',
        id                        => 'the ID of the port forwarding rule',
        ipaddress                 => 'the public ip address for the port forwarding rule',
        ipaddressid               => 'the public ip address id for the port forwarding rule',
        privateendport            => 'the ending port of port forwarding rule\'s private port range',
        privateport               => 'the starting port of port forwarding rule\'s private port range',
        protocol                  => 'the protocol of the port forwarding rule',
        publicendport             => 'the ending port of port forwarding rule\'s private port range',
        publicport                => 'the starting port of port forwarding rule\'s public port range',
        state                     => 'the state of the rule',
        virtualmachinedisplayname => 'the VM display name for the port forwarding rule',
        virtualmachineid          => 'the VM ID for the port forwarding rule',
        virtualmachinename        => 'the VM name for the port forwarding rule',
      },
      section => 'NAT',
    },
    listIsoPermissions => {
      description => 'List template visibility and all accounts that have permissions to view this template.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account =>
              'List template visibility and permissions for the specified account. Must be used with the domainId parameter.',
          domainid =>
              'List template visibility and permissions by domain. If used with the account parameter, specifies in which domain the specified account exists.',
        },
        required => { id => 'the template ID' },
      },
      response => {
        account  => 'the list of accounts the template is available for',
        domainid => 'the ID of the domain to which the template belongs',
        id       => 'the template ID',
        ispublic => 'true if this template is a public template, false otherwise',
      },
      section => 'ISO',
    },
    listIsos => {
      description => 'Lists all available ISO files.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account  => 'the account of the ISO file. Must be used with the domainId parameter.',
          bootable => 'true if the ISO is bootable, false otherwise',
          domainid =>
              'lists all available ISO files by ID of a domain. If used with the account parameter, lists all available ISO files for the account in the ID of a domain.',
          hypervisor => 'the hypervisor for which to restrict the search',
          id         => 'list all isos by id',
          isofilter =>
              'possible values are \'featured\', \'self\', \'self-executable\',\'executable\', and \'community\'. * featured-ISOs that are featured and are publicself-ISOs that have been registered/created by the owner. * selfexecutable-ISOs that have been registered/created by the owner that can be used to deploy a new VM. * executable-all ISOs that can be used to deploy a new VM * community-ISOs that are public.',
          ispublic => 'true if the ISO is publicly available to all users, false otherwise.',
          isready  => 'true if this ISO is ready to be deployed',
          keyword  => 'List by keyword',
          name     => 'list all isos by name',
          page     => 'no description',
          pagesize => 'no description',
          zoneid   => 'the ID of the zone',
        },
      },
      response => {
        account       => 'the account name to which the template belongs',
        accountid     => 'the account id to which the template belongs',
        bootable      => 'true if the ISO is bootable, false otherwise',
        checksum      => 'checksum of the template',
        created       => 'the date this template was created',
        crossZones    => 'true if the template is managed across all Zones, false otherwise',
        details       => 'additional key/value details tied with template',
        displaytext   => 'the template display text',
        domain        => 'the name of the domain to which the template belongs',
        domainid      => 'the ID of the domain to which the template belongs',
        format        => 'the format of the template.',
        hostid        => 'the ID of the secondary storage host for the template',
        hostname      => 'the name of the secondary storage host for the template',
        hypervisor    => 'the hypervisor on which the template runs',
        id            => 'the template ID',
        isextractable => 'true if the template is extractable, false otherwise',
        isfeatured    => 'true if this template is a featured template, false otherwise',
        ispublic      => 'true if this template is a public template, false otherwise',
        isready       => 'true if the template is ready to be deployed from, false otherwise.',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template',
        jobstatus        => 'shows the current pending asynchronous job status',
        name             => 'the template name',
        ostypeid         => 'the ID of the OS type for this template.',
        ostypename       => 'the name of the OS type for this template.',
        passwordenabled  => 'true if the reset password feature is enabled, false otherwise',
        removed          => 'the date this template was removed',
        size             => 'the size of the template',
        sourcetemplateid => 'the template ID of the parent template if present',
        status           => 'the status of the template',
        templatetag      => 'the tag of this template',
        templatetype     => 'the type of the template',
        zoneid           => 'the ID of the zone for this template',
        zonename         => 'the name of the zone for this template',
      },
      section => 'ISO',
    },
    listLoadBalancerRuleInstances => {
      description => 'List all virtual machine instances that are assigned to a load balancer rule.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          applied =>
              'true if listing all virtual machines currently applied to the load balancer rule; default is true',
          keyword  => 'List by keyword',
          page     => 'no description',
          pagesize => 'no description',
        },
        required => { id => 'the ID of the load balancer rule' },
      },
      response => {
        'account'     => 'the account associated with the virtual machine',
        'cpunumber'   => 'the number of cpu this virtual machine is running with',
        'cpuspeed'    => 'the speed of each cpu',
        'cpuused'     => 'the amount of the vm\'s CPU currently used',
        'created'     => 'the date when this virtual machine was created',
        'displayname' => 'user generated name. The name of the virtual machine is returned if no displayname exists.',
        'domain'      => 'the name of the domain in which the virtual machine exists',
        'domainid'    => 'the ID of the domain in which the virtual machine exists',
        'forvirtualnetwork' => 'the virtual network for the service offering',
        'group'             => 'the group name of the virtual machine',
        'groupid'           => 'the group ID of the virtual machine',
        'guestosid'         => 'Os type ID of the virtual machine',
        'haenable'          => 'true if high-availability is enabled, false otherwise',
        'hostid'            => 'the ID of the host for the virtual machine',
        'hostname'          => 'the name of the host for the virtual machine',
        'hypervisor'        => 'the hypervisor on which the template runs',
        'id'                => 'the ID of the virtual machine',
        'ipaddress'         => 'the ip address of the virtual machine',
        'isodisplaytext'    => 'an alternate display text of the ISO attached to the virtual machine',
        'isoid'             => 'the ID of the ISO attached to the virtual machine',
        'isoname'           => 'the name of the ISO attached to the virtual machine',
        'jobid' =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine',
        'jobstatus'           => 'shows the current pending asynchronous job status',
        'memory'              => 'the memory allocated for the virtual machine',
        'name'                => 'the name of the virtual machine',
        'networkkbsread'      => 'the incoming network traffic on the vm',
        'networkkbswrite'     => 'the outgoing network traffic on the host',
        'nic(*)'              => 'the list of nics associated with vm',
        'password'            => 'the password (if exists) of the virtual machine',
        'passwordenabled'     => 'true if the password rest feature is enabled, false otherwise',
        'rootdeviceid'        => 'device ID of the root volume',
        'rootdevicetype'      => 'device type of the root volume',
        'securitygroup(*)'    => 'list of security groups associated with the virtual machine',
        'serviceofferingid'   => 'the ID of the service offering of the virtual machine',
        'serviceofferingname' => 'the name of the service offering of the virtual machine',
        'state'               => 'the state of the virtual machine',
        'templatedisplaytext' => 'an alternate display text of the template for the virtual machine',
        'templateid' =>
            'the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.',
        'templatename' => 'the name of the template for the virtual machine',
        'zoneid'       => 'the ID of the availablility zone for the virtual machine',
        'zonename'     => 'the name of the availability zone for the virtual machine',
      },
      section => 'LoadBalancer',
    },
    listLoadBalancerRules => {
      description => 'Lists load balancer rules.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account => 'the account of the load balancer rule. Must be used with the domainId parameter.',
          domainid =>
              'the domain ID of the load balancer rule. If used with the account parameter, lists load balancer rules for the account in the specified domain.',
          id               => 'the ID of the load balancer rule',
          keyword          => 'List by keyword',
          name             => 'the name of the load balancer rule',
          page             => 'no description',
          pagesize         => 'no description',
          publicipid       => 'the public IP address id of the load balancer rule',
          virtualmachineid => 'the ID of the virtual machine of the load balancer rule',
          zoneid           => 'the availability zone ID',
        },
      },
      response => {
        account     => 'the account of the load balancer rule',
        algorithm   => 'the load balancer algorithm (source, roundrobin, leastconn)',
        cidrlist    => 'the cidr list to forward traffic from',
        description => 'the description of the load balancer',
        domain      => 'the domain of the load balancer rule',
        domainid    => 'the domain ID of the load balancer rule',
        id          => 'the load balancer rule ID',
        name        => 'the name of the load balancer',
        privateport => 'the private port',
        publicip    => 'the public ip address',
        publicipid  => 'the public ip address id',
        publicport  => 'the public port',
        state       => 'the state of the rule',
        zoneid      => 'the id of the zone the rule belongs to',
      },
      section => 'LoadBalancer',
    },
    listLunsOnFiler => {
      description => 'List LUN',
      isAsync     => 'false',
      level       => 15,
      request     => { required => { poolname => 'pool name.' } },
      response    => { id => 'lun id', iqn => 'lun iqn', name => 'lun name', volumeid => 'volume id', },
      section     => 'NetAppIntegration',
    },
    listNetworkDevice => {
      description => 'List network device.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          keyword                    => 'List by keyword',
          networkdeviceparameterlist => 'parameters for network device',
          networkdevicetype =>
              'Network device type, now supports ExternalDhcp, ExternalFirewall, ExternalLoadBalancer, PxeServer',
          page     => 'no description',
          pagesize => 'no description',
        },
      },
      response => { id => 'the ID of the network device' },
      section  => 'NetworkDevices',
    },
    listNetworkOfferings => {
      description => 'Lists all available network offerings.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          availability => 'the availability of network offering. Default value is Required',
          displaytext  => 'list network offerings by display text',
          guestiptype  => 'the guest ip type for the network offering, supported types are Direct and Virtual.',
          id           => 'list network offerings by id',
          isdefault    => 'true if need to list only default network offerings. Default value is false',
          isshared     => 'true is network offering supports vlans',
          keyword      => 'List by keyword',
          name         => 'list network offerings by name',
          page         => 'no description',
          pagesize     => 'no description',
          specifyvlan  => 'the tags for the network offering.',
          traffictype  => 'list by traffic type',
          zoneid       => 'list netowrk offerings available for network creation in specific zone',
        },
      },
      response => {
        availability   => 'availability of the network offering',
        created        => 'the date this network offering was created',
        displaytext    => 'an alternate display text of the network offering.',
        guestiptype    => 'guest ip type of the network offering',
        id             => 'the id of the network offering',
        isdefault      => 'true if network offering is default, false otherwise',
        maxconnections => 'the max number of concurrent connection the network offering supports',
        name           => 'the name of the network offering',
        networkrate    => 'data transfer rate in megabits per second allowed.',
        specifyvlan    => 'true if network offering supports vlans, false otherwise',
        tags           => 'the tags for the network offering',
        traffictype =>
            'the traffic type for the network offering, supported types are Public, Management, Control, Guest, Vlan or Storage.',
      },
      section => 'NetworkOffering',
    },
    listNetworks => {
      description => 'Lists all available networks.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account     => 'account who will own the VLAN. If VLAN is Zone wide, this parameter should be ommited',
          domainid    => 'domain ID of the account owning a VLAN',
          id          => 'list networks by id',
          isdefault   => 'true if network is default, false otherwise',
          isshared    => 'true if network is shared across accounts in the Zone, false otherwise',
          issystem    => 'true if network is system, false otherwise',
          keyword     => 'List by keyword',
          page        => 'no description',
          pagesize    => 'no description',
          traffictype => 'type of the traffic',
          type        => 'the type of the network',
          zoneid      => 'the Zone ID of the network',
        },
      },
      response => {
        'account'                     => 'the owner of the network',
        'broadcastdomaintype'         => 'Broadcast domain type of the network',
        'broadcasturi'                => 'broadcast uri of the network',
        'displaytext'                 => 'the displaytext of the network',
        'dns1'                        => 'the first DNS for the network',
        'dns2'                        => 'the second DNS for the network',
        'domain'                      => 'the domain name of the network owner',
        'domainid'                    => 'the domain id of the network owner',
        'endip'                       => 'the end ip of the network',
        'gateway'                     => 'the network\'s gateway',
        'id'                          => 'the id of the network',
        'isdefault'                   => 'true if network is default, false otherwise',
        'isshared'                    => 'true if network is shared, false otherwise',
        'issystem'                    => 'true if network is system, false otherwise',
        'name'                        => 'the name of the network',
        'netmask'                     => 'the network\'s netmask',
        'networkdomain'               => 'the network domain',
        'networkofferingavailability' => 'availability of the network offering the network is created from',
        'networkofferingdisplaytext'  => 'display text of the network offering the network is created from',
        'networkofferingid'           => 'network offering id the network is created from',
        'networkofferingname'         => 'name of the network offering the network is created from',
        'related'                     => 'related to what other network configuration',
        'securitygroupenabled'        => 'true if security group is enabled, false otherwise',
        'service(*)'                  => 'the list of services',
        'startip'                     => 'the start ip of the network',
        'state'                       => 'state of the network',
        'tags'                        => 'comma separated tag',
        'traffictype'                 => 'the traffic type of the network',
        'type'                        => 'the type of the network',
        'vlan'                        => 'the vlan of the network',
        'zoneid'                      => 'zone id of the network',
      },
      section => 'Network',
    },
    listOsCategories => {
      description => 'Lists all supported OS categories for this cloud.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          id       => 'list Os category by id',
          keyword  => 'List by keyword',
          page     => 'no description',
          pagesize => 'no description',
        },
      },
      response => { id => 'the ID of the OS category', name => 'the name of the OS category', },
      section  => 'GuestOS',
    },
    listOsTypes => {
      description => 'Lists all supported OS types for this cloud.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          id           => 'list by Os type Id',
          keyword      => 'List by keyword',
          oscategoryid => 'list by Os Category id',
          page         => 'no description',
          pagesize     => 'no description',
        },
      },
      response => {
        description  => 'the name/description of the OS type',
        id           => 'the ID of the OS type',
        oscategoryid => 'the ID of the OS category',
      },
      section => 'GuestOS',
    },
    listPods => {
      description => 'Lists all Pods.',
      isAsync     => 'false',
      level       => 3,
      request     => {
        optional => {
          allocationstate => 'list pods by allocation state',
          id              => 'list Pods by ID',
          keyword         => 'List by keyword',
          name            => 'list Pods by name',
          page            => 'no description',
          pagesize        => 'no description',
          zoneid          => 'list Pods by Zone ID',
        },
      },
      response => {
        allocationstate => 'the allocation state of the cluster',
        endip           => 'the ending IP for the Pod',
        gateway         => 'the gateway of the Pod',
        id              => 'the ID of the Pod',
        name            => 'the name of the Pod',
        netmask         => 'the netmask of the Pod',
        startip         => 'the starting IP for the Pod',
        zoneid          => 'the Zone ID of the Pod',
        zonename        => 'the Zone name of the Pod',
      },
      section => 'Pod',
    },
    listPools => {
      description => 'List Pool',
      isAsync     => 'false',
      level       => 15,
      request     => undef,
      response    => { algorithm => 'pool algorithm', id => 'pool id', name => 'pool name' },
      section     => 'NetAppIntegration',
    },
    listPortForwardingRules => {
      description => 'Lists all port forwarding rules for an IP address.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account => 'account. Must be used with the domainId parameter.',
          domainid =>
              'the domain ID. If used with the account parameter, lists port forwarding rules for the specified account in this domain.',
          id          => 'Lists rule with the specified ID.',
          ipaddressid => 'the id of IP address of the port forwarding services',
          keyword     => 'List by keyword',
          page        => 'no description',
          pagesize    => 'no description',
        },
      },
      response => {
        cidrlist                  => 'the cidr list to forward traffic from',
        id                        => 'the ID of the port forwarding rule',
        ipaddress                 => 'the public ip address for the port forwarding rule',
        ipaddressid               => 'the public ip address id for the port forwarding rule',
        privateendport            => 'the ending port of port forwarding rule\'s private port range',
        privateport               => 'the starting port of port forwarding rule\'s private port range',
        protocol                  => 'the protocol of the port forwarding rule',
        publicendport             => 'the ending port of port forwarding rule\'s private port range',
        publicport                => 'the starting port of port forwarding rule\'s public port range',
        state                     => 'the state of the rule',
        virtualmachinedisplayname => 'the VM display name for the port forwarding rule',
        virtualmachineid          => 'the VM ID for the port forwarding rule',
        virtualmachinename        => 'the VM name for the port forwarding rule',
      },
      section => 'Firewall',
    },
    listPublicIpAddresses => {
      description => 'Lists all public ip addresses',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account       => 'lists all public IP addresses by account. Must be used with the domainId parameter.',
          allocatedonly => 'limits search results to allocated public IP addresses',
          domainid =>
              'lists all public IP addresses by domain ID. If used with the account parameter, lists all public IP addresses by account for specified domain.',
          forloadbalancing  => 'list only ips used for load balancing',
          forvirtualnetwork => 'the virtual network for the IP address',
          id                => 'lists ip address by id',
          ipaddress         => 'lists the specified IP address',
          keyword           => 'List by keyword',
          page              => 'no description',
          pagesize          => 'no description',
          vlanid            => 'lists all public IP addresses by VLAN ID',
          zoneid            => 'lists all public IP addresses by Zone ID',
        },
      },
      response => {
        account             => 'the account the public IP address is associated with',
        allocated           => 'date the public IP address was acquired',
        associatednetworkid => 'the ID of the Network associated with the IP address',
        domain              => 'the domain the public IP address is associated with',
        domainid            => 'the domain ID the public IP address is associated with',
        forvirtualnetwork   => 'the virtual network for the IP address',
        id                  => 'public IP address id',
        ipaddress           => 'public IP address',
        issourcenat         => 'true if the IP address is a source nat address, false otherwise',
        isstaticnat         => 'true if this ip is for static nat, false otherwise',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume',
        jobstatus => 'shows the current pending asynchronous job status',
        networkid => 'the ID of the Network where ip belongs to',
        state     => 'State of the ip address. Can be: Allocatin, Allocated and Releasing',
        virtualmachinedisplayname =>
            'virutal machine display name the ip address is assigned to (not null only for static nat Ip)',
        virtualmachineid   => 'virutal machine id the ip address is assigned to (not null only for static nat Ip)',
        virtualmachinename => 'virutal machine name the ip address is assigned to (not null only for static nat Ip)',
        vlanid             => 'the ID of the VLAN associated with the IP address',
        vlanname           => 'the VLAN associated with the IP address',
        zoneid             => 'the ID of the zone the public IP address belongs to',
        zonename           => 'the name of the zone the public IP address belongs to',
      },
      section => 'Address',
    },
    listRemoteAccessVpns => {
      description => 'Lists remote access vpns',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account => 'the account of the remote access vpn. Must be used with the domainId parameter.',
          domainid =>
              'the domain ID of the remote access vpn rule. If used with the account parameter, lists remote access vpns for the account in the specified domain.',
          keyword  => 'List by keyword',
          page     => 'no description',
          pagesize => 'no description',
        },
        required => { publicipid => 'public ip address id of the vpn server' },
      },
      response => {
        account      => 'the account of the remote access vpn',
        domainid     => 'the domain id of the account of the remote access vpn',
        domainname   => 'the domain name of the account of the remote access vpn',
        iprange      => 'the range of ips to allocate to the clients',
        presharedkey => 'the ipsec preshared key',
        publicip     => 'the public ip address of the vpn server',
        publicipid   => 'the public ip address of the vpn server',
        state        => 'the state of the rule',
      },
      section => 'VPN',
    },
    listResourceLimits => {
      description => 'Lists resource limits.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account => 'Lists resource limits by account. Must be used with the domainId parameter.',
          domainid =>
              'Lists resource limits by domain ID. If used with the account parameter, lists resource limits for a specified account in a specified domain.',
          id       => 'Lists resource limits by ID.',
          keyword  => 'List by keyword',
          page     => 'no description',
          pagesize => 'no description',
          resourcetype =>
              'Type of resource to update. Values are 0, 1, 2, 3, and 4. 0 - Instance. Number of instances a user can create. 1 - IP. Number of public IP addresses a user can own. 2 - Volume. Number of disk volumes a user can create.3 - Snapshot. Number of snapshots a user can create.4 - Template. Number of templates that a user can register/create.',
        },
      },
      response => {
        account  => 'the account of the resource limit',
        domain   => 'the domain name of the resource limit',
        domainid => 'the domain ID of the resource limit',
        max      => 'the maximum number of the resource. A -1 means the resource currently has no limit.',
        resourcetype =>
            'resource type. Values include 0, 1, 2, 3, 4. See the resourceType parameter for more information on these values.',
      },
      section => 'Limit',
    },
    listRouters => {
      description => 'List routers.',
      isAsync     => 'false',
      level       => 7,
      request     => {
        optional => {
          account => 'the name of the account associated with the router. Must be used with the domainId parameter.',
          domainid =>
              'the domain ID associated with the router. If used with the account parameter, lists all routers associated with an account in the specified domain.',
          hostid    => 'the host ID of the router',
          id        => 'the ID of the disk router',
          keyword   => 'List by keyword',
          name      => 'the name of the router',
          networkid => 'list by network id',
          page      => 'no description',
          pagesize  => 'no description',
          podid     => 'the Pod ID of the router',
          state     => 'the state of the router',
          zoneid    => 'the Zone ID of the router',
        },
      },
      response => {
        account             => 'the account associated with the router',
        created             => 'the date and time the router was created',
        dns1                => 'the first DNS for the router',
        dns2                => 'the second DNS for the router',
        domain              => 'the domain associated with the router',
        domainid            => 'the domain ID associated with the router',
        gateway             => 'the gateway for the router',
        guestipaddress      => 'the guest IP address for the router',
        guestmacaddress     => 'the guest MAC address for the router',
        guestnetmask        => 'the guest netmask for the router',
        guestnetworkid      => 'the ID of the corresponding guest network',
        hostid              => 'the host ID for the router',
        hostname            => 'the hostname for the router',
        id                  => 'the id of the router',
        isredundantrouter   => 'if this router is an redundant virtual router',
        linklocalip         => 'the link local IP address for the router',
        linklocalmacaddress => 'the link local MAC address for the router',
        linklocalnetmask    => 'the link local netmask for the router',
        linklocalnetworkid  => 'the ID of the corresponding link local network',
        name                => 'the name of the router',
        networkdomain       => 'the network domain for the router',
        podid               => 'the Pod ID for the router',
        publicip            => 'the public IP address for the router',
        publicmacaddress    => 'the public MAC address for the router',
        publicnetmask       => 'the public netmask for the router',
        publicnetworkid     => 'the ID of the corresponding public network',
        redundantstate      => 'the state of redundant virtual router',
        serviceofferingid   => 'the ID of the service offering of the virtual machine',
        serviceofferingname => 'the name of the service offering of the virtual machine',
        state               => 'the state of the router',
        templateid          => 'the template ID for the router',
        zoneid              => 'the Zone ID for the router',
        zonename            => 'the Zone name for the router',
      },
      section => 'Router',
    },
    listSecurityGroups => {
      description => 'Lists security groups',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account => 'lists all available port security groups for the account. Must be used with domainID parameter',
          domainid =>
              'lists all available security groups for the domain ID. If used with the account parameter, lists all available security groups for the account in the specified domain ID.',
          id                => 'list the security group by the id provided',
          keyword           => 'List by keyword',
          page              => 'no description',
          pagesize          => 'no description',
          securitygroupname => 'lists security groups by name',
          virtualmachineid  => 'lists security groups by virtual machine id',
        },
      },
      response => {
        'account'        => 'the account owning the security group',
        'description'    => 'the description of the security group',
        'domain'         => 'the domain name of the security group',
        'domainid'       => 'the domain ID of the security group',
        'id'             => 'the ID of the security group',
        'ingressrule(*)' => 'the list of ingress rules associated with the security group',
        'jobid' =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume',
        'jobstatus' => 'shows the current pending asynchronous job status',
        'name'      => 'the name of the security group',
      },
      section => 'SecurityGroup',
    },
    listServiceOfferings => {
      description => 'Lists all available service offerings.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          domainid => 'the ID of the domain associated with the service offering',
          id       => 'ID of the service offering',
          issystem => 'is this a system vm offering',
          keyword  => 'List by keyword',
          name     => 'name of the service offering',
          page     => 'no description',
          pagesize => 'no description',
          systemvmtype =>
              'the system VM type. Possible types are \'consoleproxy\', \'secondarystoragevm\' or \'domainrouter\'.',
          virtualmachineid =>
              'the ID of the virtual machine. Pass this in if you want to see the available service offering that a virtual machine can be changed to.',
        },
      },
      response => {
        cpunumber    => 'the number of CPU',
        cpuspeed     => 'the clock rate CPU speed in Mhz',
        created      => 'the date this service offering was created',
        defaultuse   => 'is this a  default system vm offering',
        displaytext  => 'an alternate display text of the service offering.',
        domain       => 'Domain name for the offering',
        domainid     => 'the domain id of the service offering',
        hosttags     => 'the host tag for the service offering',
        id           => 'the id of the service offering',
        issystem     => 'is this a system vm offering',
        limitcpuuse  => 'restrict the CPU usage to committed service offering',
        memory       => 'the memory in MB',
        name         => 'the name of the service offering',
        networkrate  => 'data transfer rate in megabits per second allowed.',
        offerha      => 'the ha support in the service offering',
        storagetype  => 'the storage type for this service offering',
        systemvmtype => 'is this a the systemvm type for system vm offering',
        tags         => 'the tags for the service offering',
      },
      section => 'ServiceOffering',
    },
    listSnapshotPolicies => {
      description => 'Lists snapshot policies.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account => 'lists snapshot policies for the specified account. Must be used with domainid parameter.',
          domainid =>
              'the domain ID. If used with the account parameter, lists snapshot policies for the specified account in this domain.',
          keyword  => 'List by keyword',
          page     => 'no description',
          pagesize => 'no description',
        },
        required => { volumeid => 'the ID of the disk volume' },
      },
      response => {
        id           => 'the ID of the snapshot policy',
        intervaltype => 'the interval type of the snapshot policy',
        maxsnaps     => 'maximum number of snapshots retained',
        schedule     => 'time the snapshot is scheduled to be taken.',
        timezone     => 'the time zone of the snapshot policy',
        volumeid     => 'the ID of the disk volume',
      },
      section => 'Snapshot',
    },
    listSnapshots => {
      description => 'Lists all available snapshots for the account.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account => 'lists snapshot belongig to the specified account. Must be used with the domainId parameter.',
          domainid =>
              'the domain ID. If used with the account parameter, lists snapshots for the specified account in this domain.',
          id           => 'lists snapshot by snapshot ID',
          intervaltype => 'valid values are HOURLY, DAILY, WEEKLY, and MONTHLY.',
          isrecursive =>
              'defaults to false, but if true, lists all snapshots from the parent specified by the domain id till leaves.',
          keyword      => 'List by keyword',
          name         => 'lists snapshot by snapshot name',
          page         => 'no description',
          pagesize     => 'no description',
          snapshottype => 'valid values are MANUAL or RECURRING.',
          volumeid     => 'the ID of the disk volume',
        },
      },
      response => {
        account      => 'the account associated with the snapshot',
        created      => 'the date the snapshot was created',
        domain       => 'the domain name of the snapshot\'s account',
        domainid     => 'the domain ID of the snapshot\'s account',
        id           => 'ID of the snapshot',
        intervaltype => 'valid types are hourly, daily, weekly, monthy, template, and none.',
        jobid =>
            'the job ID associated with the snapshot. This is only displayed if the snapshot listed is part of a currently running asynchronous job.',
        jobstatus =>
            'the job status associated with the snapshot.  This is only displayed if the snapshot listed is part of a currently running asynchronous job.',
        name         => 'name of the snapshot',
        snapshottype => 'the type of the snapshot',
        state =>
            'the state of the snapshot. BackedUp means that snapshot is ready to be used; Creating - the snapshot is being allocated on the primary storage; BackingUp - the snapshot is being backed up on secondary storage',
        volumeid   => 'ID of the disk volume',
        volumename => 'name of the disk volume',
        volumetype => 'type of the disk volume',
      },
      section => 'Snapshot',
    },
    listSSHKeyPairs => {
      description => 'List registered keypairs',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          fingerprint => 'A public key fingerprint to look for',
          keyword     => 'List by keyword',
          name        => 'A key pair name to look for',
          page        => 'no description',
          pagesize    => 'no description',
        },
      },
      response => {
        fingerprint => 'Fingerprint of the public key',
        name        => 'Name of the keypair',
        privatekey  => 'Private key',
      },
      section => 'SSHKeyPair',
    },
    listStoragePools => {
      description => 'Lists storage pools.',
      isAsync     => 'false',
      level       => 3,
      request     => {
        optional => {
          clusterid => 'list storage pools belongig to the specific cluster',
          id        => 'the ID of the storage pool',
          ipaddress => 'the IP address for the storage pool',
          keyword   => 'List by keyword',
          name      => 'the name of the storage pool',
          page      => 'no description',
          pagesize  => 'no description',
          path      => 'the storage pool path',
          podid     => 'the Pod ID for the storage pool',
          zoneid    => 'the Zone ID for the storage pool',
        },
      },
      response => {
        clusterid         => 'the ID of the cluster for the storage pool',
        clustername       => 'the name of the cluster for the storage pool',
        created           => 'the date and time the storage pool was created',
        disksizeallocated => 'the host\'s currently allocated disk size',
        disksizetotal     => 'the total disk size of the storage pool',
        id                => 'the ID of the storage pool',
        ipaddress         => 'the IP address of the storage pool',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the storage pool',
        jobstatus => 'shows the current pending asynchronous job status',
        name      => 'the name of the storage pool',
        path      => 'the storage pool path',
        podid     => 'the Pod ID of the storage pool',
        podname   => 'the Pod name of the storage pool',
        state     => 'the state of the storage pool',
        tags      => 'the tags for the storage pool',
        type      => 'the storage pool type',
        zoneid    => 'the Zone ID of the storage pool',
        zonename  => 'the Zone name of the storage pool',
      },
      section => 'StoragePools',
    },
    listSystemVms => {
      description => 'List system virtual machines.',
      isAsync     => 'false',
      level       => 3,
      request     => {
        optional => {
          hostid       => 'the host ID of the system VM',
          id           => 'the ID of the system VM',
          keyword      => 'List by keyword',
          name         => 'the name of the system VM',
          page         => 'no description',
          pagesize     => 'no description',
          podid        => 'the Pod ID of the system VM',
          state        => 'the state of the system VM',
          systemvmtype => 'the system VM type. Possible types are \'consoleproxy\' and \'secondarystoragevm\'.',
          zoneid       => 'the Zone ID of the system VM',
        },
      },
      response => {
        activeviewersessions => 'the number of active console sessions for the console proxy system vm',
        created              => 'the date and time the system VM was created',
        dns1                 => 'the first DNS for the system VM',
        dns2                 => 'the second DNS for the system VM',
        gateway              => 'the gateway for the system VM',
        hostid               => 'the host ID for the system VM',
        hostname             => 'the hostname for the system VM',
        id                   => 'the ID of the system VM',
        jobid =>
            'the job ID associated with the system VM. This is only displayed if the router listed is part of a currently running asynchronous job.',
        jobstatus =>
            'the job status associated with the system VM.  This is only displayed if the router listed is part of a currently running asynchronous job.',
        linklocalip         => 'the link local IP address for the system vm',
        linklocalmacaddress => 'the link local MAC address for the system vm',
        linklocalnetmask    => 'the link local netmask for the system vm',
        name                => 'the name of the system VM',
        networkdomain       => 'the network domain for the system VM',
        podid               => 'the Pod ID for the system VM',
        privateip           => 'the private IP address for the system VM',
        privatemacaddress   => 'the private MAC address for the system VM',
        privatenetmask      => 'the private netmask for the system VM',
        publicip            => 'the public IP address for the system VM',
        publicmacaddress    => 'the public MAC address for the system VM',
        publicnetmask       => 'the public netmask for the system VM',
        state               => 'the state of the system VM',
        systemvmtype        => 'the system VM type',
        templateid          => 'the template ID for the system VM',
        zoneid              => 'the Zone ID for the system VM',
        zonename            => 'the Zone name for the system VM',
      },
      section => 'SystemVM',
    },
    listTemplatePermissions => {
      description => 'List template visibility and all accounts that have permissions to view this template.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account =>
              'List template visibility and permissions for the specified account. Must be used with the domainId parameter.',
          domainid =>
              'List template visibility and permissions by domain. If used with the account parameter, specifies in which domain the specified account exists.',
        },
        required => { id => 'the template ID' },
      },
      response => {
        account  => 'the list of accounts the template is available for',
        domainid => 'the ID of the domain to which the template belongs',
        id       => 'the template ID',
        ispublic => 'true if this template is a public template, false otherwise',
      },
      section => 'Template',
    },
    listTemplates => {
      description => 'List all public, private, and privileged templates.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account => 'list template by account. Must be used with the domainId parameter.',
          domainid =>
              'list all templates in specified domain. If used with the account parameter, lists all templates for an account in the specified domain.',
          hypervisor => 'the hypervisor for which to restrict the search',
          id         => 'the template ID',
          keyword    => 'List by keyword',
          name       => 'the template name',
          page       => 'no description',
          pagesize   => 'no description',
          zoneid     => 'list templates by zoneId',
        },
        required => {
          templatefilter =>
              'possible values are \'featured\', \'self\', \'self-executable\', \'executable\', and \'community\'.* featured-templates that are featured and are public* self-templates that have been registered/created by the owner* selfexecutable-templates that have been registered/created by the owner that can be used to deploy a new VM* executable-all templates that can be used to deploy a new VM* community-templates that are public.',
        },
      },
      response => {
        account       => 'the account name to which the template belongs',
        accountid     => 'the account id to which the template belongs',
        bootable      => 'true if the ISO is bootable, false otherwise',
        checksum      => 'checksum of the template',
        created       => 'the date this template was created',
        crossZones    => 'true if the template is managed across all Zones, false otherwise',
        details       => 'additional key/value details tied with template',
        displaytext   => 'the template display text',
        domain        => 'the name of the domain to which the template belongs',
        domainid      => 'the ID of the domain to which the template belongs',
        format        => 'the format of the template.',
        hostid        => 'the ID of the secondary storage host for the template',
        hostname      => 'the name of the secondary storage host for the template',
        hypervisor    => 'the hypervisor on which the template runs',
        id            => 'the template ID',
        isextractable => 'true if the template is extractable, false otherwise',
        isfeatured    => 'true if this template is a featured template, false otherwise',
        ispublic      => 'true if this template is a public template, false otherwise',
        isready       => 'true if the template is ready to be deployed from, false otherwise.',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template',
        jobstatus        => 'shows the current pending asynchronous job status',
        name             => 'the template name',
        ostypeid         => 'the ID of the OS type for this template.',
        ostypename       => 'the name of the OS type for this template.',
        passwordenabled  => 'true if the reset password feature is enabled, false otherwise',
        removed          => 'the date this template was removed',
        size             => 'the size of the template',
        sourcetemplateid => 'the template ID of the parent template if present',
        status           => 'the status of the template',
        templatetag      => 'the tag of this template',
        templatetype     => 'the type of the template',
        zoneid           => 'the ID of the zone for this template',
        zonename         => 'the name of the zone for this template',
      },
      section => 'Template',
    },
    listTrafficMonitors => {
      description => 'List traffic monitor Hosts.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => { keyword => 'List by keyword', page => 'no description', pagesize => 'no description', },
        required => { zoneid  => 'zone Id' },
      },
      response => {
        id               => 'the ID of the external firewall',
        ipaddress        => 'the management IP address of the external firewall',
        numretries       => 'the number of times to retry requests to the external firewall',
        privateinterface => 'the private interface of the external firewall',
        privatezone      => 'the private security zone of the external firewall',
        publicinterface  => 'the public interface of the external firewall',
        publiczone       => 'the public security zone of the external firewall',
        timeout          => 'the timeout (in seconds) for requests to the external firewall',
        usageinterface   => 'the usage interface of the external firewall',
        username         => 'the username that\'s used to log in to the external firewall',
        zoneid           => 'the zone ID of the external firewall',
      },
      section => 'TrafficMonitor',
    },
    listUsageRecords => {
      description => 'Lists usage records for accounts',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          account   => 'List usage records for the specified user.',
          accountid => 'List usage records for the specified account',
          domainid  => 'List usage records for the specified domain.',
          keyword   => 'List by keyword',
          page      => 'no description',
          pagesize  => 'no description',
        },
        required => {
          enddate =>
              'End date range for usage record query. Use yyyy-MM-dd as the date format, e.g. startDate=2009-06-03.',
          startdate =>
              'Start date range for usage record query. Use yyyy-MM-dd as the date format, e.g. startDate=2009-06-01.',
        },
      },
      response => {
        account          => 'the user account name',
        accountid        => 'the user account Id',
        assigneddate     => 'the assign date of the account',
        description      => 'description of account, including account name, service offering, and template',
        domainid         => 'the domain ID number',
        enddate          => 'end date of account',
        ipaddress        => 'the IP address',
        issourcenat      => 'source Nat flag for IPAddress',
        name             => 'virtual machine name',
        offeringid       => 'service offering ID number',
        rawusage         => 'raw usage in hours',
        releaseddate     => 'the release date of the account',
        startdate        => 'start date of account',
        templateid       => 'template ID number',
        type             => 'type',
        usage            => 'usage in hours',
        usageid          => 'id of the usage entity',
        usagetype        => 'usage type',
        virtualmachineid => 'virtual machine ID number',
        zoneid           => 'the zone ID number',
      },
      section => 'Usage',
    },
    listUsers => {
      description => 'Lists user accounts',
      isAsync     => 'false',
      level       => 7,
      request     => {
        optional => {
          account => 'List user by account. Must be used with the domainId parameter.',
          accounttype =>
              'List users by account type. Valid types include admin, domain-admin, read-only-admin, or user.',
          domainid =>
              'List all users in a domain. If used with the account parameter, lists an account in a specific domain.',
          id       => 'List user by ID.',
          keyword  => 'List by keyword',
          page     => 'no description',
          pagesize => 'no description',
          state    => 'List users by state of the user account.',
          username => 'List user by the username',
        },
      },
      response => {
        account     => 'the account name of the user',
        accounttype => 'the account type of the user',
        apikey      => 'the api key of the user',
        created     => 'the date and time the user account was created',
        domain      => 'the domain name of the user',
        domainid    => 'the domain ID of the user',
        email       => 'the user email address',
        firstname   => 'the user firstname',
        id          => 'the user ID',
        lastname    => 'the user lastname',
        secretkey   => 'the secret key of the user',
        state       => 'the user state',
        timezone    => 'the timezone user was created in',
        username    => 'the user name',
      },
      section => 'User',
    },
    listVirtualMachines => {
      description => 'List the virtual machines owned by the account.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account => 'account. Must be used with the domainId parameter.',
          domainid =>
              'the domain ID. If used with the account parameter, lists virtual machines for the specified account in this domain.',
          forvirtualnetwork => 'list by network type; true if need to list vms using Virtual Network, false otherwise',
          groupid           => 'the group ID',
          hostid            => 'the host ID',
          hypervisor        => 'the target hypervisor for the template',
          id                => 'the ID of the virtual machine',
          isrecursive =>
              'Must be used with domainId parameter. Defaults to false, but if true, lists all vms from the parent specified by the domain id till leaves.',
          keyword   => 'List by keyword',
          name      => 'name of the virtual machine',
          networkid => 'list by network id',
          page      => 'no description',
          pagesize  => 'no description',
          podid     => 'the pod ID',
          state     => 'state of the virtual machine',
          storageid => 'the storage ID where vm\'s volumes belong to',
          zoneid    => 'the availability zone ID',
        },
      },
      response => {
        'account'     => 'the account associated with the virtual machine',
        'cpunumber'   => 'the number of cpu this virtual machine is running with',
        'cpuspeed'    => 'the speed of each cpu',
        'cpuused'     => 'the amount of the vm\'s CPU currently used',
        'created'     => 'the date when this virtual machine was created',
        'displayname' => 'user generated name. The name of the virtual machine is returned if no displayname exists.',
        'domain'      => 'the name of the domain in which the virtual machine exists',
        'domainid'    => 'the ID of the domain in which the virtual machine exists',
        'forvirtualnetwork' => 'the virtual network for the service offering',
        'group'             => 'the group name of the virtual machine',
        'groupid'           => 'the group ID of the virtual machine',
        'guestosid'         => 'Os type ID of the virtual machine',
        'haenable'          => 'true if high-availability is enabled, false otherwise',
        'hostid'            => 'the ID of the host for the virtual machine',
        'hostname'          => 'the name of the host for the virtual machine',
        'hypervisor'        => 'the hypervisor on which the template runs',
        'id'                => 'the ID of the virtual machine',
        'ipaddress'         => 'the ip address of the virtual machine',
        'isodisplaytext'    => 'an alternate display text of the ISO attached to the virtual machine',
        'isoid'             => 'the ID of the ISO attached to the virtual machine',
        'isoname'           => 'the name of the ISO attached to the virtual machine',
        'jobid' =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine',
        'jobstatus'           => 'shows the current pending asynchronous job status',
        'memory'              => 'the memory allocated for the virtual machine',
        'name'                => 'the name of the virtual machine',
        'networkkbsread'      => 'the incoming network traffic on the vm',
        'networkkbswrite'     => 'the outgoing network traffic on the host',
        'nic(*)'              => 'the list of nics associated with vm',
        'password'            => 'the password (if exists) of the virtual machine',
        'passwordenabled'     => 'true if the password rest feature is enabled, false otherwise',
        'rootdeviceid'        => 'device ID of the root volume',
        'rootdevicetype'      => 'device type of the root volume',
        'securitygroup(*)'    => 'list of security groups associated with the virtual machine',
        'serviceofferingid'   => 'the ID of the service offering of the virtual machine',
        'serviceofferingname' => 'the name of the service offering of the virtual machine',
        'state'               => 'the state of the virtual machine',
        'templatedisplaytext' => 'an alternate display text of the template for the virtual machine',
        'templateid' =>
            'the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.',
        'templatename' => 'the name of the template for the virtual machine',
        'zoneid'       => 'the ID of the availablility zone for the virtual machine',
        'zonename'     => 'the name of the availability zone for the virtual machine',
      },
      section => 'VM',
    },
    listVlanIpRanges => {
      description => 'Lists all VLAN IP ranges.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          account =>
              'the account with which the VLAN IP range is associated. Must be used with the domainId parameter.',
          domainid =>
              'the domain ID with which the VLAN IP range is associated.  If used with the account parameter, returns all VLAN IP ranges for that account in the specified domain.',
          forvirtualnetwork => 'true if VLAN is of Virtual type, false if Direct',
          id                => 'the ID of the VLAN IP range',
          keyword           => 'List by keyword',
          networkid         => 'network id of the VLAN IP range',
          page              => 'no description',
          pagesize          => 'no description',
          podid             => 'the Pod ID of the VLAN IP range',
          vlan              => 'the ID or VID of the VLAN. Default is an \'untagged\' VLAN.',
          zoneid            => 'the Zone ID of the VLAN IP range',
        },
      },
      response => {
        account           => 'the account of the VLAN IP range',
        description       => 'the description of the VLAN IP range',
        domain            => 'the domain name of the VLAN IP range',
        domainid          => 'the domain ID of the VLAN IP range',
        endip             => 'the end ip of the VLAN IP range',
        forvirtualnetwork => 'the virtual network for the VLAN IP range',
        gateway           => 'the gateway of the VLAN IP range',
        id                => 'the ID of the VLAN IP range',
        netmask           => 'the netmask of the VLAN IP range',
        networkid         => 'the network id of vlan range',
        podid             => 'the Pod ID for the VLAN IP range',
        podname           => 'the Pod name for the VLAN IP range',
        startip           => 'the start ip of the VLAN IP range',
        vlan              => 'the ID or VID of the VLAN.',
        zoneid            => 'the Zone ID of the VLAN IP range',
      },
      section => 'VLAN',
    },
    listVolumes => {
      description => 'Lists all volumes.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account => 'the account associated with the disk volume. Must be used with the domainId parameter.',
          domainid =>
              'Lists all disk volumes for the specified domain ID. If used with the account parameter, returns all disk volumes for an account in the specified domain ID.',
          hostid => 'list volumes on specified host',
          id     => 'the ID of the disk volume',
          isrecursive =>
              'defaults to false, but if true, lists all volumes from the parent specified by the domain id till leaves.',
          keyword          => 'List by keyword',
          name             => 'the name of the disk volume',
          page             => 'no description',
          pagesize         => 'no description',
          podid            => 'the pod id the disk volume belongs to',
          type             => 'the type of disk volume',
          virtualmachineid => 'the ID of the virtual machine',
          zoneid           => 'the ID of the availability zone',
        },
      },
      response => {
        account   => 'the account associated with the disk volume',
        attached  => 'the date the volume was attached to a VM instance',
        created   => 'the date the disk volume was created',
        destroyed => 'the boolean state of whether the volume is destroyed or not',
        deviceid =>
            'the ID of the device on user vm the volume is attahed to. This tag is not returned when the volume is detached.',
        diskofferingdisplaytext => 'the display text of the disk offering',
        diskofferingid          => 'ID of the disk offering',
        diskofferingname        => 'name of the disk offering',
        domain                  => 'the domain associated with the disk volume',
        domainid                => 'the ID of the domain associated with the disk volume',
        hypervisor              => 'Hypervisor the volume belongs to',
        id                      => 'ID of the disk volume',
        isextractable           => 'true if the volume is extractable, false otherwise',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume',
        jobstatus                  => 'shows the current pending asynchronous job status',
        name                       => 'name of the disk volume',
        serviceofferingdisplaytext => 'the display text of the service offering for root disk',
        serviceofferingid          => 'ID of the service offering for root disk',
        serviceofferingname        => 'name of the service offering for root disk',
        size                       => 'size of the disk volume',
        snapshotid                 => 'ID of the snapshot from which this volume was created',
        state                      => 'the state of the disk volume',
        storage                    => 'name of the primary storage hosting the disk volume',
        storagetype                => 'shared or local storage',
        type                       => 'type of the disk volume (ROOT or DATADISK)',
        virtualmachineid           => 'id of the virtual machine',
        vmdisplayname              => 'display name of the virtual machine',
        vmname                     => 'name of the virtual machine',
        vmstate                    => 'state of the virtual machine',
        zoneid                     => 'ID of the availability zone',
        zonename                   => 'name of the availability zone',
      },
      section => 'Volume',
    },
    listVolumesOnFiler => {
      description => 'List Volumes',
      isAsync     => 'false',
      level       => 15,
      request     => { required => { poolname => 'pool name.' } },
      response    => {
        aggregatename       => 'Aggregate name',
        id                  => 'volume id',
        ipaddress           => 'ip address',
        poolname            => 'pool name',
        size                => 'volume size',
        snapshotpolicy      => 'snapshot policy',
        snapshotreservation => 'snapshot reservation',
        volumename          => 'Volume name',
      },
      section => 'NetAppIntegration',
    },
    listVpnUsers => {
      description => 'Lists vpn users',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account => 'the account of the remote access vpn. Must be used with the domainId parameter.',
          domainid =>
              'the domain ID of the remote access vpn. If used with the account parameter, lists remote access vpns for the account in the specified domain.',
          id       => 'the ID of the vpn user',
          keyword  => 'List by keyword',
          page     => 'no description',
          pagesize => 'no description',
          username => 'the username of the vpn user.',
        },
      },
      response => {
        account    => 'the account of the remote access vpn',
        domainid   => 'the domain id of the account of the remote access vpn',
        domainname => 'the domain name of the account of the remote access vpn',
        id         => 'the vpn userID',
        username   => 'the username of the vpn user',
      },
      section => 'VPN',
    },
    listZones => {
      description => 'Lists zones',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          available =>
              'true if you want to retrieve all available Zones. False if you only want to return the Zones from which you have at least one VM. Default is false.',
          domainid => 'the ID of the domain associated with the zone',
          id       => 'the ID of the zone',
          keyword  => 'List by keyword',
          page     => 'no description',
          pagesize => 'no description',
        },
      },
      response => {
        allocationstate       => 'the allocation state of the cluster',
        description           => 'Zone description',
        dhcpprovider          => 'the dhcp Provider for the Zone',
        displaytext           => 'the display text of the zone',
        dns1                  => 'the first DNS for the Zone',
        dns2                  => 'the second DNS for the Zone',
        domain                => 'Network domain name for the networks in the zone',
        domainid              => 'the ID of the containing domain, null for public zones',
        guestcidraddress      => 'the guest CIDR address for the Zone',
        id                    => 'Zone id',
        internaldns1          => 'the first internal DNS for the Zone',
        internaldns2          => 'the second internal DNS for the Zone',
        name                  => 'Zone name',
        networktype           => 'the network type of the zone; can be Basic or Advanced',
        securitygroupsenabled => 'true if security groups support is enabled, false otherwise',
        vlan                  => 'the vlan range of the zone',
        zonetoken             => 'Zone Token',
      },
      section => 'Zone',
    },
    login => {
      description =>
          'Logs a user into the CloudStack. A successful login attempt will generate a JSESSIONID cookie value that can be passed in subsequent Query command calls until the \'logout\' command has been issued or the session has expired.',
      isAsync => 'false',
      level   => 15,
      request => {
        optional => {
          domain =>
              'path of the domain that the user belongs to. Example: domain=/com/cloud/internal.  If no domain is passed in, the ROOT domain is assumed.',
        },
        required => {
          password =>
              'Hashed password (Default is MD5). If you wish to use any other hashing algorithm, you would need to write a custom authentication adapter See Docs section.',
          username => 'Username',
        },
      },
      response => {
        account        => 'the account name the user belongs to',
        domainid       => 'domain ID that the user belongs to',
        firstname      => 'first name of the user',
        lastname       => 'last name of the user',
        password       => 'Password',
        sessionkey     => 'Session key that can be passed in subsequent Query command calls',
        timeout        => 'the time period before the session has expired',
        timezone       => 'user time zone',
        timezoneoffset => 'user time zone offset from UTC 00:00',
        type           => 'the account type (admin, domain-admin, read-only-admin, user)',
        userid         => 'User id',
        username       => 'Username',
      },
      section => 'Session',
    },
    logout => {
      description => 'Logs out the user',
      isAsync     => 'false',
      level       => 15,
      request     => undef,
      response    => { success => 'success if the logout action succeeded' },
      section     => 'Session',
    },
    migrateSystemVm => {
      description => 'Attempts Migration of a system virtual machine to the host specified.',
      isAsync     => 'true',
      level       => 1,
      request     => {
        required =>
            { hostid => 'destination Host ID to migrate VM to', virtualmachineid => 'the ID of the virtual machine', },
      },
      response => {
        hostid       => 'the host ID for the system VM',
        id           => 'the ID of the system VM',
        name         => 'the name of the system VM',
        role         => 'the role of the system VM',
        state        => 'the state of the system VM',
        systemvmtype => 'the system VM type',
      },
      section => 'SystemVM',
    },
    migrateVirtualMachine => {
      description => 'Attempts Migration of a user virtual machine to the host specified.',
      isAsync     => 'true',
      level       => 1,
      request     => {
        required =>
            { hostid => 'destination Host ID to migrate VM to', virtualmachineid => 'the ID of the virtual machine', },
      },
      response => {
        'account'     => 'the account associated with the virtual machine',
        'cpunumber'   => 'the number of cpu this virtual machine is running with',
        'cpuspeed'    => 'the speed of each cpu',
        'cpuused'     => 'the amount of the vm\'s CPU currently used',
        'created'     => 'the date when this virtual machine was created',
        'displayname' => 'user generated name. The name of the virtual machine is returned if no displayname exists.',
        'domain'      => 'the name of the domain in which the virtual machine exists',
        'domainid'    => 'the ID of the domain in which the virtual machine exists',
        'forvirtualnetwork' => 'the virtual network for the service offering',
        'group'             => 'the group name of the virtual machine',
        'groupid'           => 'the group ID of the virtual machine',
        'guestosid'         => 'Os type ID of the virtual machine',
        'haenable'          => 'true if high-availability is enabled, false otherwise',
        'hostid'            => 'the ID of the host for the virtual machine',
        'hostname'          => 'the name of the host for the virtual machine',
        'hypervisor'        => 'the hypervisor on which the template runs',
        'id'                => 'the ID of the virtual machine',
        'ipaddress'         => 'the ip address of the virtual machine',
        'isodisplaytext'    => 'an alternate display text of the ISO attached to the virtual machine',
        'isoid'             => 'the ID of the ISO attached to the virtual machine',
        'isoname'           => 'the name of the ISO attached to the virtual machine',
        'jobid' =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine',
        'jobstatus'           => 'shows the current pending asynchronous job status',
        'memory'              => 'the memory allocated for the virtual machine',
        'name'                => 'the name of the virtual machine',
        'networkkbsread'      => 'the incoming network traffic on the vm',
        'networkkbswrite'     => 'the outgoing network traffic on the host',
        'nic(*)'              => 'the list of nics associated with vm',
        'password'            => 'the password (if exists) of the virtual machine',
        'passwordenabled'     => 'true if the password rest feature is enabled, false otherwise',
        'rootdeviceid'        => 'device ID of the root volume',
        'rootdevicetype'      => 'device type of the root volume',
        'securitygroup(*)'    => 'list of security groups associated with the virtual machine',
        'serviceofferingid'   => 'the ID of the service offering of the virtual machine',
        'serviceofferingname' => 'the name of the service offering of the virtual machine',
        'state'               => 'the state of the virtual machine',
        'templatedisplaytext' => 'an alternate display text of the template for the virtual machine',
        'templateid' =>
            'the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.',
        'templatename' => 'the name of the template for the virtual machine',
        'zoneid'       => 'the ID of the availablility zone for the virtual machine',
        'zonename'     => 'the name of the availability zone for the virtual machine',
      },
      section => 'VM',
    },
    modifyPool => {
      description => 'Modify pool',
      isAsync     => 'false',
      level       => 15,
      request     => { required => { algorithm => 'algorithm.', poolname => 'pool name.' }, },
      response    => undef,
      section     => 'NetAppIntegration',
    },
    prepareHostForMaintenance => {
      description => 'Prepares a host for maintenance.',
      isAsync     => 'true',
      level       => 1,
      request     => { required => { id => 'the host ID' } },
      response    => {
        allocationstate         => 'the allocation state of the host',
        averageload             => 'the cpu average load on the host',
        capabilities            => 'capabilities of the host',
        clusterid               => 'the cluster ID of the host',
        clustername             => 'the cluster name of the host',
        clustertype             => 'the cluster type of the cluster that host belongs to',
        cpuallocated            => 'the amount of the host\'s CPU currently allocated',
        cpunumber               => 'the CPU number of the host',
        cpuspeed                => 'the CPU speed of the host',
        cpuused                 => 'the amount of the host\'s CPU currently used',
        cpuwithoverprovisioning => 'the amount of the host\'s CPU after applying the cpu.overprovisioning.factor',
        created                 => 'the date and time the host was created',
        disconnected            => 'true if the host is disconnected. False otherwise.',
        disksizeallocated       => 'the host\'s currently allocated disk size',
        disksizetotal           => 'the total disk size of the host',
        events                  => 'events available for the host',
        hasEnoughCapacity => 'true if this host has enough CPU and RAM capacity to migrate a VM to it, false otherwise',
        hosttags          => 'comma-separated list of tags for the host',
        hypervisor        => 'the host hypervisor',
        id                => 'the ID of the host',
        ipaddress         => 'the IP address of the host',
        islocalstorageactive => 'true if local storage is active, false otherwise',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the host',
        jobstatus          => 'shows the current pending asynchronous job status',
        lastpinged         => 'the date and time the host was last pinged',
        managementserverid => 'the management server ID of the host',
        memoryallocated    => 'the amount of the host\'s memory currently allocated',
        memorytotal        => 'the memory total of the host',
        memoryused         => 'the amount of the host\'s memory currently used',
        name               => 'the name of the host',
        networkkbsread     => 'the incoming network traffic on the host',
        networkkbswrite    => 'the outgoing network traffic on the host',
        oscategoryid       => 'the OS category ID of the host',
        oscategoryname     => 'the OS category name of the host',
        podid              => 'the Pod ID of the host',
        podname            => 'the Pod name of the host',
        removed            => 'the date and time the host was removed',
        state              => 'the state of the host',
        type               => 'the host type',
        version            => 'the host version',
        zoneid             => 'the Zone ID of the host',
        zonename           => 'the Zone name of the host',
      },
      section => 'Host',
    },
    prepareTemplate => {
      description => 'load template into primary storage',
      isAsync     => 'false',
      level       => 1,
      request     => {
        required => {
          templateid => 'template ID of the template to be prepared in primary storage(s).',
          zoneid     => 'zone ID of the template to be prepared in primary storage(s).',
        },
      },
      response => {
        account       => 'the account name to which the template belongs',
        accountid     => 'the account id to which the template belongs',
        bootable      => 'true if the ISO is bootable, false otherwise',
        checksum      => 'checksum of the template',
        created       => 'the date this template was created',
        crossZones    => 'true if the template is managed across all Zones, false otherwise',
        details       => 'additional key/value details tied with template',
        displaytext   => 'the template display text',
        domain        => 'the name of the domain to which the template belongs',
        domainid      => 'the ID of the domain to which the template belongs',
        format        => 'the format of the template.',
        hostid        => 'the ID of the secondary storage host for the template',
        hostname      => 'the name of the secondary storage host for the template',
        hypervisor    => 'the hypervisor on which the template runs',
        id            => 'the template ID',
        isextractable => 'true if the template is extractable, false otherwise',
        isfeatured    => 'true if this template is a featured template, false otherwise',
        ispublic      => 'true if this template is a public template, false otherwise',
        isready       => 'true if the template is ready to be deployed from, false otherwise.',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template',
        jobstatus        => 'shows the current pending asynchronous job status',
        name             => 'the template name',
        ostypeid         => 'the ID of the OS type for this template.',
        ostypename       => 'the name of the OS type for this template.',
        passwordenabled  => 'true if the reset password feature is enabled, false otherwise',
        removed          => 'the date this template was removed',
        size             => 'the size of the template',
        sourcetemplateid => 'the template ID of the parent template if present',
        status           => 'the status of the template',
        templatetag      => 'the tag of this template',
        templatetype     => 'the type of the template',
        zoneid           => 'the ID of the zone for this template',
        zonename         => 'the name of the zone for this template',
      },
      section => 'Template',
    },
    queryAsyncJobResult => {
      description => 'Retrieves the current status of asynchronous job.',
      isAsync     => 'false',
      level       => 15,
      request     => { required => { jobid => 'the ID of the asychronous job' } },
      response    => {
        accountid       => 'the account that executed the async command',
        cmd             => 'the async command executed',
        created         => 'the created date of the job',
        jobid           => 'async job ID',
        jobinstanceid   => 'the unique ID of the instance/entity object related to the job',
        jobinstancetype => 'the instance/entity object related to the job',
        jobprocstatus   => 'the progress information of the PENDING job',
        jobresult       => 'the result reason',
        jobresultcode   => 'the result code for the job',
        jobresulttype   => 'the result type',
        jobstatus       => 'the current job status-should be 0 for PENDING',
        userid          => 'the user that executed the async command',
      },
      section => 'AsyncQuery',
    },
    rebootRouter => {
      description => 'Starts a router.',
      isAsync     => 'true',
      level       => 7,
      request     => { required => { id => 'the ID of the router' } },
      response    => {
        account             => 'the account associated with the router',
        created             => 'the date and time the router was created',
        dns1                => 'the first DNS for the router',
        dns2                => 'the second DNS for the router',
        domain              => 'the domain associated with the router',
        domainid            => 'the domain ID associated with the router',
        gateway             => 'the gateway for the router',
        guestipaddress      => 'the guest IP address for the router',
        guestmacaddress     => 'the guest MAC address for the router',
        guestnetmask        => 'the guest netmask for the router',
        guestnetworkid      => 'the ID of the corresponding guest network',
        hostid              => 'the host ID for the router',
        hostname            => 'the hostname for the router',
        id                  => 'the id of the router',
        isredundantrouter   => 'if this router is an redundant virtual router',
        linklocalip         => 'the link local IP address for the router',
        linklocalmacaddress => 'the link local MAC address for the router',
        linklocalnetmask    => 'the link local netmask for the router',
        linklocalnetworkid  => 'the ID of the corresponding link local network',
        name                => 'the name of the router',
        networkdomain       => 'the network domain for the router',
        podid               => 'the Pod ID for the router',
        publicip            => 'the public IP address for the router',
        publicmacaddress    => 'the public MAC address for the router',
        publicnetmask       => 'the public netmask for the router',
        publicnetworkid     => 'the ID of the corresponding public network',
        redundantstate      => 'the state of redundant virtual router',
        serviceofferingid   => 'the ID of the service offering of the virtual machine',
        serviceofferingname => 'the name of the service offering of the virtual machine',
        state               => 'the state of the router',
        templateid          => 'the template ID for the router',
        zoneid              => 'the Zone ID for the router',
        zonename            => 'the Zone name for the router',
      },
      section => 'Router',
    },
    rebootSystemVm => {
      description => 'Reboots a system VM.',
      isAsync     => 'true',
      level       => 1,
      request     => { required => { id => 'The ID of the system virtual machine' } },
      response    => {
        activeviewersessions => 'the number of active console sessions for the console proxy system vm',
        created              => 'the date and time the system VM was created',
        dns1                 => 'the first DNS for the system VM',
        dns2                 => 'the second DNS for the system VM',
        gateway              => 'the gateway for the system VM',
        hostid               => 'the host ID for the system VM',
        hostname             => 'the hostname for the system VM',
        id                   => 'the ID of the system VM',
        jobid =>
            'the job ID associated with the system VM. This is only displayed if the router listed is part of a currently running asynchronous job.',
        jobstatus =>
            'the job status associated with the system VM.  This is only displayed if the router listed is part of a currently running asynchronous job.',
        linklocalip         => 'the link local IP address for the system vm',
        linklocalmacaddress => 'the link local MAC address for the system vm',
        linklocalnetmask    => 'the link local netmask for the system vm',
        name                => 'the name of the system VM',
        networkdomain       => 'the network domain for the system VM',
        podid               => 'the Pod ID for the system VM',
        privateip           => 'the private IP address for the system VM',
        privatemacaddress   => 'the private MAC address for the system VM',
        privatenetmask      => 'the private netmask for the system VM',
        publicip            => 'the public IP address for the system VM',
        publicmacaddress    => 'the public MAC address for the system VM',
        publicnetmask       => 'the public netmask for the system VM',
        state               => 'the state of the system VM',
        systemvmtype        => 'the system VM type',
        templateid          => 'the template ID for the system VM',
        zoneid              => 'the Zone ID for the system VM',
        zonename            => 'the Zone name for the system VM',
      },
      section => 'SystemVM',
    },
    rebootVirtualMachine => {
      description => 'Reboots a virtual machine.',
      isAsync     => 'true',
      level       => 15,
      request     => { required => { id => 'The ID of the virtual machine' } },
      response    => {
        'account'     => 'the account associated with the virtual machine',
        'cpunumber'   => 'the number of cpu this virtual machine is running with',
        'cpuspeed'    => 'the speed of each cpu',
        'cpuused'     => 'the amount of the vm\'s CPU currently used',
        'created'     => 'the date when this virtual machine was created',
        'displayname' => 'user generated name. The name of the virtual machine is returned if no displayname exists.',
        'domain'      => 'the name of the domain in which the virtual machine exists',
        'domainid'    => 'the ID of the domain in which the virtual machine exists',
        'forvirtualnetwork' => 'the virtual network for the service offering',
        'group'             => 'the group name of the virtual machine',
        'groupid'           => 'the group ID of the virtual machine',
        'guestosid'         => 'Os type ID of the virtual machine',
        'haenable'          => 'true if high-availability is enabled, false otherwise',
        'hostid'            => 'the ID of the host for the virtual machine',
        'hostname'          => 'the name of the host for the virtual machine',
        'hypervisor'        => 'the hypervisor on which the template runs',
        'id'                => 'the ID of the virtual machine',
        'ipaddress'         => 'the ip address of the virtual machine',
        'isodisplaytext'    => 'an alternate display text of the ISO attached to the virtual machine',
        'isoid'             => 'the ID of the ISO attached to the virtual machine',
        'isoname'           => 'the name of the ISO attached to the virtual machine',
        'jobid' =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine',
        'jobstatus'           => 'shows the current pending asynchronous job status',
        'memory'              => 'the memory allocated for the virtual machine',
        'name'                => 'the name of the virtual machine',
        'networkkbsread'      => 'the incoming network traffic on the vm',
        'networkkbswrite'     => 'the outgoing network traffic on the host',
        'nic(*)'              => 'the list of nics associated with vm',
        'password'            => 'the password (if exists) of the virtual machine',
        'passwordenabled'     => 'true if the password rest feature is enabled, false otherwise',
        'rootdeviceid'        => 'device ID of the root volume',
        'rootdevicetype'      => 'device type of the root volume',
        'securitygroup(*)'    => 'list of security groups associated with the virtual machine',
        'serviceofferingid'   => 'the ID of the service offering of the virtual machine',
        'serviceofferingname' => 'the name of the service offering of the virtual machine',
        'state'               => 'the state of the virtual machine',
        'templatedisplaytext' => 'an alternate display text of the template for the virtual machine',
        'templateid' =>
            'the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.',
        'templatename' => 'the name of the template for the virtual machine',
        'zoneid'       => 'the ID of the availablility zone for the virtual machine',
        'zonename'     => 'the name of the availability zone for the virtual machine',
      },
      section => 'VM',
    },
    reconnectHost => {
      description => 'Reconnects a host.',
      isAsync     => 'true',
      level       => 1,
      request     => { required => { id => 'the host ID' } },
      response    => {
        allocationstate         => 'the allocation state of the host',
        averageload             => 'the cpu average load on the host',
        capabilities            => 'capabilities of the host',
        clusterid               => 'the cluster ID of the host',
        clustername             => 'the cluster name of the host',
        clustertype             => 'the cluster type of the cluster that host belongs to',
        cpuallocated            => 'the amount of the host\'s CPU currently allocated',
        cpunumber               => 'the CPU number of the host',
        cpuspeed                => 'the CPU speed of the host',
        cpuused                 => 'the amount of the host\'s CPU currently used',
        cpuwithoverprovisioning => 'the amount of the host\'s CPU after applying the cpu.overprovisioning.factor',
        created                 => 'the date and time the host was created',
        disconnected            => 'true if the host is disconnected. False otherwise.',
        disksizeallocated       => 'the host\'s currently allocated disk size',
        disksizetotal           => 'the total disk size of the host',
        events                  => 'events available for the host',
        hasEnoughCapacity => 'true if this host has enough CPU and RAM capacity to migrate a VM to it, false otherwise',
        hosttags          => 'comma-separated list of tags for the host',
        hypervisor        => 'the host hypervisor',
        id                => 'the ID of the host',
        ipaddress         => 'the IP address of the host',
        islocalstorageactive => 'true if local storage is active, false otherwise',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the host',
        jobstatus          => 'shows the current pending asynchronous job status',
        lastpinged         => 'the date and time the host was last pinged',
        managementserverid => 'the management server ID of the host',
        memoryallocated    => 'the amount of the host\'s memory currently allocated',
        memorytotal        => 'the memory total of the host',
        memoryused         => 'the amount of the host\'s memory currently used',
        name               => 'the name of the host',
        networkkbsread     => 'the incoming network traffic on the host',
        networkkbswrite    => 'the outgoing network traffic on the host',
        oscategoryid       => 'the OS category ID of the host',
        oscategoryname     => 'the OS category name of the host',
        podid              => 'the Pod ID of the host',
        podname            => 'the Pod name of the host',
        removed            => 'the date and time the host was removed',
        state              => 'the state of the host',
        type               => 'the host type',
        version            => 'the host version',
        zoneid             => 'the Zone ID of the host',
        zonename           => 'the Zone name of the host',
      },
      section => 'Host',
    },
    recoverVirtualMachine => {
      description => 'Recovers a virtual machine.',
      isAsync     => 'false',
      level       => 7,
      request     => { required => { id => 'The ID of the virtual machine' } },
      response    => {
        'account'     => 'the account associated with the virtual machine',
        'cpunumber'   => 'the number of cpu this virtual machine is running with',
        'cpuspeed'    => 'the speed of each cpu',
        'cpuused'     => 'the amount of the vm\'s CPU currently used',
        'created'     => 'the date when this virtual machine was created',
        'displayname' => 'user generated name. The name of the virtual machine is returned if no displayname exists.',
        'domain'      => 'the name of the domain in which the virtual machine exists',
        'domainid'    => 'the ID of the domain in which the virtual machine exists',
        'forvirtualnetwork' => 'the virtual network for the service offering',
        'group'             => 'the group name of the virtual machine',
        'groupid'           => 'the group ID of the virtual machine',
        'guestosid'         => 'Os type ID of the virtual machine',
        'haenable'          => 'true if high-availability is enabled, false otherwise',
        'hostid'            => 'the ID of the host for the virtual machine',
        'hostname'          => 'the name of the host for the virtual machine',
        'hypervisor'        => 'the hypervisor on which the template runs',
        'id'                => 'the ID of the virtual machine',
        'ipaddress'         => 'the ip address of the virtual machine',
        'isodisplaytext'    => 'an alternate display text of the ISO attached to the virtual machine',
        'isoid'             => 'the ID of the ISO attached to the virtual machine',
        'isoname'           => 'the name of the ISO attached to the virtual machine',
        'jobid' =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine',
        'jobstatus'           => 'shows the current pending asynchronous job status',
        'memory'              => 'the memory allocated for the virtual machine',
        'name'                => 'the name of the virtual machine',
        'networkkbsread'      => 'the incoming network traffic on the vm',
        'networkkbswrite'     => 'the outgoing network traffic on the host',
        'nic(*)'              => 'the list of nics associated with vm',
        'password'            => 'the password (if exists) of the virtual machine',
        'passwordenabled'     => 'true if the password rest feature is enabled, false otherwise',
        'rootdeviceid'        => 'device ID of the root volume',
        'rootdevicetype'      => 'device type of the root volume',
        'securitygroup(*)'    => 'list of security groups associated with the virtual machine',
        'serviceofferingid'   => 'the ID of the service offering of the virtual machine',
        'serviceofferingname' => 'the name of the service offering of the virtual machine',
        'state'               => 'the state of the virtual machine',
        'templatedisplaytext' => 'an alternate display text of the template for the virtual machine',
        'templateid' =>
            'the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.',
        'templatename' => 'the name of the template for the virtual machine',
        'zoneid'       => 'the ID of the availablility zone for the virtual machine',
        'zonename'     => 'the name of the availability zone for the virtual machine',
      },
      section => 'VM',
    },
    registerIso => {
      description => 'Registers an existing ISO into the Cloud.com Cloud.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account       => 'an optional account name. Must be used with domainId.',
          bootable      => 'true if this ISO is bootable',
          domainid      => 'an optional domainId. If the account parameter is used, domainId must also be used.',
          isextractable => 'true if the iso or its derivatives are extractable; default is false',
          isfeatured    => 'true if you want this ISO to be featured',
          ispublic => 'true if you want to register the ISO to be publicly available to all users, false otherwise.',
          ostypeid => 'the ID of the OS Type that best represents the OS of this ISO',
        },
        required => {
          displaytext => 'the display text of the ISO. This is usually used for display purposes.',
          name        => 'the name of the ISO',
          url         => 'the URL to where the ISO is currently being hosted',
          zoneid      => 'the ID of the zone you wish to register the ISO to.',
        },
      },
      response => {
        account       => 'the account name to which the template belongs',
        accountid     => 'the account id to which the template belongs',
        bootable      => 'true if the ISO is bootable, false otherwise',
        checksum      => 'checksum of the template',
        created       => 'the date this template was created',
        crossZones    => 'true if the template is managed across all Zones, false otherwise',
        details       => 'additional key/value details tied with template',
        displaytext   => 'the template display text',
        domain        => 'the name of the domain to which the template belongs',
        domainid      => 'the ID of the domain to which the template belongs',
        format        => 'the format of the template.',
        hostid        => 'the ID of the secondary storage host for the template',
        hostname      => 'the name of the secondary storage host for the template',
        hypervisor    => 'the hypervisor on which the template runs',
        id            => 'the template ID',
        isextractable => 'true if the template is extractable, false otherwise',
        isfeatured    => 'true if this template is a featured template, false otherwise',
        ispublic      => 'true if this template is a public template, false otherwise',
        isready       => 'true if the template is ready to be deployed from, false otherwise.',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template',
        jobstatus        => 'shows the current pending asynchronous job status',
        name             => 'the template name',
        ostypeid         => 'the ID of the OS type for this template.',
        ostypename       => 'the name of the OS type for this template.',
        passwordenabled  => 'true if the reset password feature is enabled, false otherwise',
        removed          => 'the date this template was removed',
        size             => 'the size of the template',
        sourcetemplateid => 'the template ID of the parent template if present',
        status           => 'the status of the template',
        templatetag      => 'the tag of this template',
        templatetype     => 'the type of the template',
        zoneid           => 'the ID of the zone for this template',
        zonename         => 'the name of the zone for this template',
      },
      section => 'ISO',
    },
    registerSSHKeyPair => {
      description => 'Register a public key in a keypair under a certain name',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account => 'an optional account for the ssh key. Must be used with domainId.',
          domainid =>
              'an optional domainId for the ssh key. If the account parameter is used, domainId must also be used.',
        },
        required => { name => 'Name of the keypair', publickey => 'Public key material of the keypair', },
      },
      response => {
        fingerprint => 'Fingerprint of the public key',
        name        => 'Name of the keypair',
        privatekey  => 'Private key',
      },
      section => 'SSHKeyPair',
    },
    registerTemplate => {
      description => 'Registers an existing template into the Cloud.com cloud.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          account         => 'an optional accountName. Must be used with domainId.',
          bits            => '32 or 64 bits support. 64 by default',
          checksum        => 'the MD5 checksum value of this template',
          details         => 'Template details in key/value pairs.',
          domainid        => 'an optional domainId. If the account parameter is used, domainId must also be used.',
          isextractable   => 'true if the template or its derivatives are extractable; default is false',
          isfeatured      => 'true if this template is a featured template, false otherwise',
          ispublic        => 'true if the template is available to all accounts; default is true',
          passwordenabled => 'true if the template supports the password reset feature; default is false',
          requireshvm     => 'true if this template requires HVM',
          templatetag     => 'the tag for this template.',
        },
        required => {
          displaytext => 'the display text of the template. This is usually used for display purposes.',
          format      => 'the format for the template. Possible values include QCOW2, RAW, and VHD.',
          hypervisor  => 'the target hypervisor for the template',
          name        => 'the name of the template',
          ostypeid    => 'the ID of the OS Type that best represents the OS of this template.',
          url         => 'the URL of where the template is hosted. Possible URL include http:// and https://',
          zoneid      => 'the ID of the zone the template is to be hosted on',
        },
      },
      response => {
        account       => 'the account name to which the template belongs',
        accountid     => 'the account id to which the template belongs',
        bootable      => 'true if the ISO is bootable, false otherwise',
        checksum      => 'checksum of the template',
        created       => 'the date this template was created',
        crossZones    => 'true if the template is managed across all Zones, false otherwise',
        details       => 'additional key/value details tied with template',
        displaytext   => 'the template display text',
        domain        => 'the name of the domain to which the template belongs',
        domainid      => 'the ID of the domain to which the template belongs',
        format        => 'the format of the template.',
        hostid        => 'the ID of the secondary storage host for the template',
        hostname      => 'the name of the secondary storage host for the template',
        hypervisor    => 'the hypervisor on which the template runs',
        id            => 'the template ID',
        isextractable => 'true if the template is extractable, false otherwise',
        isfeatured    => 'true if this template is a featured template, false otherwise',
        ispublic      => 'true if this template is a public template, false otherwise',
        isready       => 'true if the template is ready to be deployed from, false otherwise.',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template',
        jobstatus        => 'shows the current pending asynchronous job status',
        name             => 'the template name',
        ostypeid         => 'the ID of the OS type for this template.',
        ostypename       => 'the name of the OS type for this template.',
        passwordenabled  => 'true if the reset password feature is enabled, false otherwise',
        removed          => 'the date this template was removed',
        size             => 'the size of the template',
        sourcetemplateid => 'the template ID of the parent template if present',
        status           => 'the status of the template',
        templatetag      => 'the tag of this template',
        templatetype     => 'the type of the template',
        zoneid           => 'the ID of the zone for this template',
        zonename         => 'the name of the zone for this template',
      },
      section => 'Template',
    },
    registerUserKeys => {
      description =>
          'This command allows a user to register for the developer API, returning a secret key and an API key. This request is made through the integration API port, so it is a privileged command and must be made on behalf of a user. It is up to the implementer just how the username and password are entered, and then how that translates to an integration API request. Both secret key and API key should be returned to the user',
      isAsync => 'false',
      level   => 1,
      request => { required => { id => 'User id' } },
      response =>
          { apikey => 'the api key of the registered user', secretkey => 'the secret key of the registered user', },
      section => 'Registration',
    },
    removeFromLoadBalancerRule => {
      description => 'Removes a virtual machine or a list of virtual machines from a load balancer rule.',
      isAsync     => 'true',
      level       => 15,
      request     => {
        required => {
          id => 'The ID of the load balancer rule',
          virtualmachineids =>
              'the list of IDs of the virtual machines that are being removed from the load balancer rule (i.e. virtualMachineIds=1,2,3)',
        },
      },
      response => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'LoadBalancer',
    },
    removeVpnUser => {
      description => 'Removes vpn user',
      isAsync     => 'true',
      level       => 15,
      request     => {
        optional => {
          account => 'an optional account for the vpn user. Must be used with domainId.',
          domainid =>
              'an optional domainId for the vpn user. If the account parameter is used, domainId must also be used.',
        },
        required => { username => 'username for the vpn user' },
      },
      response => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'VPN',
    },
    resetPasswordForVirtualMachine => {
      description =>
          'Resets the password for virtual machine. The virtual machine must be in a \'Stopped\' state and the template must already support this feature for this command to take effect. [async]',
      isAsync  => 'true',
      level    => 15,
      request  => { required => { id => 'The ID of the virtual machine' } },
      response => {
        'account'     => 'the account associated with the virtual machine',
        'cpunumber'   => 'the number of cpu this virtual machine is running with',
        'cpuspeed'    => 'the speed of each cpu',
        'cpuused'     => 'the amount of the vm\'s CPU currently used',
        'created'     => 'the date when this virtual machine was created',
        'displayname' => 'user generated name. The name of the virtual machine is returned if no displayname exists.',
        'domain'      => 'the name of the domain in which the virtual machine exists',
        'domainid'    => 'the ID of the domain in which the virtual machine exists',
        'forvirtualnetwork' => 'the virtual network for the service offering',
        'group'             => 'the group name of the virtual machine',
        'groupid'           => 'the group ID of the virtual machine',
        'guestosid'         => 'Os type ID of the virtual machine',
        'haenable'          => 'true if high-availability is enabled, false otherwise',
        'hostid'            => 'the ID of the host for the virtual machine',
        'hostname'          => 'the name of the host for the virtual machine',
        'hypervisor'        => 'the hypervisor on which the template runs',
        'id'                => 'the ID of the virtual machine',
        'ipaddress'         => 'the ip address of the virtual machine',
        'isodisplaytext'    => 'an alternate display text of the ISO attached to the virtual machine',
        'isoid'             => 'the ID of the ISO attached to the virtual machine',
        'isoname'           => 'the name of the ISO attached to the virtual machine',
        'jobid' =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine',
        'jobstatus'           => 'shows the current pending asynchronous job status',
        'memory'              => 'the memory allocated for the virtual machine',
        'name'                => 'the name of the virtual machine',
        'networkkbsread'      => 'the incoming network traffic on the vm',
        'networkkbswrite'     => 'the outgoing network traffic on the host',
        'nic(*)'              => 'the list of nics associated with vm',
        'password'            => 'the password (if exists) of the virtual machine',
        'passwordenabled'     => 'true if the password rest feature is enabled, false otherwise',
        'rootdeviceid'        => 'device ID of the root volume',
        'rootdevicetype'      => 'device type of the root volume',
        'securitygroup(*)'    => 'list of security groups associated with the virtual machine',
        'serviceofferingid'   => 'the ID of the service offering of the virtual machine',
        'serviceofferingname' => 'the name of the service offering of the virtual machine',
        'state'               => 'the state of the virtual machine',
        'templatedisplaytext' => 'an alternate display text of the template for the virtual machine',
        'templateid' =>
            'the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.',
        'templatename' => 'the name of the template for the virtual machine',
        'zoneid'       => 'the ID of the availablility zone for the virtual machine',
        'zonename'     => 'the name of the availability zone for the virtual machine',
      },
      section => 'VM',
    },
    restartNetwork => {
      description =>
          'Restarts the network; includes 1) restarting network elements - virtual routers, dhcp servers 2) reapplying all public ips 3) reapplying loadBalancing/portForwarding rules',
      isAsync => 'true',
      level   => 15,
      request => {
        optional => { cleanup => 'If cleanup old network elements' },
        required => { id      => 'The id of the network to restart.' },
      },
      response => {
        account             => 'the account the public IP address is associated with',
        allocated           => 'date the public IP address was acquired',
        associatednetworkid => 'the ID of the Network associated with the IP address',
        domain              => 'the domain the public IP address is associated with',
        domainid            => 'the domain ID the public IP address is associated with',
        forvirtualnetwork   => 'the virtual network for the IP address',
        id                  => 'public IP address id',
        ipaddress           => 'public IP address',
        issourcenat         => 'true if the IP address is a source nat address, false otherwise',
        isstaticnat         => 'true if this ip is for static nat, false otherwise',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume',
        jobstatus => 'shows the current pending asynchronous job status',
        networkid => 'the ID of the Network where ip belongs to',
        state     => 'State of the ip address. Can be: Allocatin, Allocated and Releasing',
        virtualmachinedisplayname =>
            'virutal machine display name the ip address is assigned to (not null only for static nat Ip)',
        virtualmachineid   => 'virutal machine id the ip address is assigned to (not null only for static nat Ip)',
        virtualmachinename => 'virutal machine name the ip address is assigned to (not null only for static nat Ip)',
        vlanid             => 'the ID of the VLAN associated with the IP address',
        vlanname           => 'the VLAN associated with the IP address',
        zoneid             => 'the ID of the zone the public IP address belongs to',
        zonename           => 'the name of the zone the public IP address belongs to',
      },
      section => 'Network',
    },
    revokeSecurityGroupIngress => {
      description => 'Deletes a particular ingress rule from this security group',
      isAsync     => 'true',
      level       => 15,
      request     => { required => { id => 'The ID of the ingress rule' } },
      response    => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'SecurityGroup',
    },
    startRouter => {
      description => 'Starts a router.',
      isAsync     => 'true',
      level       => 7,
      request     => { required => { id => 'the ID of the router' } },
      response    => {
        account             => 'the account associated with the router',
        created             => 'the date and time the router was created',
        dns1                => 'the first DNS for the router',
        dns2                => 'the second DNS for the router',
        domain              => 'the domain associated with the router',
        domainid            => 'the domain ID associated with the router',
        gateway             => 'the gateway for the router',
        guestipaddress      => 'the guest IP address for the router',
        guestmacaddress     => 'the guest MAC address for the router',
        guestnetmask        => 'the guest netmask for the router',
        guestnetworkid      => 'the ID of the corresponding guest network',
        hostid              => 'the host ID for the router',
        hostname            => 'the hostname for the router',
        id                  => 'the id of the router',
        isredundantrouter   => 'if this router is an redundant virtual router',
        linklocalip         => 'the link local IP address for the router',
        linklocalmacaddress => 'the link local MAC address for the router',
        linklocalnetmask    => 'the link local netmask for the router',
        linklocalnetworkid  => 'the ID of the corresponding link local network',
        name                => 'the name of the router',
        networkdomain       => 'the network domain for the router',
        podid               => 'the Pod ID for the router',
        publicip            => 'the public IP address for the router',
        publicmacaddress    => 'the public MAC address for the router',
        publicnetmask       => 'the public netmask for the router',
        publicnetworkid     => 'the ID of the corresponding public network',
        redundantstate      => 'the state of redundant virtual router',
        serviceofferingid   => 'the ID of the service offering of the virtual machine',
        serviceofferingname => 'the name of the service offering of the virtual machine',
        state               => 'the state of the router',
        templateid          => 'the template ID for the router',
        zoneid              => 'the Zone ID for the router',
        zonename            => 'the Zone name for the router',
      },
      section => 'Router',
    },
    startSystemVm => {
      description => 'Starts a system virtual machine.',
      isAsync     => 'true',
      level       => 1,
      request     => { required => { id => 'The ID of the system virtual machine' } },
      response    => {
        activeviewersessions => 'the number of active console sessions for the console proxy system vm',
        created              => 'the date and time the system VM was created',
        dns1                 => 'the first DNS for the system VM',
        dns2                 => 'the second DNS for the system VM',
        gateway              => 'the gateway for the system VM',
        hostid               => 'the host ID for the system VM',
        hostname             => 'the hostname for the system VM',
        id                   => 'the ID of the system VM',
        jobid =>
            'the job ID associated with the system VM. This is only displayed if the router listed is part of a currently running asynchronous job.',
        jobstatus =>
            'the job status associated with the system VM.  This is only displayed if the router listed is part of a currently running asynchronous job.',
        linklocalip         => 'the link local IP address for the system vm',
        linklocalmacaddress => 'the link local MAC address for the system vm',
        linklocalnetmask    => 'the link local netmask for the system vm',
        name                => 'the name of the system VM',
        networkdomain       => 'the network domain for the system VM',
        podid               => 'the Pod ID for the system VM',
        privateip           => 'the private IP address for the system VM',
        privatemacaddress   => 'the private MAC address for the system VM',
        privatenetmask      => 'the private netmask for the system VM',
        publicip            => 'the public IP address for the system VM',
        publicmacaddress    => 'the public MAC address for the system VM',
        publicnetmask       => 'the public netmask for the system VM',
        state               => 'the state of the system VM',
        systemvmtype        => 'the system VM type',
        templateid          => 'the template ID for the system VM',
        zoneid              => 'the Zone ID for the system VM',
        zonename            => 'the Zone name for the system VM',
      },
      section => 'SystemVM',
    },
    startVirtualMachine => {
      description => 'Starts a virtual machine.',
      isAsync     => 'true',
      level       => 15,
      request     => { required => { id => 'The ID of the virtual machine' } },
      response    => {
        'account'     => 'the account associated with the virtual machine',
        'cpunumber'   => 'the number of cpu this virtual machine is running with',
        'cpuspeed'    => 'the speed of each cpu',
        'cpuused'     => 'the amount of the vm\'s CPU currently used',
        'created'     => 'the date when this virtual machine was created',
        'displayname' => 'user generated name. The name of the virtual machine is returned if no displayname exists.',
        'domain'      => 'the name of the domain in which the virtual machine exists',
        'domainid'    => 'the ID of the domain in which the virtual machine exists',
        'forvirtualnetwork' => 'the virtual network for the service offering',
        'group'             => 'the group name of the virtual machine',
        'groupid'           => 'the group ID of the virtual machine',
        'guestosid'         => 'Os type ID of the virtual machine',
        'haenable'          => 'true if high-availability is enabled, false otherwise',
        'hostid'            => 'the ID of the host for the virtual machine',
        'hostname'          => 'the name of the host for the virtual machine',
        'hypervisor'        => 'the hypervisor on which the template runs',
        'id'                => 'the ID of the virtual machine',
        'ipaddress'         => 'the ip address of the virtual machine',
        'isodisplaytext'    => 'an alternate display text of the ISO attached to the virtual machine',
        'isoid'             => 'the ID of the ISO attached to the virtual machine',
        'isoname'           => 'the name of the ISO attached to the virtual machine',
        'jobid' =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine',
        'jobstatus'           => 'shows the current pending asynchronous job status',
        'memory'              => 'the memory allocated for the virtual machine',
        'name'                => 'the name of the virtual machine',
        'networkkbsread'      => 'the incoming network traffic on the vm',
        'networkkbswrite'     => 'the outgoing network traffic on the host',
        'nic(*)'              => 'the list of nics associated with vm',
        'password'            => 'the password (if exists) of the virtual machine',
        'passwordenabled'     => 'true if the password rest feature is enabled, false otherwise',
        'rootdeviceid'        => 'device ID of the root volume',
        'rootdevicetype'      => 'device type of the root volume',
        'securitygroup(*)'    => 'list of security groups associated with the virtual machine',
        'serviceofferingid'   => 'the ID of the service offering of the virtual machine',
        'serviceofferingname' => 'the name of the service offering of the virtual machine',
        'state'               => 'the state of the virtual machine',
        'templatedisplaytext' => 'an alternate display text of the template for the virtual machine',
        'templateid' =>
            'the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.',
        'templatename' => 'the name of the template for the virtual machine',
        'zoneid'       => 'the ID of the availablility zone for the virtual machine',
        'zonename'     => 'the name of the availability zone for the virtual machine',
      },
      section => 'VM',
    },
    stopRouter => {
      description => 'Stops a router.',
      isAsync     => 'true',
      level       => 7,
      request     => {
        optional => { forced => 'Force stop the VM. The caller knows the VM is stopped.', },
        required => { id     => 'the ID of the router' },
      },
      response => {
        account             => 'the account associated with the router',
        created             => 'the date and time the router was created',
        dns1                => 'the first DNS for the router',
        dns2                => 'the second DNS for the router',
        domain              => 'the domain associated with the router',
        domainid            => 'the domain ID associated with the router',
        gateway             => 'the gateway for the router',
        guestipaddress      => 'the guest IP address for the router',
        guestmacaddress     => 'the guest MAC address for the router',
        guestnetmask        => 'the guest netmask for the router',
        guestnetworkid      => 'the ID of the corresponding guest network',
        hostid              => 'the host ID for the router',
        hostname            => 'the hostname for the router',
        id                  => 'the id of the router',
        isredundantrouter   => 'if this router is an redundant virtual router',
        linklocalip         => 'the link local IP address for the router',
        linklocalmacaddress => 'the link local MAC address for the router',
        linklocalnetmask    => 'the link local netmask for the router',
        linklocalnetworkid  => 'the ID of the corresponding link local network',
        name                => 'the name of the router',
        networkdomain       => 'the network domain for the router',
        podid               => 'the Pod ID for the router',
        publicip            => 'the public IP address for the router',
        publicmacaddress    => 'the public MAC address for the router',
        publicnetmask       => 'the public netmask for the router',
        publicnetworkid     => 'the ID of the corresponding public network',
        redundantstate      => 'the state of redundant virtual router',
        serviceofferingid   => 'the ID of the service offering of the virtual machine',
        serviceofferingname => 'the name of the service offering of the virtual machine',
        state               => 'the state of the router',
        templateid          => 'the template ID for the router',
        zoneid              => 'the Zone ID for the router',
        zonename            => 'the Zone name for the router',
      },
      section => 'Router',
    },
    stopSystemVm => {
      description => 'Stops a system VM.',
      isAsync     => 'true',
      level       => 1,
      request     => {
        optional => { forced => 'Force stop the VM.  The caller knows the VM is stopped.', },
        required => { id     => 'The ID of the system virtual machine' },
      },
      response => {
        activeviewersessions => 'the number of active console sessions for the console proxy system vm',
        created              => 'the date and time the system VM was created',
        dns1                 => 'the first DNS for the system VM',
        dns2                 => 'the second DNS for the system VM',
        gateway              => 'the gateway for the system VM',
        hostid               => 'the host ID for the system VM',
        hostname             => 'the hostname for the system VM',
        id                   => 'the ID of the system VM',
        jobid =>
            'the job ID associated with the system VM. This is only displayed if the router listed is part of a currently running asynchronous job.',
        jobstatus =>
            'the job status associated with the system VM.  This is only displayed if the router listed is part of a currently running asynchronous job.',
        linklocalip         => 'the link local IP address for the system vm',
        linklocalmacaddress => 'the link local MAC address for the system vm',
        linklocalnetmask    => 'the link local netmask for the system vm',
        name                => 'the name of the system VM',
        networkdomain       => 'the network domain for the system VM',
        podid               => 'the Pod ID for the system VM',
        privateip           => 'the private IP address for the system VM',
        privatemacaddress   => 'the private MAC address for the system VM',
        privatenetmask      => 'the private netmask for the system VM',
        publicip            => 'the public IP address for the system VM',
        publicmacaddress    => 'the public MAC address for the system VM',
        publicnetmask       => 'the public netmask for the system VM',
        state               => 'the state of the system VM',
        systemvmtype        => 'the system VM type',
        templateid          => 'the template ID for the system VM',
        zoneid              => 'the Zone ID for the system VM',
        zonename            => 'the Zone name for the system VM',
      },
      section => 'SystemVM',
    },
    stopVirtualMachine => {
      description => 'Stops a virtual machine.',
      isAsync     => 'true',
      level       => 15,
      request     => {
        optional => { forced => 'Force stop the VM.  The caller knows the VM is stopped.', },
        required => { id     => 'The ID of the virtual machine' },
      },
      response => {
        'account'     => 'the account associated with the virtual machine',
        'cpunumber'   => 'the number of cpu this virtual machine is running with',
        'cpuspeed'    => 'the speed of each cpu',
        'cpuused'     => 'the amount of the vm\'s CPU currently used',
        'created'     => 'the date when this virtual machine was created',
        'displayname' => 'user generated name. The name of the virtual machine is returned if no displayname exists.',
        'domain'      => 'the name of the domain in which the virtual machine exists',
        'domainid'    => 'the ID of the domain in which the virtual machine exists',
        'forvirtualnetwork' => 'the virtual network for the service offering',
        'group'             => 'the group name of the virtual machine',
        'groupid'           => 'the group ID of the virtual machine',
        'guestosid'         => 'Os type ID of the virtual machine',
        'haenable'          => 'true if high-availability is enabled, false otherwise',
        'hostid'            => 'the ID of the host for the virtual machine',
        'hostname'          => 'the name of the host for the virtual machine',
        'hypervisor'        => 'the hypervisor on which the template runs',
        'id'                => 'the ID of the virtual machine',
        'ipaddress'         => 'the ip address of the virtual machine',
        'isodisplaytext'    => 'an alternate display text of the ISO attached to the virtual machine',
        'isoid'             => 'the ID of the ISO attached to the virtual machine',
        'isoname'           => 'the name of the ISO attached to the virtual machine',
        'jobid' =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine',
        'jobstatus'           => 'shows the current pending asynchronous job status',
        'memory'              => 'the memory allocated for the virtual machine',
        'name'                => 'the name of the virtual machine',
        'networkkbsread'      => 'the incoming network traffic on the vm',
        'networkkbswrite'     => 'the outgoing network traffic on the host',
        'nic(*)'              => 'the list of nics associated with vm',
        'password'            => 'the password (if exists) of the virtual machine',
        'passwordenabled'     => 'true if the password rest feature is enabled, false otherwise',
        'rootdeviceid'        => 'device ID of the root volume',
        'rootdevicetype'      => 'device type of the root volume',
        'securitygroup(*)'    => 'list of security groups associated with the virtual machine',
        'serviceofferingid'   => 'the ID of the service offering of the virtual machine',
        'serviceofferingname' => 'the name of the service offering of the virtual machine',
        'state'               => 'the state of the virtual machine',
        'templatedisplaytext' => 'an alternate display text of the template for the virtual machine',
        'templateid' =>
            'the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.',
        'templatename' => 'the name of the template for the virtual machine',
        'zoneid'       => 'the ID of the availablility zone for the virtual machine',
        'zonename'     => 'the name of the availability zone for the virtual machine',
      },
      section => 'VM',
    },
    updateAccount => {
      description => 'Updates account information for the authenticated user',
      isAsync     => 'false',
      level       => 3,
      request     => {
        optional => { networkdomain => 'Network domain for the account\'s networks' },
        required => {
          account  => 'the current account name',
          domainid => 'the ID of the domain where the account exists',
          newname  => 'new name for the account',
        },
      },
      response => {
        'accounttype'       => 'account type (admin, domain-admin, user)',
        'domain'            => 'name of the Domain the account belongs too',
        'domainid'          => 'id of the Domain the account belongs too',
        'id'                => 'the id of the account',
        'ipavailable'       => 'the total number of public ip addresses available for this account to acquire',
        'iplimit'           => 'the total number of public ip addresses this account can acquire',
        'iptotal'           => 'the total number of public ip addresses allocated for this account',
        'iscleanuprequired' => 'true if the account requires cleanup',
        'name'              => 'the name of the account',
        'networkdomain'     => 'the network domain',
        'receivedbytes'     => 'the total number of network traffic bytes received',
        'sentbytes'         => 'the total number of network traffic bytes sent',
        'snapshotavailable' => 'the total number of snapshots available for this account',
        'snapshotlimit'     => 'the total number of snapshots which can be stored by this account',
        'snapshottotal'     => 'the total number of snapshots stored by this account',
        'state'             => 'the state of the account',
        'templateavailable' => 'the total number of templates available to be created by this account',
        'templatelimit'     => 'the total number of templates which can be created by this account',
        'templatetotal'     => 'the total number of templates which have been created by this account',
        'user(*)'           => 'the list of users associated with account',
        'vmavailable'       => 'the total number of virtual machines available for this account to acquire',
        'vmlimit'           => 'the total number of virtual machines that can be deployed by this account',
        'vmrunning'         => 'the total number of virtual machines running for this account',
        'vmstopped'         => 'the total number of virtual machines stopped for this account',
        'vmtotal'           => 'the total number of virtual machines deployed by this account',
        'volumeavailable'   => 'the total volume available for this account',
        'volumelimit'       => 'the total volume which can be used by this account',
        'volumetotal'       => 'the total volume being used by this account',
      },
      section => 'Account',
    },
    updateCluster => {
      description => 'Updates an existing cluster',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          allocationstate => 'Allocation state of this cluster for allocation of new resources',
          clustername     => 'the cluster name',
          clustertype     => 'hypervisor type of the cluster',
          hypervisor      => 'hypervisor type of the cluster',
          managedstate    => 'whether this cluster is managed by cloudstack',
        },
        required => { id => 'the ID of the Cluster' },
      },
      response => {
        allocationstate => 'the allocation state of the cluster',
        clustertype     => 'the type of the cluster',
        hypervisortype  => 'the hypervisor type of the cluster',
        id              => 'the cluster ID',
        managedstate    => 'whether this cluster is managed by cloudstack',
        name            => 'the cluster name',
        podid           => 'the Pod ID of the cluster',
        podname         => 'the Pod name of the cluster',
        zoneid          => 'the Zone ID of the cluster',
        zonename        => 'the Zone name of the cluster',
      },
      section => 'Host',
    },
    updateConfiguration => {
      description => 'Updates a configuration.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => { value => 'the value of the configuration' },
        required => { name  => 'the name of the configuration' },
      },
      response => {
        category    => 'the category of the configuration',
        description => 'the description of the configuration',
        name        => 'the name of the configuration',
        value       => 'the value of the configuration',
      },
      section => 'Configuration',
    },
    updateDiskOffering => {
      description => 'Updates a disk offering.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          displaytext => 'updates alternate display text of the disk offering with this value',
          name        => 'updates name of the disk offering with this value',
        },
        required => { id => 'ID of the disk offering' },
      },
      response => {
        created     => 'the date this disk offering was created',
        disksize    => 'the size of the disk offering in GB',
        displaytext => 'an alternate display text of the disk offering.',
        domain =>
            'the domain name this disk offering belongs to. Ignore this information as it is not currently applicable.',
        domainid =>
            'the domain ID this disk offering belongs to. Ignore this information as it is not currently applicable.',
        id           => 'unique ID of the disk offering',
        iscustomized => 'true if disk offering uses custom size, false otherwise',
        name         => 'the name of the disk offering',
        tags         => 'the tags for the disk offering',
      },
      section => 'DiskOffering',
    },
    updateDomain => {
      description => 'Updates a domain with a new name',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional =>
            { name => 'updates domain with this name', networkdomain => 'Network domain for the domain\'s networks', },
        required => { id => 'ID of domain to update' },
      },
      response => {
        haschild         => 'whether the domain has one or more sub-domains',
        id               => 'the ID of the domain',
        level            => 'the level of the domain',
        name             => 'the name of the domain',
        networkdomain    => 'the network domain',
        parentdomainid   => 'the domain ID of the parent domain',
        parentdomainname => 'the domain name of the parent domain',
        path             => 'the path of the domain',
      },
      section => 'Domain',
    },
    updateHost => {
      description => 'Updates a host.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          allocationstate => 'Allocation state of this Host for allocation of new resources',
          hosttags        => 'list of tags to be added to the host',
          oscategoryid    => 'the id of Os category to update the host with',
        },
        required => { id => 'the ID of the host to update' },
      },
      response => {
        allocationstate         => 'the allocation state of the host',
        averageload             => 'the cpu average load on the host',
        capabilities            => 'capabilities of the host',
        clusterid               => 'the cluster ID of the host',
        clustername             => 'the cluster name of the host',
        clustertype             => 'the cluster type of the cluster that host belongs to',
        cpuallocated            => 'the amount of the host\'s CPU currently allocated',
        cpunumber               => 'the CPU number of the host',
        cpuspeed                => 'the CPU speed of the host',
        cpuused                 => 'the amount of the host\'s CPU currently used',
        cpuwithoverprovisioning => 'the amount of the host\'s CPU after applying the cpu.overprovisioning.factor',
        created                 => 'the date and time the host was created',
        disconnected            => 'true if the host is disconnected. False otherwise.',
        disksizeallocated       => 'the host\'s currently allocated disk size',
        disksizetotal           => 'the total disk size of the host',
        events                  => 'events available for the host',
        hasEnoughCapacity => 'true if this host has enough CPU and RAM capacity to migrate a VM to it, false otherwise',
        hosttags          => 'comma-separated list of tags for the host',
        hypervisor        => 'the host hypervisor',
        id                => 'the ID of the host',
        ipaddress         => 'the IP address of the host',
        islocalstorageactive => 'true if local storage is active, false otherwise',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the host',
        jobstatus          => 'shows the current pending asynchronous job status',
        lastpinged         => 'the date and time the host was last pinged',
        managementserverid => 'the management server ID of the host',
        memoryallocated    => 'the amount of the host\'s memory currently allocated',
        memorytotal        => 'the memory total of the host',
        memoryused         => 'the amount of the host\'s memory currently used',
        name               => 'the name of the host',
        networkkbsread     => 'the incoming network traffic on the host',
        networkkbswrite    => 'the outgoing network traffic on the host',
        oscategoryid       => 'the OS category ID of the host',
        oscategoryname     => 'the OS category name of the host',
        podid              => 'the Pod ID of the host',
        podname            => 'the Pod name of the host',
        removed            => 'the date and time the host was removed',
        state              => 'the state of the host',
        type               => 'the host type',
        version            => 'the host version',
        zoneid             => 'the Zone ID of the host',
        zonename           => 'the Zone name of the host',
      },
      section => 'Host',
    },
    updateHostPassword => {
      description => 'Update password of a host/pool on management server.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          clusterid => 'the cluster ID. Either this parameter, or hostId has to be passed in',
          hostid    => 'the host ID. Either this parameter, or clusterId has to be passed in',
        },
        required =>
            { password => 'the new password for the host/cluster', username => 'the username for the host/cluster', },
      },
      response => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'Host',
    },
    updateInstanceGroup => {
      description => 'Updates a vm group',
      isAsync     => 'false',
      level       => 15,
      request     => { optional => { name => 'new instance group name' }, required => { id => 'Instance group ID' }, },
      response    => {
        account  => 'the account owning the instance group',
        created  => 'time and date the instance group was created',
        domain   => 'the domain name of the instance group',
        domainid => 'the domain ID of the instance group',
        id       => 'the id of the instance group',
        name     => 'the name of the instance group',
      },
      section => 'VMGroup',
    },
    updateIso => {
      description => 'Updates an ISO file.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          bootable        => 'true if image is bootable, false otherwise',
          displaytext     => 'the display text of the image',
          format          => 'the format for the image',
          name            => 'the name of the image file',
          ostypeid        => 'the ID of the OS type that best represents the OS of this image.',
          passwordenabled => 'true if the image supports the password reset feature; default is false',
        },
        required => { id => 'the ID of the image file' },
      },
      response => {
        account       => 'the account name to which the template belongs',
        accountid     => 'the account id to which the template belongs',
        bootable      => 'true if the ISO is bootable, false otherwise',
        checksum      => 'checksum of the template',
        created       => 'the date this template was created',
        crossZones    => 'true if the template is managed across all Zones, false otherwise',
        details       => 'additional key/value details tied with template',
        displaytext   => 'the template display text',
        domain        => 'the name of the domain to which the template belongs',
        domainid      => 'the ID of the domain to which the template belongs',
        format        => 'the format of the template.',
        hostid        => 'the ID of the secondary storage host for the template',
        hostname      => 'the name of the secondary storage host for the template',
        hypervisor    => 'the hypervisor on which the template runs',
        id            => 'the template ID',
        isextractable => 'true if the template is extractable, false otherwise',
        isfeatured    => 'true if this template is a featured template, false otherwise',
        ispublic      => 'true if this template is a public template, false otherwise',
        isready       => 'true if the template is ready to be deployed from, false otherwise.',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template',
        jobstatus        => 'shows the current pending asynchronous job status',
        name             => 'the template name',
        ostypeid         => 'the ID of the OS type for this template.',
        ostypename       => 'the name of the OS type for this template.',
        passwordenabled  => 'true if the reset password feature is enabled, false otherwise',
        removed          => 'the date this template was removed',
        size             => 'the size of the template',
        sourcetemplateid => 'the template ID of the parent template if present',
        status           => 'the status of the template',
        templatetag      => 'the tag of this template',
        templatetype     => 'the type of the template',
        zoneid           => 'the ID of the zone for this template',
        zonename         => 'the name of the zone for this template',
      },
      section => 'ISO',
    },
    updateIsoPermissions => {
      description => 'Updates iso permissions',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          accounts      => 'a comma delimited list of accounts. If specified, \'op\' parameter has to be passed in.',
          isextractable => 'true if the template/iso is extractable, false other wise. Can be set only by root admin',
          isfeatured    => 'true for featured template/iso, false otherwise',
          ispublic      => 'true for public template/iso, false for private templates/isos',
          op            => 'permission operator (add, remove, reset)',
        },
        required => { id => 'the template ID' },
      },
      response => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'ISO',
    },
    updateLoadBalancerRule => {
      description => 'Updates load balancer',
      isAsync     => 'true',
      level       => 15,
      request     => {
        optional => {
          algorithm   => 'load balancer algorithm (source, roundrobin, leastconn)',
          description => 'the description of the load balancer rule',
          name        => 'the name of the load balancer rule',
        },
        required => { id => 'the id of the load balancer rule to update' },
      },
      response => {
        account     => 'the account of the load balancer rule',
        algorithm   => 'the load balancer algorithm (source, roundrobin, leastconn)',
        cidrlist    => 'the cidr list to forward traffic from',
        description => 'the description of the load balancer',
        domain      => 'the domain of the load balancer rule',
        domainid    => 'the domain ID of the load balancer rule',
        id          => 'the load balancer rule ID',
        name        => 'the name of the load balancer',
        privateport => 'the private port',
        publicip    => 'the public ip address',
        publicipid  => 'the public ip address id',
        publicport  => 'the public port',
        state       => 'the state of the rule',
        zoneid      => 'the id of the zone the rule belongs to',
      },
      section => 'LoadBalancer',
    },
    updateNetwork => {
      description => 'Updates a network',
      isAsync     => 'true',
      level       => 15,
      request     => {
        optional => {
          displaytext   => 'the new display text for the network',
          name          => 'the new name for the network',
          networkdomain => 'network domain',
          tags          => 'tags for the network',
        },
        required => { id => 'the ID of the network' },
      },
      response => {
        'account'                     => 'the owner of the network',
        'broadcastdomaintype'         => 'Broadcast domain type of the network',
        'broadcasturi'                => 'broadcast uri of the network',
        'displaytext'                 => 'the displaytext of the network',
        'dns1'                        => 'the first DNS for the network',
        'dns2'                        => 'the second DNS for the network',
        'domain'                      => 'the domain name of the network owner',
        'domainid'                    => 'the domain id of the network owner',
        'endip'                       => 'the end ip of the network',
        'gateway'                     => 'the network\'s gateway',
        'id'                          => 'the id of the network',
        'isdefault'                   => 'true if network is default, false otherwise',
        'isshared'                    => 'true if network is shared, false otherwise',
        'issystem'                    => 'true if network is system, false otherwise',
        'name'                        => 'the name of the network',
        'netmask'                     => 'the network\'s netmask',
        'networkdomain'               => 'the network domain',
        'networkofferingavailability' => 'availability of the network offering the network is created from',
        'networkofferingdisplaytext'  => 'display text of the network offering the network is created from',
        'networkofferingid'           => 'network offering id the network is created from',
        'networkofferingname'         => 'name of the network offering the network is created from',
        'related'                     => 'related to what other network configuration',
        'securitygroupenabled'        => 'true if security group is enabled, false otherwise',
        'service(*)'                  => 'the list of services',
        'startip'                     => 'the start ip of the network',
        'state'                       => 'state of the network',
        'tags'                        => 'comma separated tag',
        'traffictype'                 => 'the traffic type of the network',
        'type'                        => 'the type of the network',
        'vlan'                        => 'the vlan of the network',
        'zoneid'                      => 'zone id of the network',
      },
      section => 'Network',
    },
    updateNetworkOffering => {
      description => 'Updates a network offering.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          availability =>
              'the availability of network offering. Default value is Required for Guest Virtual network offering; Optional for Guest Direct network offering',
          displaytext => 'the display text of the network offering',
          id          => 'the id of the network offering',
          name        => 'the name of the network offering',
        },
      },
      response => {
        availability   => 'availability of the network offering',
        created        => 'the date this network offering was created',
        displaytext    => 'an alternate display text of the network offering.',
        guestiptype    => 'guest ip type of the network offering',
        id             => 'the id of the network offering',
        isdefault      => 'true if network offering is default, false otherwise',
        maxconnections => 'the max number of concurrent connection the network offering supports',
        name           => 'the name of the network offering',
        networkrate    => 'data transfer rate in megabits per second allowed.',
        specifyvlan    => 'true if network offering supports vlans, false otherwise',
        tags           => 'the tags for the network offering',
        traffictype =>
            'the traffic type for the network offering, supported types are Public, Management, Control, Guest, Vlan or Storage.',
      },
      section => 'NetworkOffering',
    },
    updatePod => {
      description => 'Updates a Pod.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          allocationstate => 'Allocation state of this cluster for allocation of new resources',
          endip           => 'the ending IP address for the Pod',
          gateway         => 'the gateway for the Pod',
          name            => 'the name of the Pod',
          netmask         => 'the netmask of the Pod',
          startip         => 'the starting IP address for the Pod',
        },
        required => { id => 'the ID of the Pod' },
      },
      response => {
        allocationstate => 'the allocation state of the cluster',
        endip           => 'the ending IP for the Pod',
        gateway         => 'the gateway of the Pod',
        id              => 'the ID of the Pod',
        name            => 'the name of the Pod',
        netmask         => 'the netmask of the Pod',
        startip         => 'the starting IP for the Pod',
        zoneid          => 'the Zone ID of the Pod',
        zonename        => 'the Zone name of the Pod',
      },
      section => 'Pod',
    },
    updateResourceCount => {
      description => 'Recalculate and update resource count for an account or domain.',
      isAsync     => 'false',
      level       => 7,
      request     => {
        optional => {
          account => 'Update resource count for a specified account. Must be used with the domainId parameter.',
          resourcetype =>
              'Type of resource to update. If specifies valid values are 0, 1, 2, 3, and 4. If not specified will update all resource counts0 - Instance. Number of instances a user can create. 1 - IP. Number of public IP addresses a user can own. 2 - Volume. Number of disk volumes a user can create.3 - Snapshot. Number of snapshots a user can create.4 - Template. Number of templates that a user can register/create.',
        },
        required => {
          domainid =>
              'If account parameter specified then updates resource counts for a specified account in this domain else update resource counts for all accounts & child domains in specified domain.',
        },
      },
      response => {
        account       => 'the account for which resource count\'s are updated',
        domain        => 'the domain name for which resource count\'s are updated',
        domainid      => 'the domain ID for which resource count\'s are updated',
        resourcecount => 'resource count',
        resourcetype =>
            'resource type. Values include 0, 1, 2, 3, 4. See the resourceType parameter for more information on these values.',
      },
      section => 'Limit',
    },
    updateResourceLimit => {
      description => 'Updates resource limits for an account or domain.',
      isAsync     => 'false',
      level       => 7,
      request     => {
        optional => {
          account => 'Update resource for a specified account. Must be used with the domainId parameter.',
          domainid =>
              'Update resource limits for all accounts in specified domain. If used with the account parameter, updates resource limits for a specified account in specified domain.',
          max => 'Maximum resource limit.',
        },
        required => {
          resourcetype =>
              'Type of resource to update. Values are 0, 1, 2, 3, and 4. 0 - Instance. Number of instances a user can create. 1 - IP. Number of public IP addresses a user can own. 2 - Volume. Number of disk volumes a user can create.3 - Snapshot. Number of snapshots a user can create.4 - Template. Number of templates that a user can register/create.',
        },
      },
      response => {
        account  => 'the account of the resource limit',
        domain   => 'the domain name of the resource limit',
        domainid => 'the domain ID of the resource limit',
        max      => 'the maximum number of the resource. A -1 means the resource currently has no limit.',
        resourcetype =>
            'resource type. Values include 0, 1, 2, 3, 4. See the resourceType parameter for more information on these values.',
      },
      section => 'Limit',
    },
    updateServiceOffering => {
      description => 'Updates a service offering.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          displaytext => 'the display text of the service offering to be updated',
          name        => 'the name of the service offering to be updated',
        },
        required => { id => 'the ID of the service offering to be updated' },
      },
      response => {
        cpunumber    => 'the number of CPU',
        cpuspeed     => 'the clock rate CPU speed in Mhz',
        created      => 'the date this service offering was created',
        defaultuse   => 'is this a  default system vm offering',
        displaytext  => 'an alternate display text of the service offering.',
        domain       => 'Domain name for the offering',
        domainid     => 'the domain id of the service offering',
        hosttags     => 'the host tag for the service offering',
        id           => 'the id of the service offering',
        issystem     => 'is this a system vm offering',
        limitcpuuse  => 'restrict the CPU usage to committed service offering',
        memory       => 'the memory in MB',
        name         => 'the name of the service offering',
        networkrate  => 'data transfer rate in megabits per second allowed.',
        offerha      => 'the ha support in the service offering',
        storagetype  => 'the storage type for this service offering',
        systemvmtype => 'is this a the systemvm type for system vm offering',
        tags         => 'the tags for the service offering',
      },
      section => 'ServiceOffering',
    },
    updateTemplate => {
      description => 'Updates attributes of a template.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          bootable        => 'true if image is bootable, false otherwise',
          displaytext     => 'the display text of the image',
          format          => 'the format for the image',
          name            => 'the name of the image file',
          ostypeid        => 'the ID of the OS type that best represents the OS of this image.',
          passwordenabled => 'true if the image supports the password reset feature; default is false',
        },
        required => { id => 'the ID of the image file' },
      },
      response => {
        account       => 'the account name to which the template belongs',
        accountid     => 'the account id to which the template belongs',
        bootable      => 'true if the ISO is bootable, false otherwise',
        checksum      => 'checksum of the template',
        created       => 'the date this template was created',
        crossZones    => 'true if the template is managed across all Zones, false otherwise',
        details       => 'additional key/value details tied with template',
        displaytext   => 'the template display text',
        domain        => 'the name of the domain to which the template belongs',
        domainid      => 'the ID of the domain to which the template belongs',
        format        => 'the format of the template.',
        hostid        => 'the ID of the secondary storage host for the template',
        hostname      => 'the name of the secondary storage host for the template',
        hypervisor    => 'the hypervisor on which the template runs',
        id            => 'the template ID',
        isextractable => 'true if the template is extractable, false otherwise',
        isfeatured    => 'true if this template is a featured template, false otherwise',
        ispublic      => 'true if this template is a public template, false otherwise',
        isready       => 'true if the template is ready to be deployed from, false otherwise.',
        jobid =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template',
        jobstatus        => 'shows the current pending asynchronous job status',
        name             => 'the template name',
        ostypeid         => 'the ID of the OS type for this template.',
        ostypename       => 'the name of the OS type for this template.',
        passwordenabled  => 'true if the reset password feature is enabled, false otherwise',
        removed          => 'the date this template was removed',
        size             => 'the size of the template',
        sourcetemplateid => 'the template ID of the parent template if present',
        status           => 'the status of the template',
        templatetag      => 'the tag of this template',
        templatetype     => 'the type of the template',
        zoneid           => 'the ID of the zone for this template',
        zonename         => 'the name of the zone for this template',
      },
      section => 'Template',
    },
    updateTemplatePermissions => {
      description =>
          'Updates a template visibility permissions. A public template is visible to all accounts within the same domain. A private template is visible only to the owner of the template. A priviledged template is a private template with account permissions added. Only accounts specified under the template permissions are visible to them.',
      isAsync => 'false',
      level   => 15,
      request => {
        optional => {
          accounts      => 'a comma delimited list of accounts. If specified, \'op\' parameter has to be passed in.',
          isextractable => 'true if the template/iso is extractable, false other wise. Can be set only by root admin',
          isfeatured    => 'true for featured template/iso, false otherwise',
          ispublic      => 'true for public template/iso, false for private templates/isos',
          op            => 'permission operator (add, remove, reset)',
        },
        required => { id => 'the template ID' },
      },
      response => {
        displaytext => 'any text associated with the success or failure',
        success     => 'true if operation is executed successfully',
      },
      section => 'Template',
    },
    updateUser => {
      description => 'Updates a user account',
      isAsync     => 'false',
      level       => 3,
      request     => {
        optional => {
          email     => 'email',
          firstname => 'first name',
          lastname  => 'last name',
          password =>
              'Hashed password (default is MD5). If you wish to use any other hasing algorithm, you would need to write a custom authentication adapter',
          timezone =>
              'Specifies a timezone for this command. For more information on the timezone parameter, see Time Zone Format.',
          userapikey    => 'The API key for the user. Must be specified with userSecretKey',
          username      => 'Unique username',
          usersecretkey => 'The secret key for the user. Must be specified with userApiKey',
        },
        required => { id => 'User id' },
      },
      response => {
        account     => 'the account name of the user',
        accounttype => 'the account type of the user',
        apikey      => 'the api key of the user',
        created     => 'the date and time the user account was created',
        domain      => 'the domain name of the user',
        domainid    => 'the domain ID of the user',
        email       => 'the user email address',
        firstname   => 'the user firstname',
        id          => 'the user ID',
        lastname    => 'the user lastname',
        secretkey   => 'the secret key of the user',
        state       => 'the user state',
        timezone    => 'the timezone user was created in',
        username    => 'the user name',
      },
      section => 'User',
    },
    updateVirtualMachine => {
      description => 'Updates parameters of a virtual machine.',
      isAsync     => 'false',
      level       => 15,
      request     => {
        optional => {
          displayname => 'user generated name',
          group       => 'group of the virtual machine',
          haenable    => 'true if high-availability is enabled for the virtual machine, false otherwise',
          ostypeid    => 'the ID of the OS type that best represents this VM.',
          userdata =>
              'an optional binary data that can be sent to the virtual machine upon a successful deployment. This binary data must be base64 encoded before adding it to the request. Currently only HTTP GET is supported. Using HTTP GET (via querystring), you can send up to 2KB of data after base64 encoding.',
        },
        required => { id => 'The ID of the virtual machine' },
      },
      response => {
        'account'     => 'the account associated with the virtual machine',
        'cpunumber'   => 'the number of cpu this virtual machine is running with',
        'cpuspeed'    => 'the speed of each cpu',
        'cpuused'     => 'the amount of the vm\'s CPU currently used',
        'created'     => 'the date when this virtual machine was created',
        'displayname' => 'user generated name. The name of the virtual machine is returned if no displayname exists.',
        'domain'      => 'the name of the domain in which the virtual machine exists',
        'domainid'    => 'the ID of the domain in which the virtual machine exists',
        'forvirtualnetwork' => 'the virtual network for the service offering',
        'group'             => 'the group name of the virtual machine',
        'groupid'           => 'the group ID of the virtual machine',
        'guestosid'         => 'Os type ID of the virtual machine',
        'haenable'          => 'true if high-availability is enabled, false otherwise',
        'hostid'            => 'the ID of the host for the virtual machine',
        'hostname'          => 'the name of the host for the virtual machine',
        'hypervisor'        => 'the hypervisor on which the template runs',
        'id'                => 'the ID of the virtual machine',
        'ipaddress'         => 'the ip address of the virtual machine',
        'isodisplaytext'    => 'an alternate display text of the ISO attached to the virtual machine',
        'isoid'             => 'the ID of the ISO attached to the virtual machine',
        'isoname'           => 'the name of the ISO attached to the virtual machine',
        'jobid' =>
            'shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine',
        'jobstatus'           => 'shows the current pending asynchronous job status',
        'memory'              => 'the memory allocated for the virtual machine',
        'name'                => 'the name of the virtual machine',
        'networkkbsread'      => 'the incoming network traffic on the vm',
        'networkkbswrite'     => 'the outgoing network traffic on the host',
        'nic(*)'              => 'the list of nics associated with vm',
        'password'            => 'the password (if exists) of the virtual machine',
        'passwordenabled'     => 'true if the password rest feature is enabled, false otherwise',
        'rootdeviceid'        => 'device ID of the root volume',
        'rootdevicetype'      => 'device type of the root volume',
        'securitygroup(*)'    => 'list of security groups associated with the virtual machine',
        'serviceofferingid'   => 'the ID of the service offering of the virtual machine',
        'serviceofferingname' => 'the name of the service offering of the virtual machine',
        'state'               => 'the state of the virtual machine',
        'templatedisplaytext' => 'an alternate display text of the template for the virtual machine',
        'templateid' =>
            'the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.',
        'templatename' => 'the name of the template for the virtual machine',
        'zoneid'       => 'the ID of the availablility zone for the virtual machine',
        'zonename'     => 'the name of the availability zone for the virtual machine',
      },
      section => 'VM',
    },
    updateZone => {
      description => 'Updates a Zone.',
      isAsync     => 'false',
      level       => 1,
      request     => {
        optional => {
          allocationstate  => 'Allocation state of this cluster for allocation of new resources',
          details          => 'the details for the Zone',
          dhcpprovider     => 'the dhcp Provider for the Zone',
          dns1             => 'the first DNS for the Zone',
          dns2             => 'the second DNS for the Zone',
          dnssearchorder   => 'the dns search order list',
          domain           => 'Network domain name for the networks in the zone',
          guestcidraddress => 'the guest CIDR address for the Zone',
          internaldns1     => 'the first internal DNS for the Zone',
          internaldns2     => 'the second internal DNS for the Zone',
          ispublic         => 'updates a private zone to public if set, but not vice-versa',
          name             => 'the name of the Zone',
          vlan             => 'the VLAN for the Zone',
        },
        required => { id => 'the ID of the Zone' },
      },
      response => {
        allocationstate       => 'the allocation state of the cluster',
        description           => 'Zone description',
        dhcpprovider          => 'the dhcp Provider for the Zone',
        displaytext           => 'the display text of the zone',
        dns1                  => 'the first DNS for the Zone',
        dns2                  => 'the second DNS for the Zone',
        domain                => 'Network domain name for the networks in the zone',
        domainid              => 'the ID of the containing domain, null for public zones',
        guestcidraddress      => 'the guest CIDR address for the Zone',
        id                    => 'Zone id',
        internaldns1          => 'the first internal DNS for the Zone',
        internaldns2          => 'the second internal DNS for the Zone',
        name                  => 'Zone name',
        networktype           => 'the network type of the zone; can be Basic or Advanced',
        securitygroupsenabled => 'true if security groups support is enabled, false otherwise',
        vlan                  => 'the vlan range of the zone',
        zonetoken             => 'Zone Token',
      },
      section => 'Zone',
    },
    uploadCustomCertificate => {
      description => 'Uploads custom certificate',
      isAsync     => 'true',
      level       => 1,
      request     => {
        optional => {
          id         => 'the custom cert id in the chain',
          name       => 'the alias of the certificate',
          privatekey => 'the private key for the certificate',
        },
        required => {
          certificate  => 'the custom cert to be uploaded',
          domainsuffix => 'DNS domain suffix that the certificate is granted for',
        },
      },
      response => { message => 'message of the certificate upload operation' },
      section  => 'Certificate',
    },
  };

##############################################################################
  # Setup exports

  my ( $exports, $groups, @all );

  for my $cmd ( keys %$command ) { ## no critic qw( References::ProhibitDoubleSigils )

    $exports->{ $cmd } = \&_generate_method;
    push @{ $groups->{ $command->{ $cmd }{ section } } }, $cmd;
    push @all, $cmd;

  }

  $groups->{ all } = \@all;

  my $config = {

    exports => $exports,
    groups  => $groups,

  };

  Sub::Exporter::setup_exporter( $config );

##############################################################################
  # Setup OO interface

  # handle either a list of elements or a hashref

  sub new { ## no critic qw( Subroutines::RequireArgUnpacking )
    return bless {}, ref $_[0] || $_[0];
  }

  our $AUTOLOAD;

  sub AUTOLOAD { ## no critic qw( Subroutines::RequireArgUnpacking )

    my $self = $_[0];

    ( my $method = $AUTOLOAD ) =~ s/^.*:://;

    croak "unknown method $method"
        unless exists $command->{ $method };

    no strict 'refs'; ## no critic qw( TestingAndDebugging::ProhibitNoStrict )
    *$AUTOLOAD = $self->_generate_method( $method ); ## no critic qw( References::ProhibitDoubleSigils )

    goto &$AUTOLOAD; ## no critic qw( References::ProhibitDoubleSigils )

  }

  sub DESTROY { }

##############################################################################
  # Utility methods

  sub _generate_method {

    my ( undef, $cmd ) = @_;

    croak "Unknown method: $cmd"
        unless exists $command->{ $cmd };

    # FIXME: allow caller to pass in their own validation structures.
    # FIXME: more robust handling of at least the obvious data types.
    my %validate;

    # Only build this part of the hash once ...
    $validate{ spec }{ $_ } = { type => SCALAR } for keys %{ $command->{ $cmd }{ request }{ required } };
    $validate{ spec }{ $_ } = { type => SCALAR, optional => 1 } for keys %{ $command->{ $cmd }{ request }{ optional } };

    return sub {

      my $self = '';
      $self = shift
          if blessed $_[0];

      $validate{ params } = \@_;

      my %arg;
      %arg = validate_with( %validate )
          if keys %{ $validate{ spec } };

      my @proc = $cmd;

      if ( keys %arg ) {

        push @proc, join q{&}, map { "$_=$arg{$_}" } keys %arg;

      }

      my $api = blessed $self ? $self->api : api();

      $api->proc( @proc );

      return $api->send_request eq 'yes' ? $api->response : $api->url;

    };
  } ## end sub _generate_method

  {  # Hide api stuff

    my $api;

    sub api { ## no critic qw( Subroutines::RequireArgUnpacking )

      if ( ! @_ || ( @_ == 1 && blessed $_[0] eq __PACKAGE__ ) ) {

        croak 'api not setup correctly'
            unless defined $api && blessed $api eq 'Net::CloudStack';

        return $api;

      }

      my $args
          = ( $_[0] eq __PACKAGE__ || blessed $_[0] eq __PACKAGE__ )
          ? $_[1]
          : $_[0];

      croak 'args must be a hashref'
          if ref $args && ref $args ne 'HASH';

      $api = Net::CloudStack->new( $args )
          if ! defined $api || blessed $api ne 'Net::CloudStack';

      return $api
          unless ref $args;

      $api->$_( $args->{ $_ } ) for keys %$args; ## no critic qw( References::ProhibitDoubleSigils )

      return $api;

    } ## end sub api
  }  # End hiding api stuff

}  # End general hiding

1;

__END__
=pod

=encoding utf-8

=for :stopwords Alan Young API Allocatin AsyncQuery BackedUp BackingUp BareMetal CIDR CIFS
CloudIdentifier CloudManaged CloudStack DATADISK DNS Destroyes DiskOffering
ExternalDhcp ExternalFirewall ExternalLoadBalancer ExternalManaged FIXME
GuestOS HVM Hyperv Hypervisor ICMP IP IPAddress IQN ISOs Ip JSESSIONID KVM
LUN LoadBalancer Mhz NetAppIntegration NetworkDevices NetworkOffering
PxeServer QCOW SSHKeyPair SecurityGroup ServiceOffering StoragePools
SystemCapacity SystemVM TCP TrafficMonitor UDP UI UTC Username VHD VID VLAN
VM VMGroup VMs VMware VPN Vlan Vm XenServer accountName accountid
accounttype activeviewersessions addCluster addExternalFirewall
addExternalLoadBalancer addHost addNetworkDevice addSecondaryStorage
addTrafficMonitor addVpnUser aggregatename allocatedonly allocationstate
api apikey assignToLoadBalancerRule assigneddate associateIp
associateIpAddress associateLun associatednetworkid asychronous async
attachIso attachVolume attahed authorizeSecurityGroupIngress availablility
averageload balancer baremetal belongig boolean bootable
broadcastdomaintype broadcasturi cancelHostMaintenance
cancelStorageMaintenance capacitytotal capacityused changeServiceForRouter
changeServiceForVirtualMachine checksum cidr cidrlist cleanuprequred
cloudidentifier cloudstack cloudstackversion clusterId clusterid
clustername clustertype cmd consoleproxy copyIso copyTemplate count's cpu
cpuallocated cpunumber cpuspeed cpuused cpuwithoverprovisioning
createAccount createConfiguration createDiskOffering createDomain
createFirewallRule createInstanceGroup createIpForwardingRule
createLoadBalancerRule createLunOnFiler createNetwork createPod createPool
createPortForwardingRule createRemoteAccessVpn createSSHKeyPair
createSecurityGroup createServiceOffering createSnapshot
createSnapshotPolicy createStoragePool createTemplate createUser
createVlanIpRange createVolume createVolumeOnFiler createZone crossZones
defaultuse deleteAccount deleteCluster deleteDiskOffering deleteDomain
deleteExternalFirewall deleteExternalLoadBalancer deleteFirewallRule
deleteHost deleteInstanceGroup deleteIpForwardingRule deleteIso
deleteLoadBalancerRule deleteNetwork deleteNetworkDevice deletePod
deletePool deletePortForwardingRule deleteRemoteAccessVpn deleteSSHKeyPair
deleteSecurityGroup deleteServiceOffering deleteSnapshot
deleteSnapshotPolicies deleteStoragePool deleteTemplate
deleteTrafficMonitor deleteUser deleteVlanIpRange deleteVolume deleteZone
deployVirtualMachine destroyLunOnFiler destroyRouter destroySystemVm
destroyVirtualMachine destroyVolumeOnFiler destzoneid detachIso
detachVolume deviceId deviceid dhcp dhcpprovider disableAccount
disableStaticNat disableUser disableed disassociateIpAddress diskOfferingId
diskofferingdisplaytext diskofferingid diskofferingname disksize
disksizeallocated disksizetotal displayname displaytext dissociateLun dns
dnssearchorder domainID domainId domainid domainname domainrouter
domainsuffix enableAccount enableStaticNat enableStorageMaintenance
enableUser encryptedpassword enddate endip endport entrytime explicitely
extractId extractIso extractMode extractTemplate extractVolume
firewallRuleUiEnabled firstname firwall forcedestroylocalstorage
forloadbalancing forvirtualnetwork fowarding generateUsageRecords
getCloudIdentifier getVMPassword groupid guestcidraddress guestipaddress
guestiptype guestmacaddress guestnetmask guestnetworkid guestosid haenable
hasEnoughCapacity haschild hasing hostId hostid hostname hosttags
hypervisor hypervisors hypervisortype icmp icmpcode icmptype inline
internaldns intervaltype ip ipToNetworkList ipaddress ipaddressid
ipavailable iplimit iprange ips ipsec iptonetworklist iptotal iqn
iscleanuprequired iscustomized isdefault isextractable isfeatured
islocalstorageactive iso isodisplaytext isofilter isoid isoname isos
ispublic isready isrecursive isredundantrouter isshared issourcenat
isstaticnat issystem jobid jobinstanceid jobinstancetype jobltcode
jobprocstatus jobresult jobresultcode jobresulttype jobstatus keypair
keypairs lastname lastpinged leastconn limitcpuuse linklocalip
linklocalmacaddress linklocalnetmask linklocalnetworkid listAccounts
listAlerts listAsyncJobs listCapabilities listCapacity listClusters
listConfigurations listDiskOfferings listDomainChildren listDomains
listEventTypes listEvents listExternalFirewalls listExternalLoadBalancers
listFirewallRules listHosts listHypervisors listInstanceGroups
listIpForwardingRules listIsoPermissions listIsos
listLoadBalancerRuleInstances listLoadBalancerRules listLunsOnFiler
listNetworkDevice listNetworkOfferings listNetworks listOsCategories
listOsTypes listPods listPools listPortForwardingRules
listPublicIpAddresses listRemoteAccessVpns listResourceLimits listRouters
listSSHKeyPairs listSecurityGroups listServiceOfferings
listSnapshotPolicies listSnapshots listStoragePools listSystemVms
listTemplatePermissions listTemplates listTrafficMonitors listUsageRecords
listUsers listVirtualMachines listVlanIpRanges listVolumes
listVolumesOnFiler listVpnUsers listZones loadbalancer login logout lun
managedstate managementserverid maxconnections maxsnaps memoryallocated
memorytotal memoryused migrateSystemVm migrateVirtualMachine modifyPool
monthy nat netmask netowrk networkIds networkdeviceparameterlist
networkdevicetype networkdomain networkid networkids networkkbsread
networkkbswrite networkofferingavailability networkofferingdisplaytext
networkofferingid networkofferingname networkrate networktype newname nics
numretries offerha offeringid ommited openfirewall oscategoryid
oscategoryname ostypeid ostypename pagesize parentdomainid parentdomainname
parentid passwordenabled percentused podid podname policyid poolname
prepareHostForMaintenance prepareTemplate preshared presharedkey
privateendport privateinterface privateip privatekey privatemacaddress
privatenetmask privateport privatezone priviledged publicendport
publicinterface publicip publicipid publickey publicmacaddress
publicnetmask publicnetworkid publicport publicself publiczone
queryAsyncJobResult querystring rawusage rebootRouter rebootSystemVm
rebootVirtualMachine receivedbytes reconnectHost recoverVirtualMachine
redundantstate registerIso registerSSHKeyPair registerTemplate
registerUserKeys releaseddate removeFromLoadBalancerRule removeVpnUser
requireshvm requres resetPasswordForVirtualMachine resourceType
resourcecount resourcetype restartNetwork revokeSecurityGroupIngress
rootdeviceid rootdevicetype roundrobin ruleid secondarystoragevm secretkey
securityGroupName securitygroupenabled securitygroupid securitygroupids
securitygroupname securitygroupnames securitygroupsenabled selfexecutable
sentbytes serviceofferingdisplaytext serviceofferingid serviceofferingname
sessionkey snapshotId snapshotavailable snapshotid snapshotlimit
snapshotpolicy snapshotreservation snapshottotal snapshottype
sourcetemplateid sourcezoneid specied specifyvlan startIP startRouter
startSystemVm startVirtualMachine startdate startip startport stopRouter
stopSystemVm stopVirtualMachine storageid storagetype supportELB systemvm
systemvmtype targetiqn templateId templateavailable templatedisplaytext
templatefilter templateid templatelimit templatename templatetag
templatetotal templatetype timezoneoffset traffictype updateAccount
updateCluster updateConfiguration updateDiskOffering updateDomain
updateHost updateHostPassword updateInstanceGroup updateIso
updateIsoPermissions updateLoadBalancerRule updateNetwork
updateNetworkOffering updatePod updateResourceCount updateResourceLimit
updateServiceOffering updateTemplate updateTemplatePermissions updateUser
updateVirtualMachine updateZone uploadCustomCertificate uploadpercentage
uri url usageid usageinterface usagetype userApiKey userID userSecretKey
userapikey userdata userid username userpublictemplateenabled usersecretkey
usersecuritygrouplist versa virtualmachinedisplayname virtualmachineid
virtualmachineids virtualmachinename virutal vlan vlanid vlanname vlans vm
vm's vmavailable vmdisplayname vmlimit vmname vmrunning vms vmstate
vmstopped vmtotal volumeId volumeavailable volumeid volumelimit volumename
volumetotal volumetype vpn vpns yyyy zoneId zoneid zonename zonetoken

=head1 NAME

Net::CloudStack::API - Basic request and response handling for calls to a CloudStack service.

=head1 VERSION

  This document describes v0.02 of Net::CloudStack::API - released July 13, 2012 as part of Net-CloudStack-API.

=head1 SYNOPSIS

  use Net::CloudStack::API;
  my $cs = Net::CloudStack::API->new;
  $cs->api( 'see Net::CloudStack docs for setup details' );
  print $cs->listVolumes;

  use Net::CloudStack::API 'listVolumes';
  Net::CloudStack::API::api( 'see Net::CloudStack docs for setup details' );
  print listVolume();

  use Net::CloudStack::API ':Volume';
  Net::CloudStack::API::api( 'see Net::CloudStack docs for setup details' );
  print listVolumes();

=head1 DESCRIPTION

This module handles parameter checking for the various calls available from a cloudstack service.

Probably should include some explanatory text here about how this file is generated.

=head1 METHODS

Something about how these are the methods available.

(A) indicates the method is asynchronous.

Include text and reference here for async calls from docs.

=head1 Account Methods

=head2 createAccount

Creates an account

User Level: 3 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item accounttype

Type of the account.  Specify 0 for user, 1 for root admin, and 2 for domain admin

=item email

email

=item firstname

firstname

=item lastname

lastname

=item password

Hashed password (Default is MD5). If you wish to use any other hashing algorithm, you would need to write a custom authentication adapter See Docs section.

=item username

Unique username.

=back

=head4 Optional Parameters

=over

=item account

Creates the user under the specified account. If no account is specified, the username will be used as the account name.

=item domainid

Creates the user under the specified domain.

=item networkdomain

Network domain for the account's networks

=item timezone

Specifies a timezone for this command. For more information on the timezone parameter, see Time Zone Format.

=back

=head3 Response

=over

=item account

the account name of the user

=item accounttype

the account type of the user

=item apikey

the api key of the user

=item created

the date and time the user account was created

=item domain

the domain name of the user

=item domainid

the domain ID of the user

=item email

the user email address

=item firstname

the user firstname

=item id

the user ID

=item lastname

the user lastname

=item secretkey

the secret key of the user

=item state

the user state

=item timezone

the timezone user was created in

=item username

the user name

=back

=head2 deleteAccount

Deletes a account, and all users associated with this account

User Level: 3 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

Account id

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 updateAccount (A)

Updates account information for the authenticated user

User Level: 3 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item account

the current account name

=item domainid

the ID of the domain where the account exists

=item newname

new name for the account

=back

=head4 Optional Parameters

=over

=item networkdomain

Network domain for the account's networks

=back

=head3 Response

=over

=item accounttype

account type (admin, domain-admin, user)

=item domain

name of the Domain the account belongs too

=item domainid

id of the Domain the account belongs too

=item id

the id of the account

=item ipavailable

the total number of public ip addresses available for this account to acquire

=item iplimit

the total number of public ip addresses this account can acquire

=item iptotal

the total number of public ip addresses allocated for this account

=item iscleanuprequired

true if the account requires cleanup

=item name

the name of the account

=item networkdomain

the network domain

=item receivedbytes

the total number of network traffic bytes received

=item sentbytes

the total number of network traffic bytes sent

=item snapshotavailable

the total number of snapshots available for this account

=item snapshotlimit

the total number of snapshots which can be stored by this account

=item snapshottotal

the total number of snapshots stored by this account

=item state

the state of the account

=item templateavailable

the total number of templates available to be created by this account

=item templatelimit

the total number of templates which can be created by this account

=item templatetotal

the total number of templates which have been created by this account

=item user(*)

the list of users associated with account

=item vmavailable

the total number of virtual machines available for this account to acquire

=item vmlimit

the total number of virtual machines that can be deployed by this account

=item vmrunning

the total number of virtual machines running for this account

=item vmstopped

the total number of virtual machines stopped for this account

=item vmtotal

the total number of virtual machines deployed by this account

=item volumeavailable

the total volume available for this account

=item volumelimit

the total volume which can be used by this account

=item volumetotal

the total volume being used by this account

=back

=head2 disableAccount

Disables an account

User Level: 7 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item account

Disables specified account.

=item domainid

Disables specified account in this domain.

=item lock

If true, only lock the account; else disable the account

=back

=head3 Response

=over

=item accounttype

account type (admin, domain-admin, user)

=item domain

name of the Domain the account belongs too

=item domainid

id of the Domain the account belongs too

=item id

the id of the account

=item ipavailable

the total number of public ip addresses available for this account to acquire

=item iplimit

the total number of public ip addresses this account can acquire

=item iptotal

the total number of public ip addresses allocated for this account

=item iscleanuprequired

true if the account requires cleanup

=item name

the name of the account

=item networkdomain

the network domain

=item receivedbytes

the total number of network traffic bytes received

=item sentbytes

the total number of network traffic bytes sent

=item snapshotavailable

the total number of snapshots available for this account

=item snapshotlimit

the total number of snapshots which can be stored by this account

=item snapshottotal

the total number of snapshots stored by this account

=item state

the state of the account

=item templateavailable

the total number of templates available to be created by this account

=item templatelimit

the total number of templates which can be created by this account

=item templatetotal

the total number of templates which have been created by this account

=item user(*)

the list of users associated with account

=item vmavailable

the total number of virtual machines available for this account to acquire

=item vmlimit

the total number of virtual machines that can be deployed by this account

=item vmrunning

the total number of virtual machines running for this account

=item vmstopped

the total number of virtual machines stopped for this account

=item vmtotal

the total number of virtual machines deployed by this account

=item volumeavailable

the total volume available for this account

=item volumelimit

the total volume which can be used by this account

=item volumetotal

the total volume being used by this account

=back

=head2 enableAccount (A)

Enables an account

User Level: 7 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item account

Enables specified account.

=item domainid

Enables specified account in this domain.

=back

=head3 Response

=over

=item accounttype

account type (admin, domain-admin, user)

=item domain

name of the Domain the account belongs too

=item domainid

id of the Domain the account belongs too

=item id

the id of the account

=item ipavailable

the total number of public ip addresses available for this account to acquire

=item iplimit

the total number of public ip addresses this account can acquire

=item iptotal

the total number of public ip addresses allocated for this account

=item iscleanuprequired

true if the account requires cleanup

=item name

the name of the account

=item networkdomain

the network domain

=item receivedbytes

the total number of network traffic bytes received

=item sentbytes

the total number of network traffic bytes sent

=item snapshotavailable

the total number of snapshots available for this account

=item snapshotlimit

the total number of snapshots which can be stored by this account

=item snapshottotal

the total number of snapshots stored by this account

=item state

the state of the account

=item templateavailable

the total number of templates available to be created by this account

=item templatelimit

the total number of templates which can be created by this account

=item templatetotal

the total number of templates which have been created by this account

=item user(*)

the list of users associated with account

=item vmavailable

the total number of virtual machines available for this account to acquire

=item vmlimit

the total number of virtual machines that can be deployed by this account

=item vmrunning

the total number of virtual machines running for this account

=item vmstopped

the total number of virtual machines stopped for this account

=item vmtotal

the total number of virtual machines deployed by this account

=item volumeavailable

the total volume available for this account

=item volumelimit

the total volume which can be used by this account

=item volumetotal

the total volume being used by this account

=back

=head2 listAccounts

Lists accounts and provides detailed account information for listed accounts

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item accounttype

list accounts by account type. Valid account types are 1 (admin), 2 (domain-admin), and 0 (user).

=item domainid

list all accounts in specified domain. If used with the name parameter, retrieves account information for the account with specified name in specified domain.

=item id

list account by account ID

=item iscleanuprequired

list accounts by cleanuprequred attribute (values are true or false)

=item isrecursive

defaults to false, but if true, lists all accounts from the parent specified by the domain id till leaves.

=item keyword

List by keyword

=item name

list account by account name

=item page

no description

=item pagesize

no description

=item state

list accounts by state. Valid states are enabled, disabled, and locked.

=back

=head3 Response

=over

=item accounttype

account type (admin, domain-admin, user)

=item domain

name of the Domain the account belongs too

=item domainid

id of the Domain the account belongs too

=item id

the id of the account

=item ipavailable

the total number of public ip addresses available for this account to acquire

=item iplimit

the total number of public ip addresses this account can acquire

=item iptotal

the total number of public ip addresses allocated for this account

=item iscleanuprequired

true if the account requires cleanup

=item name

the name of the account

=item networkdomain

the network domain

=item receivedbytes

the total number of network traffic bytes received

=item sentbytes

the total number of network traffic bytes sent

=item snapshotavailable

the total number of snapshots available for this account

=item snapshotlimit

the total number of snapshots which can be stored by this account

=item snapshottotal

the total number of snapshots stored by this account

=item state

the state of the account

=item templateavailable

the total number of templates available to be created by this account

=item templatelimit

the total number of templates which can be created by this account

=item templatetotal

the total number of templates which have been created by this account

=item user(*)

the list of users associated with account

=item vmavailable

the total number of virtual machines available for this account to acquire

=item vmlimit

the total number of virtual machines that can be deployed by this account

=item vmrunning

the total number of virtual machines running for this account

=item vmstopped

the total number of virtual machines stopped for this account

=item vmtotal

the total number of virtual machines deployed by this account

=item volumeavailable

the total volume available for this account

=item volumelimit

the total volume which can be used by this account

=item volumetotal

the total volume being used by this account

=back

=head1 Address Methods

=head2 associateIpAddress

Acquires and associates a public IP to an account.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item zoneid

the ID of the availability zone you want to acquire an public IP address from

=back

=head4 Optional Parameters

=over

=item account

the account to associate with this IP address

=item domainid

the ID of the domain to associate with this IP address

=item networkid

The network this ip address should be associated to.

=back

=head3 Response

=over

=item account

the account the public IP address is associated with

=item allocated

date the public IP address was acquired

=item associatednetworkid

the ID of the Network associated with the IP address

=item domain

the domain the public IP address is associated with

=item domainid

the domain ID the public IP address is associated with

=item forvirtualnetwork

the virtual network for the IP address

=item id

public IP address id

=item ipaddress

public IP address

=item issourcenat

true if the IP address is a source nat address, false otherwise

=item isstaticnat

true if this ip is for static nat, false otherwise

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume

=item jobstatus

shows the current pending asynchronous job status

=item networkid

the ID of the Network where ip belongs to

=item state

State of the ip address. Can be: Allocatin, Allocated and Releasing

=item virtualmachinedisplayname

virutal machine display name the ip address is assigned to (not null only for static nat Ip)

=item virtualmachineid

virutal machine id the ip address is assigned to (not null only for static nat Ip)

=item virtualmachinename

virutal machine name the ip address is assigned to (not null only for static nat Ip)

=item vlanid

the ID of the VLAN associated with the IP address

=item vlanname

the VLAN associated with the IP address

=item zoneid

the ID of the zone the public IP address belongs to

=item zonename

the name of the zone the public IP address belongs to

=back

=head2 disassociateIpAddress (A)

Disassociates an ip address from the account.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the id of the public ip address to disassociate

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listPublicIpAddresses (A)

Lists all public ip addresses

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item account

lists all public IP addresses by account. Must be used with the domainId parameter.

=item allocatedonly

limits search results to allocated public IP addresses

=item domainid

lists all public IP addresses by domain ID. If used with the account parameter, lists all public IP addresses by account for specified domain.

=item forloadbalancing

list only ips used for load balancing

=item forvirtualnetwork

the virtual network for the IP address

=item id

lists ip address by id

=item ipaddress

lists the specified IP address

=item keyword

List by keyword

=item page

no description

=item pagesize

no description

=item vlanid

lists all public IP addresses by VLAN ID

=item zoneid

lists all public IP addresses by Zone ID

=back

=head3 Response

=over

=item account

the account the public IP address is associated with

=item allocated

date the public IP address was acquired

=item associatednetworkid

the ID of the Network associated with the IP address

=item domain

the domain the public IP address is associated with

=item domainid

the domain ID the public IP address is associated with

=item forvirtualnetwork

the virtual network for the IP address

=item id

public IP address id

=item ipaddress

public IP address

=item issourcenat

true if the IP address is a source nat address, false otherwise

=item isstaticnat

true if this ip is for static nat, false otherwise

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume

=item jobstatus

shows the current pending asynchronous job status

=item networkid

the ID of the Network where ip belongs to

=item state

State of the ip address. Can be: Allocatin, Allocated and Releasing

=item virtualmachinedisplayname

virutal machine display name the ip address is assigned to (not null only for static nat Ip)

=item virtualmachineid

virutal machine id the ip address is assigned to (not null only for static nat Ip)

=item virtualmachinename

virutal machine name the ip address is assigned to (not null only for static nat Ip)

=item vlanid

the ID of the VLAN associated with the IP address

=item vlanname

the VLAN associated with the IP address

=item zoneid

the ID of the zone the public IP address belongs to

=item zonename

the name of the zone the public IP address belongs to

=back

=head1 Alerts Methods

=head2 listAlerts

Lists all alerts.

User Level: 3 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item id

the ID of the alert

=item keyword

List by keyword

=item page

no description

=item pagesize

no description

=item type

list by alert type

=back

=head3 Response

=over

=item description

description of the alert

=item id

the id of the alert

=item sent

the date and time the alert was sent

=item type

the alert type

=back

=head1 AsyncQuery Methods

=head2 queryAsyncJobResult

Retrieves the current status of asynchronous job.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item jobid

the ID of the asychronous job

=back

=head3 Response

=over

=item accountid

the account that executed the async command

=item cmd

the async command executed

=item created

the created date of the job

=item jobid

async job ID

=item jobinstanceid

the unique ID of the instance/entity object related to the job

=item jobinstancetype

the instance/entity object related to the job

=item jobprocstatus

the progress information of the PENDING job

=item jobresult

the result reason

=item jobresultcode

the result code for the job

=item jobresulttype

the result type

=item jobstatus

the current job status-should be 0 for PENDING

=item userid

the user that executed the async command

=back

=head2 listAsyncJobs

Lists all pending asynchronous jobs for the account.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item account

the account associated with the async job. Must be used with the domainId parameter.

=item domainid

the domain ID associated with the async job.  If used with the account parameter, returns async jobs for the account in the specified domain.

=item keyword

List by keyword

=item page

no description

=item pagesize

no description

=item startdate

the start date of the async job

=back

=head3 Response

=over

=item accountid

the account that executed the async command

=item cmd

the async command executed

=item created

the created date of the job

=item jobid

async job ID

=item jobinstanceid

the unique ID of the instance/entity object related to the job

=item jobinstancetype

the instance/entity object related to the job

=item jobprocstatus

the progress information of the PENDING job

=item jobresult

the result reason

=item jobresultcode

the result code for the job

=item jobresulttype

the result type

=item jobstatus

the current job status-should be 0 for PENDING

=item userid

the user that executed the async command

=back

=head1 Certificate Methods

=head2 uploadCustomCertificate

Uploads custom certificate

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item certificate

the custom cert to be uploaded

=item domainsuffix

DNS domain suffix that the certificate is granted for

=back

=head4 Optional Parameters

=over

=item id

the custom cert id in the chain

=item name

the alias of the certificate

=item privatekey

the private key for the certificate

=back

=head3 Response

=over

=item message

message of the certificate upload operation

=back

=head1 CloudIdentifier Methods

=head2 getCloudIdentifier (A)

Retrieves a cloud identifier.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item userid

the user ID for the cloud identifier

=back

=head3 Response

=over

=item cloudidentifier

the cloud identifier

=item signature

the signed response for the cloud identifier

=item userid

the user ID for the cloud identifier

=back

=head1 Configuration Methods

=head2 updateConfiguration

Updates a configuration.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item name

the name of the configuration

=back

=head4 Optional Parameters

=over

=item value

the value of the configuration

=back

=head3 Response

=over

=item category

the category of the configuration

=item description

the description of the configuration

=item name

the name of the configuration

=item value

the value of the configuration

=back

=head2 listConfigurations

Lists all configurations.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item category

lists configurations by category

=item keyword

List by keyword

=item name

lists configuration by name

=item page

no description

=item pagesize

no description

=back

=head3 Response

=over

=item category

the category of the configuration

=item description

the description of the configuration

=item name

the name of the configuration

=item value

the value of the configuration

=back

=head2 createConfiguration

Adds configuration value

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item category

component's category

=item component

the component of the configuration

=item instance

the instance of the configuration

=item name

the name of the configuration

=back

=head4 Optional Parameters

=over

=item description

the description of the configuration

=item value

the value of the configuration

=back

=head3 Response

=over

=item category

the category of the configuration

=item description

the description of the configuration

=item name

the name of the configuration

=item value

the value of the configuration

=back

=head2 listCapabilities

Lists capabilities

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head3 Response

=over

=item cloudstackversion

version of the cloud stack

=item firewallRuleUiEnabled

true if the firewall rule UI is enabled

=item securitygroupsenabled

true if security groups support is enabled, false otherwise

=item supportELB

true if region supports elastic load balancer on basic zones

=item userpublictemplateenabled

true if user and domain admins can set templates to be shared, false otherwise

=back

=head1 DiskOffering Methods

=head2 createDiskOffering

Creates a disk offering.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item displaytext

alternate display text of the disk offering

=item name

name of the disk offering

=back

=head4 Optional Parameters

=over

=item customized

whether disk offering is custom or not

=item disksize

size of the disk offering in GB

=item domainid

the ID of the containing domain, null for public offerings

=item tags

tags for the disk offering

=back

=head3 Response

=over

=item created

the date this disk offering was created

=item disksize

the size of the disk offering in GB

=item displaytext

an alternate display text of the disk offering.

=item domain

the domain name this disk offering belongs to. Ignore this information as it is not currently applicable.

=item domainid

the domain ID this disk offering belongs to. Ignore this information as it is not currently applicable.

=item id

unique ID of the disk offering

=item iscustomized

true if disk offering uses custom size, false otherwise

=item name

the name of the disk offering

=item tags

the tags for the disk offering

=back

=head2 updateDiskOffering

Updates a disk offering.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

ID of the disk offering

=back

=head4 Optional Parameters

=over

=item displaytext

updates alternate display text of the disk offering with this value

=item name

updates name of the disk offering with this value

=back

=head3 Response

=over

=item created

the date this disk offering was created

=item disksize

the size of the disk offering in GB

=item displaytext

an alternate display text of the disk offering.

=item domain

the domain name this disk offering belongs to. Ignore this information as it is not currently applicable.

=item domainid

the domain ID this disk offering belongs to. Ignore this information as it is not currently applicable.

=item id

unique ID of the disk offering

=item iscustomized

true if disk offering uses custom size, false otherwise

=item name

the name of the disk offering

=item tags

the tags for the disk offering

=back

=head2 deleteDiskOffering

Updates a disk offering.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

ID of the disk offering

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listDiskOfferings

Lists all available disk offerings.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item domainid

the ID of the domain of the disk offering.

=item id

ID of the disk offering

=item keyword

List by keyword

=item name

name of the disk offering

=item page

no description

=item pagesize

no description

=back

=head3 Response

=over

=item created

the date this disk offering was created

=item disksize

the size of the disk offering in GB

=item displaytext

an alternate display text of the disk offering.

=item domain

the domain name this disk offering belongs to. Ignore this information as it is not currently applicable.

=item domainid

the domain ID this disk offering belongs to. Ignore this information as it is not currently applicable.

=item id

unique ID of the disk offering

=item iscustomized

true if disk offering uses custom size, false otherwise

=item name

the name of the disk offering

=item tags

the tags for the disk offering

=back

=head1 Domain Methods

=head2 createDomain

Creates a domain

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item name

creates domain with this name

=back

=head4 Optional Parameters

=over

=item networkdomain

Network domain for networks in the domain

=item parentdomainid

assigns new domain a parent domain by domain ID of the parent.  If no parent domain is specied, the ROOT domain is assumed.

=back

=head3 Response

=over

=item haschild

whether the domain has one or more sub-domains

=item id

the ID of the domain

=item level

the level of the domain

=item name

the name of the domain

=item networkdomain

the network domain

=item parentdomainid

the domain ID of the parent domain

=item parentdomainname

the domain name of the parent domain

=item path

the path of the domain

=back

=head2 updateDomain

Updates a domain with a new name

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

ID of domain to update

=back

=head4 Optional Parameters

=over

=item name

updates domain with this name

=item networkdomain

Network domain for the domain's networks

=back

=head3 Response

=over

=item haschild

whether the domain has one or more sub-domains

=item id

the ID of the domain

=item level

the level of the domain

=item name

the name of the domain

=item networkdomain

the network domain

=item parentdomainid

the domain ID of the parent domain

=item parentdomainname

the domain name of the parent domain

=item path

the path of the domain

=back

=head2 deleteDomain

Deletes a specified domain

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

ID of domain to delete

=back

=head4 Optional Parameters

=over

=item cleanup

true if all domain resources (child domains, accounts) have to be cleaned up, false otherwise

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listDomains (A)

Lists domains and provides detailed information for listed domains

User Level: 7 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item id

List domain by domain ID.

=item keyword

List by keyword

=item level

List domains by domain level.

=item name

List domain by domain name.

=item page

no description

=item pagesize

no description

=back

=head3 Response

=over

=item haschild

whether the domain has one or more sub-domains

=item id

the ID of the domain

=item level

the level of the domain

=item name

the name of the domain

=item networkdomain

the network domain

=item parentdomainid

the domain ID of the parent domain

=item parentdomainname

the domain name of the parent domain

=item path

the path of the domain

=back

=head2 listDomainChildren

Lists all children domains belonging to a specified domain

User Level: 7 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item id

list children domain by parent domain ID.

=item isrecursive

to return the entire tree, use the value "true". To return the first level children, use the value "false".

=item keyword

List by keyword

=item name

list children domains by name

=item page

no description

=item pagesize

no description

=back

=head3 Response

=over

=item haschild

whether the domain has one or more sub-domains

=item id

the ID of the domain

=item level

the level of the domain

=item name

the name of the domain

=item networkdomain

the network domain

=item parentdomainid

the domain ID of the parent domain

=item parentdomainname

the domain name of the parent domain

=item path

the path of the domain

=back

=head1 Events Methods

=head2 listEvents

A command to list events.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item account

the account for the event. Must be used with the domainId parameter.

=item domainid

the domain ID for the event. If used with the account parameter, returns all events for an account in the specified domain ID.

=item duration

the duration of the event

=item enddate

the end date range of the list you want to retrieve (use format "yyyy-MM-dd" or the new format "yyyy-MM-dd HH:mm:ss")

=item entrytime

the time the event was entered

=item id

the ID of the event

=item keyword

List by keyword

=item level

the event level (INFO, WARN, ERROR)

=item page

no description

=item pagesize

no description

=item startdate

the start date range of the list you want to retrieve (use format "yyyy-MM-dd" or the new format "yyyy-MM-dd HH:mm:ss")

=item type

the event type (see event types)

=back

=head3 Response

=over

=item account

the account name for the account that owns the object being acted on in the event (e.g. the owner of the virtual machine, ip address, or security group)

=item created

the date the event was created

=item description

a brief description of the event

=item domain

the name of the account's domain

=item domainid

the id of the account's domain

=item id

the ID of the event

=item level

the event level (INFO, WARN, ERROR)

=item parentid

whether the event is parented

=item state

the state of the event

=item type

the type of the event (see event types)

=item username

the name of the user who performed the action (can be different from the account if an admin is performing an action for a user, e.g. starting/stopping a user's virtual machine)

=back

=head2 listEventTypes

List Event Types

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head3 Response

=over

=item name

Event Type

=back

=head1 ExternalFirewall Methods

=head2 addExternalFirewall

Adds an external firewall appliance

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item password

Password of the external firewall appliance.

=item url

URL of the external firewall appliance.

=item username

Username of the external firewall appliance.

=item zoneid

Zone in which to add the external firewall appliance.

=back

=head3 Response

=over

=item id

the ID of the external firewall

=item ipaddress

the management IP address of the external firewall

=item numretries

the number of times to retry requests to the external firewall

=item privateinterface

the private interface of the external firewall

=item privatezone

the private security zone of the external firewall

=item publicinterface

the public interface of the external firewall

=item publiczone

the public security zone of the external firewall

=item timeout

the timeout (in seconds) for requests to the external firewall

=item usageinterface

the usage interface of the external firewall

=item username

the username that's used to log in to the external firewall

=item zoneid

the zone ID of the external firewall

=back

=head2 deleteExternalFirewall

Deletes an external firewall appliance.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

Id of the external firewall appliance.

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listExternalFirewalls

List external firewall appliances.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item zoneid

zone Id

=back

=head4 Optional Parameters

=over

=item keyword

List by keyword

=item page

no description

=item pagesize

no description

=back

=head3 Response

=over

=item id

the ID of the external firewall

=item ipaddress

the management IP address of the external firewall

=item numretries

the number of times to retry requests to the external firewall

=item privateinterface

the private interface of the external firewall

=item privatezone

the private security zone of the external firewall

=item publicinterface

the public interface of the external firewall

=item publiczone

the public security zone of the external firewall

=item timeout

the timeout (in seconds) for requests to the external firewall

=item usageinterface

the usage interface of the external firewall

=item username

the username that's used to log in to the external firewall

=item zoneid

the zone ID of the external firewall

=back

=head1 ExternalLoadBalancer Methods

=head2 addExternalLoadBalancer

Adds an external load balancer appliance.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item password

Password of the external load balancer appliance.

=item url

URL of the external load balancer appliance.

=item username

Username of the external load balancer appliance.

=item zoneid

Zone in which to add the external load balancer appliance.

=back

=head3 Response

=over

=item id

the ID of the external load balancer

=item inline

configures the external load balancer to be inline with an external firewall

=item ipaddress

the management IP address of the external load balancer

=item numretries

the number of times to retry requests to the external load balancer

=item privateinterface

the private interface of the external load balancer

=item publicinterface

the public interface of the external load balancer

=item username

the username that's used to log in to the external load balancer

=item zoneid

the zone ID of the external load balancer

=back

=head2 deleteExternalLoadBalancer

Deletes an external load balancer appliance.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

Id of the external loadbalancer appliance.

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listExternalLoadBalancers

List external load balancer appliances.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item keyword

List by keyword

=item page

no description

=item pagesize

no description

=item zoneid

zone Id

=back

=head3 Response

=over

=item allocationstate

the allocation state of the host

=item averageload

the cpu average load on the host

=item capabilities

capabilities of the host

=item clusterid

the cluster ID of the host

=item clustername

the cluster name of the host

=item clustertype

the cluster type of the cluster that host belongs to

=item cpuallocated

the amount of the host's CPU currently allocated

=item cpunumber

the CPU number of the host

=item cpuspeed

the CPU speed of the host

=item cpuused

the amount of the host's CPU currently used

=item cpuwithoverprovisioning

the amount of the host's CPU after applying the cpu.overprovisioning.factor

=item created

the date and time the host was created

=item disconnected

true if the host is disconnected. False otherwise.

=item disksizeallocated

the host's currently allocated disk size

=item disksizetotal

the total disk size of the host

=item events

events available for the host

=item hasEnoughCapacity

true if this host has enough CPU and RAM capacity to migrate a VM to it, false otherwise

=item hosttags

comma-separated list of tags for the host

=item hypervisor

the host hypervisor

=item id

the ID of the host

=item ipaddress

the IP address of the host

=item islocalstorageactive

true if local storage is active, false otherwise

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the host

=item jobstatus

shows the current pending asynchronous job status

=item lastpinged

the date and time the host was last pinged

=item managementserverid

the management server ID of the host

=item memoryallocated

the amount of the host's memory currently allocated

=item memorytotal

the memory total of the host

=item memoryused

the amount of the host's memory currently used

=item name

the name of the host

=item networkkbsread

the incoming network traffic on the host

=item networkkbswrite

the outgoing network traffic on the host

=item oscategoryid

the OS category ID of the host

=item oscategoryname

the OS category name of the host

=item podid

the Pod ID of the host

=item podname

the Pod name of the host

=item removed

the date and time the host was removed

=item state

the state of the host

=item type

the host type

=item version

the host version

=item zoneid

the Zone ID of the host

=item zonename

the Zone name of the host

=back

=head1 Firewall Methods

=head2 listPortForwardingRules

Lists all port forwarding rules for an IP address.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item account

account. Must be used with the domainId parameter.

=item domainid

the domain ID. If used with the account parameter, lists port forwarding rules for the specified account in this domain.

=item id

Lists rule with the specified ID.

=item ipaddressid

the id of IP address of the port forwarding services

=item keyword

List by keyword

=item page

no description

=item pagesize

no description

=back

=head3 Response

=over

=item cidrlist

the cidr list to forward traffic from

=item id

the ID of the port forwarding rule

=item ipaddress

the public ip address for the port forwarding rule

=item ipaddressid

the public ip address id for the port forwarding rule

=item privateendport

the ending port of port forwarding rule's private port range

=item privateport

the starting port of port forwarding rule's private port range

=item protocol

the protocol of the port forwarding rule

=item publicendport

the ending port of port forwarding rule's private port range

=item publicport

the starting port of port forwarding rule's public port range

=item state

the state of the rule

=item virtualmachinedisplayname

the VM display name for the port forwarding rule

=item virtualmachineid

the VM ID for the port forwarding rule

=item virtualmachinename

the VM name for the port forwarding rule

=back

=head2 createPortForwardingRule

Creates a port forwarding rule

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item ipaddressid

the IP address id of the port forwarding rule

=item privateport

the starting port of port forwarding rule's private port range

=item protocol

the protocol for the port fowarding rule. Valid values are TCP or UDP.

=item publicport

the starting port of port forwarding rule's public port range

=item virtualmachineid

the ID of the virtual machine for the port forwarding rule

=back

=head4 Optional Parameters

=over

=item cidrlist

the cidr list to forward traffic from

=item openfirewall

if true, firewall rule for source/end pubic port is automatically created; if false - firewall rule has to be created explicitely. Has value true by default

=item privateendport

the ending port of port forwarding rule's private port range

=item publicendport

the ending port of port forwarding rule's private port range

=back

=head3 Response

=over

=item cidrlist

the cidr list to forward traffic from

=item id

the ID of the port forwarding rule

=item ipaddress

the public ip address for the port forwarding rule

=item ipaddressid

the public ip address id for the port forwarding rule

=item privateendport

the ending port of port forwarding rule's private port range

=item privateport

the starting port of port forwarding rule's private port range

=item protocol

the protocol of the port forwarding rule

=item publicendport

the ending port of port forwarding rule's private port range

=item publicport

the starting port of port forwarding rule's public port range

=item state

the state of the rule

=item virtualmachinedisplayname

the VM display name for the port forwarding rule

=item virtualmachineid

the VM ID for the port forwarding rule

=item virtualmachinename

the VM name for the port forwarding rule

=back

=head2 deletePortForwardingRule (A)

Deletes a port forwarding rule

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the port forwarding rule

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 createFirewallRule (A)

Creates a firewall rule for a given ip address

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item ipaddressid

the IP address id of the port forwarding rule

=item protocol

the protocol for the firewall rule. Valid values are TCP/UDP/ICMP.

=back

=head4 Optional Parameters

=over

=item cidrlist

the cidr list to forward traffic from

=item endport

the ending port of firewall rule

=item icmpcode

error code for this icmp message

=item icmptype

type of the icmp message being sent

=item startport

the starting port of firewall rule

=back

=head3 Response

=over

=item cidrlist

the cidr list to forward traffic from

=item endport

the ending port of firewall rule's port range

=item icmpcode

error code for this icmp message

=item icmptype

type of the icmp message being sent

=item id

the ID of the firewall rule

=item ipaddress

the public ip address for the port forwarding rule

=item ipaddressid

the public ip address id for the port forwarding rule

=item protocol

the protocol of the firewall rule

=item startport

the starting port of firewall rule's port range

=item state

the state of the rule

=back

=head2 deleteFirewallRule (A)

Deletes a firewall rule

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the firewall rule

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listFirewallRules (A)

Lists all firewall rules for an IP address.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item account

account. Must be used with the domainId parameter.

=item domainid

the domain ID. If used with the account parameter, lists firewall rules for the specified account in this domain.

=item id

Lists rule with the specified ID.

=item ipaddressid

the id of IP address of the firwall services

=item keyword

List by keyword

=item page

no description

=item pagesize

no description

=back

=head3 Response

=over

=item cidrlist

the cidr list to forward traffic from

=item endport

the ending port of firewall rule's port range

=item icmpcode

error code for this icmp message

=item icmptype

type of the icmp message being sent

=item id

the ID of the firewall rule

=item ipaddress

the public ip address for the port forwarding rule

=item ipaddressid

the public ip address id for the port forwarding rule

=item protocol

the protocol of the firewall rule

=item startport

the starting port of firewall rule's port range

=item state

the state of the rule

=back

=head1 GuestOS Methods

=head2 listOsTypes

Lists all supported OS types for this cloud.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item id

list by Os type Id

=item keyword

List by keyword

=item oscategoryid

list by Os Category id

=item page

no description

=item pagesize

no description

=back

=head3 Response

=over

=item description

the name/description of the OS type

=item id

the ID of the OS type

=item oscategoryid

the ID of the OS category

=back

=head2 listOsCategories

Lists all supported OS categories for this cloud.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item id

list Os category by id

=item keyword

List by keyword

=item page

no description

=item pagesize

no description

=back

=head3 Response

=over

=item id

the ID of the OS category

=item name

the name of the OS category

=back

=head1 Host Methods

=head2 addHost

Adds a new host.

User Level: 3 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item hypervisor

hypervisor type of the host

=item password

the password for the host

=item url

the host URL

=item username

the username for the host

=item zoneid

the Zone ID for the host

=back

=head4 Optional Parameters

=over

=item allocationstate

Allocation state of this Host for allocation of new resources

=item clusterid

the cluster ID for the host

=item clustername

the cluster name for the host

=item hosttags

list of tags to be added to the host

=item podid

the Pod ID for the host

=back

=head3 Response

=over

=item allocationstate

the allocation state of the host

=item averageload

the cpu average load on the host

=item capabilities

capabilities of the host

=item clusterid

the cluster ID of the host

=item clustername

the cluster name of the host

=item clustertype

the cluster type of the cluster that host belongs to

=item cpuallocated

the amount of the host's CPU currently allocated

=item cpunumber

the CPU number of the host

=item cpuspeed

the CPU speed of the host

=item cpuused

the amount of the host's CPU currently used

=item cpuwithoverprovisioning

the amount of the host's CPU after applying the cpu.overprovisioning.factor

=item created

the date and time the host was created

=item disconnected

true if the host is disconnected. False otherwise.

=item disksizeallocated

the host's currently allocated disk size

=item disksizetotal

the total disk size of the host

=item events

events available for the host

=item hasEnoughCapacity

true if this host has enough CPU and RAM capacity to migrate a VM to it, false otherwise

=item hosttags

comma-separated list of tags for the host

=item hypervisor

the host hypervisor

=item id

the ID of the host

=item ipaddress

the IP address of the host

=item islocalstorageactive

true if local storage is active, false otherwise

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the host

=item jobstatus

shows the current pending asynchronous job status

=item lastpinged

the date and time the host was last pinged

=item managementserverid

the management server ID of the host

=item memoryallocated

the amount of the host's memory currently allocated

=item memorytotal

the memory total of the host

=item memoryused

the amount of the host's memory currently used

=item name

the name of the host

=item networkkbsread

the incoming network traffic on the host

=item networkkbswrite

the outgoing network traffic on the host

=item oscategoryid

the OS category ID of the host

=item oscategoryname

the OS category name of the host

=item podid

the Pod ID of the host

=item podname

the Pod name of the host

=item removed

the date and time the host was removed

=item state

the state of the host

=item type

the host type

=item version

the host version

=item zoneid

the Zone ID of the host

=item zonename

the Zone name of the host

=back

=head2 addCluster

Adds a new cluster

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item clustername

the cluster name

=item clustertype

type of the cluster: CloudManaged, ExternalManaged

=item hypervisor

hypervisor type of the cluster: XenServer,KVM,VMware,Hyperv,BareMetal,Simulator

=item zoneid

the Zone ID for the cluster

=back

=head4 Optional Parameters

=over

=item allocationstate

Allocation state of this cluster for allocation of new resources

=item password

the password for the host

=item podid

the Pod ID for the host

=item url

the URL

=item username

the username for the cluster

=back

=head3 Response

=over

=item allocationstate

the allocation state of the cluster

=item clustertype

the type of the cluster

=item hypervisortype

the hypervisor type of the cluster

=item id

the cluster ID

=item managedstate

whether this cluster is managed by cloudstack

=item name

the cluster name

=item podid

the Pod ID of the cluster

=item podname

the Pod name of the cluster

=item zoneid

the Zone ID of the cluster

=item zonename

the Zone name of the cluster

=back

=head2 deleteCluster

Deletes a cluster.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the cluster ID

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 updateCluster

Updates an existing cluster

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the Cluster

=back

=head4 Optional Parameters

=over

=item allocationstate

Allocation state of this cluster for allocation of new resources

=item clustername

the cluster name

=item clustertype

hypervisor type of the cluster

=item hypervisor

hypervisor type of the cluster

=item managedstate

whether this cluster is managed by cloudstack

=back

=head3 Response

=over

=item allocationstate

the allocation state of the cluster

=item clustertype

the type of the cluster

=item hypervisortype

the hypervisor type of the cluster

=item id

the cluster ID

=item managedstate

whether this cluster is managed by cloudstack

=item name

the cluster name

=item podid

the Pod ID of the cluster

=item podname

the Pod name of the cluster

=item zoneid

the Zone ID of the cluster

=item zonename

the Zone name of the cluster

=back

=head2 reconnectHost

Reconnects a host.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the host ID

=back

=head3 Response

=over

=item allocationstate

the allocation state of the host

=item averageload

the cpu average load on the host

=item capabilities

capabilities of the host

=item clusterid

the cluster ID of the host

=item clustername

the cluster name of the host

=item clustertype

the cluster type of the cluster that host belongs to

=item cpuallocated

the amount of the host's CPU currently allocated

=item cpunumber

the CPU number of the host

=item cpuspeed

the CPU speed of the host

=item cpuused

the amount of the host's CPU currently used

=item cpuwithoverprovisioning

the amount of the host's CPU after applying the cpu.overprovisioning.factor

=item created

the date and time the host was created

=item disconnected

true if the host is disconnected. False otherwise.

=item disksizeallocated

the host's currently allocated disk size

=item disksizetotal

the total disk size of the host

=item events

events available for the host

=item hasEnoughCapacity

true if this host has enough CPU and RAM capacity to migrate a VM to it, false otherwise

=item hosttags

comma-separated list of tags for the host

=item hypervisor

the host hypervisor

=item id

the ID of the host

=item ipaddress

the IP address of the host

=item islocalstorageactive

true if local storage is active, false otherwise

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the host

=item jobstatus

shows the current pending asynchronous job status

=item lastpinged

the date and time the host was last pinged

=item managementserverid

the management server ID of the host

=item memoryallocated

the amount of the host's memory currently allocated

=item memorytotal

the memory total of the host

=item memoryused

the amount of the host's memory currently used

=item name

the name of the host

=item networkkbsread

the incoming network traffic on the host

=item networkkbswrite

the outgoing network traffic on the host

=item oscategoryid

the OS category ID of the host

=item oscategoryname

the OS category name of the host

=item podid

the Pod ID of the host

=item podname

the Pod name of the host

=item removed

the date and time the host was removed

=item state

the state of the host

=item type

the host type

=item version

the host version

=item zoneid

the Zone ID of the host

=item zonename

the Zone name of the host

=back

=head2 updateHost (A)

Updates a host.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the host to update

=back

=head4 Optional Parameters

=over

=item allocationstate

Allocation state of this Host for allocation of new resources

=item hosttags

list of tags to be added to the host

=item oscategoryid

the id of Os category to update the host with

=back

=head3 Response

=over

=item allocationstate

the allocation state of the host

=item averageload

the cpu average load on the host

=item capabilities

capabilities of the host

=item clusterid

the cluster ID of the host

=item clustername

the cluster name of the host

=item clustertype

the cluster type of the cluster that host belongs to

=item cpuallocated

the amount of the host's CPU currently allocated

=item cpunumber

the CPU number of the host

=item cpuspeed

the CPU speed of the host

=item cpuused

the amount of the host's CPU currently used

=item cpuwithoverprovisioning

the amount of the host's CPU after applying the cpu.overprovisioning.factor

=item created

the date and time the host was created

=item disconnected

true if the host is disconnected. False otherwise.

=item disksizeallocated

the host's currently allocated disk size

=item disksizetotal

the total disk size of the host

=item events

events available for the host

=item hasEnoughCapacity

true if this host has enough CPU and RAM capacity to migrate a VM to it, false otherwise

=item hosttags

comma-separated list of tags for the host

=item hypervisor

the host hypervisor

=item id

the ID of the host

=item ipaddress

the IP address of the host

=item islocalstorageactive

true if local storage is active, false otherwise

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the host

=item jobstatus

shows the current pending asynchronous job status

=item lastpinged

the date and time the host was last pinged

=item managementserverid

the management server ID of the host

=item memoryallocated

the amount of the host's memory currently allocated

=item memorytotal

the memory total of the host

=item memoryused

the amount of the host's memory currently used

=item name

the name of the host

=item networkkbsread

the incoming network traffic on the host

=item networkkbswrite

the outgoing network traffic on the host

=item oscategoryid

the OS category ID of the host

=item oscategoryname

the OS category name of the host

=item podid

the Pod ID of the host

=item podname

the Pod name of the host

=item removed

the date and time the host was removed

=item state

the state of the host

=item type

the host type

=item version

the host version

=item zoneid

the Zone ID of the host

=item zonename

the Zone name of the host

=back

=head2 deleteHost

Deletes a host.

User Level: 3 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the host ID

=back

=head4 Optional Parameters

=over

=item forced

Force delete the host. All HA enabled vms running on the host will be put to HA; HA disabled ones will be stopped

=item forcedestroylocalstorage

Force destroy local storage on this host. All VMs created on this local storage will be destroyed

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 prepareHostForMaintenance

Prepares a host for maintenance.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the host ID

=back

=head3 Response

=over

=item allocationstate

the allocation state of the host

=item averageload

the cpu average load on the host

=item capabilities

capabilities of the host

=item clusterid

the cluster ID of the host

=item clustername

the cluster name of the host

=item clustertype

the cluster type of the cluster that host belongs to

=item cpuallocated

the amount of the host's CPU currently allocated

=item cpunumber

the CPU number of the host

=item cpuspeed

the CPU speed of the host

=item cpuused

the amount of the host's CPU currently used

=item cpuwithoverprovisioning

the amount of the host's CPU after applying the cpu.overprovisioning.factor

=item created

the date and time the host was created

=item disconnected

true if the host is disconnected. False otherwise.

=item disksizeallocated

the host's currently allocated disk size

=item disksizetotal

the total disk size of the host

=item events

events available for the host

=item hasEnoughCapacity

true if this host has enough CPU and RAM capacity to migrate a VM to it, false otherwise

=item hosttags

comma-separated list of tags for the host

=item hypervisor

the host hypervisor

=item id

the ID of the host

=item ipaddress

the IP address of the host

=item islocalstorageactive

true if local storage is active, false otherwise

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the host

=item jobstatus

shows the current pending asynchronous job status

=item lastpinged

the date and time the host was last pinged

=item managementserverid

the management server ID of the host

=item memoryallocated

the amount of the host's memory currently allocated

=item memorytotal

the memory total of the host

=item memoryused

the amount of the host's memory currently used

=item name

the name of the host

=item networkkbsread

the incoming network traffic on the host

=item networkkbswrite

the outgoing network traffic on the host

=item oscategoryid

the OS category ID of the host

=item oscategoryname

the OS category name of the host

=item podid

the Pod ID of the host

=item podname

the Pod name of the host

=item removed

the date and time the host was removed

=item state

the state of the host

=item type

the host type

=item version

the host version

=item zoneid

the Zone ID of the host

=item zonename

the Zone name of the host

=back

=head2 cancelHostMaintenance (A)

Cancels host maintenance.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the host ID

=back

=head3 Response

=over

=item allocationstate

the allocation state of the host

=item averageload

the cpu average load on the host

=item capabilities

capabilities of the host

=item clusterid

the cluster ID of the host

=item clustername

the cluster name of the host

=item clustertype

the cluster type of the cluster that host belongs to

=item cpuallocated

the amount of the host's CPU currently allocated

=item cpunumber

the CPU number of the host

=item cpuspeed

the CPU speed of the host

=item cpuused

the amount of the host's CPU currently used

=item cpuwithoverprovisioning

the amount of the host's CPU after applying the cpu.overprovisioning.factor

=item created

the date and time the host was created

=item disconnected

true if the host is disconnected. False otherwise.

=item disksizeallocated

the host's currently allocated disk size

=item disksizetotal

the total disk size of the host

=item events

events available for the host

=item hasEnoughCapacity

true if this host has enough CPU and RAM capacity to migrate a VM to it, false otherwise

=item hosttags

comma-separated list of tags for the host

=item hypervisor

the host hypervisor

=item id

the ID of the host

=item ipaddress

the IP address of the host

=item islocalstorageactive

true if local storage is active, false otherwise

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the host

=item jobstatus

shows the current pending asynchronous job status

=item lastpinged

the date and time the host was last pinged

=item managementserverid

the management server ID of the host

=item memoryallocated

the amount of the host's memory currently allocated

=item memorytotal

the memory total of the host

=item memoryused

the amount of the host's memory currently used

=item name

the name of the host

=item networkkbsread

the incoming network traffic on the host

=item networkkbswrite

the outgoing network traffic on the host

=item oscategoryid

the OS category ID of the host

=item oscategoryname

the OS category name of the host

=item podid

the Pod ID of the host

=item podname

the Pod name of the host

=item removed

the date and time the host was removed

=item state

the state of the host

=item type

the host type

=item version

the host version

=item zoneid

the Zone ID of the host

=item zonename

the Zone name of the host

=back

=head2 listHosts (A)

Lists hosts.

User Level: 3 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item allocationstate

list hosts by allocation state

=item clusterid

lists hosts existing in particular cluster

=item details

give details.  1 = minimal; 2 = include static info; 3 = include events; 4 = include allocation and statistics

=item id

the id of the host

=item keyword

List by keyword

=item name

the name of the host

=item page

no description

=item pagesize

no description

=item podid

the Pod ID for the host

=item state

the state of the host

=item type

the host type

=item virtualmachineid

lists hosts in the same cluster as this VM and flag hosts with enough CPU/RAm to host this VM

=item zoneid

the Zone ID for the host

=back

=head3 Response

=over

=item allocationstate

the allocation state of the host

=item averageload

the cpu average load on the host

=item capabilities

capabilities of the host

=item clusterid

the cluster ID of the host

=item clustername

the cluster name of the host

=item clustertype

the cluster type of the cluster that host belongs to

=item cpuallocated

the amount of the host's CPU currently allocated

=item cpunumber

the CPU number of the host

=item cpuspeed

the CPU speed of the host

=item cpuused

the amount of the host's CPU currently used

=item cpuwithoverprovisioning

the amount of the host's CPU after applying the cpu.overprovisioning.factor

=item created

the date and time the host was created

=item disconnected

true if the host is disconnected. False otherwise.

=item disksizeallocated

the host's currently allocated disk size

=item disksizetotal

the total disk size of the host

=item events

events available for the host

=item hasEnoughCapacity

true if this host has enough CPU and RAM capacity to migrate a VM to it, false otherwise

=item hosttags

comma-separated list of tags for the host

=item hypervisor

the host hypervisor

=item id

the ID of the host

=item ipaddress

the IP address of the host

=item islocalstorageactive

true if local storage is active, false otherwise

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the host

=item jobstatus

shows the current pending asynchronous job status

=item lastpinged

the date and time the host was last pinged

=item managementserverid

the management server ID of the host

=item memoryallocated

the amount of the host's memory currently allocated

=item memorytotal

the memory total of the host

=item memoryused

the amount of the host's memory currently used

=item name

the name of the host

=item networkkbsread

the incoming network traffic on the host

=item networkkbswrite

the outgoing network traffic on the host

=item oscategoryid

the OS category ID of the host

=item oscategoryname

the OS category name of the host

=item podid

the Pod ID of the host

=item podname

the Pod name of the host

=item removed

the date and time the host was removed

=item state

the state of the host

=item type

the host type

=item version

the host version

=item zoneid

the Zone ID of the host

=item zonename

the Zone name of the host

=back

=head2 addSecondaryStorage

Adds secondary storage.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item url

the URL for the secondary storage

=back

=head4 Optional Parameters

=over

=item zoneid

the Zone ID for the secondary storage

=back

=head3 Response

=over

=item allocationstate

the allocation state of the host

=item averageload

the cpu average load on the host

=item capabilities

capabilities of the host

=item clusterid

the cluster ID of the host

=item clustername

the cluster name of the host

=item clustertype

the cluster type of the cluster that host belongs to

=item cpuallocated

the amount of the host's CPU currently allocated

=item cpunumber

the CPU number of the host

=item cpuspeed

the CPU speed of the host

=item cpuused

the amount of the host's CPU currently used

=item cpuwithoverprovisioning

the amount of the host's CPU after applying the cpu.overprovisioning.factor

=item created

the date and time the host was created

=item disconnected

true if the host is disconnected. False otherwise.

=item disksizeallocated

the host's currently allocated disk size

=item disksizetotal

the total disk size of the host

=item events

events available for the host

=item hasEnoughCapacity

true if this host has enough CPU and RAM capacity to migrate a VM to it, false otherwise

=item hosttags

comma-separated list of tags for the host

=item hypervisor

the host hypervisor

=item id

the ID of the host

=item ipaddress

the IP address of the host

=item islocalstorageactive

true if local storage is active, false otherwise

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the host

=item jobstatus

shows the current pending asynchronous job status

=item lastpinged

the date and time the host was last pinged

=item managementserverid

the management server ID of the host

=item memoryallocated

the amount of the host's memory currently allocated

=item memorytotal

the memory total of the host

=item memoryused

the amount of the host's memory currently used

=item name

the name of the host

=item networkkbsread

the incoming network traffic on the host

=item networkkbswrite

the outgoing network traffic on the host

=item oscategoryid

the OS category ID of the host

=item oscategoryname

the OS category name of the host

=item podid

the Pod ID of the host

=item podname

the Pod name of the host

=item removed

the date and time the host was removed

=item state

the state of the host

=item type

the host type

=item version

the host version

=item zoneid

the Zone ID of the host

=item zonename

the Zone name of the host

=back

=head2 updateHostPassword

Update password of a host/pool on management server.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item password

the new password for the host/cluster

=item username

the username for the host/cluster

=back

=head4 Optional Parameters

=over

=item clusterid

the cluster ID. Either this parameter, or hostId has to be passed in

=item hostid

the host ID. Either this parameter, or clusterId has to be passed in

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head1 ISO Methods

=head2 attachIso

Attaches an ISO to a virtual machine.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the ISO file

=item virtualmachineid

the ID of the virtual machine

=back

=head3 Response

=over

=item account

the account associated with the virtual machine

=item cpunumber

the number of cpu this virtual machine is running with

=item cpuspeed

the speed of each cpu

=item cpuused

the amount of the vm's CPU currently used

=item created

the date when this virtual machine was created

=item displayname

user generated name. The name of the virtual machine is returned if no displayname exists.

=item domain

the name of the domain in which the virtual machine exists

=item domainid

the ID of the domain in which the virtual machine exists

=item forvirtualnetwork

the virtual network for the service offering

=item group

the group name of the virtual machine

=item groupid

the group ID of the virtual machine

=item guestosid

Os type ID of the virtual machine

=item haenable

true if high-availability is enabled, false otherwise

=item hostid

the ID of the host for the virtual machine

=item hostname

the name of the host for the virtual machine

=item hypervisor

the hypervisor on which the template runs

=item id

the ID of the virtual machine

=item ipaddress

the ip address of the virtual machine

=item isodisplaytext

an alternate display text of the ISO attached to the virtual machine

=item isoid

the ID of the ISO attached to the virtual machine

=item isoname

the name of the ISO attached to the virtual machine

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine

=item jobstatus

shows the current pending asynchronous job status

=item memory

the memory allocated for the virtual machine

=item name

the name of the virtual machine

=item networkkbsread

the incoming network traffic on the vm

=item networkkbswrite

the outgoing network traffic on the host

=item nic(*)

the list of nics associated with vm

=item password

the password (if exists) of the virtual machine

=item passwordenabled

true if the password rest feature is enabled, false otherwise

=item rootdeviceid

device ID of the root volume

=item rootdevicetype

device type of the root volume

=item securitygroup(*)

list of security groups associated with the virtual machine

=item serviceofferingid

the ID of the service offering of the virtual machine

=item serviceofferingname

the name of the service offering of the virtual machine

=item state

the state of the virtual machine

=item templatedisplaytext

an alternate display text of the template for the virtual machine

=item templateid

the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.

=item templatename

the name of the template for the virtual machine

=item zoneid

the ID of the availablility zone for the virtual machine

=item zonename

the name of the availability zone for the virtual machine

=back

=head2 detachIso (A)

Detaches any ISO file (if any) currently attached to a virtual machine.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item virtualmachineid

The ID of the virtual machine

=back

=head3 Response

=over

=item account

the account associated with the virtual machine

=item cpunumber

the number of cpu this virtual machine is running with

=item cpuspeed

the speed of each cpu

=item cpuused

the amount of the vm's CPU currently used

=item created

the date when this virtual machine was created

=item displayname

user generated name. The name of the virtual machine is returned if no displayname exists.

=item domain

the name of the domain in which the virtual machine exists

=item domainid

the ID of the domain in which the virtual machine exists

=item forvirtualnetwork

the virtual network for the service offering

=item group

the group name of the virtual machine

=item groupid

the group ID of the virtual machine

=item guestosid

Os type ID of the virtual machine

=item haenable

true if high-availability is enabled, false otherwise

=item hostid

the ID of the host for the virtual machine

=item hostname

the name of the host for the virtual machine

=item hypervisor

the hypervisor on which the template runs

=item id

the ID of the virtual machine

=item ipaddress

the ip address of the virtual machine

=item isodisplaytext

an alternate display text of the ISO attached to the virtual machine

=item isoid

the ID of the ISO attached to the virtual machine

=item isoname

the name of the ISO attached to the virtual machine

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine

=item jobstatus

shows the current pending asynchronous job status

=item memory

the memory allocated for the virtual machine

=item name

the name of the virtual machine

=item networkkbsread

the incoming network traffic on the vm

=item networkkbswrite

the outgoing network traffic on the host

=item nic(*)

the list of nics associated with vm

=item password

the password (if exists) of the virtual machine

=item passwordenabled

true if the password rest feature is enabled, false otherwise

=item rootdeviceid

device ID of the root volume

=item rootdevicetype

device type of the root volume

=item securitygroup(*)

list of security groups associated with the virtual machine

=item serviceofferingid

the ID of the service offering of the virtual machine

=item serviceofferingname

the name of the service offering of the virtual machine

=item state

the state of the virtual machine

=item templatedisplaytext

an alternate display text of the template for the virtual machine

=item templateid

the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.

=item templatename

the name of the template for the virtual machine

=item zoneid

the ID of the availablility zone for the virtual machine

=item zonename

the name of the availability zone for the virtual machine

=back

=head2 listIsos (A)

Lists all available ISO files.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item account

the account of the ISO file. Must be used with the domainId parameter.

=item bootable

true if the ISO is bootable, false otherwise

=item domainid

lists all available ISO files by ID of a domain. If used with the account parameter, lists all available ISO files for the account in the ID of a domain.

=item hypervisor

the hypervisor for which to restrict the search

=item id

list all isos by id

=item isofilter

possible values are "featured", "self", "self-executable","executable", and "community". * featured-ISOs that are featured and are publicself-ISOs that have been registered/created by the owner. * selfexecutable-ISOs that have been registered/created by the owner that can be used to deploy a new VM. * executable-all ISOs that can be used to deploy a new VM * community-ISOs that are public.

=item ispublic

true if the ISO is publicly available to all users, false otherwise.

=item isready

true if this ISO is ready to be deployed

=item keyword

List by keyword

=item name

list all isos by name

=item page

no description

=item pagesize

no description

=item zoneid

the ID of the zone

=back

=head3 Response

=over

=item account

the account name to which the template belongs

=item accountid

the account id to which the template belongs

=item bootable

true if the ISO is bootable, false otherwise

=item checksum

checksum of the template

=item created

the date this template was created

=item crossZones

true if the template is managed across all Zones, false otherwise

=item details

additional key/value details tied with template

=item displaytext

the template display text

=item domain

the name of the domain to which the template belongs

=item domainid

the ID of the domain to which the template belongs

=item format

the format of the template.

=item hostid

the ID of the secondary storage host for the template

=item hostname

the name of the secondary storage host for the template

=item hypervisor

the hypervisor on which the template runs

=item id

the template ID

=item isextractable

true if the template is extractable, false otherwise

=item isfeatured

true if this template is a featured template, false otherwise

=item ispublic

true if this template is a public template, false otherwise

=item isready

true if the template is ready to be deployed from, false otherwise.

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template

=item jobstatus

shows the current pending asynchronous job status

=item name

the template name

=item ostypeid

the ID of the OS type for this template.

=item ostypename

the name of the OS type for this template.

=item passwordenabled

true if the reset password feature is enabled, false otherwise

=item removed

the date this template was removed

=item size

the size of the template

=item sourcetemplateid

the template ID of the parent template if present

=item status

the status of the template

=item templatetag

the tag of this template

=item templatetype

the type of the template

=item zoneid

the ID of the zone for this template

=item zonename

the name of the zone for this template

=back

=head2 registerIso

Registers an existing ISO into the Cloud.com Cloud.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item displaytext

the display text of the ISO. This is usually used for display purposes.

=item name

the name of the ISO

=item url

the URL to where the ISO is currently being hosted

=item zoneid

the ID of the zone you wish to register the ISO to.

=back

=head4 Optional Parameters

=over

=item account

an optional account name. Must be used with domainId.

=item bootable

true if this ISO is bootable

=item domainid

an optional domainId. If the account parameter is used, domainId must also be used.

=item isextractable

true if the iso or its derivatives are extractable; default is false

=item isfeatured

true if you want this ISO to be featured

=item ispublic

true if you want to register the ISO to be publicly available to all users, false otherwise.

=item ostypeid

the ID of the OS Type that best represents the OS of this ISO

=back

=head3 Response

=over

=item account

the account name to which the template belongs

=item accountid

the account id to which the template belongs

=item bootable

true if the ISO is bootable, false otherwise

=item checksum

checksum of the template

=item created

the date this template was created

=item crossZones

true if the template is managed across all Zones, false otherwise

=item details

additional key/value details tied with template

=item displaytext

the template display text

=item domain

the name of the domain to which the template belongs

=item domainid

the ID of the domain to which the template belongs

=item format

the format of the template.

=item hostid

the ID of the secondary storage host for the template

=item hostname

the name of the secondary storage host for the template

=item hypervisor

the hypervisor on which the template runs

=item id

the template ID

=item isextractable

true if the template is extractable, false otherwise

=item isfeatured

true if this template is a featured template, false otherwise

=item ispublic

true if this template is a public template, false otherwise

=item isready

true if the template is ready to be deployed from, false otherwise.

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template

=item jobstatus

shows the current pending asynchronous job status

=item name

the template name

=item ostypeid

the ID of the OS type for this template.

=item ostypename

the name of the OS type for this template.

=item passwordenabled

true if the reset password feature is enabled, false otherwise

=item removed

the date this template was removed

=item size

the size of the template

=item sourcetemplateid

the template ID of the parent template if present

=item status

the status of the template

=item templatetag

the tag of this template

=item templatetype

the type of the template

=item zoneid

the ID of the zone for this template

=item zonename

the name of the zone for this template

=back

=head2 updateIso

Updates an ISO file.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the image file

=back

=head4 Optional Parameters

=over

=item bootable

true if image is bootable, false otherwise

=item displaytext

the display text of the image

=item format

the format for the image

=item name

the name of the image file

=item ostypeid

the ID of the OS type that best represents the OS of this image.

=item passwordenabled

true if the image supports the password reset feature; default is false

=back

=head3 Response

=over

=item account

the account name to which the template belongs

=item accountid

the account id to which the template belongs

=item bootable

true if the ISO is bootable, false otherwise

=item checksum

checksum of the template

=item created

the date this template was created

=item crossZones

true if the template is managed across all Zones, false otherwise

=item details

additional key/value details tied with template

=item displaytext

the template display text

=item domain

the name of the domain to which the template belongs

=item domainid

the ID of the domain to which the template belongs

=item format

the format of the template.

=item hostid

the ID of the secondary storage host for the template

=item hostname

the name of the secondary storage host for the template

=item hypervisor

the hypervisor on which the template runs

=item id

the template ID

=item isextractable

true if the template is extractable, false otherwise

=item isfeatured

true if this template is a featured template, false otherwise

=item ispublic

true if this template is a public template, false otherwise

=item isready

true if the template is ready to be deployed from, false otherwise.

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template

=item jobstatus

shows the current pending asynchronous job status

=item name

the template name

=item ostypeid

the ID of the OS type for this template.

=item ostypename

the name of the OS type for this template.

=item passwordenabled

true if the reset password feature is enabled, false otherwise

=item removed

the date this template was removed

=item size

the size of the template

=item sourcetemplateid

the template ID of the parent template if present

=item status

the status of the template

=item templatetag

the tag of this template

=item templatetype

the type of the template

=item zoneid

the ID of the zone for this template

=item zonename

the name of the zone for this template

=back

=head2 deleteIso

Deletes an ISO file.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the ISO file

=back

=head4 Optional Parameters

=over

=item zoneid

the ID of the zone of the ISO file. If not specified, the ISO will be deleted from all the zones

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 copyIso (A)

Copies a template from one zone to another.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item destzoneid

ID of the zone the template is being copied to.

=item id

Template ID.

=item sourcezoneid

ID of the zone the template is currently hosted on.

=back

=head3 Response

=over

=item account

the account name to which the template belongs

=item accountid

the account id to which the template belongs

=item bootable

true if the ISO is bootable, false otherwise

=item checksum

checksum of the template

=item created

the date this template was created

=item crossZones

true if the template is managed across all Zones, false otherwise

=item details

additional key/value details tied with template

=item displaytext

the template display text

=item domain

the name of the domain to which the template belongs

=item domainid

the ID of the domain to which the template belongs

=item format

the format of the template.

=item hostid

the ID of the secondary storage host for the template

=item hostname

the name of the secondary storage host for the template

=item hypervisor

the hypervisor on which the template runs

=item id

the template ID

=item isextractable

true if the template is extractable, false otherwise

=item isfeatured

true if this template is a featured template, false otherwise

=item ispublic

true if this template is a public template, false otherwise

=item isready

true if the template is ready to be deployed from, false otherwise.

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template

=item jobstatus

shows the current pending asynchronous job status

=item name

the template name

=item ostypeid

the ID of the OS type for this template.

=item ostypename

the name of the OS type for this template.

=item passwordenabled

true if the reset password feature is enabled, false otherwise

=item removed

the date this template was removed

=item size

the size of the template

=item sourcetemplateid

the template ID of the parent template if present

=item status

the status of the template

=item templatetag

the tag of this template

=item templatetype

the type of the template

=item zoneid

the ID of the zone for this template

=item zonename

the name of the zone for this template

=back

=head2 updateIsoPermissions (A)

Updates iso permissions

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the template ID

=back

=head4 Optional Parameters

=over

=item accounts

a comma delimited list of accounts. If specified, "op" parameter has to be passed in.

=item isextractable

true if the template/iso is extractable, false other wise. Can be set only by root admin

=item isfeatured

true for featured template/iso, false otherwise

=item ispublic

true for public template/iso, false for private templates/isos

=item op

permission operator (add, remove, reset)

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listIsoPermissions

List template visibility and all accounts that have permissions to view this template.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the template ID

=back

=head4 Optional Parameters

=over

=item account

List template visibility and permissions for the specified account. Must be used with the domainId parameter.

=item domainid

List template visibility and permissions by domain. If used with the account parameter, specifies in which domain the specified account exists.

=back

=head3 Response

=over

=item account

the list of accounts the template is available for

=item domainid

the ID of the domain to which the template belongs

=item id

the template ID

=item ispublic

true if this template is a public template, false otherwise

=back

=head2 extractIso

Extracts an ISO

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the ISO file

=item mode

the mode of extraction - HTTP_DOWNLOAD or FTP_UPLOAD

=item zoneid

the ID of the zone where the ISO is originally located

=back

=head4 Optional Parameters

=over

=item url

the url to which the ISO would be extracted

=back

=head3 Response

=over

=item accountid

the account id to which the extracted object belongs

=item created

the time and date the object was created

=item extractId

the upload id of extracted object

=item extractMode

the mode of extraction - upload or download

=item id

the id of extracted object

=item name

the name of the extracted object

=item state

the state of the extracted object

=item status

the status of the extraction

=item storagetype

type of the storage

=item uploadpercentage

the percentage of the entity uploaded to the specified location

=item url

if mode = upload then url of the uploaded entity. if mode = download the url from which the entity can be downloaded

=item zoneid

zone ID the object was extracted from

=item zonename

zone name the object was extracted from

=back

=head1 Limit Methods

=head2 updateResourceLimit (A)

Updates resource limits for an account or domain.

User Level: 7 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item resourcetype

Type of resource to update. Values are 0, 1, 2, 3, and 4. 0 - Instance. Number of instances a user can create. 1 - IP. Number of public IP addresses a user can own. 2 - Volume. Number of disk volumes a user can create.3 - Snapshot. Number of snapshots a user can create.4 - Template. Number of templates that a user can register/create.

=back

=head4 Optional Parameters

=over

=item account

Update resource for a specified account. Must be used with the domainId parameter.

=item domainid

Update resource limits for all accounts in specified domain. If used with the account parameter, updates resource limits for a specified account in specified domain.

=item max

Maximum resource limit.

=back

=head3 Response

=over

=item account

the account of the resource limit

=item domain

the domain name of the resource limit

=item domainid

the domain ID of the resource limit

=item max

the maximum number of the resource. A -1 means the resource currently has no limit.

=item resourcetype

resource type. Values include 0, 1, 2, 3, 4. See the resourceType parameter for more information on these values.

=back

=head2 updateResourceCount

Recalculate and update resource count for an account or domain.

User Level: 7 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item domainid

If account parameter specified then updates resource counts for a specified account in this domain else update resource counts for all accounts & child domains in specified domain.

=back

=head4 Optional Parameters

=over

=item account

Update resource count for a specified account. Must be used with the domainId parameter.

=item resourcetype

Type of resource to update. If specifies valid values are 0, 1, 2, 3, and 4. If not specified will update all resource counts0 - Instance. Number of instances a user can create. 1 - IP. Number of public IP addresses a user can own. 2 - Volume. Number of disk volumes a user can create.3 - Snapshot. Number of snapshots a user can create.4 - Template. Number of templates that a user can register/create.

=back

=head3 Response

=over

=item account

the account for which resource count's are updated

=item domain

the domain name for which resource count's are updated

=item domainid

the domain ID for which resource count's are updated

=item resourcecount

resource count

=item resourcetype

resource type. Values include 0, 1, 2, 3, 4. See the resourceType parameter for more information on these values.

=back

=head2 listResourceLimits

Lists resource limits.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item account

Lists resource limits by account. Must be used with the domainId parameter.

=item domainid

Lists resource limits by domain ID. If used with the account parameter, lists resource limits for a specified account in a specified domain.

=item id

Lists resource limits by ID.

=item keyword

List by keyword

=item page

no description

=item pagesize

no description

=item resourcetype

Type of resource to update. Values are 0, 1, 2, 3, and 4. 0 - Instance. Number of instances a user can create. 1 - IP. Number of public IP addresses a user can own. 2 - Volume. Number of disk volumes a user can create.3 - Snapshot. Number of snapshots a user can create.4 - Template. Number of templates that a user can register/create.

=back

=head3 Response

=over

=item account

the account of the resource limit

=item domain

the domain name of the resource limit

=item domainid

the domain ID of the resource limit

=item max

the maximum number of the resource. A -1 means the resource currently has no limit.

=item resourcetype

resource type. Values include 0, 1, 2, 3, 4. See the resourceType parameter for more information on these values.

=back

=head1 LoadBalancer Methods

=head2 createLoadBalancerRule

Creates a load balancer rule

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item algorithm

load balancer algorithm (source, roundrobin, leastconn)

=item name

name of the load balancer rule

=item privateport

the private port of the private ip address/virtual machine where the network traffic will be load balanced to

=item publicport

the public port from where the network traffic will be load balanced from

=back

=head4 Optional Parameters

=over

=item account

the account associated with the load balancer. Must be used with the domainId parameter.

=item cidrlist

the cidr list to forward traffic from

=item description

the description of the load balancer rule

=item domainid

the domain ID associated with the load balancer

=item openfirewall

if true, firewall rule for source/end pubic port is automatically created; if false - firewall rule has to be created explicitely. Has value true by default

=item publicipid

public ip address id from where the network traffic will be load balanced from

=item zoneid

public ip address id from where the network traffic will be load balanced from

=back

=head3 Response

=over

=item account

the account of the load balancer rule

=item algorithm

the load balancer algorithm (source, roundrobin, leastconn)

=item cidrlist

the cidr list to forward traffic from

=item description

the description of the load balancer

=item domain

the domain of the load balancer rule

=item domainid

the domain ID of the load balancer rule

=item id

the load balancer rule ID

=item name

the name of the load balancer

=item privateport

the private port

=item publicip

the public ip address

=item publicipid

the public ip address id

=item publicport

the public port

=item state

the state of the rule

=item zoneid

the id of the zone the rule belongs to

=back

=head2 deleteLoadBalancerRule (A)

Deletes a load balancer rule.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the load balancer rule

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 removeFromLoadBalancerRule (A)

Removes a virtual machine or a list of virtual machines from a load balancer rule.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

The ID of the load balancer rule

=item virtualmachineids

the list of IDs of the virtual machines that are being removed from the load balancer rule (i.e. virtualMachineIds=1,2,3)

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 assignToLoadBalancerRule (A)

Assigns virtual machine or a list of virtual machines to a load balancer rule.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the load balancer rule

=item virtualmachineids

the list of IDs of the virtual machine that are being assigned to the load balancer rule(i.e. virtualMachineIds=1,2,3)

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listLoadBalancerRules (A)

Lists load balancer rules.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item account

the account of the load balancer rule. Must be used with the domainId parameter.

=item domainid

the domain ID of the load balancer rule. If used with the account parameter, lists load balancer rules for the account in the specified domain.

=item id

the ID of the load balancer rule

=item keyword

List by keyword

=item name

the name of the load balancer rule

=item page

no description

=item pagesize

no description

=item publicipid

the public IP address id of the load balancer rule

=item virtualmachineid

the ID of the virtual machine of the load balancer rule

=item zoneid

the availability zone ID

=back

=head3 Response

=over

=item account

the account of the load balancer rule

=item algorithm

the load balancer algorithm (source, roundrobin, leastconn)

=item cidrlist

the cidr list to forward traffic from

=item description

the description of the load balancer

=item domain

the domain of the load balancer rule

=item domainid

the domain ID of the load balancer rule

=item id

the load balancer rule ID

=item name

the name of the load balancer

=item privateport

the private port

=item publicip

the public ip address

=item publicipid

the public ip address id

=item publicport

the public port

=item state

the state of the rule

=item zoneid

the id of the zone the rule belongs to

=back

=head2 listLoadBalancerRuleInstances

List all virtual machine instances that are assigned to a load balancer rule.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the load balancer rule

=back

=head4 Optional Parameters

=over

=item applied

true if listing all virtual machines currently applied to the load balancer rule; default is true

=item keyword

List by keyword

=item page

no description

=item pagesize

no description

=back

=head3 Response

=over

=item account

the account associated with the virtual machine

=item cpunumber

the number of cpu this virtual machine is running with

=item cpuspeed

the speed of each cpu

=item cpuused

the amount of the vm's CPU currently used

=item created

the date when this virtual machine was created

=item displayname

user generated name. The name of the virtual machine is returned if no displayname exists.

=item domain

the name of the domain in which the virtual machine exists

=item domainid

the ID of the domain in which the virtual machine exists

=item forvirtualnetwork

the virtual network for the service offering

=item group

the group name of the virtual machine

=item groupid

the group ID of the virtual machine

=item guestosid

Os type ID of the virtual machine

=item haenable

true if high-availability is enabled, false otherwise

=item hostid

the ID of the host for the virtual machine

=item hostname

the name of the host for the virtual machine

=item hypervisor

the hypervisor on which the template runs

=item id

the ID of the virtual machine

=item ipaddress

the ip address of the virtual machine

=item isodisplaytext

an alternate display text of the ISO attached to the virtual machine

=item isoid

the ID of the ISO attached to the virtual machine

=item isoname

the name of the ISO attached to the virtual machine

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine

=item jobstatus

shows the current pending asynchronous job status

=item memory

the memory allocated for the virtual machine

=item name

the name of the virtual machine

=item networkkbsread

the incoming network traffic on the vm

=item networkkbswrite

the outgoing network traffic on the host

=item nic(*)

the list of nics associated with vm

=item password

the password (if exists) of the virtual machine

=item passwordenabled

true if the password rest feature is enabled, false otherwise

=item rootdeviceid

device ID of the root volume

=item rootdevicetype

device type of the root volume

=item securitygroup(*)

list of security groups associated with the virtual machine

=item serviceofferingid

the ID of the service offering of the virtual machine

=item serviceofferingname

the name of the service offering of the virtual machine

=item state

the state of the virtual machine

=item templatedisplaytext

an alternate display text of the template for the virtual machine

=item templateid

the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.

=item templatename

the name of the template for the virtual machine

=item zoneid

the ID of the availablility zone for the virtual machine

=item zonename

the name of the availability zone for the virtual machine

=back

=head2 updateLoadBalancerRule

Updates load balancer

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the id of the load balancer rule to update

=back

=head4 Optional Parameters

=over

=item algorithm

load balancer algorithm (source, roundrobin, leastconn)

=item description

the description of the load balancer rule

=item name

the name of the load balancer rule

=back

=head3 Response

=over

=item account

the account of the load balancer rule

=item algorithm

the load balancer algorithm (source, roundrobin, leastconn)

=item cidrlist

the cidr list to forward traffic from

=item description

the description of the load balancer

=item domain

the domain of the load balancer rule

=item domainid

the domain ID of the load balancer rule

=item id

the load balancer rule ID

=item name

the name of the load balancer

=item privateport

the private port

=item publicip

the public ip address

=item publicipid

the public ip address id

=item publicport

the public port

=item state

the state of the rule

=item zoneid

the id of the zone the rule belongs to

=back

=head1 NAT Methods

=head2 enableStaticNat (A)

Enables static nat for given ip address

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item ipaddressid

the public IP address id for which static nat feature is being enabled

=item virtualmachineid

the ID of the virtual machine for enabling static nat feature

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 createIpForwardingRule

Creates an ip forwarding rule

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item ipaddressid

the public IP address id of the forwarding rule, already associated via associateIp

=item protocol

the protocol for the rule. Valid values are TCP or UDP.

=item startport

the start port for the rule

=back

=head4 Optional Parameters

=over

=item cidrlist

the cidr list to forward traffic from

=item endport

the end port for the rule

=item openfirewall

if true, firewall rule for source/end pubic port is automatically created; if false - firewall rule has to be created explicitely. Has value true by default

=back

=head3 Response

=over

=item cidrlist

the cidr list to forward traffic from

=item id

the ID of the port forwarding rule

=item ipaddress

the public ip address for the port forwarding rule

=item ipaddressid

the public ip address id for the port forwarding rule

=item privateendport

the ending port of port forwarding rule's private port range

=item privateport

the starting port of port forwarding rule's private port range

=item protocol

the protocol of the port forwarding rule

=item publicendport

the ending port of port forwarding rule's private port range

=item publicport

the starting port of port forwarding rule's public port range

=item state

the state of the rule

=item virtualmachinedisplayname

the VM display name for the port forwarding rule

=item virtualmachineid

the VM ID for the port forwarding rule

=item virtualmachinename

the VM name for the port forwarding rule

=back

=head2 deleteIpForwardingRule (A)

Deletes an ip forwarding rule

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the id of the forwarding rule

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listIpForwardingRules (A)

List the ip forwarding rules

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item account

the account associated with the ip forwarding rule. Must be used with the domainId parameter.

=item domainid

Lists all rules for this id. If used with the account parameter, returns all rules for an account in the specified domain ID.

=item id

Lists rule with the specified ID.

=item ipaddressid

list the rule belonging to this public ip address

=item keyword

List by keyword

=item page

no description

=item pagesize

no description

=item virtualmachineid

Lists all rules applied to the specified Vm.

=back

=head3 Response

=over

=item cidrlist

the cidr list to forward traffic from

=item id

the ID of the port forwarding rule

=item ipaddress

the public ip address for the port forwarding rule

=item ipaddressid

the public ip address id for the port forwarding rule

=item privateendport

the ending port of port forwarding rule's private port range

=item privateport

the starting port of port forwarding rule's private port range

=item protocol

the protocol of the port forwarding rule

=item publicendport

the ending port of port forwarding rule's private port range

=item publicport

the starting port of port forwarding rule's public port range

=item state

the state of the rule

=item virtualmachinedisplayname

the VM display name for the port forwarding rule

=item virtualmachineid

the VM ID for the port forwarding rule

=item virtualmachinename

the VM name for the port forwarding rule

=back

=head2 disableStaticNat

Disables static rule for given ip address

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item ipaddressid

the public IP address id for which static nat feature is being disableed

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head1 NetAppIntegration Methods

=head2 createVolumeOnFiler (A)

Create a volume

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item aggregatename

aggregate name.

=item ipaddress

ip address.

=item password

password.

=item poolname

pool name.

=item size

volume size.

=item username

user name.

=item volumename

volume name.

=back

=head4 Optional Parameters

=over

=item snapshotpolicy

snapshot policy.

=item snapshotreservation

snapshot reservation.

=back

=head3 Response

=over

=back

=head2 destroyVolumeOnFiler

Destroy a Volume

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item aggregatename

aggregate name.

=item ipaddress

ip address.

=item volumename

volume name.

=back

=head3 Response

=over

=back

=head2 listVolumesOnFiler

List Volumes

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item poolname

pool name.

=back

=head3 Response

=over

=item aggregatename

Aggregate name

=item id

volume id

=item ipaddress

ip address

=item poolname

pool name

=item size

volume size

=item snapshotpolicy

snapshot policy

=item snapshotreservation

snapshot reservation

=item volumename

Volume name

=back

=head2 createLunOnFiler

Create a LUN from a pool

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item name

pool name.

=item size

LUN size.

=back

=head3 Response

=over

=item ipaddress

ip address

=item iqn

iqn

=item path

pool path

=back

=head2 destroyLunOnFiler

Destroy a LUN

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item path

LUN path.

=back

=head3 Response

=over

=back

=head2 listLunsOnFiler

List LUN

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item poolname

pool name.

=back

=head3 Response

=over

=item id

lun id

=item iqn

lun iqn

=item name

lun name

=item volumeid

volume id

=back

=head2 associateLun

Associate a LUN with a guest IQN

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item iqn

Guest IQN to which the LUN associate.

=item name

LUN name.

=back

=head3 Response

=over

=item id

the LUN id

=item ipaddress

the IP address of

=item targetiqn

the target IQN

=back

=head2 dissociateLun

Dissociate a LUN

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item iqn

Guest IQN.

=item path

LUN path.

=back

=head3 Response

=over

=back

=head2 createPool

Create a pool

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item algorithm

algorithm.

=item name

pool name.

=back

=head3 Response

=over

=back

=head2 deletePool

Delete a pool

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item poolname

pool name.

=back

=head3 Response

=over

=back

=head2 modifyPool

Modify pool

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item algorithm

algorithm.

=item poolname

pool name.

=back

=head3 Response

=over

=back

=head2 listPools

List Pool

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head3 Response

=over

=item algorithm

pool algorithm

=item id

pool id

=item name

pool name

=back

=head1 Network Methods

=head2 createNetwork

Creates a network

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item displaytext

the display text of the network

=item name

the name of the network

=item networkofferingid

the network offering id

=item zoneid

the Zone ID for the network

=back

=head4 Optional Parameters

=over

=item account

account who will own the network

=item domainid

domain ID of the account owning a network

=item endip

the ending IP address in the network IP range. If not specified, will be defaulted to startIP

=item gateway

the gateway of the network

=item isdefault

true if network is default, false otherwise

=item isshared

true is network is shared across accounts in the Zone

=item netmask

the netmask of the network

=item networkdomain

network domain

=item startip

the beginning IP address in the network IP range

=item tags

Tag the network

=item vlan

the ID or VID of the network

=back

=head3 Response

=over

=item account

the owner of the network

=item broadcastdomaintype

Broadcast domain type of the network

=item broadcasturi

broadcast uri of the network

=item displaytext

the displaytext of the network

=item dns1

the first DNS for the network

=item dns2

the second DNS for the network

=item domain

the domain name of the network owner

=item domainid

the domain id of the network owner

=item endip

the end ip of the network

=item gateway

the network's gateway

=item id

the id of the network

=item isdefault

true if network is default, false otherwise

=item isshared

true if network is shared, false otherwise

=item issystem

true if network is system, false otherwise

=item name

the name of the network

=item netmask

the network's netmask

=item networkdomain

the network domain

=item networkofferingavailability

availability of the network offering the network is created from

=item networkofferingdisplaytext

display text of the network offering the network is created from

=item networkofferingid

network offering id the network is created from

=item networkofferingname

name of the network offering the network is created from

=item related

related to what other network configuration

=item securitygroupenabled

true if security group is enabled, false otherwise

=item service(*)

the list of services

=item startip

the start ip of the network

=item state

state of the network

=item tags

comma separated tag

=item traffictype

the traffic type of the network

=item type

the type of the network

=item vlan

the vlan of the network

=item zoneid

zone id of the network

=back

=head2 deleteNetwork

Deletes a network

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the network

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listNetworks (A)

Lists all available networks.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item account

account who will own the VLAN. If VLAN is Zone wide, this parameter should be ommited

=item domainid

domain ID of the account owning a VLAN

=item id

list networks by id

=item isdefault

true if network is default, false otherwise

=item isshared

true if network is shared across accounts in the Zone, false otherwise

=item issystem

true if network is system, false otherwise

=item keyword

List by keyword

=item page

no description

=item pagesize

no description

=item traffictype

type of the traffic

=item type

the type of the network

=item zoneid

the Zone ID of the network

=back

=head3 Response

=over

=item account

the owner of the network

=item broadcastdomaintype

Broadcast domain type of the network

=item broadcasturi

broadcast uri of the network

=item displaytext

the displaytext of the network

=item dns1

the first DNS for the network

=item dns2

the second DNS for the network

=item domain

the domain name of the network owner

=item domainid

the domain id of the network owner

=item endip

the end ip of the network

=item gateway

the network's gateway

=item id

the id of the network

=item isdefault

true if network is default, false otherwise

=item isshared

true if network is shared, false otherwise

=item issystem

true if network is system, false otherwise

=item name

the name of the network

=item netmask

the network's netmask

=item networkdomain

the network domain

=item networkofferingavailability

availability of the network offering the network is created from

=item networkofferingdisplaytext

display text of the network offering the network is created from

=item networkofferingid

network offering id the network is created from

=item networkofferingname

name of the network offering the network is created from

=item related

related to what other network configuration

=item securitygroupenabled

true if security group is enabled, false otherwise

=item service(*)

the list of services

=item startip

the start ip of the network

=item state

state of the network

=item tags

comma separated tag

=item traffictype

the traffic type of the network

=item type

the type of the network

=item vlan

the vlan of the network

=item zoneid

zone id of the network

=back

=head2 restartNetwork

Restarts the network; includes 1) restarting network elements - virtual routers, dhcp servers 2) reapplying all public ips 3) reapplying loadBalancing/portForwarding rules

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

The id of the network to restart.

=back

=head4 Optional Parameters

=over

=item cleanup

If cleanup old network elements

=back

=head3 Response

=over

=item account

the account the public IP address is associated with

=item allocated

date the public IP address was acquired

=item associatednetworkid

the ID of the Network associated with the IP address

=item domain

the domain the public IP address is associated with

=item domainid

the domain ID the public IP address is associated with

=item forvirtualnetwork

the virtual network for the IP address

=item id

public IP address id

=item ipaddress

public IP address

=item issourcenat

true if the IP address is a source nat address, false otherwise

=item isstaticnat

true if this ip is for static nat, false otherwise

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume

=item jobstatus

shows the current pending asynchronous job status

=item networkid

the ID of the Network where ip belongs to

=item state

State of the ip address. Can be: Allocatin, Allocated and Releasing

=item virtualmachinedisplayname

virutal machine display name the ip address is assigned to (not null only for static nat Ip)

=item virtualmachineid

virutal machine id the ip address is assigned to (not null only for static nat Ip)

=item virtualmachinename

virutal machine name the ip address is assigned to (not null only for static nat Ip)

=item vlanid

the ID of the VLAN associated with the IP address

=item vlanname

the VLAN associated with the IP address

=item zoneid

the ID of the zone the public IP address belongs to

=item zonename

the name of the zone the public IP address belongs to

=back

=head2 updateNetwork (A)

Updates a network

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the network

=back

=head4 Optional Parameters

=over

=item displaytext

the new display text for the network

=item name

the new name for the network

=item networkdomain

network domain

=item tags

tags for the network

=back

=head3 Response

=over

=item account

the owner of the network

=item broadcastdomaintype

Broadcast domain type of the network

=item broadcasturi

broadcast uri of the network

=item displaytext

the displaytext of the network

=item dns1

the first DNS for the network

=item dns2

the second DNS for the network

=item domain

the domain name of the network owner

=item domainid

the domain id of the network owner

=item endip

the end ip of the network

=item gateway

the network's gateway

=item id

the id of the network

=item isdefault

true if network is default, false otherwise

=item isshared

true if network is shared, false otherwise

=item issystem

true if network is system, false otherwise

=item name

the name of the network

=item netmask

the network's netmask

=item networkdomain

the network domain

=item networkofferingavailability

availability of the network offering the network is created from

=item networkofferingdisplaytext

display text of the network offering the network is created from

=item networkofferingid

network offering id the network is created from

=item networkofferingname

name of the network offering the network is created from

=item related

related to what other network configuration

=item securitygroupenabled

true if security group is enabled, false otherwise

=item service(*)

the list of services

=item startip

the start ip of the network

=item state

state of the network

=item tags

comma separated tag

=item traffictype

the traffic type of the network

=item type

the type of the network

=item vlan

the vlan of the network

=item zoneid

zone id of the network

=back

=head1 NetworkDevices Methods

=head2 addNetworkDevice (A)

List external load balancer appliances.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item networkdeviceparameterlist

parameters for network device

=item networkdevicetype

Network device type, now supports ExternalDhcp, ExternalFirewall, ExternalLoadBalancer, PxeServer

=back

=head3 Response

=over

=item id

the ID of the network device

=back

=head2 listNetworkDevice

List network device.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item keyword

List by keyword

=item networkdeviceparameterlist

parameters for network device

=item networkdevicetype

Network device type, now supports ExternalDhcp, ExternalFirewall, ExternalLoadBalancer, PxeServer

=item page

no description

=item pagesize

no description

=back

=head3 Response

=over

=item id

the ID of the network device

=back

=head2 deleteNetworkDevice

Delete network device.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item id

Id of network device to delete

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head1 NetworkOffering Methods

=head2 updateNetworkOffering

Updates a network offering.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item availability

the availability of network offering. Default value is Required for Guest Virtual network offering; Optional for Guest Direct network offering

=item displaytext

the display text of the network offering

=item id

the id of the network offering

=item name

the name of the network offering

=back

=head3 Response

=over

=item availability

availability of the network offering

=item created

the date this network offering was created

=item displaytext

an alternate display text of the network offering.

=item guestiptype

guest ip type of the network offering

=item id

the id of the network offering

=item isdefault

true if network offering is default, false otherwise

=item maxconnections

the max number of concurrent connection the network offering supports

=item name

the name of the network offering

=item networkrate

data transfer rate in megabits per second allowed.

=item specifyvlan

true if network offering supports vlans, false otherwise

=item tags

the tags for the network offering

=item traffictype

the traffic type for the network offering, supported types are Public, Management, Control, Guest, Vlan or Storage.

=back

=head2 listNetworkOfferings

Lists all available network offerings.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item availability

the availability of network offering. Default value is Required

=item displaytext

list network offerings by display text

=item guestiptype

the guest ip type for the network offering, supported types are Direct and Virtual.

=item id

list network offerings by id

=item isdefault

true if need to list only default network offerings. Default value is false

=item isshared

true is network offering supports vlans

=item keyword

List by keyword

=item name

list network offerings by name

=item page

no description

=item pagesize

no description

=item specifyvlan

the tags for the network offering.

=item traffictype

list by traffic type

=item zoneid

list netowrk offerings available for network creation in specific zone

=back

=head3 Response

=over

=item availability

availability of the network offering

=item created

the date this network offering was created

=item displaytext

an alternate display text of the network offering.

=item guestiptype

guest ip type of the network offering

=item id

the id of the network offering

=item isdefault

true if network offering is default, false otherwise

=item maxconnections

the max number of concurrent connection the network offering supports

=item name

the name of the network offering

=item networkrate

data transfer rate in megabits per second allowed.

=item specifyvlan

true if network offering supports vlans, false otherwise

=item tags

the tags for the network offering

=item traffictype

the traffic type for the network offering, supported types are Public, Management, Control, Guest, Vlan or Storage.

=back

=head1 Other Methods

=head2 listHypervisors

List hypervisors

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item zoneid

the zone id for listing hypervisors.

=back

=head3 Response

=over

=item name

Hypervisor name

=back

=head1 Pod Methods

=head2 createPod

Creates a new Pod.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item gateway

the gateway for the Pod

=item name

the name of the Pod

=item netmask

the netmask for the Pod

=item startip

the starting IP address for the Pod

=item zoneid

the Zone ID in which the Pod will be created

=back

=head4 Optional Parameters

=over

=item allocationstate

Allocation state of this Pod for allocation of new resources

=item endip

the ending IP address for the Pod

=back

=head3 Response

=over

=item allocationstate

the allocation state of the cluster

=item endip

the ending IP for the Pod

=item gateway

the gateway of the Pod

=item id

the ID of the Pod

=item name

the name of the Pod

=item netmask

the netmask of the Pod

=item startip

the starting IP for the Pod

=item zoneid

the Zone ID of the Pod

=item zonename

the Zone name of the Pod

=back

=head2 updatePod

Updates a Pod.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the Pod

=back

=head4 Optional Parameters

=over

=item allocationstate

Allocation state of this cluster for allocation of new resources

=item endip

the ending IP address for the Pod

=item gateway

the gateway for the Pod

=item name

the name of the Pod

=item netmask

the netmask of the Pod

=item startip

the starting IP address for the Pod

=back

=head3 Response

=over

=item allocationstate

the allocation state of the cluster

=item endip

the ending IP for the Pod

=item gateway

the gateway of the Pod

=item id

the ID of the Pod

=item name

the name of the Pod

=item netmask

the netmask of the Pod

=item startip

the starting IP for the Pod

=item zoneid

the Zone ID of the Pod

=item zonename

the Zone name of the Pod

=back

=head2 deletePod

Deletes a Pod.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the Pod

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listPods

Lists all Pods.

User Level: 3 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item allocationstate

list pods by allocation state

=item id

list Pods by ID

=item keyword

List by keyword

=item name

list Pods by name

=item page

no description

=item pagesize

no description

=item zoneid

list Pods by Zone ID

=back

=head3 Response

=over

=item allocationstate

the allocation state of the cluster

=item endip

the ending IP for the Pod

=item gateway

the gateway of the Pod

=item id

the ID of the Pod

=item name

the name of the Pod

=item netmask

the netmask of the Pod

=item startip

the starting IP for the Pod

=item zoneid

the Zone ID of the Pod

=item zonename

the Zone name of the Pod

=back

=head1 Registration Methods

=head2 registerUserKeys

This command allows a user to register for the developer API, returning a secret key and an API key. This request is made through the integration API port, so it is a privileged command and must be made on behalf of a user. It is up to the implementer just how the username and password are entered, and then how that translates to an integration API request. Both secret key and API key should be returned to the user

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

User id

=back

=head3 Response

=over

=item apikey

the api key of the registered user

=item secretkey

the secret key of the registered user

=back

=head1 Router Methods

=head2 startRouter

Starts a router.

User Level: 7 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the router

=back

=head3 Response

=over

=item account

the account associated with the router

=item created

the date and time the router was created

=item dns1

the first DNS for the router

=item dns2

the second DNS for the router

=item domain

the domain associated with the router

=item domainid

the domain ID associated with the router

=item gateway

the gateway for the router

=item guestipaddress

the guest IP address for the router

=item guestmacaddress

the guest MAC address for the router

=item guestnetmask

the guest netmask for the router

=item guestnetworkid

the ID of the corresponding guest network

=item hostid

the host ID for the router

=item hostname

the hostname for the router

=item id

the id of the router

=item isredundantrouter

if this router is an redundant virtual router

=item linklocalip

the link local IP address for the router

=item linklocalmacaddress

the link local MAC address for the router

=item linklocalnetmask

the link local netmask for the router

=item linklocalnetworkid

the ID of the corresponding link local network

=item name

the name of the router

=item networkdomain

the network domain for the router

=item podid

the Pod ID for the router

=item publicip

the public IP address for the router

=item publicmacaddress

the public MAC address for the router

=item publicnetmask

the public netmask for the router

=item publicnetworkid

the ID of the corresponding public network

=item redundantstate

the state of redundant virtual router

=item serviceofferingid

the ID of the service offering of the virtual machine

=item serviceofferingname

the name of the service offering of the virtual machine

=item state

the state of the router

=item templateid

the template ID for the router

=item zoneid

the Zone ID for the router

=item zonename

the Zone name for the router

=back

=head2 rebootRouter (A)

Starts a router.

User Level: 7 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the router

=back

=head3 Response

=over

=item account

the account associated with the router

=item created

the date and time the router was created

=item dns1

the first DNS for the router

=item dns2

the second DNS for the router

=item domain

the domain associated with the router

=item domainid

the domain ID associated with the router

=item gateway

the gateway for the router

=item guestipaddress

the guest IP address for the router

=item guestmacaddress

the guest MAC address for the router

=item guestnetmask

the guest netmask for the router

=item guestnetworkid

the ID of the corresponding guest network

=item hostid

the host ID for the router

=item hostname

the hostname for the router

=item id

the id of the router

=item isredundantrouter

if this router is an redundant virtual router

=item linklocalip

the link local IP address for the router

=item linklocalmacaddress

the link local MAC address for the router

=item linklocalnetmask

the link local netmask for the router

=item linklocalnetworkid

the ID of the corresponding link local network

=item name

the name of the router

=item networkdomain

the network domain for the router

=item podid

the Pod ID for the router

=item publicip

the public IP address for the router

=item publicmacaddress

the public MAC address for the router

=item publicnetmask

the public netmask for the router

=item publicnetworkid

the ID of the corresponding public network

=item redundantstate

the state of redundant virtual router

=item serviceofferingid

the ID of the service offering of the virtual machine

=item serviceofferingname

the name of the service offering of the virtual machine

=item state

the state of the router

=item templateid

the template ID for the router

=item zoneid

the Zone ID for the router

=item zonename

the Zone name for the router

=back

=head2 stopRouter (A)

Stops a router.

User Level: 7 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the router

=back

=head4 Optional Parameters

=over

=item forced

Force stop the VM. The caller knows the VM is stopped.

=back

=head3 Response

=over

=item account

the account associated with the router

=item created

the date and time the router was created

=item dns1

the first DNS for the router

=item dns2

the second DNS for the router

=item domain

the domain associated with the router

=item domainid

the domain ID associated with the router

=item gateway

the gateway for the router

=item guestipaddress

the guest IP address for the router

=item guestmacaddress

the guest MAC address for the router

=item guestnetmask

the guest netmask for the router

=item guestnetworkid

the ID of the corresponding guest network

=item hostid

the host ID for the router

=item hostname

the hostname for the router

=item id

the id of the router

=item isredundantrouter

if this router is an redundant virtual router

=item linklocalip

the link local IP address for the router

=item linklocalmacaddress

the link local MAC address for the router

=item linklocalnetmask

the link local netmask for the router

=item linklocalnetworkid

the ID of the corresponding link local network

=item name

the name of the router

=item networkdomain

the network domain for the router

=item podid

the Pod ID for the router

=item publicip

the public IP address for the router

=item publicmacaddress

the public MAC address for the router

=item publicnetmask

the public netmask for the router

=item publicnetworkid

the ID of the corresponding public network

=item redundantstate

the state of redundant virtual router

=item serviceofferingid

the ID of the service offering of the virtual machine

=item serviceofferingname

the name of the service offering of the virtual machine

=item state

the state of the router

=item templateid

the template ID for the router

=item zoneid

the Zone ID for the router

=item zonename

the Zone name for the router

=back

=head2 destroyRouter (A)

Destroys a router.

User Level: 7 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the router

=back

=head3 Response

=over

=item account

the account associated with the router

=item created

the date and time the router was created

=item dns1

the first DNS for the router

=item dns2

the second DNS for the router

=item domain

the domain associated with the router

=item domainid

the domain ID associated with the router

=item gateway

the gateway for the router

=item guestipaddress

the guest IP address for the router

=item guestmacaddress

the guest MAC address for the router

=item guestnetmask

the guest netmask for the router

=item guestnetworkid

the ID of the corresponding guest network

=item hostid

the host ID for the router

=item hostname

the hostname for the router

=item id

the id of the router

=item isredundantrouter

if this router is an redundant virtual router

=item linklocalip

the link local IP address for the router

=item linklocalmacaddress

the link local MAC address for the router

=item linklocalnetmask

the link local netmask for the router

=item linklocalnetworkid

the ID of the corresponding link local network

=item name

the name of the router

=item networkdomain

the network domain for the router

=item podid

the Pod ID for the router

=item publicip

the public IP address for the router

=item publicmacaddress

the public MAC address for the router

=item publicnetmask

the public netmask for the router

=item publicnetworkid

the ID of the corresponding public network

=item redundantstate

the state of redundant virtual router

=item serviceofferingid

the ID of the service offering of the virtual machine

=item serviceofferingname

the name of the service offering of the virtual machine

=item state

the state of the router

=item templateid

the template ID for the router

=item zoneid

the Zone ID for the router

=item zonename

the Zone name for the router

=back

=head2 changeServiceForRouter (A)

Upgrades domain router to a new service offering

User Level: 7 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

The ID of the router

=item serviceofferingid

the service offering ID to apply to the domain router

=back

=head3 Response

=over

=item account

the account associated with the router

=item created

the date and time the router was created

=item dns1

the first DNS for the router

=item dns2

the second DNS for the router

=item domain

the domain associated with the router

=item domainid

the domain ID associated with the router

=item gateway

the gateway for the router

=item guestipaddress

the guest IP address for the router

=item guestmacaddress

the guest MAC address for the router

=item guestnetmask

the guest netmask for the router

=item guestnetworkid

the ID of the corresponding guest network

=item hostid

the host ID for the router

=item hostname

the hostname for the router

=item id

the id of the router

=item isredundantrouter

if this router is an redundant virtual router

=item linklocalip

the link local IP address for the router

=item linklocalmacaddress

the link local MAC address for the router

=item linklocalnetmask

the link local netmask for the router

=item linklocalnetworkid

the ID of the corresponding link local network

=item name

the name of the router

=item networkdomain

the network domain for the router

=item podid

the Pod ID for the router

=item publicip

the public IP address for the router

=item publicmacaddress

the public MAC address for the router

=item publicnetmask

the public netmask for the router

=item publicnetworkid

the ID of the corresponding public network

=item redundantstate

the state of redundant virtual router

=item serviceofferingid

the ID of the service offering of the virtual machine

=item serviceofferingname

the name of the service offering of the virtual machine

=item state

the state of the router

=item templateid

the template ID for the router

=item zoneid

the Zone ID for the router

=item zonename

the Zone name for the router

=back

=head2 listRouters

List routers.

User Level: 7 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item account

the name of the account associated with the router. Must be used with the domainId parameter.

=item domainid

the domain ID associated with the router. If used with the account parameter, lists all routers associated with an account in the specified domain.

=item hostid

the host ID of the router

=item id

the ID of the disk router

=item keyword

List by keyword

=item name

the name of the router

=item networkid

list by network id

=item page

no description

=item pagesize

no description

=item podid

the Pod ID of the router

=item state

the state of the router

=item zoneid

the Zone ID of the router

=back

=head3 Response

=over

=item account

the account associated with the router

=item created

the date and time the router was created

=item dns1

the first DNS for the router

=item dns2

the second DNS for the router

=item domain

the domain associated with the router

=item domainid

the domain ID associated with the router

=item gateway

the gateway for the router

=item guestipaddress

the guest IP address for the router

=item guestmacaddress

the guest MAC address for the router

=item guestnetmask

the guest netmask for the router

=item guestnetworkid

the ID of the corresponding guest network

=item hostid

the host ID for the router

=item hostname

the hostname for the router

=item id

the id of the router

=item isredundantrouter

if this router is an redundant virtual router

=item linklocalip

the link local IP address for the router

=item linklocalmacaddress

the link local MAC address for the router

=item linklocalnetmask

the link local netmask for the router

=item linklocalnetworkid

the ID of the corresponding link local network

=item name

the name of the router

=item networkdomain

the network domain for the router

=item podid

the Pod ID for the router

=item publicip

the public IP address for the router

=item publicmacaddress

the public MAC address for the router

=item publicnetmask

the public netmask for the router

=item publicnetworkid

the ID of the corresponding public network

=item redundantstate

the state of redundant virtual router

=item serviceofferingid

the ID of the service offering of the virtual machine

=item serviceofferingname

the name of the service offering of the virtual machine

=item state

the state of the router

=item templateid

the template ID for the router

=item zoneid

the Zone ID for the router

=item zonename

the Zone name for the router

=back

=head1 SSHKeyPair Methods

=head2 registerSSHKeyPair

Register a public key in a keypair under a certain name

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item name

Name of the keypair

=item publickey

Public key material of the keypair

=back

=head4 Optional Parameters

=over

=item account

an optional account for the ssh key. Must be used with domainId.

=item domainid

an optional domainId for the ssh key. If the account parameter is used, domainId must also be used.

=back

=head3 Response

=over

=item fingerprint

Fingerprint of the public key

=item name

Name of the keypair

=item privatekey

Private key

=back

=head2 createSSHKeyPair

Create a new keypair and returns the private key

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item name

Name of the keypair

=back

=head4 Optional Parameters

=over

=item account

an optional account for the ssh key. Must be used with domainId.

=item domainid

an optional domainId for the ssh key. If the account parameter is used, domainId must also be used.

=back

=head3 Response

=over

=item fingerprint

Fingerprint of the public key

=item name

Name of the keypair

=item privatekey

Private key

=back

=head2 deleteSSHKeyPair

Deletes a keypair by name

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item name

Name of the keypair

=back

=head4 Optional Parameters

=over

=item account

the account associated with the keypair. Must be used with the domainId parameter.

=item domainid

the domain ID associated with the keypair

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listSSHKeyPairs

List registered keypairs

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item fingerprint

A public key fingerprint to look for

=item keyword

List by keyword

=item name

A key pair name to look for

=item page

no description

=item pagesize

no description

=back

=head3 Response

=over

=item fingerprint

Fingerprint of the public key

=item name

Name of the keypair

=item privatekey

Private key

=back

=head1 SecurityGroup Methods

=head2 createSecurityGroup

Creates a security group

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item name

name of the security group

=back

=head4 Optional Parameters

=over

=item account

an optional account for the security group. Must be used with domainId.

=item description

the description of the security group

=item domainid

an optional domainId for the security group. If the account parameter is used, domainId must also be used.

=back

=head3 Response

=over

=item account

the account owning the security group

=item description

the description of the security group

=item domain

the domain name of the security group

=item domainid

the domain ID of the security group

=item id

the ID of the security group

=item ingressrule(*)

the list of ingress rules associated with the security group

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume

=item jobstatus

shows the current pending asynchronous job status

=item name

the name of the security group

=back

=head2 deleteSecurityGroup

Deletes security group

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item account

the account of the security group. Must be specified with domain ID

=item domainid

the domain ID of account owning the security group

=item id

The ID of the security group. Mutually exclusive with name parameter

=item name

The ID of the security group. Mutually exclusive with id parameter

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 authorizeSecurityGroupIngress

Authorizes a particular ingress rule for this security group

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item account

an optional account for the virtual machine. Must be used with domainId.

=item cidrlist

the cidr list associated

=item domainid

an optional domainId for the security group. If the account parameter is used, domainId must also be used.

=item endport

end port for this ingress rule

=item icmpcode

error code for this icmp message

=item icmptype

type of the icmp message being sent

=item protocol

TCP is default. UDP is the other supported protocol

=item securitygroupid

The ID of the security group. Mutually exclusive with securityGroupName parameter

=item securitygroupname

The name of the security group. Mutually exclusive with securityGroupName parameter

=item startport

start port for this ingress rule

=item usersecuritygrouplist

user to security group mapping

=back

=head3 Response

=over

=item account

account owning the ingress rule

=item cidr

the CIDR notation for the base IP address of the ingress rule

=item endport

the ending IP of the ingress rule

=item icmpcode

the code for the ICMP message response

=item icmptype

the type of the ICMP message response

=item protocol

the protocol of the ingress rule

=item ruleid

the id of the ingress rule

=item securitygroupname

security group name

=item startport

the starting IP of the ingress rule

=back

=head2 revokeSecurityGroupIngress (A)

Deletes a particular ingress rule from this security group

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

The ID of the ingress rule

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listSecurityGroups (A)

Lists security groups

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item account

lists all available port security groups for the account. Must be used with domainID parameter

=item domainid

lists all available security groups for the domain ID. If used with the account parameter, lists all available security groups for the account in the specified domain ID.

=item id

list the security group by the id provided

=item keyword

List by keyword

=item page

no description

=item pagesize

no description

=item securitygroupname

lists security groups by name

=item virtualmachineid

lists security groups by virtual machine id

=back

=head3 Response

=over

=item account

the account owning the security group

=item description

the description of the security group

=item domain

the domain name of the security group

=item domainid

the domain ID of the security group

=item id

the ID of the security group

=item ingressrule(*)

the list of ingress rules associated with the security group

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume

=item jobstatus

shows the current pending asynchronous job status

=item name

the name of the security group

=back

=head1 ServiceOffering Methods

=head2 createServiceOffering

Creates a service offering.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item cpunumber

the CPU number of the service offering

=item cpuspeed

the CPU speed of the service offering in MHz.

=item displaytext

the display text of the service offering

=item memory

the total memory of the service offering in MB

=item name

the name of the service offering

=back

=head4 Optional Parameters

=over

=item domainid

the ID of the containing domain, null for public offerings

=item hosttags

the host tag for this service offering.

=item issystem

is this a system vm offering

=item limitcpuuse

restrict the CPU usage to committed service offering

=item networkrate

data transfer rate in megabits per second allowed. Supported only for non-System offering and system offerings having "domainrouter" systemvmtype

=item offerha

the HA for the service offering

=item storagetype

the storage type of the service offering. Values are local and shared.

=item systemvmtype

the system VM type. Possible types are "domainrouter", "consoleproxy" and "secondarystoragevm".

=item tags

the tags for this service offering.

=back

=head3 Response

=over

=item cpunumber

the number of CPU

=item cpuspeed

the clock rate CPU speed in Mhz

=item created

the date this service offering was created

=item defaultuse

is this a  default system vm offering

=item displaytext

an alternate display text of the service offering.

=item domain

Domain name for the offering

=item domainid

the domain id of the service offering

=item hosttags

the host tag for the service offering

=item id

the id of the service offering

=item issystem

is this a system vm offering

=item limitcpuuse

restrict the CPU usage to committed service offering

=item memory

the memory in MB

=item name

the name of the service offering

=item networkrate

data transfer rate in megabits per second allowed.

=item offerha

the ha support in the service offering

=item storagetype

the storage type for this service offering

=item systemvmtype

is this a the systemvm type for system vm offering

=item tags

the tags for the service offering

=back

=head2 deleteServiceOffering

Deletes a service offering.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the service offering

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 updateServiceOffering

Updates a service offering.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the service offering to be updated

=back

=head4 Optional Parameters

=over

=item displaytext

the display text of the service offering to be updated

=item name

the name of the service offering to be updated

=back

=head3 Response

=over

=item cpunumber

the number of CPU

=item cpuspeed

the clock rate CPU speed in Mhz

=item created

the date this service offering was created

=item defaultuse

is this a  default system vm offering

=item displaytext

an alternate display text of the service offering.

=item domain

Domain name for the offering

=item domainid

the domain id of the service offering

=item hosttags

the host tag for the service offering

=item id

the id of the service offering

=item issystem

is this a system vm offering

=item limitcpuuse

restrict the CPU usage to committed service offering

=item memory

the memory in MB

=item name

the name of the service offering

=item networkrate

data transfer rate in megabits per second allowed.

=item offerha

the ha support in the service offering

=item storagetype

the storage type for this service offering

=item systemvmtype

is this a the systemvm type for system vm offering

=item tags

the tags for the service offering

=back

=head2 listServiceOfferings

Lists all available service offerings.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item domainid

the ID of the domain associated with the service offering

=item id

ID of the service offering

=item issystem

is this a system vm offering

=item keyword

List by keyword

=item name

name of the service offering

=item page

no description

=item pagesize

no description

=item systemvmtype

the system VM type. Possible types are "consoleproxy", "secondarystoragevm" or "domainrouter".

=item virtualmachineid

the ID of the virtual machine. Pass this in if you want to see the available service offering that a virtual machine can be changed to.

=back

=head3 Response

=over

=item cpunumber

the number of CPU

=item cpuspeed

the clock rate CPU speed in Mhz

=item created

the date this service offering was created

=item defaultuse

is this a  default system vm offering

=item displaytext

an alternate display text of the service offering.

=item domain

Domain name for the offering

=item domainid

the domain id of the service offering

=item hosttags

the host tag for the service offering

=item id

the id of the service offering

=item issystem

is this a system vm offering

=item limitcpuuse

restrict the CPU usage to committed service offering

=item memory

the memory in MB

=item name

the name of the service offering

=item networkrate

data transfer rate in megabits per second allowed.

=item offerha

the ha support in the service offering

=item storagetype

the storage type for this service offering

=item systemvmtype

is this a the systemvm type for system vm offering

=item tags

the tags for the service offering

=back

=head1 Session Methods

=head2 login

Logs a user into the CloudStack. A successful login attempt will generate a JSESSIONID cookie value that can be passed in subsequent Query command calls until the "logout" command has been issued or the session has expired.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item password

Hashed password (Default is MD5). If you wish to use any other hashing algorithm, you would need to write a custom authentication adapter See Docs section.

=item username

Username

=back

=head4 Optional Parameters

=over

=item domain

path of the domain that the user belongs to. Example: domain=/com/cloud/internal.  If no domain is passed in, the ROOT domain is assumed.

=back

=head3 Response

=over

=item account

the account name the user belongs to

=item domainid

domain ID that the user belongs to

=item firstname

first name of the user

=item lastname

last name of the user

=item password

Password

=item sessionkey

Session key that can be passed in subsequent Query command calls

=item timeout

the time period before the session has expired

=item timezone

user time zone

=item timezoneoffset

user time zone offset from UTC 00:00

=item type

the account type (admin, domain-admin, read-only-admin, user)

=item userid

User id

=item username

Username

=back

=head2 logout

Logs out the user

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head3 Response

=over

=item success

success if the logout action succeeded

=back

=head1 Snapshot Methods

=head2 createSnapshot

Creates an instant snapshot of a volume.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item volumeid

The ID of the disk volume

=back

=head4 Optional Parameters

=over

=item account

The account of the snapshot. The account parameter must be used with the domainId parameter.

=item domainid

The domain ID of the snapshot. If used with the account parameter, specifies a domain for the account associated with the disk volume.

=item policyid

policy id of the snapshot, if this is null, then use MANUAL_POLICY.

=back

=head3 Response

=over

=item account

the account associated with the snapshot

=item created

the date the snapshot was created

=item domain

the domain name of the snapshot's account

=item domainid

the domain ID of the snapshot's account

=item id

ID of the snapshot

=item intervaltype

valid types are hourly, daily, weekly, monthy, template, and none.

=item jobid

the job ID associated with the snapshot. This is only displayed if the snapshot listed is part of a currently running asynchronous job.

=item jobstatus

the job status associated with the snapshot.  This is only displayed if the snapshot listed is part of a currently running asynchronous job.

=item name

name of the snapshot

=item snapshottype

the type of the snapshot

=item state

the state of the snapshot. BackedUp means that snapshot is ready to be used; Creating - the snapshot is being allocated on the primary storage; BackingUp - the snapshot is being backed up on secondary storage

=item volumeid

ID of the disk volume

=item volumename

name of the disk volume

=item volumetype

type of the disk volume

=back

=head2 listSnapshots (A)

Lists all available snapshots for the account.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item account

lists snapshot belongig to the specified account. Must be used with the domainId parameter.

=item domainid

the domain ID. If used with the account parameter, lists snapshots for the specified account in this domain.

=item id

lists snapshot by snapshot ID

=item intervaltype

valid values are HOURLY, DAILY, WEEKLY, and MONTHLY.

=item isrecursive

defaults to false, but if true, lists all snapshots from the parent specified by the domain id till leaves.

=item keyword

List by keyword

=item name

lists snapshot by snapshot name

=item page

no description

=item pagesize

no description

=item snapshottype

valid values are MANUAL or RECURRING.

=item volumeid

the ID of the disk volume

=back

=head3 Response

=over

=item account

the account associated with the snapshot

=item created

the date the snapshot was created

=item domain

the domain name of the snapshot's account

=item domainid

the domain ID of the snapshot's account

=item id

ID of the snapshot

=item intervaltype

valid types are hourly, daily, weekly, monthy, template, and none.

=item jobid

the job ID associated with the snapshot. This is only displayed if the snapshot listed is part of a currently running asynchronous job.

=item jobstatus

the job status associated with the snapshot.  This is only displayed if the snapshot listed is part of a currently running asynchronous job.

=item name

name of the snapshot

=item snapshottype

the type of the snapshot

=item state

the state of the snapshot. BackedUp means that snapshot is ready to be used; Creating - the snapshot is being allocated on the primary storage; BackingUp - the snapshot is being backed up on secondary storage

=item volumeid

ID of the disk volume

=item volumename

name of the disk volume

=item volumetype

type of the disk volume

=back

=head2 deleteSnapshot

Deletes a snapshot of a disk volume.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

The ID of the snapshot

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 createSnapshotPolicy (A)

Creates a snapshot policy for the account.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item intervaltype

valid values are HOURLY, DAILY, WEEKLY, and MONTHLY

=item maxsnaps

maximum number of snapshots to retain

=item schedule

time the snapshot is scheduled to be taken. Format is:* if HOURLY, MM* if DAILY, MM:HH* if WEEKLY, MM:HH:DD (1-7)* if MONTHLY, MM:HH:DD (1-28)

=item timezone

Specifies a timezone for this command. For more information on the timezone parameter, see Time Zone Format.

=item volumeid

the ID of the disk volume

=back

=head3 Response

=over

=item id

the ID of the snapshot policy

=item intervaltype

the interval type of the snapshot policy

=item maxsnaps

maximum number of snapshots retained

=item schedule

time the snapshot is scheduled to be taken.

=item timezone

the time zone of the snapshot policy

=item volumeid

the ID of the disk volume

=back

=head2 deleteSnapshotPolicies

Deletes snapshot policies for the account.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item id

the Id of the snapshot

=item ids

list of snapshots IDs separated by comma

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listSnapshotPolicies

Lists snapshot policies.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item volumeid

the ID of the disk volume

=back

=head4 Optional Parameters

=over

=item account

lists snapshot policies for the specified account. Must be used with domainid parameter.

=item domainid

the domain ID. If used with the account parameter, lists snapshot policies for the specified account in this domain.

=item keyword

List by keyword

=item page

no description

=item pagesize

no description

=back

=head3 Response

=over

=item id

the ID of the snapshot policy

=item intervaltype

the interval type of the snapshot policy

=item maxsnaps

maximum number of snapshots retained

=item schedule

time the snapshot is scheduled to be taken.

=item timezone

the time zone of the snapshot policy

=item volumeid

the ID of the disk volume

=back

=head1 StoragePools Methods

=head2 listStoragePools

Lists storage pools.

User Level: 3 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item clusterid

list storage pools belongig to the specific cluster

=item id

the ID of the storage pool

=item ipaddress

the IP address for the storage pool

=item keyword

List by keyword

=item name

the name of the storage pool

=item page

no description

=item pagesize

no description

=item path

the storage pool path

=item podid

the Pod ID for the storage pool

=item zoneid

the Zone ID for the storage pool

=back

=head3 Response

=over

=item clusterid

the ID of the cluster for the storage pool

=item clustername

the name of the cluster for the storage pool

=item created

the date and time the storage pool was created

=item disksizeallocated

the host's currently allocated disk size

=item disksizetotal

the total disk size of the storage pool

=item id

the ID of the storage pool

=item ipaddress

the IP address of the storage pool

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the storage pool

=item jobstatus

shows the current pending asynchronous job status

=item name

the name of the storage pool

=item path

the storage pool path

=item podid

the Pod ID of the storage pool

=item podname

the Pod name of the storage pool

=item state

the state of the storage pool

=item tags

the tags for the storage pool

=item type

the storage pool type

=item zoneid

the Zone ID of the storage pool

=item zonename

the Zone name of the storage pool

=back

=head2 createStoragePool

Creates a storage pool.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item name

the name for the storage pool

=item url

the URL of the storage pool

=item zoneid

the Zone ID for the storage pool

=back

=head4 Optional Parameters

=over

=item clusterid

the cluster ID for the storage pool

=item details

the details for the storage pool

=item podid

the Pod ID for the storage pool

=item tags

the tags for the storage pool

=back

=head3 Response

=over

=item clusterid

the ID of the cluster for the storage pool

=item clustername

the name of the cluster for the storage pool

=item created

the date and time the storage pool was created

=item disksizeallocated

the host's currently allocated disk size

=item disksizetotal

the total disk size of the storage pool

=item id

the ID of the storage pool

=item ipaddress

the IP address of the storage pool

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the storage pool

=item jobstatus

shows the current pending asynchronous job status

=item name

the name of the storage pool

=item path

the storage pool path

=item podid

the Pod ID of the storage pool

=item podname

the Pod name of the storage pool

=item state

the state of the storage pool

=item tags

the tags for the storage pool

=item type

the storage pool type

=item zoneid

the Zone ID of the storage pool

=item zonename

the Zone name of the storage pool

=back

=head2 deleteStoragePool

Deletes a storage pool.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

Storage pool id

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listClusters

Lists clusters.

User Level: 3 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item allocationstate

lists clusters by allocation state

=item clustertype

lists clusters by cluster type

=item hypervisor

lists clusters by hypervisor type

=item id

lists clusters by the cluster ID

=item keyword

List by keyword

=item managedstate

whether this cluster is managed by cloudstack

=item name

lists clusters by the cluster name

=item page

no description

=item pagesize

no description

=item podid

lists clusters by Pod ID

=item zoneid

lists clusters by Zone ID

=back

=head3 Response

=over

=item allocationstate

the allocation state of the cluster

=item clustertype

the type of the cluster

=item hypervisortype

the hypervisor type of the cluster

=item id

the cluster ID

=item managedstate

whether this cluster is managed by cloudstack

=item name

the cluster name

=item podid

the Pod ID of the cluster

=item podname

the Pod name of the cluster

=item zoneid

the Zone ID of the cluster

=item zonename

the Zone name of the cluster

=back

=head2 enableStorageMaintenance

Puts storage pool into maintenance state

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

Primary storage ID

=back

=head3 Response

=over

=item clusterid

the ID of the cluster for the storage pool

=item clustername

the name of the cluster for the storage pool

=item created

the date and time the storage pool was created

=item disksizeallocated

the host's currently allocated disk size

=item disksizetotal

the total disk size of the storage pool

=item id

the ID of the storage pool

=item ipaddress

the IP address of the storage pool

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the storage pool

=item jobstatus

shows the current pending asynchronous job status

=item name

the name of the storage pool

=item path

the storage pool path

=item podid

the Pod ID of the storage pool

=item podname

the Pod name of the storage pool

=item state

the state of the storage pool

=item tags

the tags for the storage pool

=item type

the storage pool type

=item zoneid

the Zone ID of the storage pool

=item zonename

the Zone name of the storage pool

=back

=head2 cancelStorageMaintenance (A)

Cancels maintenance for primary storage

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the primary storage ID

=back

=head3 Response

=over

=item clusterid

the ID of the cluster for the storage pool

=item clustername

the name of the cluster for the storage pool

=item created

the date and time the storage pool was created

=item disksizeallocated

the host's currently allocated disk size

=item disksizetotal

the total disk size of the storage pool

=item id

the ID of the storage pool

=item ipaddress

the IP address of the storage pool

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the storage pool

=item jobstatus

shows the current pending asynchronous job status

=item name

the name of the storage pool

=item path

the storage pool path

=item podid

the Pod ID of the storage pool

=item podname

the Pod name of the storage pool

=item state

the state of the storage pool

=item tags

the tags for the storage pool

=item type

the storage pool type

=item zoneid

the Zone ID of the storage pool

=item zonename

the Zone name of the storage pool

=back

=head1 SystemCapacity Methods

=head2 listCapacity (A)

Lists capacity.

User Level: 3 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item hostid

lists capacity by the Host ID

=item keyword

List by keyword

=item page

no description

=item pagesize

no description

=item podid

lists capacity by the Pod ID

=item type

lists capacity by type* CAPACITY_TYPE_MEMORY = 0* CAPACITY_TYPE_CPU = 1* CAPACITY_TYPE_STORAGE = 2* CAPACITY_TYPE_STORAGE_ALLOCATED = 3* CAPACITY_TYPE_PUBLIC_IP = 4* CAPACITY_TYPE_PRIVATE_IP = 5* CAPACITY_TYPE_SECONDARY_STORAGE = 6

=item zoneid

lists capacity by the Zone ID

=back

=head3 Response

=over

=item capacitytotal

the total capacity available

=item capacityused

the capacity currently in use

=item percentused

the percentage of capacity currently in use

=item podid

the Pod ID

=item podname

the Pod name

=item type

the capacity type

=item zoneid

the Zone ID

=item zonename

the Zone name

=back

=head1 SystemVM Methods

=head2 startSystemVm

Starts a system virtual machine.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

The ID of the system virtual machine

=back

=head3 Response

=over

=item activeviewersessions

the number of active console sessions for the console proxy system vm

=item created

the date and time the system VM was created

=item dns1

the first DNS for the system VM

=item dns2

the second DNS for the system VM

=item gateway

the gateway for the system VM

=item hostid

the host ID for the system VM

=item hostname

the hostname for the system VM

=item id

the ID of the system VM

=item jobid

the job ID associated with the system VM. This is only displayed if the router listed is part of a currently running asynchronous job.

=item jobstatus

the job status associated with the system VM.  This is only displayed if the router listed is part of a currently running asynchronous job.

=item linklocalip

the link local IP address for the system vm

=item linklocalmacaddress

the link local MAC address for the system vm

=item linklocalnetmask

the link local netmask for the system vm

=item name

the name of the system VM

=item networkdomain

the network domain for the system VM

=item podid

the Pod ID for the system VM

=item privateip

the private IP address for the system VM

=item privatemacaddress

the private MAC address for the system VM

=item privatenetmask

the private netmask for the system VM

=item publicip

the public IP address for the system VM

=item publicmacaddress

the public MAC address for the system VM

=item publicnetmask

the public netmask for the system VM

=item state

the state of the system VM

=item systemvmtype

the system VM type

=item templateid

the template ID for the system VM

=item zoneid

the Zone ID for the system VM

=item zonename

the Zone name for the system VM

=back

=head2 rebootSystemVm (A)

Reboots a system VM.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

The ID of the system virtual machine

=back

=head3 Response

=over

=item activeviewersessions

the number of active console sessions for the console proxy system vm

=item created

the date and time the system VM was created

=item dns1

the first DNS for the system VM

=item dns2

the second DNS for the system VM

=item gateway

the gateway for the system VM

=item hostid

the host ID for the system VM

=item hostname

the hostname for the system VM

=item id

the ID of the system VM

=item jobid

the job ID associated with the system VM. This is only displayed if the router listed is part of a currently running asynchronous job.

=item jobstatus

the job status associated with the system VM.  This is only displayed if the router listed is part of a currently running asynchronous job.

=item linklocalip

the link local IP address for the system vm

=item linklocalmacaddress

the link local MAC address for the system vm

=item linklocalnetmask

the link local netmask for the system vm

=item name

the name of the system VM

=item networkdomain

the network domain for the system VM

=item podid

the Pod ID for the system VM

=item privateip

the private IP address for the system VM

=item privatemacaddress

the private MAC address for the system VM

=item privatenetmask

the private netmask for the system VM

=item publicip

the public IP address for the system VM

=item publicmacaddress

the public MAC address for the system VM

=item publicnetmask

the public netmask for the system VM

=item state

the state of the system VM

=item systemvmtype

the system VM type

=item templateid

the template ID for the system VM

=item zoneid

the Zone ID for the system VM

=item zonename

the Zone name for the system VM

=back

=head2 stopSystemVm (A)

Stops a system VM.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

The ID of the system virtual machine

=back

=head4 Optional Parameters

=over

=item forced

Force stop the VM.  The caller knows the VM is stopped.

=back

=head3 Response

=over

=item activeviewersessions

the number of active console sessions for the console proxy system vm

=item created

the date and time the system VM was created

=item dns1

the first DNS for the system VM

=item dns2

the second DNS for the system VM

=item gateway

the gateway for the system VM

=item hostid

the host ID for the system VM

=item hostname

the hostname for the system VM

=item id

the ID of the system VM

=item jobid

the job ID associated with the system VM. This is only displayed if the router listed is part of a currently running asynchronous job.

=item jobstatus

the job status associated with the system VM.  This is only displayed if the router listed is part of a currently running asynchronous job.

=item linklocalip

the link local IP address for the system vm

=item linklocalmacaddress

the link local MAC address for the system vm

=item linklocalnetmask

the link local netmask for the system vm

=item name

the name of the system VM

=item networkdomain

the network domain for the system VM

=item podid

the Pod ID for the system VM

=item privateip

the private IP address for the system VM

=item privatemacaddress

the private MAC address for the system VM

=item privatenetmask

the private netmask for the system VM

=item publicip

the public IP address for the system VM

=item publicmacaddress

the public MAC address for the system VM

=item publicnetmask

the public netmask for the system VM

=item state

the state of the system VM

=item systemvmtype

the system VM type

=item templateid

the template ID for the system VM

=item zoneid

the Zone ID for the system VM

=item zonename

the Zone name for the system VM

=back

=head2 destroySystemVm (A)

Destroyes a system virtual machine.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

The ID of the system virtual machine

=back

=head3 Response

=over

=item activeviewersessions

the number of active console sessions for the console proxy system vm

=item created

the date and time the system VM was created

=item dns1

the first DNS for the system VM

=item dns2

the second DNS for the system VM

=item gateway

the gateway for the system VM

=item hostid

the host ID for the system VM

=item hostname

the hostname for the system VM

=item id

the ID of the system VM

=item jobid

the job ID associated with the system VM. This is only displayed if the router listed is part of a currently running asynchronous job.

=item jobstatus

the job status associated with the system VM.  This is only displayed if the router listed is part of a currently running asynchronous job.

=item linklocalip

the link local IP address for the system vm

=item linklocalmacaddress

the link local MAC address for the system vm

=item linklocalnetmask

the link local netmask for the system vm

=item name

the name of the system VM

=item networkdomain

the network domain for the system VM

=item podid

the Pod ID for the system VM

=item privateip

the private IP address for the system VM

=item privatemacaddress

the private MAC address for the system VM

=item privatenetmask

the private netmask for the system VM

=item publicip

the public IP address for the system VM

=item publicmacaddress

the public MAC address for the system VM

=item publicnetmask

the public netmask for the system VM

=item state

the state of the system VM

=item systemvmtype

the system VM type

=item templateid

the template ID for the system VM

=item zoneid

the Zone ID for the system VM

=item zonename

the Zone name for the system VM

=back

=head2 listSystemVms (A)

List system virtual machines.

User Level: 3 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item hostid

the host ID of the system VM

=item id

the ID of the system VM

=item keyword

List by keyword

=item name

the name of the system VM

=item page

no description

=item pagesize

no description

=item podid

the Pod ID of the system VM

=item state

the state of the system VM

=item systemvmtype

the system VM type. Possible types are "consoleproxy" and "secondarystoragevm".

=item zoneid

the Zone ID of the system VM

=back

=head3 Response

=over

=item activeviewersessions

the number of active console sessions for the console proxy system vm

=item created

the date and time the system VM was created

=item dns1

the first DNS for the system VM

=item dns2

the second DNS for the system VM

=item gateway

the gateway for the system VM

=item hostid

the host ID for the system VM

=item hostname

the hostname for the system VM

=item id

the ID of the system VM

=item jobid

the job ID associated with the system VM. This is only displayed if the router listed is part of a currently running asynchronous job.

=item jobstatus

the job status associated with the system VM.  This is only displayed if the router listed is part of a currently running asynchronous job.

=item linklocalip

the link local IP address for the system vm

=item linklocalmacaddress

the link local MAC address for the system vm

=item linklocalnetmask

the link local netmask for the system vm

=item name

the name of the system VM

=item networkdomain

the network domain for the system VM

=item podid

the Pod ID for the system VM

=item privateip

the private IP address for the system VM

=item privatemacaddress

the private MAC address for the system VM

=item privatenetmask

the private netmask for the system VM

=item publicip

the public IP address for the system VM

=item publicmacaddress

the public MAC address for the system VM

=item publicnetmask

the public netmask for the system VM

=item state

the state of the system VM

=item systemvmtype

the system VM type

=item templateid

the template ID for the system VM

=item zoneid

the Zone ID for the system VM

=item zonename

the Zone name for the system VM

=back

=head2 migrateSystemVm

Attempts Migration of a system virtual machine to the host specified.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item hostid

destination Host ID to migrate VM to

=item virtualmachineid

the ID of the virtual machine

=back

=head3 Response

=over

=item hostid

the host ID for the system VM

=item id

the ID of the system VM

=item name

the name of the system VM

=item role

the role of the system VM

=item state

the state of the system VM

=item systemvmtype

the system VM type

=back

=head1 Template Methods

=head2 createTemplate (A)

Creates a template of a virtual machine. The virtual machine must be in a STOPPED state. A template created from this command is automatically designated as a private template visible to the account that created it.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item displaytext

the display text of the template. This is usually used for display purposes.

=item name

the name of the template

=item ostypeid

the ID of the OS Type that best represents the OS of this template.

=back

=head4 Optional Parameters

=over

=item bits

32 or 64 bit

=item details

Template details in key/value pairs.

=item isfeatured

true if this template is a featured template, false otherwise

=item ispublic

true if this template is a public template, false otherwise

=item passwordenabled

true if the template supports the password reset feature; default is false

=item requireshvm

true if the template requres HVM, false otherwise

=item snapshotid

the ID of the snapshot the template is being created from. Either this parameter, or volumeId has to be passed in

=item templatetag

the tag for this template.

=item url

Optional, only for baremetal hypervisor. The directory name where template stored on CIFS server

=item virtualmachineid

Optional, VM ID. If this presents, it is going to create a baremetal template for VM this ID refers to. This is only for VM whose hypervisor type is BareMetal

=item volumeid

the ID of the disk volume the template is being created from. Either this parameter, or snapshotId has to be passed in

=back

=head3 Response

=over

=item clusterid

the ID of the cluster for the storage pool

=item clustername

the name of the cluster for the storage pool

=item created

the date and time the storage pool was created

=item disksizeallocated

the host's currently allocated disk size

=item disksizetotal

the total disk size of the storage pool

=item id

the ID of the storage pool

=item ipaddress

the IP address of the storage pool

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the storage pool

=item jobstatus

shows the current pending asynchronous job status

=item name

the name of the storage pool

=item path

the storage pool path

=item podid

the Pod ID of the storage pool

=item podname

the Pod name of the storage pool

=item state

the state of the storage pool

=item tags

the tags for the storage pool

=item type

the storage pool type

=item zoneid

the Zone ID of the storage pool

=item zonename

the Zone name of the storage pool

=back

=head2 registerTemplate (A)

Registers an existing template into the Cloud.com cloud.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item displaytext

the display text of the template. This is usually used for display purposes.

=item format

the format for the template. Possible values include QCOW2, RAW, and VHD.

=item hypervisor

the target hypervisor for the template

=item name

the name of the template

=item ostypeid

the ID of the OS Type that best represents the OS of this template.

=item url

the URL of where the template is hosted. Possible URL include http:// and https://

=item zoneid

the ID of the zone the template is to be hosted on

=back

=head4 Optional Parameters

=over

=item account

an optional accountName. Must be used with domainId.

=item bits

32 or 64 bits support. 64 by default

=item checksum

the MD5 checksum value of this template

=item details

Template details in key/value pairs.

=item domainid

an optional domainId. If the account parameter is used, domainId must also be used.

=item isextractable

true if the template or its derivatives are extractable; default is false

=item isfeatured

true if this template is a featured template, false otherwise

=item ispublic

true if the template is available to all accounts; default is true

=item passwordenabled

true if the template supports the password reset feature; default is false

=item requireshvm

true if this template requires HVM

=item templatetag

the tag for this template.

=back

=head3 Response

=over

=item account

the account name to which the template belongs

=item accountid

the account id to which the template belongs

=item bootable

true if the ISO is bootable, false otherwise

=item checksum

checksum of the template

=item created

the date this template was created

=item crossZones

true if the template is managed across all Zones, false otherwise

=item details

additional key/value details tied with template

=item displaytext

the template display text

=item domain

the name of the domain to which the template belongs

=item domainid

the ID of the domain to which the template belongs

=item format

the format of the template.

=item hostid

the ID of the secondary storage host for the template

=item hostname

the name of the secondary storage host for the template

=item hypervisor

the hypervisor on which the template runs

=item id

the template ID

=item isextractable

true if the template is extractable, false otherwise

=item isfeatured

true if this template is a featured template, false otherwise

=item ispublic

true if this template is a public template, false otherwise

=item isready

true if the template is ready to be deployed from, false otherwise.

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template

=item jobstatus

shows the current pending asynchronous job status

=item name

the template name

=item ostypeid

the ID of the OS type for this template.

=item ostypename

the name of the OS type for this template.

=item passwordenabled

true if the reset password feature is enabled, false otherwise

=item removed

the date this template was removed

=item size

the size of the template

=item sourcetemplateid

the template ID of the parent template if present

=item status

the status of the template

=item templatetag

the tag of this template

=item templatetype

the type of the template

=item zoneid

the ID of the zone for this template

=item zonename

the name of the zone for this template

=back

=head2 updateTemplate

Updates attributes of a template.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the image file

=back

=head4 Optional Parameters

=over

=item bootable

true if image is bootable, false otherwise

=item displaytext

the display text of the image

=item format

the format for the image

=item name

the name of the image file

=item ostypeid

the ID of the OS type that best represents the OS of this image.

=item passwordenabled

true if the image supports the password reset feature; default is false

=back

=head3 Response

=over

=item account

the account name to which the template belongs

=item accountid

the account id to which the template belongs

=item bootable

true if the ISO is bootable, false otherwise

=item checksum

checksum of the template

=item created

the date this template was created

=item crossZones

true if the template is managed across all Zones, false otherwise

=item details

additional key/value details tied with template

=item displaytext

the template display text

=item domain

the name of the domain to which the template belongs

=item domainid

the ID of the domain to which the template belongs

=item format

the format of the template.

=item hostid

the ID of the secondary storage host for the template

=item hostname

the name of the secondary storage host for the template

=item hypervisor

the hypervisor on which the template runs

=item id

the template ID

=item isextractable

true if the template is extractable, false otherwise

=item isfeatured

true if this template is a featured template, false otherwise

=item ispublic

true if this template is a public template, false otherwise

=item isready

true if the template is ready to be deployed from, false otherwise.

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template

=item jobstatus

shows the current pending asynchronous job status

=item name

the template name

=item ostypeid

the ID of the OS type for this template.

=item ostypename

the name of the OS type for this template.

=item passwordenabled

true if the reset password feature is enabled, false otherwise

=item removed

the date this template was removed

=item size

the size of the template

=item sourcetemplateid

the template ID of the parent template if present

=item status

the status of the template

=item templatetag

the tag of this template

=item templatetype

the type of the template

=item zoneid

the ID of the zone for this template

=item zonename

the name of the zone for this template

=back

=head2 copyTemplate

Copies a template from one zone to another.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item destzoneid

ID of the zone the template is being copied to.

=item id

Template ID.

=item sourcezoneid

ID of the zone the template is currently hosted on.

=back

=head3 Response

=over

=item account

the account name to which the template belongs

=item accountid

the account id to which the template belongs

=item bootable

true if the ISO is bootable, false otherwise

=item checksum

checksum of the template

=item created

the date this template was created

=item crossZones

true if the template is managed across all Zones, false otherwise

=item details

additional key/value details tied with template

=item displaytext

the template display text

=item domain

the name of the domain to which the template belongs

=item domainid

the ID of the domain to which the template belongs

=item format

the format of the template.

=item hostid

the ID of the secondary storage host for the template

=item hostname

the name of the secondary storage host for the template

=item hypervisor

the hypervisor on which the template runs

=item id

the template ID

=item isextractable

true if the template is extractable, false otherwise

=item isfeatured

true if this template is a featured template, false otherwise

=item ispublic

true if this template is a public template, false otherwise

=item isready

true if the template is ready to be deployed from, false otherwise.

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template

=item jobstatus

shows the current pending asynchronous job status

=item name

the template name

=item ostypeid

the ID of the OS type for this template.

=item ostypename

the name of the OS type for this template.

=item passwordenabled

true if the reset password feature is enabled, false otherwise

=item removed

the date this template was removed

=item size

the size of the template

=item sourcetemplateid

the template ID of the parent template if present

=item status

the status of the template

=item templatetag

the tag of this template

=item templatetype

the type of the template

=item zoneid

the ID of the zone for this template

=item zonename

the name of the zone for this template

=back

=head2 deleteTemplate (A)

Deletes a template from the system. All virtual machines using the deleted template will not be affected.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the template

=back

=head4 Optional Parameters

=over

=item zoneid

the ID of zone of the template

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listTemplates (A)

List all public, private, and privileged templates.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item templatefilter

possible values are "featured", "self", "self-executable", "executable", and "community".* featured-templates that are featured and are public* self-templates that have been registered/created by the owner* selfexecutable-templates that have been registered/created by the owner that can be used to deploy a new VM* executable-all templates that can be used to deploy a new VM* community-templates that are public.

=back

=head4 Optional Parameters

=over

=item account

list template by account. Must be used with the domainId parameter.

=item domainid

list all templates in specified domain. If used with the account parameter, lists all templates for an account in the specified domain.

=item hypervisor

the hypervisor for which to restrict the search

=item id

the template ID

=item keyword

List by keyword

=item name

the template name

=item page

no description

=item pagesize

no description

=item zoneid

list templates by zoneId

=back

=head3 Response

=over

=item account

the account name to which the template belongs

=item accountid

the account id to which the template belongs

=item bootable

true if the ISO is bootable, false otherwise

=item checksum

checksum of the template

=item created

the date this template was created

=item crossZones

true if the template is managed across all Zones, false otherwise

=item details

additional key/value details tied with template

=item displaytext

the template display text

=item domain

the name of the domain to which the template belongs

=item domainid

the ID of the domain to which the template belongs

=item format

the format of the template.

=item hostid

the ID of the secondary storage host for the template

=item hostname

the name of the secondary storage host for the template

=item hypervisor

the hypervisor on which the template runs

=item id

the template ID

=item isextractable

true if the template is extractable, false otherwise

=item isfeatured

true if this template is a featured template, false otherwise

=item ispublic

true if this template is a public template, false otherwise

=item isready

true if the template is ready to be deployed from, false otherwise.

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template

=item jobstatus

shows the current pending asynchronous job status

=item name

the template name

=item ostypeid

the ID of the OS type for this template.

=item ostypename

the name of the OS type for this template.

=item passwordenabled

true if the reset password feature is enabled, false otherwise

=item removed

the date this template was removed

=item size

the size of the template

=item sourcetemplateid

the template ID of the parent template if present

=item status

the status of the template

=item templatetag

the tag of this template

=item templatetype

the type of the template

=item zoneid

the ID of the zone for this template

=item zonename

the name of the zone for this template

=back

=head2 updateTemplatePermissions

Updates a template visibility permissions. A public template is visible to all accounts within the same domain. A private template is visible only to the owner of the template. A priviledged template is a private template with account permissions added. Only accounts specified under the template permissions are visible to them.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the template ID

=back

=head4 Optional Parameters

=over

=item accounts

a comma delimited list of accounts. If specified, "op" parameter has to be passed in.

=item isextractable

true if the template/iso is extractable, false other wise. Can be set only by root admin

=item isfeatured

true for featured template/iso, false otherwise

=item ispublic

true for public template/iso, false for private templates/isos

=item op

permission operator (add, remove, reset)

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listTemplatePermissions

List template visibility and all accounts that have permissions to view this template.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the template ID

=back

=head4 Optional Parameters

=over

=item account

List template visibility and permissions for the specified account. Must be used with the domainId parameter.

=item domainid

List template visibility and permissions by domain. If used with the account parameter, specifies in which domain the specified account exists.

=back

=head3 Response

=over

=item account

the list of accounts the template is available for

=item domainid

the ID of the domain to which the template belongs

=item id

the template ID

=item ispublic

true if this template is a public template, false otherwise

=back

=head2 extractTemplate

Extracts a template

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the template

=item mode

the mode of extraction - HTTP_DOWNLOAD or FTP_UPLOAD

=item zoneid

the ID of the zone where the ISO is originally located

=back

=head4 Optional Parameters

=over

=item url

the url to which the ISO would be extracted

=back

=head3 Response

=over

=item accountid

the account id to which the extracted object belongs

=item created

the time and date the object was created

=item extractId

the upload id of extracted object

=item extractMode

the mode of extraction - upload or download

=item id

the id of extracted object

=item name

the name of the extracted object

=item state

the state of the extracted object

=item status

the status of the extraction

=item storagetype

type of the storage

=item uploadpercentage

the percentage of the entity uploaded to the specified location

=item url

if mode = upload then url of the uploaded entity. if mode = download the url from which the entity can be downloaded

=item zoneid

zone ID the object was extracted from

=item zonename

zone name the object was extracted from

=back

=head2 prepareTemplate (A)

load template into primary storage

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item templateid

template ID of the template to be prepared in primary storage(s).

=item zoneid

zone ID of the template to be prepared in primary storage(s).

=back

=head3 Response

=over

=item account

the account name to which the template belongs

=item accountid

the account id to which the template belongs

=item bootable

true if the ISO is bootable, false otherwise

=item checksum

checksum of the template

=item created

the date this template was created

=item crossZones

true if the template is managed across all Zones, false otherwise

=item details

additional key/value details tied with template

=item displaytext

the template display text

=item domain

the name of the domain to which the template belongs

=item domainid

the ID of the domain to which the template belongs

=item format

the format of the template.

=item hostid

the ID of the secondary storage host for the template

=item hostname

the name of the secondary storage host for the template

=item hypervisor

the hypervisor on which the template runs

=item id

the template ID

=item isextractable

true if the template is extractable, false otherwise

=item isfeatured

true if this template is a featured template, false otherwise

=item ispublic

true if this template is a public template, false otherwise

=item isready

true if the template is ready to be deployed from, false otherwise.

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the template

=item jobstatus

shows the current pending asynchronous job status

=item name

the template name

=item ostypeid

the ID of the OS type for this template.

=item ostypename

the name of the OS type for this template.

=item passwordenabled

true if the reset password feature is enabled, false otherwise

=item removed

the date this template was removed

=item size

the size of the template

=item sourcetemplateid

the template ID of the parent template if present

=item status

the status of the template

=item templatetag

the tag of this template

=item templatetype

the type of the template

=item zoneid

the ID of the zone for this template

=item zonename

the name of the zone for this template

=back

=head1 TrafficMonitor Methods

=head2 addTrafficMonitor

Adds Traffic Monitor Host for Direct Network Usage

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item url

URL of the traffic monitor Host

=item zoneid

Zone in which to add the external firewall appliance.

=back

=head3 Response

=over

=item id

the ID of the external firewall

=item ipaddress

the management IP address of the external firewall

=item numretries

the number of times to retry requests to the external firewall

=item privateinterface

the private interface of the external firewall

=item privatezone

the private security zone of the external firewall

=item publicinterface

the public interface of the external firewall

=item publiczone

the public security zone of the external firewall

=item timeout

the timeout (in seconds) for requests to the external firewall

=item usageinterface

the usage interface of the external firewall

=item username

the username that's used to log in to the external firewall

=item zoneid

the zone ID of the external firewall

=back

=head2 deleteTrafficMonitor

Deletes an traffic monitor host.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

Id of the Traffic Monitor Host.

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listTrafficMonitors

List traffic monitor Hosts.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item zoneid

zone Id

=back

=head4 Optional Parameters

=over

=item keyword

List by keyword

=item page

no description

=item pagesize

no description

=back

=head3 Response

=over

=item id

the ID of the external firewall

=item ipaddress

the management IP address of the external firewall

=item numretries

the number of times to retry requests to the external firewall

=item privateinterface

the private interface of the external firewall

=item privatezone

the private security zone of the external firewall

=item publicinterface

the public interface of the external firewall

=item publiczone

the public security zone of the external firewall

=item timeout

the timeout (in seconds) for requests to the external firewall

=item usageinterface

the usage interface of the external firewall

=item username

the username that's used to log in to the external firewall

=item zoneid

the zone ID of the external firewall

=back

=head1 Usage Methods

=head2 generateUsageRecords

Generates usage records

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item enddate

End date range for usage record query. Use yyyy-MM-dd as the date format, e.g. startDate=2009-06-03.

=item startdate

Start date range for usage record query. Use yyyy-MM-dd as the date format, e.g. startDate=2009-06-01.

=back

=head4 Optional Parameters

=over

=item domainid

List events for the specified domain.

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listUsageRecords

Lists usage records for accounts

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item enddate

End date range for usage record query. Use yyyy-MM-dd as the date format, e.g. startDate=2009-06-03.

=item startdate

Start date range for usage record query. Use yyyy-MM-dd as the date format, e.g. startDate=2009-06-01.

=back

=head4 Optional Parameters

=over

=item account

List usage records for the specified user.

=item accountid

List usage records for the specified account

=item domainid

List usage records for the specified domain.

=item keyword

List by keyword

=item page

no description

=item pagesize

no description

=back

=head3 Response

=over

=item account

the user account name

=item accountid

the user account Id

=item assigneddate

the assign date of the account

=item description

description of account, including account name, service offering, and template

=item domainid

the domain ID number

=item enddate

end date of account

=item ipaddress

the IP address

=item issourcenat

source Nat flag for IPAddress

=item name

virtual machine name

=item offeringid

service offering ID number

=item rawusage

raw usage in hours

=item releaseddate

the release date of the account

=item startdate

start date of account

=item templateid

template ID number

=item type

type

=item usage

usage in hours

=item usageid

id of the usage entity

=item usagetype

usage type

=item virtualmachineid

virtual machine ID number

=item zoneid

the zone ID number

=back

=head1 User Methods

=head2 createUser

Creates a user for an account that already exists

User Level: 3 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item account

Creates the user under the specified account. If no account is specified, the username will be used as the account name.

=item email

email

=item firstname

firstname

=item lastname

lastname

=item password

Hashed password (Default is MD5). If you wish to use any other hashing algorithm, you would need to write a custom authentication adapter See Docs section.

=item username

Unique username.

=back

=head4 Optional Parameters

=over

=item domainid

Creates the user under the specified domain. Has to be accompanied with the account parameter

=item timezone

Specifies a timezone for this command. For more information on the timezone parameter, see Time Zone Format.

=back

=head3 Response

=over

=item account

the account name of the user

=item accounttype

the account type of the user

=item apikey

the api key of the user

=item created

the date and time the user account was created

=item domain

the domain name of the user

=item domainid

the domain ID of the user

=item email

the user email address

=item firstname

the user firstname

=item id

the user ID

=item lastname

the user lastname

=item secretkey

the secret key of the user

=item state

the user state

=item timezone

the timezone user was created in

=item username

the user name

=back

=head2 deleteUser

Creates a user for an account

User Level: 3 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

Deletes a user

=back

=head3 Response

=over

=item account

the account name of the user

=item accounttype

the account type of the user

=item apikey

the api key of the user

=item created

the date and time the user account was created

=item domain

the domain name of the user

=item domainid

the domain ID of the user

=item email

the user email address

=item firstname

the user firstname

=item id

the user ID

=item lastname

the user lastname

=item secretkey

the secret key of the user

=item state

the user state

=item timezone

the timezone user was created in

=item username

the user name

=back

=head2 updateUser

Updates a user account

User Level: 3 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

User id

=back

=head4 Optional Parameters

=over

=item email

email

=item firstname

first name

=item lastname

last name

=item password

Hashed password (default is MD5). If you wish to use any other hasing algorithm, you would need to write a custom authentication adapter

=item timezone

Specifies a timezone for this command. For more information on the timezone parameter, see Time Zone Format.

=item userapikey

The API key for the user. Must be specified with userSecretKey

=item username

Unique username

=item usersecretkey

The secret key for the user. Must be specified with userApiKey

=back

=head3 Response

=over

=item account

the account name of the user

=item accounttype

the account type of the user

=item apikey

the api key of the user

=item created

the date and time the user account was created

=item domain

the domain name of the user

=item domainid

the domain ID of the user

=item email

the user email address

=item firstname

the user firstname

=item id

the user ID

=item lastname

the user lastname

=item secretkey

the secret key of the user

=item state

the user state

=item timezone

the timezone user was created in

=item username

the user name

=back

=head2 listUsers

Lists user accounts

User Level: 7 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item account

List user by account. Must be used with the domainId parameter.

=item accounttype

List users by account type. Valid types include admin, domain-admin, read-only-admin, or user.

=item domainid

List all users in a domain. If used with the account parameter, lists an account in a specific domain.

=item id

List user by ID.

=item keyword

List by keyword

=item page

no description

=item pagesize

no description

=item state

List users by state of the user account.

=item username

List user by the username

=back

=head3 Response

=over

=item account

the account name of the user

=item accounttype

the account type of the user

=item apikey

the api key of the user

=item created

the date and time the user account was created

=item domain

the domain name of the user

=item domainid

the domain ID of the user

=item email

the user email address

=item firstname

the user firstname

=item id

the user ID

=item lastname

the user lastname

=item secretkey

the secret key of the user

=item state

the user state

=item timezone

the timezone user was created in

=item username

the user name

=back

=head2 disableUser

Disables a user account

User Level: 7 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

Disables user by user ID.

=back

=head3 Response

=over

=item account

the account name of the user

=item accounttype

the account type of the user

=item apikey

the api key of the user

=item created

the date and time the user account was created

=item domain

the domain name of the user

=item domainid

the domain ID of the user

=item email

the user email address

=item firstname

the user firstname

=item id

the user ID

=item lastname

the user lastname

=item secretkey

the secret key of the user

=item state

the user state

=item timezone

the timezone user was created in

=item username

the user name

=back

=head2 enableUser (A)

Enables a user account

User Level: 7 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

Enables user by user ID.

=back

=head3 Response

=over

=item account

the account name of the user

=item accounttype

the account type of the user

=item apikey

the api key of the user

=item created

the date and time the user account was created

=item domain

the domain name of the user

=item domainid

the domain ID of the user

=item email

the user email address

=item firstname

the user firstname

=item id

the user ID

=item lastname

the user lastname

=item secretkey

the secret key of the user

=item state

the user state

=item timezone

the timezone user was created in

=item username

the user name

=back

=head1 VLAN Methods

=head2 createVlanIpRange

Creates a VLAN IP range.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item startip

the beginning IP address in the VLAN IP range

=back

=head4 Optional Parameters

=over

=item account

account who will own the VLAN. If VLAN is Zone wide, this parameter should be ommited

=item domainid

domain ID of the account owning a VLAN

=item endip

the ending IP address in the VLAN IP range

=item forvirtualnetwork

true if VLAN is of Virtual type, false if Direct

=item gateway

the gateway of the VLAN IP range

=item netmask

the netmask of the VLAN IP range

=item networkid

the network id

=item podid

optional parameter. Have to be specified for Direct Untagged vlan only.

=item vlan

the ID or VID of the VLAN. Default is an "untagged" VLAN.

=item zoneid

the Zone ID of the VLAN IP range

=back

=head3 Response

=over

=item account

the account of the VLAN IP range

=item description

the description of the VLAN IP range

=item domain

the domain name of the VLAN IP range

=item domainid

the domain ID of the VLAN IP range

=item endip

the end ip of the VLAN IP range

=item forvirtualnetwork

the virtual network for the VLAN IP range

=item gateway

the gateway of the VLAN IP range

=item id

the ID of the VLAN IP range

=item netmask

the netmask of the VLAN IP range

=item networkid

the network id of vlan range

=item podid

the Pod ID for the VLAN IP range

=item podname

the Pod name for the VLAN IP range

=item startip

the start ip of the VLAN IP range

=item vlan

the ID or VID of the VLAN.

=item zoneid

the Zone ID of the VLAN IP range

=back

=head2 deleteVlanIpRange

Creates a VLAN IP range.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the id of the VLAN IP range

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listVlanIpRanges

Lists all VLAN IP ranges.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item account

the account with which the VLAN IP range is associated. Must be used with the domainId parameter.

=item domainid

the domain ID with which the VLAN IP range is associated.  If used with the account parameter, returns all VLAN IP ranges for that account in the specified domain.

=item forvirtualnetwork

true if VLAN is of Virtual type, false if Direct

=item id

the ID of the VLAN IP range

=item keyword

List by keyword

=item networkid

network id of the VLAN IP range

=item page

no description

=item pagesize

no description

=item podid

the Pod ID of the VLAN IP range

=item vlan

the ID or VID of the VLAN. Default is an "untagged" VLAN.

=item zoneid

the Zone ID of the VLAN IP range

=back

=head3 Response

=over

=item account

the account of the VLAN IP range

=item description

the description of the VLAN IP range

=item domain

the domain name of the VLAN IP range

=item domainid

the domain ID of the VLAN IP range

=item endip

the end ip of the VLAN IP range

=item forvirtualnetwork

the virtual network for the VLAN IP range

=item gateway

the gateway of the VLAN IP range

=item id

the ID of the VLAN IP range

=item netmask

the netmask of the VLAN IP range

=item networkid

the network id of vlan range

=item podid

the Pod ID for the VLAN IP range

=item podname

the Pod name for the VLAN IP range

=item startip

the start ip of the VLAN IP range

=item vlan

the ID or VID of the VLAN.

=item zoneid

the Zone ID of the VLAN IP range

=back

=head1 VM Methods

=head2 deployVirtualMachine

Creates and automatically starts a virtual machine based on a service offering, disk offering, and template.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item serviceofferingid

the ID of the service offering for the virtual machine

=item templateid

the ID of the template for the virtual machine

=item zoneid

availability zone for the virtual machine

=back

=head4 Optional Parameters

=over

=item account

an optional account for the virtual machine. Must be used with domainId.

=item diskofferingid

the ID of the disk offering for the virtual machine. If the template is of ISO format, the diskOfferingId is for the root disk volume. Otherwise this parameter is used to indicate the offering for the data disk volume. If the templateId parameter passed is from a Template object, the diskOfferingId refers to a DATA Disk Volume created. If the templateId parameter passed is from an ISO object, the diskOfferingId refers to a ROOT Disk Volume created.

=item displayname

an optional user generated name for the virtual machine

=item domainid

an optional domainId for the virtual machine. If the account parameter is used, domainId must also be used.

=item group

an optional group for the virtual machine

=item hostid

destination Host ID to deploy the VM to - parameter available for root admin only

=item hypervisor

the hypervisor on which to deploy the virtual machine

=item ipaddress

the ip address for default vm's network

=item iptonetworklist

ip to network mapping. Can't be specified with networkIds parameter. Example: iptonetworklist[0].ip=10.10.10.11&iptonetworklist[0].networkid=204 - requests to use ip 10.10.10.11 in network id=204

=item keyboard

an optional keyboard device type for the virtual machine. valid value can be one of de,de-ch,es,fi,fr,fr-be,fr-ch,is,it,jp,nl-be,no,pt,uk,us

=item keypair

name of the ssh key pair used to login to the virtual machine

=item name

host name for the virtual machine

=item networkids

list of network ids used by virtual machine. Can't be specified with ipToNetworkList parameter

=item securitygroupids

comma separated list of security groups id that going to be applied to the virtual machine. Should be passed only when vm is created from a zone with Basic Network support. Mutually exclusive with securitygroupnames parameter

=item securitygroupnames

comma separated list of security groups names that going to be applied to the virtual machine. Should be passed only when vm is created from a zone with Basic Network support. Mutually exclusive with securitygroupids parameter

=item size

the arbitrary size for the DATADISK volume. Mutually exclusive with diskOfferingId

=item userdata

an optional binary data that can be sent to the virtual machine upon a successful deployment. This binary data must be base64 encoded before adding it to the request. Currently only HTTP GET is supported. Using HTTP GET (via querystring), you can send up to 2KB of data after base64 encoding.

=back

=head3 Response

=over

=item account

the account associated with the virtual machine

=item cpunumber

the number of cpu this virtual machine is running with

=item cpuspeed

the speed of each cpu

=item cpuused

the amount of the vm's CPU currently used

=item created

the date when this virtual machine was created

=item displayname

user generated name. The name of the virtual machine is returned if no displayname exists.

=item domain

the name of the domain in which the virtual machine exists

=item domainid

the ID of the domain in which the virtual machine exists

=item forvirtualnetwork

the virtual network for the service offering

=item group

the group name of the virtual machine

=item groupid

the group ID of the virtual machine

=item guestosid

Os type ID of the virtual machine

=item haenable

true if high-availability is enabled, false otherwise

=item hostid

the ID of the host for the virtual machine

=item hostname

the name of the host for the virtual machine

=item hypervisor

the hypervisor on which the template runs

=item id

the ID of the virtual machine

=item ipaddress

the ip address of the virtual machine

=item isodisplaytext

an alternate display text of the ISO attached to the virtual machine

=item isoid

the ID of the ISO attached to the virtual machine

=item isoname

the name of the ISO attached to the virtual machine

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine

=item jobstatus

shows the current pending asynchronous job status

=item memory

the memory allocated for the virtual machine

=item name

the name of the virtual machine

=item networkkbsread

the incoming network traffic on the vm

=item networkkbswrite

the outgoing network traffic on the host

=item nic(*)

the list of nics associated with vm

=item password

the password (if exists) of the virtual machine

=item passwordenabled

true if the password rest feature is enabled, false otherwise

=item rootdeviceid

device ID of the root volume

=item rootdevicetype

device type of the root volume

=item securitygroup(*)

list of security groups associated with the virtual machine

=item serviceofferingid

the ID of the service offering of the virtual machine

=item serviceofferingname

the name of the service offering of the virtual machine

=item state

the state of the virtual machine

=item templatedisplaytext

an alternate display text of the template for the virtual machine

=item templateid

the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.

=item templatename

the name of the template for the virtual machine

=item zoneid

the ID of the availablility zone for the virtual machine

=item zonename

the name of the availability zone for the virtual machine

=back

=head2 destroyVirtualMachine (A)

Destroys a virtual machine. Once destroyed, only the administrator can recover it.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

The ID of the virtual machine

=back

=head3 Response

=over

=item account

the account associated with the virtual machine

=item cpunumber

the number of cpu this virtual machine is running with

=item cpuspeed

the speed of each cpu

=item cpuused

the amount of the vm's CPU currently used

=item created

the date when this virtual machine was created

=item displayname

user generated name. The name of the virtual machine is returned if no displayname exists.

=item domain

the name of the domain in which the virtual machine exists

=item domainid

the ID of the domain in which the virtual machine exists

=item forvirtualnetwork

the virtual network for the service offering

=item group

the group name of the virtual machine

=item groupid

the group ID of the virtual machine

=item guestosid

Os type ID of the virtual machine

=item haenable

true if high-availability is enabled, false otherwise

=item hostid

the ID of the host for the virtual machine

=item hostname

the name of the host for the virtual machine

=item hypervisor

the hypervisor on which the template runs

=item id

the ID of the virtual machine

=item ipaddress

the ip address of the virtual machine

=item isodisplaytext

an alternate display text of the ISO attached to the virtual machine

=item isoid

the ID of the ISO attached to the virtual machine

=item isoname

the name of the ISO attached to the virtual machine

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine

=item jobstatus

shows the current pending asynchronous job status

=item memory

the memory allocated for the virtual machine

=item name

the name of the virtual machine

=item networkkbsread

the incoming network traffic on the vm

=item networkkbswrite

the outgoing network traffic on the host

=item nic(*)

the list of nics associated with vm

=item password

the password (if exists) of the virtual machine

=item passwordenabled

true if the password rest feature is enabled, false otherwise

=item rootdeviceid

device ID of the root volume

=item rootdevicetype

device type of the root volume

=item securitygroup(*)

list of security groups associated with the virtual machine

=item serviceofferingid

the ID of the service offering of the virtual machine

=item serviceofferingname

the name of the service offering of the virtual machine

=item state

the state of the virtual machine

=item templatedisplaytext

an alternate display text of the template for the virtual machine

=item templateid

the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.

=item templatename

the name of the template for the virtual machine

=item zoneid

the ID of the availablility zone for the virtual machine

=item zonename

the name of the availability zone for the virtual machine

=back

=head2 rebootVirtualMachine (A)

Reboots a virtual machine.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

The ID of the virtual machine

=back

=head3 Response

=over

=item account

the account associated with the virtual machine

=item cpunumber

the number of cpu this virtual machine is running with

=item cpuspeed

the speed of each cpu

=item cpuused

the amount of the vm's CPU currently used

=item created

the date when this virtual machine was created

=item displayname

user generated name. The name of the virtual machine is returned if no displayname exists.

=item domain

the name of the domain in which the virtual machine exists

=item domainid

the ID of the domain in which the virtual machine exists

=item forvirtualnetwork

the virtual network for the service offering

=item group

the group name of the virtual machine

=item groupid

the group ID of the virtual machine

=item guestosid

Os type ID of the virtual machine

=item haenable

true if high-availability is enabled, false otherwise

=item hostid

the ID of the host for the virtual machine

=item hostname

the name of the host for the virtual machine

=item hypervisor

the hypervisor on which the template runs

=item id

the ID of the virtual machine

=item ipaddress

the ip address of the virtual machine

=item isodisplaytext

an alternate display text of the ISO attached to the virtual machine

=item isoid

the ID of the ISO attached to the virtual machine

=item isoname

the name of the ISO attached to the virtual machine

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine

=item jobstatus

shows the current pending asynchronous job status

=item memory

the memory allocated for the virtual machine

=item name

the name of the virtual machine

=item networkkbsread

the incoming network traffic on the vm

=item networkkbswrite

the outgoing network traffic on the host

=item nic(*)

the list of nics associated with vm

=item password

the password (if exists) of the virtual machine

=item passwordenabled

true if the password rest feature is enabled, false otherwise

=item rootdeviceid

device ID of the root volume

=item rootdevicetype

device type of the root volume

=item securitygroup(*)

list of security groups associated with the virtual machine

=item serviceofferingid

the ID of the service offering of the virtual machine

=item serviceofferingname

the name of the service offering of the virtual machine

=item state

the state of the virtual machine

=item templatedisplaytext

an alternate display text of the template for the virtual machine

=item templateid

the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.

=item templatename

the name of the template for the virtual machine

=item zoneid

the ID of the availablility zone for the virtual machine

=item zonename

the name of the availability zone for the virtual machine

=back

=head2 startVirtualMachine (A)

Starts a virtual machine.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

The ID of the virtual machine

=back

=head3 Response

=over

=item account

the account associated with the virtual machine

=item cpunumber

the number of cpu this virtual machine is running with

=item cpuspeed

the speed of each cpu

=item cpuused

the amount of the vm's CPU currently used

=item created

the date when this virtual machine was created

=item displayname

user generated name. The name of the virtual machine is returned if no displayname exists.

=item domain

the name of the domain in which the virtual machine exists

=item domainid

the ID of the domain in which the virtual machine exists

=item forvirtualnetwork

the virtual network for the service offering

=item group

the group name of the virtual machine

=item groupid

the group ID of the virtual machine

=item guestosid

Os type ID of the virtual machine

=item haenable

true if high-availability is enabled, false otherwise

=item hostid

the ID of the host for the virtual machine

=item hostname

the name of the host for the virtual machine

=item hypervisor

the hypervisor on which the template runs

=item id

the ID of the virtual machine

=item ipaddress

the ip address of the virtual machine

=item isodisplaytext

an alternate display text of the ISO attached to the virtual machine

=item isoid

the ID of the ISO attached to the virtual machine

=item isoname

the name of the ISO attached to the virtual machine

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine

=item jobstatus

shows the current pending asynchronous job status

=item memory

the memory allocated for the virtual machine

=item name

the name of the virtual machine

=item networkkbsread

the incoming network traffic on the vm

=item networkkbswrite

the outgoing network traffic on the host

=item nic(*)

the list of nics associated with vm

=item password

the password (if exists) of the virtual machine

=item passwordenabled

true if the password rest feature is enabled, false otherwise

=item rootdeviceid

device ID of the root volume

=item rootdevicetype

device type of the root volume

=item securitygroup(*)

list of security groups associated with the virtual machine

=item serviceofferingid

the ID of the service offering of the virtual machine

=item serviceofferingname

the name of the service offering of the virtual machine

=item state

the state of the virtual machine

=item templatedisplaytext

an alternate display text of the template for the virtual machine

=item templateid

the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.

=item templatename

the name of the template for the virtual machine

=item zoneid

the ID of the availablility zone for the virtual machine

=item zonename

the name of the availability zone for the virtual machine

=back

=head2 stopVirtualMachine (A)

Stops a virtual machine.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

The ID of the virtual machine

=back

=head4 Optional Parameters

=over

=item forced

Force stop the VM.  The caller knows the VM is stopped.

=back

=head3 Response

=over

=item account

the account associated with the virtual machine

=item cpunumber

the number of cpu this virtual machine is running with

=item cpuspeed

the speed of each cpu

=item cpuused

the amount of the vm's CPU currently used

=item created

the date when this virtual machine was created

=item displayname

user generated name. The name of the virtual machine is returned if no displayname exists.

=item domain

the name of the domain in which the virtual machine exists

=item domainid

the ID of the domain in which the virtual machine exists

=item forvirtualnetwork

the virtual network for the service offering

=item group

the group name of the virtual machine

=item groupid

the group ID of the virtual machine

=item guestosid

Os type ID of the virtual machine

=item haenable

true if high-availability is enabled, false otherwise

=item hostid

the ID of the host for the virtual machine

=item hostname

the name of the host for the virtual machine

=item hypervisor

the hypervisor on which the template runs

=item id

the ID of the virtual machine

=item ipaddress

the ip address of the virtual machine

=item isodisplaytext

an alternate display text of the ISO attached to the virtual machine

=item isoid

the ID of the ISO attached to the virtual machine

=item isoname

the name of the ISO attached to the virtual machine

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine

=item jobstatus

shows the current pending asynchronous job status

=item memory

the memory allocated for the virtual machine

=item name

the name of the virtual machine

=item networkkbsread

the incoming network traffic on the vm

=item networkkbswrite

the outgoing network traffic on the host

=item nic(*)

the list of nics associated with vm

=item password

the password (if exists) of the virtual machine

=item passwordenabled

true if the password rest feature is enabled, false otherwise

=item rootdeviceid

device ID of the root volume

=item rootdevicetype

device type of the root volume

=item securitygroup(*)

list of security groups associated with the virtual machine

=item serviceofferingid

the ID of the service offering of the virtual machine

=item serviceofferingname

the name of the service offering of the virtual machine

=item state

the state of the virtual machine

=item templatedisplaytext

an alternate display text of the template for the virtual machine

=item templateid

the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.

=item templatename

the name of the template for the virtual machine

=item zoneid

the ID of the availablility zone for the virtual machine

=item zonename

the name of the availability zone for the virtual machine

=back

=head2 resetPasswordForVirtualMachine (A)

Resets the password for virtual machine. The virtual machine must be in a "Stopped" state and the template must already support this feature for this command to take effect. [async]

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

The ID of the virtual machine

=back

=head3 Response

=over

=item account

the account associated with the virtual machine

=item cpunumber

the number of cpu this virtual machine is running with

=item cpuspeed

the speed of each cpu

=item cpuused

the amount of the vm's CPU currently used

=item created

the date when this virtual machine was created

=item displayname

user generated name. The name of the virtual machine is returned if no displayname exists.

=item domain

the name of the domain in which the virtual machine exists

=item domainid

the ID of the domain in which the virtual machine exists

=item forvirtualnetwork

the virtual network for the service offering

=item group

the group name of the virtual machine

=item groupid

the group ID of the virtual machine

=item guestosid

Os type ID of the virtual machine

=item haenable

true if high-availability is enabled, false otherwise

=item hostid

the ID of the host for the virtual machine

=item hostname

the name of the host for the virtual machine

=item hypervisor

the hypervisor on which the template runs

=item id

the ID of the virtual machine

=item ipaddress

the ip address of the virtual machine

=item isodisplaytext

an alternate display text of the ISO attached to the virtual machine

=item isoid

the ID of the ISO attached to the virtual machine

=item isoname

the name of the ISO attached to the virtual machine

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine

=item jobstatus

shows the current pending asynchronous job status

=item memory

the memory allocated for the virtual machine

=item name

the name of the virtual machine

=item networkkbsread

the incoming network traffic on the vm

=item networkkbswrite

the outgoing network traffic on the host

=item nic(*)

the list of nics associated with vm

=item password

the password (if exists) of the virtual machine

=item passwordenabled

true if the password rest feature is enabled, false otherwise

=item rootdeviceid

device ID of the root volume

=item rootdevicetype

device type of the root volume

=item securitygroup(*)

list of security groups associated with the virtual machine

=item serviceofferingid

the ID of the service offering of the virtual machine

=item serviceofferingname

the name of the service offering of the virtual machine

=item state

the state of the virtual machine

=item templatedisplaytext

an alternate display text of the template for the virtual machine

=item templateid

the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.

=item templatename

the name of the template for the virtual machine

=item zoneid

the ID of the availablility zone for the virtual machine

=item zonename

the name of the availability zone for the virtual machine

=back

=head2 changeServiceForVirtualMachine (A)

Changes the service offering for a virtual machine. The virtual machine must be in a "Stopped" state for this command to take effect.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

The ID of the virtual machine

=item serviceofferingid

the service offering ID to apply to the virtual machine

=back

=head3 Response

=over

=item account

the account associated with the virtual machine

=item cpunumber

the number of cpu this virtual machine is running with

=item cpuspeed

the speed of each cpu

=item cpuused

the amount of the vm's CPU currently used

=item created

the date when this virtual machine was created

=item displayname

user generated name. The name of the virtual machine is returned if no displayname exists.

=item domain

the name of the domain in which the virtual machine exists

=item domainid

the ID of the domain in which the virtual machine exists

=item forvirtualnetwork

the virtual network for the service offering

=item group

the group name of the virtual machine

=item groupid

the group ID of the virtual machine

=item guestosid

Os type ID of the virtual machine

=item haenable

true if high-availability is enabled, false otherwise

=item hostid

the ID of the host for the virtual machine

=item hostname

the name of the host for the virtual machine

=item hypervisor

the hypervisor on which the template runs

=item id

the ID of the virtual machine

=item ipaddress

the ip address of the virtual machine

=item isodisplaytext

an alternate display text of the ISO attached to the virtual machine

=item isoid

the ID of the ISO attached to the virtual machine

=item isoname

the name of the ISO attached to the virtual machine

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine

=item jobstatus

shows the current pending asynchronous job status

=item memory

the memory allocated for the virtual machine

=item name

the name of the virtual machine

=item networkkbsread

the incoming network traffic on the vm

=item networkkbswrite

the outgoing network traffic on the host

=item nic(*)

the list of nics associated with vm

=item password

the password (if exists) of the virtual machine

=item passwordenabled

true if the password rest feature is enabled, false otherwise

=item rootdeviceid

device ID of the root volume

=item rootdevicetype

device type of the root volume

=item securitygroup(*)

list of security groups associated with the virtual machine

=item serviceofferingid

the ID of the service offering of the virtual machine

=item serviceofferingname

the name of the service offering of the virtual machine

=item state

the state of the virtual machine

=item templatedisplaytext

an alternate display text of the template for the virtual machine

=item templateid

the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.

=item templatename

the name of the template for the virtual machine

=item zoneid

the ID of the availablility zone for the virtual machine

=item zonename

the name of the availability zone for the virtual machine

=back

=head2 updateVirtualMachine

Updates parameters of a virtual machine.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

The ID of the virtual machine

=back

=head4 Optional Parameters

=over

=item displayname

user generated name

=item group

group of the virtual machine

=item haenable

true if high-availability is enabled for the virtual machine, false otherwise

=item ostypeid

the ID of the OS type that best represents this VM.

=item userdata

an optional binary data that can be sent to the virtual machine upon a successful deployment. This binary data must be base64 encoded before adding it to the request. Currently only HTTP GET is supported. Using HTTP GET (via querystring), you can send up to 2KB of data after base64 encoding.

=back

=head3 Response

=over

=item account

the account associated with the virtual machine

=item cpunumber

the number of cpu this virtual machine is running with

=item cpuspeed

the speed of each cpu

=item cpuused

the amount of the vm's CPU currently used

=item created

the date when this virtual machine was created

=item displayname

user generated name. The name of the virtual machine is returned if no displayname exists.

=item domain

the name of the domain in which the virtual machine exists

=item domainid

the ID of the domain in which the virtual machine exists

=item forvirtualnetwork

the virtual network for the service offering

=item group

the group name of the virtual machine

=item groupid

the group ID of the virtual machine

=item guestosid

Os type ID of the virtual machine

=item haenable

true if high-availability is enabled, false otherwise

=item hostid

the ID of the host for the virtual machine

=item hostname

the name of the host for the virtual machine

=item hypervisor

the hypervisor on which the template runs

=item id

the ID of the virtual machine

=item ipaddress

the ip address of the virtual machine

=item isodisplaytext

an alternate display text of the ISO attached to the virtual machine

=item isoid

the ID of the ISO attached to the virtual machine

=item isoname

the name of the ISO attached to the virtual machine

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine

=item jobstatus

shows the current pending asynchronous job status

=item memory

the memory allocated for the virtual machine

=item name

the name of the virtual machine

=item networkkbsread

the incoming network traffic on the vm

=item networkkbswrite

the outgoing network traffic on the host

=item nic(*)

the list of nics associated with vm

=item password

the password (if exists) of the virtual machine

=item passwordenabled

true if the password rest feature is enabled, false otherwise

=item rootdeviceid

device ID of the root volume

=item rootdevicetype

device type of the root volume

=item securitygroup(*)

list of security groups associated with the virtual machine

=item serviceofferingid

the ID of the service offering of the virtual machine

=item serviceofferingname

the name of the service offering of the virtual machine

=item state

the state of the virtual machine

=item templatedisplaytext

an alternate display text of the template for the virtual machine

=item templateid

the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.

=item templatename

the name of the template for the virtual machine

=item zoneid

the ID of the availablility zone for the virtual machine

=item zonename

the name of the availability zone for the virtual machine

=back

=head2 recoverVirtualMachine

Recovers a virtual machine.

User Level: 7 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

The ID of the virtual machine

=back

=head3 Response

=over

=item account

the account associated with the virtual machine

=item cpunumber

the number of cpu this virtual machine is running with

=item cpuspeed

the speed of each cpu

=item cpuused

the amount of the vm's CPU currently used

=item created

the date when this virtual machine was created

=item displayname

user generated name. The name of the virtual machine is returned if no displayname exists.

=item domain

the name of the domain in which the virtual machine exists

=item domainid

the ID of the domain in which the virtual machine exists

=item forvirtualnetwork

the virtual network for the service offering

=item group

the group name of the virtual machine

=item groupid

the group ID of the virtual machine

=item guestosid

Os type ID of the virtual machine

=item haenable

true if high-availability is enabled, false otherwise

=item hostid

the ID of the host for the virtual machine

=item hostname

the name of the host for the virtual machine

=item hypervisor

the hypervisor on which the template runs

=item id

the ID of the virtual machine

=item ipaddress

the ip address of the virtual machine

=item isodisplaytext

an alternate display text of the ISO attached to the virtual machine

=item isoid

the ID of the ISO attached to the virtual machine

=item isoname

the name of the ISO attached to the virtual machine

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine

=item jobstatus

shows the current pending asynchronous job status

=item memory

the memory allocated for the virtual machine

=item name

the name of the virtual machine

=item networkkbsread

the incoming network traffic on the vm

=item networkkbswrite

the outgoing network traffic on the host

=item nic(*)

the list of nics associated with vm

=item password

the password (if exists) of the virtual machine

=item passwordenabled

true if the password rest feature is enabled, false otherwise

=item rootdeviceid

device ID of the root volume

=item rootdevicetype

device type of the root volume

=item securitygroup(*)

list of security groups associated with the virtual machine

=item serviceofferingid

the ID of the service offering of the virtual machine

=item serviceofferingname

the name of the service offering of the virtual machine

=item state

the state of the virtual machine

=item templatedisplaytext

an alternate display text of the template for the virtual machine

=item templateid

the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.

=item templatename

the name of the template for the virtual machine

=item zoneid

the ID of the availablility zone for the virtual machine

=item zonename

the name of the availability zone for the virtual machine

=back

=head2 listVirtualMachines

List the virtual machines owned by the account.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item account

account. Must be used with the domainId parameter.

=item domainid

the domain ID. If used with the account parameter, lists virtual machines for the specified account in this domain.

=item forvirtualnetwork

list by network type; true if need to list vms using Virtual Network, false otherwise

=item groupid

the group ID

=item hostid

the host ID

=item hypervisor

the target hypervisor for the template

=item id

the ID of the virtual machine

=item isrecursive

Must be used with domainId parameter. Defaults to false, but if true, lists all vms from the parent specified by the domain id till leaves.

=item keyword

List by keyword

=item name

name of the virtual machine

=item networkid

list by network id

=item page

no description

=item pagesize

no description

=item podid

the pod ID

=item state

state of the virtual machine

=item storageid

the storage ID where vm's volumes belong to

=item zoneid

the availability zone ID

=back

=head3 Response

=over

=item account

the account associated with the virtual machine

=item cpunumber

the number of cpu this virtual machine is running with

=item cpuspeed

the speed of each cpu

=item cpuused

the amount of the vm's CPU currently used

=item created

the date when this virtual machine was created

=item displayname

user generated name. The name of the virtual machine is returned if no displayname exists.

=item domain

the name of the domain in which the virtual machine exists

=item domainid

the ID of the domain in which the virtual machine exists

=item forvirtualnetwork

the virtual network for the service offering

=item group

the group name of the virtual machine

=item groupid

the group ID of the virtual machine

=item guestosid

Os type ID of the virtual machine

=item haenable

true if high-availability is enabled, false otherwise

=item hostid

the ID of the host for the virtual machine

=item hostname

the name of the host for the virtual machine

=item hypervisor

the hypervisor on which the template runs

=item id

the ID of the virtual machine

=item ipaddress

the ip address of the virtual machine

=item isodisplaytext

an alternate display text of the ISO attached to the virtual machine

=item isoid

the ID of the ISO attached to the virtual machine

=item isoname

the name of the ISO attached to the virtual machine

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine

=item jobstatus

shows the current pending asynchronous job status

=item memory

the memory allocated for the virtual machine

=item name

the name of the virtual machine

=item networkkbsread

the incoming network traffic on the vm

=item networkkbswrite

the outgoing network traffic on the host

=item nic(*)

the list of nics associated with vm

=item password

the password (if exists) of the virtual machine

=item passwordenabled

true if the password rest feature is enabled, false otherwise

=item rootdeviceid

device ID of the root volume

=item rootdevicetype

device type of the root volume

=item securitygroup(*)

list of security groups associated with the virtual machine

=item serviceofferingid

the ID of the service offering of the virtual machine

=item serviceofferingname

the name of the service offering of the virtual machine

=item state

the state of the virtual machine

=item templatedisplaytext

an alternate display text of the template for the virtual machine

=item templateid

the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.

=item templatename

the name of the template for the virtual machine

=item zoneid

the ID of the availablility zone for the virtual machine

=item zonename

the name of the availability zone for the virtual machine

=back

=head2 getVMPassword

Returns an encrypted password for the VM

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

The ID of the virtual machine

=back

=head3 Response

=over

=item encryptedpassword

The encrypted password of the VM

=back

=head2 migrateVirtualMachine

Attempts Migration of a user virtual machine to the host specified.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item hostid

destination Host ID to migrate VM to

=item virtualmachineid

the ID of the virtual machine

=back

=head3 Response

=over

=item account

the account associated with the virtual machine

=item cpunumber

the number of cpu this virtual machine is running with

=item cpuspeed

the speed of each cpu

=item cpuused

the amount of the vm's CPU currently used

=item created

the date when this virtual machine was created

=item displayname

user generated name. The name of the virtual machine is returned if no displayname exists.

=item domain

the name of the domain in which the virtual machine exists

=item domainid

the ID of the domain in which the virtual machine exists

=item forvirtualnetwork

the virtual network for the service offering

=item group

the group name of the virtual machine

=item groupid

the group ID of the virtual machine

=item guestosid

Os type ID of the virtual machine

=item haenable

true if high-availability is enabled, false otherwise

=item hostid

the ID of the host for the virtual machine

=item hostname

the name of the host for the virtual machine

=item hypervisor

the hypervisor on which the template runs

=item id

the ID of the virtual machine

=item ipaddress

the ip address of the virtual machine

=item isodisplaytext

an alternate display text of the ISO attached to the virtual machine

=item isoid

the ID of the ISO attached to the virtual machine

=item isoname

the name of the ISO attached to the virtual machine

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the virtual machine

=item jobstatus

shows the current pending asynchronous job status

=item memory

the memory allocated for the virtual machine

=item name

the name of the virtual machine

=item networkkbsread

the incoming network traffic on the vm

=item networkkbswrite

the outgoing network traffic on the host

=item nic(*)

the list of nics associated with vm

=item password

the password (if exists) of the virtual machine

=item passwordenabled

true if the password rest feature is enabled, false otherwise

=item rootdeviceid

device ID of the root volume

=item rootdevicetype

device type of the root volume

=item securitygroup(*)

list of security groups associated with the virtual machine

=item serviceofferingid

the ID of the service offering of the virtual machine

=item serviceofferingname

the name of the service offering of the virtual machine

=item state

the state of the virtual machine

=item templatedisplaytext

an alternate display text of the template for the virtual machine

=item templateid

the ID of the template for the virtual machine. A -1 is returned if the virtual machine was created from an ISO file.

=item templatename

the name of the template for the virtual machine

=item zoneid

the ID of the availablility zone for the virtual machine

=item zonename

the name of the availability zone for the virtual machine

=back

=head1 VMGroup Methods

=head2 createInstanceGroup (A)

Creates a vm group

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item name

the name of the instance group

=back

=head4 Optional Parameters

=over

=item account

the account of the instance group. The account parameter must be used with the domainId parameter.

=item domainid

the domain ID of account owning the instance group

=back

=head3 Response

=over

=item account

the account owning the instance group

=item created

time and date the instance group was created

=item domain

the domain name of the instance group

=item domainid

the domain ID of the instance group

=item id

the id of the instance group

=item name

the name of the instance group

=back

=head2 deleteInstanceGroup

Deletes a vm group

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the instance group

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 updateInstanceGroup

Updates a vm group

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

Instance group ID

=back

=head4 Optional Parameters

=over

=item name

new instance group name

=back

=head3 Response

=over

=item account

the account owning the instance group

=item created

time and date the instance group was created

=item domain

the domain name of the instance group

=item domainid

the domain ID of the instance group

=item id

the id of the instance group

=item name

the name of the instance group

=back

=head2 listInstanceGroups

Lists vm groups

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item account

list instance group belonging to the specified account. Must be used with domainid parameter

=item domainid

the domain ID. If used with the account parameter, lists virtual machines for the specified account in this domain.

=item id

list instance groups by ID

=item keyword

List by keyword

=item name

list instance groups by name

=item page

no description

=item pagesize

no description

=back

=head3 Response

=over

=item account

the account owning the instance group

=item created

time and date the instance group was created

=item domain

the domain name of the instance group

=item domainid

the domain ID of the instance group

=item id

the id of the instance group

=item name

the name of the instance group

=back

=head1 VPN Methods

=head2 createRemoteAccessVpn

Creates a l2tp/ipsec remote access vpn

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item publicipid

public ip address id of the vpn server

=back

=head4 Optional Parameters

=over

=item account

an optional account for the VPN. Must be used with domainId.

=item domainid

an optional domainId for the VPN. If the account parameter is used, domainId must also be used.

=item iprange

the range of ip addresses to allocate to vpn clients. The first ip in the range will be taken by the vpn server

=item openfirewall

if true, firewall rule for source/end pubic port is automatically created; if false - firewall rule has to be created explicitely. Has value true by default

=back

=head3 Response

=over

=item account

the account of the remote access vpn

=item domainid

the domain id of the account of the remote access vpn

=item domainname

the domain name of the account of the remote access vpn

=item iprange

the range of ips to allocate to the clients

=item presharedkey

the ipsec preshared key

=item publicip

the public ip address of the vpn server

=item publicipid

the public ip address of the vpn server

=item state

the state of the rule

=back

=head2 deleteRemoteAccessVpn (A)

Destroys a l2tp/ipsec remote access vpn

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item publicipid

public ip address id of the vpn server

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listRemoteAccessVpns (A)

Lists remote access vpns

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item publicipid

public ip address id of the vpn server

=back

=head4 Optional Parameters

=over

=item account

the account of the remote access vpn. Must be used with the domainId parameter.

=item domainid

the domain ID of the remote access vpn rule. If used with the account parameter, lists remote access vpns for the account in the specified domain.

=item keyword

List by keyword

=item page

no description

=item pagesize

no description

=back

=head3 Response

=over

=item account

the account of the remote access vpn

=item domainid

the domain id of the account of the remote access vpn

=item domainname

the domain name of the account of the remote access vpn

=item iprange

the range of ips to allocate to the clients

=item presharedkey

the ipsec preshared key

=item publicip

the public ip address of the vpn server

=item publicipid

the public ip address of the vpn server

=item state

the state of the rule

=back

=head2 addVpnUser

Adds vpn users

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item password

password for the username

=item username

username for the vpn user

=back

=head4 Optional Parameters

=over

=item account

an optional account for the vpn user. Must be used with domainId.

=item domainid

an optional domainId for the vpn user. If the account parameter is used, domainId must also be used.

=back

=head3 Response

=over

=item account

the account of the remote access vpn

=item domainid

the domain id of the account of the remote access vpn

=item domainname

the domain name of the account of the remote access vpn

=item id

the vpn userID

=item username

the username of the vpn user

=back

=head2 removeVpnUser (A)

Removes vpn user

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item username

username for the vpn user

=back

=head4 Optional Parameters

=over

=item account

an optional account for the vpn user. Must be used with domainId.

=item domainid

an optional domainId for the vpn user. If the account parameter is used, domainId must also be used.

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listVpnUsers (A)

Lists vpn users

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item account

the account of the remote access vpn. Must be used with the domainId parameter.

=item domainid

the domain ID of the remote access vpn. If used with the account parameter, lists remote access vpns for the account in the specified domain.

=item id

the ID of the vpn user

=item keyword

List by keyword

=item page

no description

=item pagesize

no description

=item username

the username of the vpn user.

=back

=head3 Response

=over

=item account

the account of the remote access vpn

=item domainid

the domain id of the account of the remote access vpn

=item domainname

the domain name of the account of the remote access vpn

=item id

the vpn userID

=item username

the username of the vpn user

=back

=head1 Volume Methods

=head2 attachVolume

Attaches a disk volume to a virtual machine.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the disk volume

=item virtualmachineid

the ID of the virtual machine

=back

=head4 Optional Parameters

=over

=item deviceid

the ID of the device to map the volume to within the guest OS. If no deviceId is passed in, the next available deviceId will be chosen. Possible values for a Linux OS are:* 1 - /dev/xvdb* 2 - /dev/xvdc* 4 - /dev/xvde* 5 - /dev/xvdf* 6 - /dev/xvdg* 7 - /dev/xvdh* 8 - /dev/xvdi* 9 - /dev/xvdj

=back

=head3 Response

=over

=item account

the account associated with the disk volume

=item attached

the date the volume was attached to a VM instance

=item created

the date the disk volume was created

=item destroyed

the boolean state of whether the volume is destroyed or not

=item deviceid

the ID of the device on user vm the volume is attahed to. This tag is not returned when the volume is detached.

=item diskofferingdisplaytext

the display text of the disk offering

=item diskofferingid

ID of the disk offering

=item diskofferingname

name of the disk offering

=item domain

the domain associated with the disk volume

=item domainid

the ID of the domain associated with the disk volume

=item hypervisor

Hypervisor the volume belongs to

=item id

ID of the disk volume

=item isextractable

true if the volume is extractable, false otherwise

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume

=item jobstatus

shows the current pending asynchronous job status

=item name

name of the disk volume

=item serviceofferingdisplaytext

the display text of the service offering for root disk

=item serviceofferingid

ID of the service offering for root disk

=item serviceofferingname

name of the service offering for root disk

=item size

size of the disk volume

=item snapshotid

ID of the snapshot from which this volume was created

=item state

the state of the disk volume

=item storage

name of the primary storage hosting the disk volume

=item storagetype

shared or local storage

=item type

type of the disk volume (ROOT or DATADISK)

=item virtualmachineid

id of the virtual machine

=item vmdisplayname

display name of the virtual machine

=item vmname

name of the virtual machine

=item vmstate

state of the virtual machine

=item zoneid

ID of the availability zone

=item zonename

name of the availability zone

=back

=head2 detachVolume (A)

Detaches a disk volume from a virtual machine.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item deviceid

the device ID on the virtual machine where volume is detached from

=item id

the ID of the disk volume

=item virtualmachineid

the ID of the virtual machine where the volume is detached from

=back

=head3 Response

=over

=item account

the account associated with the disk volume

=item attached

the date the volume was attached to a VM instance

=item created

the date the disk volume was created

=item destroyed

the boolean state of whether the volume is destroyed or not

=item deviceid

the ID of the device on user vm the volume is attahed to. This tag is not returned when the volume is detached.

=item diskofferingdisplaytext

the display text of the disk offering

=item diskofferingid

ID of the disk offering

=item diskofferingname

name of the disk offering

=item domain

the domain associated with the disk volume

=item domainid

the ID of the domain associated with the disk volume

=item hypervisor

Hypervisor the volume belongs to

=item id

ID of the disk volume

=item isextractable

true if the volume is extractable, false otherwise

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume

=item jobstatus

shows the current pending asynchronous job status

=item name

name of the disk volume

=item serviceofferingdisplaytext

the display text of the service offering for root disk

=item serviceofferingid

ID of the service offering for root disk

=item serviceofferingname

name of the service offering for root disk

=item size

size of the disk volume

=item snapshotid

ID of the snapshot from which this volume was created

=item state

the state of the disk volume

=item storage

name of the primary storage hosting the disk volume

=item storagetype

shared or local storage

=item type

type of the disk volume (ROOT or DATADISK)

=item virtualmachineid

id of the virtual machine

=item vmdisplayname

display name of the virtual machine

=item vmname

name of the virtual machine

=item vmstate

state of the virtual machine

=item zoneid

ID of the availability zone

=item zonename

name of the availability zone

=back

=head2 createVolume (A)

Creates a disk volume from a disk offering. This disk volume must still be attached to a virtual machine to make use of it.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item name

the name of the disk volume

=back

=head4 Optional Parameters

=over

=item account

the account associated with the disk volume. Must be used with the domainId parameter.

=item diskofferingid

the ID of the disk offering. Either diskOfferingId or snapshotId must be passed in.

=item domainid

the domain ID associated with the disk offering. If used with the account parameter returns the disk volume associated with the account for the specified domain.

=item size

Arbitrary volume size

=item snapshotid

the snapshot ID for the disk volume. Either diskOfferingId or snapshotId must be passed in.

=item zoneid

the ID of the availability zone

=back

=head3 Response

=over

=item account

the account associated with the disk volume

=item attached

the date the volume was attached to a VM instance

=item created

the date the disk volume was created

=item destroyed

the boolean state of whether the volume is destroyed or not

=item deviceid

the ID of the device on user vm the volume is attahed to. This tag is not returned when the volume is detached.

=item diskofferingdisplaytext

the display text of the disk offering

=item diskofferingid

ID of the disk offering

=item diskofferingname

name of the disk offering

=item domain

the domain associated with the disk volume

=item domainid

the ID of the domain associated with the disk volume

=item hypervisor

Hypervisor the volume belongs to

=item id

ID of the disk volume

=item isextractable

true if the volume is extractable, false otherwise

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume

=item jobstatus

shows the current pending asynchronous job status

=item name

name of the disk volume

=item serviceofferingdisplaytext

the display text of the service offering for root disk

=item serviceofferingid

ID of the service offering for root disk

=item serviceofferingname

name of the service offering for root disk

=item size

size of the disk volume

=item snapshotid

ID of the snapshot from which this volume was created

=item state

the state of the disk volume

=item storage

name of the primary storage hosting the disk volume

=item storagetype

shared or local storage

=item type

type of the disk volume (ROOT or DATADISK)

=item virtualmachineid

id of the virtual machine

=item vmdisplayname

display name of the virtual machine

=item vmname

name of the virtual machine

=item vmstate

state of the virtual machine

=item zoneid

ID of the availability zone

=item zonename

name of the availability zone

=back

=head2 deleteVolume (A)

Deletes a detached disk volume.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

The ID of the disk volume

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listVolumes

Lists all volumes.

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item account

the account associated with the disk volume. Must be used with the domainId parameter.

=item domainid

Lists all disk volumes for the specified domain ID. If used with the account parameter, returns all disk volumes for an account in the specified domain ID.

=item hostid

list volumes on specified host

=item id

the ID of the disk volume

=item isrecursive

defaults to false, but if true, lists all volumes from the parent specified by the domain id till leaves.

=item keyword

List by keyword

=item name

the name of the disk volume

=item page

no description

=item pagesize

no description

=item podid

the pod id the disk volume belongs to

=item type

the type of disk volume

=item virtualmachineid

the ID of the virtual machine

=item zoneid

the ID of the availability zone

=back

=head3 Response

=over

=item account

the account associated with the disk volume

=item attached

the date the volume was attached to a VM instance

=item created

the date the disk volume was created

=item destroyed

the boolean state of whether the volume is destroyed or not

=item deviceid

the ID of the device on user vm the volume is attahed to. This tag is not returned when the volume is detached.

=item diskofferingdisplaytext

the display text of the disk offering

=item diskofferingid

ID of the disk offering

=item diskofferingname

name of the disk offering

=item domain

the domain associated with the disk volume

=item domainid

the ID of the domain associated with the disk volume

=item hypervisor

Hypervisor the volume belongs to

=item id

ID of the disk volume

=item isextractable

true if the volume is extractable, false otherwise

=item jobid

shows the current pending asynchronous job ID. This tag is not returned if no current pending jobs are acting on the volume

=item jobstatus

shows the current pending asynchronous job status

=item name

name of the disk volume

=item serviceofferingdisplaytext

the display text of the service offering for root disk

=item serviceofferingid

ID of the service offering for root disk

=item serviceofferingname

name of the service offering for root disk

=item size

size of the disk volume

=item snapshotid

ID of the snapshot from which this volume was created

=item state

the state of the disk volume

=item storage

name of the primary storage hosting the disk volume

=item storagetype

shared or local storage

=item type

type of the disk volume (ROOT or DATADISK)

=item virtualmachineid

id of the virtual machine

=item vmdisplayname

display name of the virtual machine

=item vmname

name of the virtual machine

=item vmstate

state of the virtual machine

=item zoneid

ID of the availability zone

=item zonename

name of the availability zone

=back

=head2 extractVolume

Extracts volume

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the volume

=item mode

the mode of extraction - HTTP_DOWNLOAD or FTP_UPLOAD

=item zoneid

the ID of the zone where the volume is located

=back

=head4 Optional Parameters

=over

=item url

the url to which the volume would be extracted

=back

=head3 Response

=over

=item accountid

the account id to which the extracted object belongs

=item created

the time and date the object was created

=item extractId

the upload id of extracted object

=item extractMode

the mode of extraction - upload or download

=item id

the id of extracted object

=item name

the name of the extracted object

=item state

the state of the extracted object

=item status

the status of the extraction

=item storagetype

type of the storage

=item uploadpercentage

the percentage of the entity uploaded to the specified location

=item url

if mode = upload then url of the uploaded entity. if mode = download the url from which the entity can be downloaded

=item zoneid

zone ID the object was extracted from

=item zonename

zone name the object was extracted from

=back

=head1 Zone Methods

=head2 createZone (A)

Creates a Zone.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item dns1

the first DNS for the Zone

=item internaldns1

the first internal DNS for the Zone

=item name

the name of the Zone

=item networktype

network type of the zone, can be Basic or Advanced

=back

=head4 Optional Parameters

=over

=item allocationstate

Allocation state of this Zone for allocation of new resources

=item dns2

the second DNS for the Zone

=item domain

Network domain name for the networks in the zone

=item domainid

the ID of the containing domain, null for public zones

=item guestcidraddress

the guest CIDR address for the Zone

=item internaldns2

the second internal DNS for the Zone

=item securitygroupenabled

true if network is security group enabled, false otherwise

=item vlan

the VLAN for the Zone

=back

=head3 Response

=over

=item allocationstate

the allocation state of the cluster

=item description

Zone description

=item dhcpprovider

the dhcp Provider for the Zone

=item displaytext

the display text of the zone

=item dns1

the first DNS for the Zone

=item dns2

the second DNS for the Zone

=item domain

Network domain name for the networks in the zone

=item domainid

the ID of the containing domain, null for public zones

=item guestcidraddress

the guest CIDR address for the Zone

=item id

Zone id

=item internaldns1

the first internal DNS for the Zone

=item internaldns2

the second internal DNS for the Zone

=item name

Zone name

=item networktype

the network type of the zone; can be Basic or Advanced

=item securitygroupsenabled

true if security groups support is enabled, false otherwise

=item vlan

the vlan range of the zone

=item zonetoken

Zone Token

=back

=head2 updateZone

Updates a Zone.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the Zone

=back

=head4 Optional Parameters

=over

=item allocationstate

Allocation state of this cluster for allocation of new resources

=item details

the details for the Zone

=item dhcpprovider

the dhcp Provider for the Zone

=item dns1

the first DNS for the Zone

=item dns2

the second DNS for the Zone

=item dnssearchorder

the dns search order list

=item domain

Network domain name for the networks in the zone

=item guestcidraddress

the guest CIDR address for the Zone

=item internaldns1

the first internal DNS for the Zone

=item internaldns2

the second internal DNS for the Zone

=item ispublic

updates a private zone to public if set, but not vice-versa

=item name

the name of the Zone

=item vlan

the VLAN for the Zone

=back

=head3 Response

=over

=item allocationstate

the allocation state of the cluster

=item description

Zone description

=item dhcpprovider

the dhcp Provider for the Zone

=item displaytext

the display text of the zone

=item dns1

the first DNS for the Zone

=item dns2

the second DNS for the Zone

=item domain

Network domain name for the networks in the zone

=item domainid

the ID of the containing domain, null for public zones

=item guestcidraddress

the guest CIDR address for the Zone

=item id

Zone id

=item internaldns1

the first internal DNS for the Zone

=item internaldns2

the second internal DNS for the Zone

=item name

Zone name

=item networktype

the network type of the zone; can be Basic or Advanced

=item securitygroupsenabled

true if security groups support is enabled, false otherwise

=item vlan

the vlan range of the zone

=item zonetoken

Zone Token

=back

=head2 deleteZone

Deletes a Zone.

User Level: 1 (FIXME: this needs to be improved)

=head3 Request

=head4 Required Parameters

=over

=item id

the ID of the Zone

=back

=head3 Response

=over

=item displaytext

any text associated with the success or failure

=item success

true if operation is executed successfully

=back

=head2 listZones

Lists zones

User Level: 15 (FIXME: this needs to be improved)

=head3 Request

=head4 Optional Parameters

=over

=item available

true if you want to retrieve all available Zones. False if you only want to return the Zones from which you have at least one VM. Default is false.

=item domainid

the ID of the domain associated with the zone

=item id

the ID of the zone

=item keyword

List by keyword

=item page

no description

=item pagesize

no description

=back

=head3 Response

=over

=item allocationstate

the allocation state of the cluster

=item description

Zone description

=item dhcpprovider

the dhcp Provider for the Zone

=item displaytext

the display text of the zone

=item dns1

the first DNS for the Zone

=item dns2

the second DNS for the Zone

=item domain

Network domain name for the networks in the zone

=item domainid

the ID of the containing domain, null for public zones

=item guestcidraddress

the guest CIDR address for the Zone

=item id

Zone id

=item internaldns1

the first internal DNS for the Zone

=item internaldns2

the second internal DNS for the Zone

=item name

Zone name

=item networktype

the network type of the zone; can be Basic or Advanced

=item securitygroupsenabled

true if security groups support is enabled, false otherwise

=item vlan

the vlan range of the zone

=item zonetoken

Zone Token

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Alan Young <harleypig@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alan Young.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

