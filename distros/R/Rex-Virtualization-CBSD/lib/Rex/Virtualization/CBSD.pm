package Rex::Virtualization::CBSD;

use 5.006;
use strict;
use warnings;

use Rex::Virtualization::Base;
use base qw(Rex::Virtualization::Base);

=head1 NAME

Rex::Virtualization::CBSD - CBSD virtualization module for bhyve

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 SYNOPSIS

    use Rex::Commands::Virtualization;

    set virtualization => "CBSD";
    
    vm 'create', name=>'foo',
                 'vm_os_type'=>'freebsd',
                 'vm_os_profile'=>'FreeBSD-x64-13.0',
                 'vm_ram'=>'1g',
                 'vm_cpus'=>'1',
                 'imgsize'=>'10g';
    
    vm 'start' => 'foo';
    
    # list the basic settings for the VM foo from the VM list
    my %vm_list = vm 'list';
    print Dumper \%{ $vm_list{foo} };
    
    # get all the config info for the VM foo and display it
    %vm_info=vm 'info' => 'foo';
    foreach my $vm_info_key (@{keys(%vm_info)}){
        print $vm_info_key.": ".$vm_info{$vm_info_key}."\n";
    }
    
    # stop the VM foo
    vm 'stop' => 'foo';
    
    # remove the VM foo
    vm 'remove' => 'foo';
    
    # show all VM
    my %vm_list = vm 'list';
    print Dumper \%vm_list;

=cut

sub new {
	my $that  = shift;
	my $proto = ref($that) || $that;
	my $self  = {@_};

	bless( $self, $proto );

	return $self;
}

=head1 Methods

=head2 General

=head3 cbsd_base_dir

This returns the CBSD base dir that the install is stored in.

No arguments are taken.

This will die upon error.

    my $cbsd_base_dir=vm 'cbsd_base_dir'

=head3 freejname

Gets the next available VM name.

One argument is required and that is the base VM to use.

The optional argument 'lease_time' may be used to specify the number
of seconds a lease for the VM name should last. The default is 30.

    vm 'freejname' => 'foo';
    
    # the same thing, but with a 60 second lease time
    vm 'freejname' => 'foo', lease_time => '60';

=head2 bhyve

=head3 bcheckpoint_create

Creates a checkpoint via the command below.

    cbsd bcheckpoint mode=create jname=$vm suspend=$suspend name=$name

The only required option is the key vm.

    vm - VM to checkpoint
    
    name - name of checkpoint. by default: 'checkpoint'.
    
    suspend=  - when set to 1 then turn off the domain immediately after checkpoint,
                for disk consistency. By default - 0, create checkpoint only.

This will die upon error.

    vm 'bcheckpoint_create', vm=>'foo';

=head3 bcheckpoint_destroyall

Removes all checkpoints via the command below.

    cbsd bcheckpoint mode=destroyall jname=$vm

One argument is taken and that is the name of the VM.

This will die upon error.

    # removes all checkpoints for the VM 'foo'
    vm 'bcheckpoint_destroyall', 'foo';

=head3 bclone

This closnes a VM.

    old - The VM to clone.
    
    new - The name of the new VM.
    
    checkstate - 0 do not check for VM online. Default is 1 - check
    
    promote - Promotes clone to no longer be dependent from origin: 0 or 1.
              Default is 0 (not promote). This means new new VM operates in
              copy-on-write mode and will be promoted upon removal of the
              original.
    
    mac_reinit - 0,1 (default 1). 0 - leave old MAC.
                 1 set mac to re-generate

This will will die upon error.

    vm 'bclone' old => 'foo', 'new' => 'bar';

=head3 bcreate

Creates a new VM.

