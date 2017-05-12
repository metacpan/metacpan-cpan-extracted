package Ovirt::VM;

use v5.10;
use Carp;
use Moo;

with 'Ovirt';
our $VERSION = '0.04';

=head1 NAME

Ovirt::VM - Bindings for oVirt VM API 

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

 use Ovirt::VM;

 my %con = (
            username            => 'admin',
            password            => 'password',
            manager             => 'ovirt-mgr.example.com',
            vm_output_attrs     => 'id,name,state,description', # optional
            vm_output_delimiter => '||', # optional
 );

 my $vm = Ovirt::VM->new(%con);

 # return xml / json output
 print $vm->list_xml; 
 print $vm->list_json;
 
 # list vm separated by new line
 # return attributes specified on 'vm_output_attrs'
 print $vm->list;
 
 # list specific vm 
 print $vm->list('b4738b0f-b73d-4a66-baa8-2ba465d63132');
 
 # create, remove, get all running vm, stop all vm
 $vm->create('vm1','Default','CentOS7');
 $vm->remove('2d83bb51-9a77-432d-939c-35be207017b9');
 $vm->get_running();
 $vm->stop_all();
 
 # start, stop, reboot, migrate vm
 $vm->start     ('b4738b0f-b73d-4a66-baa8-2ba465d63132');
 $vm->stop      ('b4738b0f-b73d-4a66-baa8-2ba465d63132');
 $vm->reboot    ('b4738b0f-b73d-4a66-baa8-2ba465d63132');
 $vm->migrate   ('b4738b0f-b73d-4a66-baa8-2ba465d63132');

 # get vm's statistics
 $vm->get_statistics($vmid);
 
 # add/remove/list nic and disk
 $vm->add_disk('6efc0cfa-8495-4a96-93e5-ee490328cf48',  # vm id
                'virtio',                               # driver interface
                'cow',                                  # format
                '1073741824',                           # size
                'mydisk1',                              # disk name
                '9b952bdc-b7ec-4673-84b0-477b48945a9a'  # storage domain id
              );

 $vm->add_nic('6efc0cfa-8495-4a96-93e5-ee490328cf48',   # vm id
              'virtio',                                 # driver interface
              'nic1',                                   # nic name
              'rhevm'                                   # network name
             );

 # Output also available in hash
 # for example to print all vm name and state
 my $hash = $vm->hash_output;
 for my $array (keys $hash->{vm}) {
    print $hash->{vm}[$array]->{name} . " " . 
            $hash->{vm}[$array]->{status}->{state};
 }
 
 # we can also specify specific vm 'id' when initiating an object
 # so we can direct access the element for specific vm
 print $vm->hash_output->{name};                   
 print $vm->hash_output->{cluster}->{id};

=head1 Attributes

 Other attributes is also inherited from Ovirt.pm
 Check 'perldoc Ovirt' for detail
 
 notes :
 ro                     = read only, can be specified only during initialization
 rw                     = read write, user can set this attribute
 rwp                    = read write protected, for internal class
 
 vm_url                 = (ro) store default vm url path                  
 vm_cdrom_xml           = (ro) store xml to be post on start/stop vm action with boot device set to cdrom
 vm_hd_xml              = (ro) store xml to be post on start/stop vm action with boot device set to hd
 vm_boot_dev            = (rw) set boot device when start / stopping vm, default to hd
 vm_output_delimiter    = (rw) specify output delimiter between attribute, default is '||'
 vm_output_attrs        = (rw) store vm attributes to be returned, default is (id, name, state)
                          supported attributes :
                            id              name    
                            memory          description
                            state           cpu_cores
                            cpu_sockets     cpu_arch
                            cpu_shares      os_type
                            boot_dev        ha_enabled
                            ha_priority     display_type
                            display_address display_port
                            cluster_id      template_id
                            stop_time       creation_time
                            timezone        usb_enabled
                            host_id         display_host_subject
                            
=cut

has 'vm_url'                => ( is => 'ro', default => '/api/vms' );
has 'vm_output_attrs'       => ( is => 'rw', default => 'id,name,state',
                                 isa => 
                                 sub 
                                 {
                                     # store all output attribute into array split by ','
                                     # $_[0] is the arguments spefied during initialization
                                     my @attrs = split ',' => $_[0];
                                     
                                     croak "vm_output_attrs can't be empty"
                                        unless @attrs;
                                     
                                     # check if provided attribute is valid / supported
                                     my @supported_attr = qw |
                                                                id              name    
                                                                memory          description
                                                                state           cpu_cores
                                                                cpu_sockets     cpu_arch
                                                                cpu_shares      os_type
                                                                boot_dev        ha_enabled
                                                                ha_priority     display_type
                                                                display_address display_port
                                                                cluster_id      template_id
                                                                stop_time       creation_time
                                                                timezone        usb_enabled
                                                                host_id         display_host_subject
                                                            |;
                                     for my $attr (@attrs) 
                                     {
                                         $attr = lc ($attr);
                                         $attr = Ovirt->trim($attr);
                                         croak "Attribute $attr is not valid / supported"
                                            unless grep { /\b$attr\b/ } @supported_attr;
                                     }
                                 });
                                 