Below is a list of the basic options.

    name - Name of the VM.
    
    bhyve_vnc_tcp_bind - VNC bind, e.g: '127.0.0.1', '0.0.0.0', '::1'.
    
    imgsize - VM first/boot disk size, e.g.: '10g', '21474836480000'.
    
    interface2 - <parent>, create VM with two interfaces, <parent> is uplink for nic2,
                 do not confuse with the ci_interface2 parameter.
    
    nic_flags - '0' to disable. Pass additional flags for NIC, e.g.: 'private'.
    
    nic_flags2 - '0' to disable. Pass additional flags for NIC2, e.g.: 'private'.
    
    quiet - 0,1: be quiet, dont output verbose message.
    
    removejconf - 0,1: remove jconf after bcreate? 0 - don't remove.
    
    runasap - 0,1: when 1 - run a VM immediately (atomic bcreate+bstart).
    
    vm_cpus - VM CPUs cores, e.g.: '2'.
    
    vm_os_profile - <name>: full config file is: vm-${vm_os_type}-${vm_os_profile}.conf, file
                       must be present in ~cbsd/etc/defaults/ or ~cbsd/etc/ directory.
    
    vm_os_type - <name>: full config file is: vm-${vm_os_type}-${vm_os_profile}.conf, file
                 must be present in ~cbsd/etc/defaults/ or ~cbsd/etc/ directory.
    
    vm_ram - VM RAM, e.g.: '1g', '2147483648'.
    
    zfs_snapsrc - <name>: use ZFS snapshot as data source.

Below is a list of options for when using cloud init.

    ci_gw4 - <ipv4> (cloud-init profile only): set IPv4 gateway for VM.

    ci_interface2 - configure second interface via cloud-init,
                    do not confuse with the interface2 parameter.

    ci_interface_mtu - set MTU for NIC1, default: 1500.

    ci_interface_mtu2 - set MTU for NIC2, default: 1500.

    ci_ip4_addr  - <ipv4> (cloud-init profile only): set IPv4 address for VM,
                   default is: DHCP. Can be: 'DHCPv6' or static IPv4/IPv6.

    ci_ip4_addr2 - <ipv4> (cloud-init profile only): set IPv4 address for VM
                    NIC2 (see also: ci_interface2,ci_gw42). Possible values same as ci_ip4_addr.

    ci_user_pubkey - full/relative path to authorized_keys or may contain pubkey
                     string itself, e.g: ci_user_pubkey="ssh-ed25519 XXXXX root@my.domain".
                     (cloud-init profile only): set authorized_keys file for cloud-init user for VM.

    ci_user_pw_user - set password for cloud-init user.

    ci_user_pw_root - set password for 'root' user.

A minimum of 'vm_os_type', 'vm_os_profile', 'vm_ram', 'vm_cpus', and 'imgsize' is needed.

This ran non-interactively.

This will die upon a error.

    # create a x64 FreeBSD 13.0 VM named foo with 1G of ram, 1 CPU, and a 10G disk
    print Dumper vm 'create', name=>'foo',
                              'vm_os_type'=>'freebsd',
                              'vm_os_profile'=>'FreeBSD-x64-13.0',
                              'vm_ram'=>'1g',
                              'vm_cpus'=>'1',
                              'imgsize'=>'10g';

=head3 bdisk_list

This returns a list of disks setup for use with Bhyve in CBSD via parsing
the output of the command below.

    cbsd bhyve-dsk-list display=jname,dsk_controller,dsk_path,dsk_size,dsk_sectorsize,bootable,dsk_zfs_guid header=0

This returned data is a array of hashes.

The keys are as below.

    vm - The name of the VM in question.
    
    controller - Controller type configured for this.
    
    path - The path to the disk.
    
    size - Size of the disk in question.
    
    sectorsize - size of the sectors in question.
    
    bootable - If it is bootable. true/false
    
    zfs_guid - ZFS GUID of the disk.

This dies upon failure.

    my @disks
    eval{
        @disks=vm 'bdisk_list';
    } or do {
        my $error = $@ || 'Unknown failure';
        warn('Failed to the disk list... '.$error);
    }
    
    print Dumper(\@disks);

=head3 binfo

This fetches the available configuration information for a VM via
the command below.

    cbsd bget jname=$vm

The returned value is a flat hash of key value pairs.

    my %vm_info
    eval{
        %vm_info=vm 'binfo' => 'foo';
    } or do {
        my $error = $@ || 'Unknown failure';
        warn('Failed to get settings for the VM... '.$error);
    }
    
    foreach my $vm_info_key (@{keys(%vm_info)}){
        print $vm_info_key.": ".$vm_info{$vm_info_key}."\n";
    }