has 'vm_output_delimiter'   => ( is => 'rw', default => '||' );
has 'vm_cdrom_xml'          => ( is => 'ro', default => '<action><vm><os><boot dev="cdrom"/></os></vm></action>');
has 'vm_hd_xml'             => ( is => 'ro', default => '<action><vm><os><boot dev="hd"/></os></vm></action>');
has 'vm_boot_dev'           => ( is => 'rw', 
                                 isa => sub 
                                        { 
                                                my $dev = $_[0];
                                                $dev    = lc ($dev);
                                                
                                                croak "supported boot device is hd or cdrom"
                                                    unless $dev =~ /^(hd|cdrom)/;
                                        },
                                default => 'hd');

=head1 SUBROUTINES/METHODS

=head2 BUILD

 The Constructor, build logging, call pass_log_obj method
 Built root_url with vm_url
 set output with get_api_response method from Ovirt.pm
 check if output attributes is valid
=cut

sub BUILD 
{
    my $self = shift;
    
    $self->pass_log_obj;
    
    if ($self->id) 
    {
        $self->_set_root_url($self->vm_url . '/' . $self->id);
    }
    else 
    {
        $self->_set_root_url($self->vm_url);
    }
    
    $self->get_api_response();
}

=head2 vm_action_output

 this method handle the output e.g start / stop vm
 required arguments ($xml), output passed by start/stop method
=cut

sub vm_action_output 
{
    my $self    = shift;
    
    # xml output from action (start,stop,reboot, etc)
    my $xml     = shift;
    
    $self->log->debug($xml);
    
    return $xml;
}

=head2 remove

 remove vm

=cut

sub remove 
{
    my $self = shift;
    
    my $vmid = shift || undef;
    my $move_url;
    
    # set the move final url
    if ($self->id) 
    {
        $move_url = $self->url;
    }
    else 
    {
        if ($vmid) 
        {
            my $is_valid = $self->is_vmid_valid($vmid);
            croak "vm id not found" unless $is_valid;
            
            $move_url = $self->url . "/$vmid";
        }
        else 
        {
            croak "vm id is required";
        }
    }
    
    $self->log->debug("move action url = $move_url");
    
    # set user agent
    my $ua      = LWP::UserAgent->new();
    my $action  = $ua->delete($move_url);
    
    my $parser = XML::LibXML->new();
    my $output = $parser->parse_string($action->decoded_content);
    
    $self->vm_action_output($output);
}

=head2 list_snapshot

 list vm's snapshot
 required argument ('vm id')

=cut

sub list_snapshot 
{
    my $self    = shift;
    my $vmid    = shift || undef;
    
    my $snapshot_url;
    
    # don't proceed if vm not exist
    my $is_valid = $self->is_vmid_valid($vmid);
    croak "vm id not found" 
        unless $is_valid;
    
    # set the url
    $snapshot_url = $self->url . "/$vmid/snapshots";
    
    $self->get_api_output($snapshot_url);
}

=head2 create_snapshot

 required arguments ('vm id', 'snapshot description', 'memorystate')
 memorystate can be true/false
 
 $vm->create_snapshot('ec191b8c-b3ec-41b9-9f9f-6d92bc32732b', 'test3', 'false');

=cut

sub create_snapshot
{
    my $self    = shift;
    
    my ($vmid, $description, $memorystate)  = @_;
    
    # don't proceed if vm not exist
    my $is_valid = $self->is_vmid_valid($vmid);
    croak "vm id not found" 
        unless $is_valid;
    
    # set the url to be post
    my $snapshot_url = $self->url . "/$vmid/snapshots";
    
    croak "memory state not supported, use true/false." 
        unless $memorystate =~ /\b(true|false)\b/;
        
    croak "snapshot description required"
        unless $description;
        
    # set xml string to be post
    my $xml = <<EOF;
<snapshot>
    <description>$description</description>
    <persist_memorystate>$memorystate</persist_memorystate>
    <vm id="$vmid"></vm>
</snapshot>
EOF
    
    $self->log->debug($xml);
    
    # set user agent
    my $ua      = LWP::UserAgent->new();
    my $action  = $ua->post($snapshot_url, Content_Type => 'application/xml', Content => $xml);
    
    my $parser = XML::LibXML->new();
    my $output = $parser->parse_string($action->decoded_content);
    
    $self->log->debug($output);
    
    return $output;
}

=head2 delete_snapshot

 required arguments ('vm id', 'snapshot id')
 $vm->delete_snapshot('ec191b8c-b3ec-41b9-9f9f-6d92bc32732b', 'b0e9198c-a404-4659-8a82-421ae85f54e1');

=cut

sub delete_snapshot
{
    my $self    = shift;
    
    my ($vmid, $snapshot_id) = @_;
    
    my $snapshot_url;
    
    # don't proceed if vm not exist
    my $is_valid = $self->is_vmid_valid($vmid);
    croak "vm id not found" 
        unless $is_valid;
    
    # set the url to be post
    $snapshot_url = $self->url . "/$vmid/snapshots/$snapshot_id";
    
    croak "snapshot id required"
        unless $snapshot_id;
    
    $self->log->debug("delete snapshot action url = $snapshot_url");
    
    # set user agent
    my $ua      = LWP::UserAgent->new();
    my $action  = $ua->delete($snapshot_url);
    
    my $parser = XML::LibXML->new();
    my $output = $parser->parse_string($action->decoded_content);
    
    $self->vm_action_output($output);
}

=head2 list_disk

 list vm's disk
 required argument ('vm id')

=cut

sub list_disk 
{
    my $self    = shift;
    my $vmid    = shift || undef;
    
    my $disk_url;
    
    # don't proceed if vm not exist
    my $is_valid = $self->is_vmid_valid($vmid);
    croak "vm id not found" 
        unless $is_valid;
    
    # set the url
    $disk_url = $self->url . "/$vmid/disks";
    
    $self->get_api_output($disk_url);
}

=head2 add_disk

 create vm disk
 required arguments ('vm id', 'driver type', 'format' , 'size in bytes', 'disk name', 'storage domain id' )
 
 supported driver type :
 - virtio
 - ide
 
 supported format:
 - cow
 - raw
 
 use Ovirt::Storage to get more information for the storage domain id
 see 'perldoc Ovirt::Storage' for example
 
 example :
 $vm->add_disk('6efc0cfa-8495-4a96-93e5-ee490328cf48',  # vm id
                'virtio',                               # driver interface
                'cow',                                  # format
                '1073741824',                           # size
                'mydisk1',                              # disk name
                '9b952bdc-b7ec-4673-84b0-477b48945a9a'  # storage domain id
              );

=cut

sub add_disk 
{
    my $self = shift;
    
    my ($vmid, $driver, $format, $size, $disk_name, $storage_domain_id)  = @_;
    
    my $disk_url;
    
    # don't proceed if vm not exist
    my $is_valid = $self->is_vmid_valid($vmid);
    croak "vm id not found" 
        unless $is_valid;
    
    # set the url to be post
    $disk_url = $self->url . "/$vmid/disks";
    
    croak "driver type not supported, use virtio/e1000/rtl8139." 
        unless $driver =~ /\b(virtio|ide)\b/;
        
    croak "disk format required"
        unless $format;
        
    croak "disk size required"
        unless $size;    
        
    croak "disk name required"
        unless $disk_name;
        
    croak "storage domain id required"
        unless $storage_domain_id;    
    
    # set xml string to be post
    my $xml = <<EOF;
<disk>
    <name>$disk_name</name>
    <storage_domains>
        <storage_domain id="$storage_domain_id"/>  
    </storage_domains>    
    <size>$size</size>
    <interface>$driver</interface>
    <format>$format</format>
    <bootable>false</bootable>
</disk>
EOF
    
    $self->log->debug($xml);
    
    # set user agent
    my $ua      = LWP::UserAgent->new();
    my $action  = $ua->post($disk_url, Content_Type => 'application/xml', Content => $xml);
    
    my $parser = XML::LibXML->new();
    my $output = $parser->parse_string($action->decoded_content);
    
    $self->log->debug($output);
    
    return $output; 
}

=head2 remove_disk

 remove vm disk
 required arguments ('vm id', 'disk id')
 use method list_disk to get the 'disk id' for particular vm
 
 example :
 $vm->remove_disk('6efc0cfa-8495-4a96-93e5-ee490328cf48', '99a4f585-9a39-465b-ae24-0068bd4eaad6');
 
=cut

sub remove_disk 
{
    my $self = shift;
    
    my ($vmid, $disk_id) = @_;
    
    my $disk_url;
    
    # don't proceed if vm not exist
    my $is_valid = $self->is_vmid_valid($vmid);
    croak "vm id not found" 
        unless $is_valid;
    
    # set the url to be post
    $disk_url = $self->url . "/$vmid/disks/$disk_id";
    
    croak "disk id required"
        unless $disk_id;
    
    $self->log->debug("move action url = $disk_url");
    
    # set user agent
    my $ua      = LWP::UserAgent->new();
    my $action  = $ua->delete($disk_url);
    
    my $parser = XML::LibXML->new();
    my $output = $parser->parse_string($action->decoded_content);
    
    $self->vm_action_output($output);
}

=head2 list_nic

 list vm's nic
 required argument ('vm id')

=cut

sub list_nic 
{
    my $self    = shift;
    my $vmid    = shift || undef;
    
    my $nic_url;
    
    # don't proceed if vm not exist
    my $is_valid = $self->is_vmid_valid($vmid);
    croak "vm id not found" 
        unless $is_valid;
    
    # set the url
    $nic_url = $self->url . "/$vmid/nics";
    
    $self->get_api_output($nic_url);
}

=head2 add_nic

 create vm nic
 required arguments ('vm id', 'driver type', 'nic name', 'network name' )
 
 supported driver type :
 - virtio
 - e1000
 - rtl8139
 
 use Ovirt::Network to get more information for the network name
 see 'perldoc Ovirt::Network' for example
 
 example :
 $vm->add_nic('6efc0cfa-8495-4a96-93e5-ee490328cf48', 'virtio', 'nic1', 'rhevm');

=cut