=head3 blist

List available VMs.

The command used is...

    cbsd bls display=nodename,jname,jid,vm_ram,vm_curmem,vm_cpus,pcpu,vm_os_type,ip4_addr,status,vnc,path header=0

The returned array is a hash of hashes. The first level hash is the jname.

    nodename - The node name that this is set to run on.
    
    name - Name of the VM.
    
    jid - Jail ID/process ID of the VM if running. IF '0' it is not running.
    
    vm_ram - Max RAM for the VM.
    
    vm_curmem - Current RAM in use by the VM.
    
    vm_cpus - Number of virtual CPUs.
    
    pcpu - Current CPU usage.
    
    vm_os_type - OS type for the VM.
    
    ip4_addr - Expected IPv4 address for the VM.
    
    status - Current status of the VM.
    
    vnc - VNC address and port for the VM.
    
    path - Path to where the VM is stored.

This dies upon failure.

    my %vm_list;
    eval{
        %vm_list=vm 'blist';
    } or do {
        my $error = $@ || 'Unknown failure';
        warn('Failed to list the VM... '.$error);
    }
    
    foreach my $vm_name (@{keys( %vm_list )}){
        print
            "---------------------------\n".
            'VM: '.$vm_name."\n".
            "---------------------------\n".
            'jid: '.$vm_list{$vm_name}{jid}."\n".
            'vm_ram: '.$vm_list{$vm_name}{vm_ram}."\n".
            'vm_curmem: '.$vm_list{$vm_name}{vm_curmem}."\n".
            'vm_cpus: '.$vm_list{$vm_name}{vm_cpus}."\n".
            'vm_ram: '.$vm_list{$vm_name}{pcpu}."\n".
            'vm_os_type: '.$vm_list{$vm_name}{vm_os_type}."\n".
            'ip4_addr: '.$vm_list{$vm_name}{ip4_addr}."\n".
            'status: '.$vm_list{$vm_name}{status}."\n".
            'vnc: '.$vm_list{$vm_name}{vnc}."\n".
            'path: '.$vm_list{$vm_name}{path}."\n".
            "\n"
    }

=head3 bnic_list

List configured NICs.

The command used is as below...

    cbsd bhyve-nic-list display=nodename,jname,nic_driver,nic_parent,nic_hwaddr,nic_address,nic_mtu,nic_persistent,nic_ratelimit header=0

This returned data is a array of hashes.

The keys are as below.

    vm - The name of the VM in question.
    
    driver - The driver in use. As of currently either vtnet or e1000.
    
    node - The node it is on.
    
    parent - Either the name of the parent NIC, example 'bridge1', or set to 'auto'.
    
    hwaddr - The MAC address for the NIC.
    
    address - Address of the NIC. '0' if not configured.
    
    mtu - The MTU of NIC. '0' if default.
    
    persistent - 0/1 - 1 mean persistent nic (no managed by CBSD)
    
    ratelimit - Rate limit for the interface. '0' is the default.
                {tx}/{rx} (outgoing/incoming limit), {rxtx} - shared(rx+tx) limit, one value

This dies upon failure.

    my @nics
    eval{
        @nics=vm 'bnic_list';
    } or do {
        my $error = $@ || 'Unknown failure';
        warn('Failed to the NIC list... '.$error);
    }
    
    print Dumper(\@nics);

=head3 bpause

This pauses a VM in question. The following modes are available. If no
more is specified, audo is used.

    auto - (by default) triggering - e.g, if vm active then pause
    on - pause, stop
    off - unpause, continue

The command called is as below.

    cbsd 'bpause' => $vm mode=>$mode

This dies upon failure.

    eval{
        vm 'bpause' => 'foo';
    } or do {
        my $error = $@ || 'Unknown failure';
        warn('Failed to pause the VM foo... '.$error);
    }

=head3 bpci_list

List configured PCI devices for a VM.

The command used is as below.

    cbsd bpcibus mode=list jname=$vm