sub add_nic 
{
    my $self = shift;
    
    my ($vmid, $driver, $nic_name, $network_name)  = @_;
    
    my $nic_url;
    
    # don't proceed if vm not exist
    my $is_valid = $self->is_vmid_valid($vmid);
    croak "vm id not found" 
        unless $is_valid;
    
    # set the url to be post
    $nic_url = $self->url . "/$vmid/nics";
    
    croak "driver type not supported, use virtio/e1000/rtl8139." 
        unless $driver =~ /\b(virtio|e1000|rtl8139)\b/;
        
    croak "nic name required"
        unless $nic_name;
        
    croak "network name required"
        unless $network_name;    
    
    # set xml string to be post
    my $xml = <<EOF;
<nic>
  <interface>$driver</interface>
  <name>$nic_name</name>
  <network>
    <name>$network_name</name>
  </network>
</nic> 
EOF
    
    $self->log->debug($xml);
    
    # set user agent
    my $ua      = LWP::UserAgent->new();
    my $action  = $ua->post($nic_url, Content_Type => 'application/xml', Content => $xml);
    
    my $parser = XML::LibXML->new();
    my $output = $parser->parse_string($action->decoded_content);
    
    $self->log->debug($output);
    
    return $output; 
}

=head2 remove_nic

 remove vm nic
 required arguments ('vm id', 'nic id')
 use method list_nic to get the 'nic id' for particular vm
 
 example :
 $vm->remove_nic('6efc0cfa-8495-4a96-93e5-ee490328cf48', '82416c65-d8b2-4c82-8134-0e73e5ead624');
 
=cut

sub remove_nic 
{
    my $self = shift;
    
    my ($vmid, $nic_id) = @_;
    
    my $nic_url;
    
    # don't proceed if vm not exist
    my $is_valid = $self->is_vmid_valid($vmid);
    croak "vm id not found" 
        unless $is_valid;
    
    # set the url to be post
    $nic_url = $self->url . "/$vmid/nics/$nic_id";
    
    croak "nic id required"
        unless $nic_id;
    
    $self->log->debug("move action url = $nic_url");
    
    # set user agent
    my $ua      = LWP::UserAgent->new();
    my $action  = $ua->delete($nic_url);
    
    my $parser = XML::LibXML->new();
    my $output = $parser->parse_string($action->decoded_content);
    
    $self->vm_action_output($output);
}

=head2 create

 create vm using template
 required arguments (vm name, cluster name, template name)
 optional argument 'memory in bytes'
 example :
 # with memory specified 
 $vm->create('vm1', 'production_cluster', 'RHEL7', 1073741824);
 
 # without memory specified (will be based on template's memory)
 $vm->create('vm1', 'production_cluster', 'RHEL7');
 
=cut

sub create 
{
    my $self = shift;
    
    my ($vm_name, $cluster_name, $template_name, $memory) = @_;
    croak "vm name required"        unless $vm_name;
    croak "cluster name required"   unless $cluster_name;
    croak "template name required"  unless $template_name;
    
    $vm_name        = $self->trim($vm_name);
    $cluster_name   = $self->trim($cluster_name);
    $template_name  = $self->trim($template_name);
    
    $self->log->debug("vm name          = $vm_name");
    $self->log->debug("cluster name     = $cluster_name");
    $self->log->debug("template name    = $template_name");
    
    # create xml to be post
    my $xml;
    
    if ($memory) 
    {
        $memory     = $self->trim($memory);
        croak "Memory did not look like number" unless $memory =~ /^\d+$/;
        
        $self->log->debug("memory           = $memory");
        
        $xml = <<EOF;
<vm>
  <name>$vm_name</name>
  <cluster>
    <name>$cluster_name</name>
  </cluster>
  <template>
    <name>$template_name</name>
  </template>
  <memory>$memory</memory> 
  <os>
    <boot dev="hd"/>
  </os>
</vm>
EOF

    }
    else 
    {
        $self->log->debug("memory not specified");
        $xml = <<EOF;
<vm>
  <name>$vm_name</name>
  <cluster>
    <name>$cluster_name</name>
  </cluster>
  <template>
    <name>$template_name</name>
  </template> 
  <os>
    <boot dev="hd"/>
  </os>
</vm>
EOF
    }
    
    $self->log->debug($xml);
    
    my $create_url = $self->base_url . $self->vm_url;
    $self->log->debug("create url = $create_url");
    
    # set user agent
    my $ua      = LWP::UserAgent->new();
    my $action  = $ua->post($create_url, Content_Type => 'application/xml', Content => $xml);
    
    my $parser = XML::LibXML->new();
    my $output = $parser->parse_string($action->decoded_content);
    
    $self->log->debug($output);
    
    return $output;
}

=head2 start

 start vm
 required arguments ($vmid)
 if $self->id is set during initialization, argument is not required
=cut

sub start 
{
    my $self = shift;
    
    my $vmid = shift || undef;
    my $start_url;
    
    # set the start final url
    if ($self->id) 
    {
        $start_url = $self->url . "/start";
    }
    else 
    {
        if ($vmid) 
        {
            my $is_valid = $self->is_vmid_valid($vmid);
            croak "vm id not found" unless $is_valid;
            
            $start_url = $self->url . "/$vmid/start";
        }
        else 
        {
            croak "vm id is required";
        }
    }
    
    $self->log->debug("start action url = $start_url");
    
    # set user agent
    my $ua      = LWP::UserAgent->new();
    my $action;
    
    if ($self->vm_boot_dev eq 'hd') 
    {
        $action = $ua->post($start_url, Content_Type => 'application/xml', Content => $self->vm_hd_xml);
    }
    else 
    {
        $action = $ua->post($start_url, Content_Type => 'application/xml', Content => $self->vm_cdrom_xml);   
    }
    
    my $parser = XML::LibXML->new();
    my $output = $parser->parse_string($action->decoded_content);
    
    $self->vm_action_output($output);
}

=head2 stop

 stop vm
 required arguments ($vmid)
 if $self->id is set during initialization, argument is not required
=cut

sub stop 
{
    my $self = shift;
    
    my $vmid = shift || undef;
    my $stop_url;
    
    # set the stop final url
    if ($self->id) 
    {
        $stop_url = $self->url . "/stop";
    }
    else 
    {
        if ($vmid) 
        {
            my $is_valid = $self->is_vmid_valid($vmid);
            croak "vm id not found" unless $is_valid;
            $stop_url = $self->url . "/$vmid/stop";
        }
        else 
        {
            croak "vm id is required";
        }
    }
    
    $self->log->debug("stop action url = $stop_url");
    
    # set user agent
    my $ua      = LWP::UserAgent->new();
    my $action;
    
    if ($self->vm_boot_dev eq 'hd') 
    {
        $action = $ua->post($stop_url, Content_Type => 'application/xml', Content => $self->vm_hd_xml);
    }
    else 
    {
        $action = $ua->post($stop_url, Content_Type => 'application/xml', Content => $self->vm_cdrom_xml);   
    }
    
    my $parser = XML::LibXML->new();
    my $output = $parser->parse_string($action->decoded_content);
    
    $self->vm_action_output($output);
}

=head2 stop_all

 stop all vm if vm state = 'up'
 do not set 'id' during initialization because it will not return all vm
 this will loop using stop method
 $vm->stop_all();
 
=cut

sub stop_all 
{
    my $self = shift;
    
    # croak if id is defined because it will not return all vm
    croak "Don't set id during initialization since it will not return all vm"
        if $self->id;
        
    my $running_vms = $self->get_running();
    
    if ($running_vms) 
    {
        my @vms = split '\n' => $running_vms;
        
        for my $vm (@vms) 
        {
            $self->log->debug($vm);
            my @vmid = split ',' => $vm;
            $self->stop($vmid[0]);
        }
    }
    else 
    {
        print "no vm in up state\n";
        exit;
    }
}

=head2 get_running

 return vmid,name if state = 'up' 
 each vm separated by new line
 do not set 'id' during initialization because it will not return all vm
 $vm->get_running();
 
=cut