This returned data is a array of hashes.

The keys are as below.

    name - Drive name of the PCI item.
    
    bus - Bus number.
    
    slot - Slot number.
    
    function - Function number.
    
    desc - Description of the device.

One argument is required and that is the name of the VM.

This dies upon failure.

    my @devices
    eval{
        @devices=vm 'bnic_list' => 'foo';
    } or do {
        my $error = $@ || 'Unknown failure';
        warn('Failed to the PCI device list... '.$error);
    }
    
    print Dumper(\@devices);

=head3 bremove

This removes the selected VM and remove the data. This is done via the command...

    cbsd bremove $vm

One argument is taken and that is the name of the VM.

This dies upon failure.

    eval{
        vm 'bremove' => 'foo'
    } or do {
        my $error = $@ || 'Unknown failure';
        warn('Failed to remove the VM foo... '.$error);
    }

=head3 brestart

This restarts the selected VM. This is done via the command...

    cbsd brestart $vm

One argument is taken and that is the name of the VM.

This dies upon failure.

    eval{
        vm 'brestart' => 'foo'
    } or do {
        my $error = $@ || 'Unknown failure';
        warn('Failed to restart the VM foo... '.$error);
    }

=head3 bset

This sets various settings for a VM via the use of...

    cbsd bset jname=$vm ...

One argument is equired and that is the VM name.

This will die upon failure. Please note the CBSD currently does
not consider non-existent variables such as 'foofoo' to be a failure
and silently ignores those.

    # set the the VM foo to boot from net with a resolution of 800x600
    vm 'bset' => 'foo',
        vm_boot => 'net',
        bhyve_vnc_resolution => '800x600';

=head3 bsnapshot_create

This creates a disk snapshot of the specified VM via the command below.

    cbsd bsnapshot mode=create jname=$vm  snapname=$name

The following argument taken.

    vm - The VM to snapshot. This is required.

    name - The snapshot name. If not specified it defaults to snapshot.

This will die upon error.

    vm 'bsnapshot_create', vm=>'foo', name=>'aSnapshot';

=head3 bsnapshot_list

This lists all the snapshots via the command below.

    cbsd bsnapshot mode=list display=jname,snapname,creation,refer header=0

No arguments are taken.

The return is a array of hashes. The hash keys are as below.

    vm - Name of the VM the snapshot is for.
    
    name - Name of the snapshot.
    
    creation - The creation date. The format is YYYY-MM-DD__hh:mm.
    
    refer - ?

This will die upon error.

    my @snaps=vm 'bsnapshot_list';
    print Dumper \@snaps;

=head3 bsnapshot_remove

This removes the specified snapshot for the specified VM.

    cbsd bsnapshot mode=destroy jname=$vm  snapname=$name

The following argument required.

    vm - The VM to snapshot. This is required.

    name - The snapshot name.

This will die upon error.

    vm 'bsnapshot_remove', vm=>'foo', name=>'aSnapshot';

=head3 bsnapshot_removeall

This removes specified snapshot for the specified VM.

    cbsd bsnapshot mode=destroyall jname=$vm

The following argument required.

    vm - The VM to remove all snapshots for.

This will die upon error.

    vm 'bsnapshot_removeall', vm=>'foo';

=head3 bsnapshot_rollback

This rolls the disks for a VM back to a specified snapshot.

    cbsd bsnapshot mode=rollback jname=$vm  snapname=$name

The following argument required.

    vm - The VM to rollback.

    name - The snapshot name.

This will die upon error.

    vm 'bsnapshot_rollback', vm=>'foo', name=>'aSnapshot';

=head3 bstart

This starts a VM. This is done via the command...

    cbsd bstart jname=$vm

One argument is required and that is the name of the VM. If '*' or 'vm*' then
start all VM whose names begin with 'vm', e.g. 'vm1', 'vm2'...

The following options may be used.

    checkpoint - The name of the checkpoint to start the VM using.

This dies upon failure.

    eval{
        vm 'bstart' => 'foo';
    } or do {
        my $error = $@ || 'Unknown failure';
        warn('Failed to start the VM foo... '.$error);
    }

    # starts foo from the checkpoint named checkpoint
    vm 'bstart' => 'foo', checkpoint=>'checkpoint';