sub get_running 
{
    my $self    = shift;
    
    # store the output and return it at the end
    my $output;
    
    # store id, name to array to be looped
    my @attrs   = qw |id name|;
    
    # store the last element to escape the vm_output_delimeter
    my $last_element = pop (@attrs);
    $self->log->debug("last element = $last_element");
    
    for my $element_id ( 0 .. $#{ $self->hash_output->{vm} } ) 
    {
        # check the state first, if up, proceed
        $self->log->debug("requesting vm state for element $element_id");
        
        if (my $state = $self->get_vm_by_element_id($element_id, 'state') || $self->not_available) 
        {   
            if ($state ne 'up') 
            {
                $self->log->debug("not interested, vm state is = " . $state);
                
                # not interested if vm is not up, go to next loop
                next;
            }            
        }
        
        # in case there's no any element left, the last element become the only attribute requested
        if (@attrs) 
        {
            for my $attr (@attrs) 
            {
                $self->log->debug("requesting attribute $attr for element $element_id");

                my $attr_output = $self->get_vm_by_element_id($element_id, $attr) || $self->not_available;
                $output         .= $attr_output . ',';
                $self->log->debug("output for attribute $attr element $element_id = " . $attr_output);
            }
        }
        
        #handle last element
        $self->log->debug("requesting attribute $last_element for element $element_id");
        
        if (my $last_output = $self->get_vm_by_element_id($element_id, $last_element) || $self->not_available) 
        {
            $output .= $last_output . "\n";
            $self->log->debug("output for attribute $last_element element $element_id = " . $last_output);
        }
           
        #$output .= "\n";
    }
    
    return $output;
}

=head2 reboot

 reboot vm
 required arguments ($vmid)
 if $self->id is set during initialization, argument is not required
=cut

sub reboot 
{
    my $self = shift;
    
    my $vmid = shift || undef;
    my $reboot_url;
    
    # set the reboot final url
    if ($self->id) 
    {
        $reboot_url = $self->url . "/reboot";
    }
    else 
    {
        if ($vmid) 
        {
            my $is_valid = $self->is_vmid_valid($vmid);
            croak "vm id not found" unless $is_valid;
            
            $reboot_url = $self->url . "/$vmid/reboot";
        }
        else 
        {
            croak "vm id is required";
        }
    }
    
    $self->log->debug("reboot action url = $reboot_url");
    
    # set user agent
    my $ua      = LWP::UserAgent->new();
    my $action;
    
    if ($self->vm_boot_dev eq 'hd') 
    {
        $action = $ua->post($reboot_url, Content_Type => 'application/xml', Content => $self->vm_hd_xml);
    }
    else 
    {
        $action = $ua->post($reboot_url, Content_Type => 'application/xml', Content => $self->vm_cdrom_xml);   
    }
    
    my $parser = XML::LibXML->new();
    my $output = $parser->parse_string($action->decoded_content);
    
    $self->vm_action_output($output);
}

=head2 suspend

 suspend vm
 required arguments ($vmid)
 if $self->id is set during initialization, argument is not required
=cut

sub suspend 
{
    my $self = shift;
    
    my $vmid = shift || undef;
    my $suspend_url;
    
    # set the suspend final url
    if ($self->id) 
    {
        $suspend_url = $self->url . "/suspend";
    }
    else {
        if ($vmid) 
        {
            my $is_valid = $self->is_vmid_valid($vmid);
            croak "vm id not found" unless $is_valid;
            
            $suspend_url = $self->url . "/$vmid/suspend";
        }
        else 
        {
            croak "vm id is required";
        }
    }
    
    $self->log->debug("suspend action url = $suspend_url");
    
    # set user agent
    my $ua      = LWP::UserAgent->new();
    my $action;
    
    if ($self->vm_boot_dev eq 'hd') {
        $action = $ua->post($suspend_url, Content_Type => 'application/xml', Content => $self->vm_hd_xml);
    }
    else {
        $action = $ua->post($suspend_url, Content_Type => 'application/xml', Content => $self->vm_cdrom_xml);   
    }
    
    my $parser = XML::LibXML->new();
    my $output = $parser->parse_string($action->decoded_content);
    
    $self->vm_action_output($output);
}

=head2 migrate

 migrate vm
 required arguments ($vmid)
 if $self->id is set during initialization, argument is not required
=cut

sub migrate 
{
    my $self = shift;
    
    my $vmid = shift || undef;
    my $migrate_url;
    
    # set the migrate final url
    if ($self->id) 
    {
        $migrate_url = $self->url . "/migrate";
    }
    else 
    {
        if ($vmid) 
        {
            my $is_valid = $self->is_vmid_valid($vmid);
            croak "vm id not found" unless $is_valid;
            
            $migrate_url = $self->url . "/$vmid/migrate";
        }
        else 
        {
            croak "vm id is required";
        }
    }
    
    $self->log->debug("migrate action url = $migrate_url");
    
    # set user agent
    my $ua      = LWP::UserAgent->new();
    my $action;
    
    if ($self->vm_boot_dev eq 'hd') 
    {
        $action = $ua->post($migrate_url, Content_Type => 'application/xml', Content => $self->vm_hd_xml);
    }
    else 
    {
        $action = $ua->post($migrate_url, Content_Type => 'application/xml', Content => $self->vm_cdrom_xml);   
    }
    
    my $parser = XML::LibXML->new();
    my $output = $parser->parse_string($action->decoded_content);
    
    $self->vm_action_output($output);
}

=head2 is_vmid_valid

    return false if vmid not valid
=cut

sub is_vmid_valid 
{
    my $self = shift;
    my $vmid = shift;
    
    croak "vm id required" unless $vmid;
    
    $vmid = $self->trim($vmid);
    $self->log->debug("vm id = $vmid");
    
    # if vm id match, return 1
    for my $element_id (0 .. $#{ $self->hash_output->{vm} }) 
    {
        if ($self->hash_output->{vm}[$element_id]->{id} eq $vmid) 
        {
            $self->log->debug("$vmid is valid");
            return 1;
        }
    }
    
    $self->log->debug("$vmid is not valid");
    return 0;
}

=head2 get_statistics

 required argument ($vmid) or set 'id' during initialization
 return vm statistics
 $vm->get_statistics($vmid);

=cut

sub get_statistics 
{
    my $self    = shift;
    my $vmid    = $self->id || shift || die "vm id required\n";
    
    my $url     = $self->base_url . $self->vm_url . '/' . $vmid . '/statistics';
    my $ua      = LWP::UserAgent->new();
    
    $self->log->debug($url);
    $self->get_api_output($url);
}

=head2 list
 
 return vm's attributes text output from hash_output attribute
 if no argument spesified, it will return all vm attributes (based on vm_output_attrs)
 argument supported is 'vm id'
 example :
 $vm->list('b4738b0f-b73d-4a66-baa8-2ba465d63132');
 
=cut

sub list 
{
    my $self = shift;
    
    my $vmid = shift || undef;
    
    # store the output and return it at the end
    my $output;
    
    # store each attribute to array to be looped
    my @attrs   = split ',' => $self->vm_output_attrs;
    
    # store the last element to escape the vm_output_delimeter
    my $last_element = pop (@attrs);
    $self->log->debug("last element = $last_element");

    # if the id is defined during initialization
    # the rest api output will only contain attributes for this id
    # so it's not necessary to loop on vm element
    if ($self->id) 
    {
        for my $attr (@attrs) 
        {
            $self->log->debug("requesting attribute $attr");
    
            my $attr_output = $self->get_vm_by_self_id($attr) || $self->not_available;
            $output         .= $attr_output . $self->vm_output_delimiter;
            $self->log->debug("output for attribute $attr  = " . $attr_output);
        }
        
        #handle last element or the only element
        $self->log->debug("requesting attribute $last_element");
        
        if (my $last_output = $self->get_vm_by_self_id($last_element) || $self->not_available) 
        {
            $output .= $last_output;
            $self->log->debug("output for attribute $last_element  = " . $last_output);
        }
        
        $output .= "\n";
    }
    elsif ($vmid) 
    {
        #store vmid element
        my $vmid_element;
        
        $vmid = $self->trim($vmid);
        
        # store hash to avoid keys on reference
        #my %hash = $self->hash_output->{vm};
        
        for my $element_id ( 0 .. $#{ $self->hash_output->{vm} } ) 
        {
            next unless 
                $self->hash_output->{vm}[$element_id]->{id} eq $vmid;
            
            $vmid_element = $element_id;
        }
        
        croak "vm id not found" unless $vmid_element >= 0;
        
        for my $attr (@attrs) 
        { 
           $self->log->debug("requesting attribute $attr for element $vmid_element");
    
            my $attr_output = $self->get_vm_by_element_id($vmid_element, $attr) || $self->not_available;
            $output         .= $attr_output . $self->vm_output_delimiter;
            $self->log->debug("output for attribute $attr element $vmid_element = " . $attr_output);
        }
        
        #handle last element or the only element
        $self->log->debug("requesting attribute $last_element for element $vmid_element");
        
        if (my $last_output = $self->get_vm_by_element_id($vmid_element, $last_element) || $self->not_available) 
        {
            $output .= $last_output;
            $self->log->debug("output for attribute $last_element element $vmid_element = " . $last_output);
        }
        
        $output .= "\n";
    }
    else 
    { 
        for my $element_id ( 0 .. $#{ $self->hash_output->{vm} } ) 
        {
            # in case there's no any element left, the last element become the only attribute requested
            if (@attrs) 
            {
                for my $attr (@attrs) 
                {
                    $self->log->debug("requesting attribute $attr for element $element_id");
    
                    my $attr_output = $self->get_vm_by_element_id($element_id, $attr) || $self->not_available;
                    $output         .= $attr_output . $self->vm_output_delimiter;
                    $self->log->debug("output for attribute $attr element $element_id = " . $attr_output);
                }
            }
            
            #handle last element or the only element
            $self->log->debug("requesting attribute $last_element for element $element_id");
            
            if (my $last_output = $self->get_vm_by_element_id($element_id, $last_element) || $self->not_available) 
            {
                $output .= $last_output;
                $self->log->debug("output for attribute $last_element element $element_id = " . $last_output);
            }
            
            $output .= "\n";
        }
    }
    
    return $output;
}

=head2 get_vm_by_element_id
 
 This method is used by list method to list all vm attribute requested
 An array element id and attribute name is required
=cut

sub get_vm_by_element_id 
{
    my $self = shift;
    
    my ($element_id, $attr) = @_;
    
    croak "hash output is not defined"
        unless $self->hash_output;
    
    $attr = $self->trim($attr);    
    $self->log->debug("element id = $element_id, attribute = $attr");
    
    if      ($attr eq 'id') 
    {
            return $self->hash_output->{vm}[$element_id]->{id};
    }
    elsif   ($attr eq 'name') 
    {
            return $self->hash_output->{vm}[$element_id]->{name};
    }
    elsif   ($attr eq 'memory') 
    {
            return $self->hash_output->{vm}[$element_id]->{memory};
    }
    elsif   ($attr eq 'state') 
    {
            return $self->hash_output->{vm}[$element_id]->{status}->{state};
    }
    elsif   ($attr eq 'description') 
    {
            return $self->hash_output->{vm}[$element_id]->{description};
    }
    elsif   ($attr eq 'cpu_cores') 
    {
            return $self->hash_output->{vm}[$element_id]->{cpu}->{topology}->{cores};
    }
    elsif   ($attr eq 'cpu_sockets') 
    {
            return $self->hash_output->{vm}[$element_id]->{cpu}->{topology}->{sockets};
    }
    elsif   ($attr eq 'cpu_arch') 
    {
            return $self->hash_output->{vm}[$element_id]->{cpu}->{architecture};
    }
    elsif   ($attr eq 'cpu_shares') 
    {
            return $self->hash_output->{vm}[$element_id]->{cpu_shares};
    }
    elsif   ($attr eq 'os_type') 
    {
            return $self->hash_output->{vm}[$element_id]->{os}->{type};
    }
    elsif   ($attr eq 'boot_dev') 
    {
            return $self->hash_output->{vm}[$element_id]->{os}->{boot}->{dev};
    }
    elsif   ($attr eq 'ha_enabled') 
    {
            return $self->hash_output->{vm}[$element_id]->{high_availability}->{enabled};
    }
    elsif   ($attr eq 'ha_priority') 
    {
            return $self->hash_output->{vm}[$element_id]->{high_availability}->{priority};
    }
    elsif   ($attr eq 'display_type') 
    {
            return $self->hash_output->{vm}[$element_id]->{display}->{type};
    }
    elsif   ($attr eq 'display_address') 
    {
            return $self->hash_output->{vm}[$element_id]->{display}->{address};
    }
    elsif   ($attr eq 'display_port') 
    {
            # spice will return secure_port
            return $self->hash_output->{vm}[$element_id]->{display}->{secure_port}
                if $self->hash_output->{vm}[$element_id]->{display}->{secure_port};
            
            # vnc will return port    
            return $self->hash_output->{vm}[$element_id]->{display}->{port}
    }
    elsif   ($attr eq 'display_host_subject') 
    {
            return $self->hash_output->{vm}[$element_id]->{display}->{certificate}->{subject};
    }
    elsif   ($attr eq 'cluster_id') 
    {
            return $self->hash_output->{vm}[$element_id]->{cluster}->{id};
    }
    elsif   ($attr eq 'template_id') 
    {
            return $self->hash_output->{vm}[$element_id]->{template}->{id};
    }
    elsif   ($attr eq 'stop_time') 
    {
            return $self->hash_output->{vm}[$element_id]->{stop_time};
    }
    elsif   ($attr eq 'creation_time') 
    {
            return $self->hash_output->{vm}[$element_id]->{creation_time};
    }
    elsif   ($attr eq 'timezone') 
    {
            return $self->hash_output->{vm}[$element_id]->{timezone};
    }
    elsif   ($attr eq 'usb_enabled') 
    {
            return $self->hash_output->{vm}[$element_id]->{usb}->{enabled};
    }
    elsif   ($attr eq 'host_id') 
    {
            return $self->hash_output->{vm}[$element_id]->{host}->{id};
    }
}

=head2 get_vm_by_self_id
 
 This method is used by list method if $self->id is defined
 The id is set during initialization (id => 'vmid')
 attribute name is required
=cut

sub get_vm_by_self_id 
{
    my $self = shift;
    
    my $attr = shift;
    
    croak "hash output is not defined"
        unless $self->hash_output;
    
    $attr = $self->trim($attr);    
    $self->log->debug("attribute = $attr");
    
    if      ($attr eq 'id') 
    {
            return $self->hash_output->{id};
    }
    elsif   ($attr eq 'name') 
    {
            return $self->hash_output->{name};
    }
    elsif   ($attr eq 'memory') 
    {
            return $self->hash_output->{memory};
    }
    elsif   ($attr eq 'state') 
    {
            return $self->hash_output->{status}->{state};
    }
    elsif   ($attr eq 'description') 
    {
            return $self->hash_output->{description};
    }
    elsif   ($attr eq 'cpu_cores') 
    {
            return $self->hash_output->{cpu}->{topology}->{cores};
    }
    elsif   ($attr eq 'cpu_sockets') 
    {
            return $self->hash_output->{cpu}->{topology}->{sockets};
    }
    elsif   ($attr eq 'cpu_arch') 
    {
            return $self->hash_output->{cpu}->{architecture};
    }
    elsif   ($attr eq 'cpu_shares') 
    {
            return $self->hash_output->{cpu_shares};
    }
    elsif   ($attr eq 'os_type') 
    {
            return $self->hash_output->{os}->{type};
    }
    elsif   ($attr eq 'boot_dev') 
    {
            return $self->hash_output->{os}->{boot}->{dev};
    }
    elsif   ($attr eq 'ha_enabled') 
    {
            return $self->hash_output->{high_availability}->{enabled};
    }
    elsif   ($attr eq 'ha_priority') 
    {
            return $self->hash_output->{high_availability}->{priority};
    }
    elsif   ($attr eq 'display_type') 
    {
            return $self->hash_output->{display}->{type};
    }
    elsif   ($attr eq 'display_address') 
    {
            return $self->hash_output->{display}->{address};
    }
    elsif   ($attr eq 'display_port') 
    {
            # spice will return secure_port
            return $self->hash_output->{display}->{secure_port}
                if $self->hash_output->{display}->{secure_port};
                
            # vnc will return port    
            return $self->hash_output->{display}->{port};
    }
    elsif   ($attr eq 'display_host_subject') 
    {
            return $self->hash_output->{display}->{certificate}->{subject};
    }
    elsif   ($attr eq 'cluster_id') 
    {
            return $self->hash_output->{cluster}->{id};
    }
    elsif   ($attr eq 'template_id') 
    {
            return $self->hash_output->{template}->{id};
    }
    elsif   ($attr eq 'stop_time') 
    {
            return $self->hash_output->{stop_time};
    }
    elsif   ($attr eq 'creation_time') 
    {
            return $self->hash_output->{creation_time};
    }
    elsif   ($attr eq 'timezone') 
    {
            return $self->hash_output->{timezone};
    }
    elsif   ($attr eq 'usb_enabled') 
    {
            return $self->hash_output->{usb}->{enabled};
    }
    elsif   ($attr eq 'host_id') 
    {
            return $self->hash_output->{host}->{id};
    }
}

=head1 AUTHOR

 "Heince Kurniawan", C<< <"heince at cpan.org"> >>

=head1 BUGS

 Please report any bugs or feature requests to C<bug-ovirt at rt.cpan.org>, or through
 the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ovirt::VM>.  I will be notified, and then you'll
 automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

 You can find documentation for this module with the perldoc command.

    perldoc Ovirt::VM

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 "Heince Kurniawan".

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;