=head3 bstop

This stops a VM. This is done via the command below...

    cbsd bstop jname=$vm [hard_timeout=$timeout] [noacpi=$noacpi]

One argument is required and that is the name of the VM.

The following options are optional.

    hard_timeout - Wait N seconds (30 by default) before hard reset.

    noacpi - 0,1. Set to 1 to prevent ACPI signal sending, just kill.
             By default it will attempt to use ACPI to ask it to shutdown.

This dies upon failure.

    eval{
        vm 'bstop' => 'foo',
            hard_timeout => 60;
    } or do {
        my $error = $@ || 'Unknown failure';
        warn('Failed to stop the VM foo... '.$error);
    }

=head3 p9shares_add

This adds a p9 share for the specified VM. This is done via

        cbsd bhyve-p9shares mode=attach jname=$vm p9device=$device p9path=$path

The keys below are required.

    vm - Name of the VM the share is for.
    
    device - p9 device name, one word.
    
    path - The shared path.

This will die upon error.

    vm 'p9shares_add', vm=>'foo', device=>'arc', path='/arc';

=head3 p9shares_list

This lists the configured p9 shares. This is fetched using the command below.

    cbsd bhyve-p9shares mode=list header=0 display=jname,p9device,p9path

No arguments are taken.

The returned data is a array of hashes. The hash keys are as below.

    vm - Name of the VM the share is for.
    
    device - p9 device name, one word.
    
    path - The shared path.

This will die upon error.

    my @shares=vm 'p9shares_list';
    print Dumper \@shares;

=head3 p9shares_rm

This removes a p9 share for the specified VM. This is done via

        cbsd bhyve-p9shares mode=deattach jname=$vm p9device=$device

The keys below are required.

    vm - Name of the VM the share is for.
    
    device - p9 device name, one word.

This will die upon error.

    vm 'p9shares_add', vm=>'foo', device=>'arc';

=head3 vm_os_profiles

Get the VM OS profiles for a specified OS type.

One argument is required and that is the OS type.

An optional argument is taken and that is cloudinit. It is a
Perl boolean value and if true it will only return profiles
with cloudinit support.

The returned value is a array.

This will die upon failure.

    # list the VM OS profiles for FreeBSD
    my @profiles=vm 'vm_os_profiles' => 'freebsd';
    print Dumper @profiles;
    
    # list the VM OS profiles for FreeBSD
    @profiles=vm 'vm_os_profiles' => 'freebsd', cloudinit=>1;
    print Dumper @profiles;

=head3 vm_os_profiles_hash

Get the VM OS profiles for a specified OS type.

One optional argument is taken and that is cloudinit. It is a
Perl boolean value and if true it will only return profiles
with cloudinit support.

The returned value is a two level hash. The keys for the first
level are the OS types and the keys for the second level are
the OS profile names.

This will die upon failure.

    my %os_profiles=vm 'vm_os_profiles_hash';
    print Dumper %os_profiles;
    
    # print the OS profiles for FreeBSD
    print Dumper keys( %{ $os_profiles{freebsd} } );
    
    my %os_profiles=vm 'vm_os_profiles_hash', cloudinit=>1;
    print Dumper %os_profiles;

=head3 vm_os_types

Get the VM OS types there are profiles for.

The returned value is a array.

This will die upon failure.

    # get a hash of all OS types and profiles
    my @os_types=vm 'vm_os_profiles';
    print Dumper @os_types;

=head1 AUTHOR

Zane C. Bowers-HAdley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rex-virtualization-cbsd at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rex-Virtualization-CBSD>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rex::Virtualization::CBSD


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Rex-Virtualization-CBSD>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Rex-Virtualization-CBSD>

=item * Repository

L<https://github.com/VVelox/Rex-Virtualization-CBSD>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Rex-Virtualization-CBSD>

=item * Search CPAN

L<https://metacpan.org/release/Rex-Virtualization-CBSD>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Zane C. Bowers-HAdley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Rex::Virtualization::CBSD
