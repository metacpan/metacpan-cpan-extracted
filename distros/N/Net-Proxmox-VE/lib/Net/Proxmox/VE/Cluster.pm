#!/bin/false
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl expandtab smarttab
# PODNAME: Net::Proxmox::VE::Cluster
# ABSTRACT: Functions for the 'cluster' portion of the API

use strict;
use warnings;

package Net::Proxmox::VE::Cluster;
$Net::Proxmox::VE::Cluster::VERSION = '0.40';
use parent 'Exporter';

use Net::Proxmox::VE::Exception;

our @EXPORT = qw(
  cluster
  cluster_backup
  create_cluster_backup
  get_cluster_backup
  update_cluster_backup
  delete_cluster_backup
  cluster_ha
  get_cluster_ha_config
  get_cluster_ha_changes
  commit_cluster_ha_changes
  revert_cluster_ha_changes
  cluster_ha_groups
  create_cluster_ha_groups
  get_cluster_ha_groups
  update_cluster_ha_groups
  delete_cluster_ha_group
  get_cluster_log
  get_cluster_nextid
  get_cluster_options
  update_cluster_options
  get_cluster_resources
  get_cluster_status
  get_cluster_tasks
);


my $BASEPATH = '/cluster';

sub cluster {

    my $self = shift or return;

    return $self->get($BASEPATH);

}


sub cluster_backup {

    my $self = shift or return;

    return $self->get( $BASEPATH, 'backup' );

}


sub create_cluster_backup {

    my $self = shift or return;

    my @p = @_;

    Net::Proxmox::VE::Exception->throw(
        'No arguments for create_cluster_backup()')
      unless @p;
    my %args;

    if ( @p == 1 ) {
        Net::Proxmox::VE::Exception->throw(
            'Single argument not a hash for create_cluster_backup()')
          unless ref $p[0] eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        Net::Proxmox::VE::Exception->throw(
            'Odd number of arguments for create_cluster_backup()')
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->post( $BASEPATH, 'backup', \%args );

}


sub get_cluster_backup {

    my $self = shift or return;

    my $id = shift
      or Net::Proxmox::VE::Exception->throw('No id for get_cluster_backup()');
    Net::Proxmox::VE::Exception->throw(
        'id must be a scalar for get_cluster_backup()')
      if ref $id;

    return $self->get( $BASEPATH, $id );

}


sub update_cluster_backup {

    my $self = shift or return;

    my $id = shift
      or
      Net::Proxmox::VE::Exception->throw('No id for update_cluster_backup()');
    Net::Proxmox::VE::Exception->throw(
        'id must be a scalar for update_cluster_backup()')
      if ref $id;

    my @p = @_;

    Net::Proxmox::VE::Exception->throw(
        'No arguments for update_cluster_backup()')
      unless @p;
    my %args;

    if ( @p == 1 ) {
        Net::Proxmox::VE::Exception->throw(
            'Single argument not a hash for update_cluster_backup()')
          unless ref $p[0] eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        Net::Proxmox::VE::Exception->throw(
            'Odd number of arguments for update_cluster_backup()')
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->put( $BASEPATH, 'backup', $id, \%args );

}


sub delete_cluster_backup {

    my $self = shift or return;

    my $id = shift
      or
      Net::Proxmox::VE::Exception->throw('No id for delete_cluster_backup()');
    Net::Proxmox::VE::Exception->throw(
        'id must be a scalar for delete_cluster_backup()')
      if ref $id;

    return $self->delete( $BASEPATH, $id );

}


sub cluster_ha {

    my $self = shift or return;

    return $self->get( $BASEPATH, 'ha' );

}


sub get_cluster_ha_config {

    my $self = shift or return;

    return $self->get( $BASEPATH, 'ha', 'config' );

}


sub get_cluster_ha_changes {

    my $self = shift or return;

    return $self->get( $BASEPATH, 'ha', 'changes' );

}


sub commit_cluster_ha_changes {

    my $self = shift or return;

    return $self->post( $BASEPATH, 'ha', 'changes' );

}


sub revert_cluster_ha_changes {

    my $self = shift or return;

    return $self->delete( $BASEPATH, 'ha', 'changes' );

}


sub cluster_ha_groups {

    my $self = shift or return;

    return $self->get( $BASEPATH, 'ha', 'groups' );

}


sub create_cluster_ha_groups {

    my $self = shift or return;

    my @p = @_;

    Net::Proxmox::VE::Exception->throw(
        'No arguments for create_cluster_ha_groups()')
      unless @p;
    my %args;

    if ( @p == 1 ) {
        Net::Proxmox::VE::Exception->throw(
            'Single argument not a hash for create_cluster_ha_groups()')
          unless ref $p[0] eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        Net::Proxmox::VE::Exception->throw(
            'Odd number of arguments for create_cluster_ha_groups()')
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->put( $BASEPATH, 'ha', 'groups', \%args );

}


sub get_cluster_ha_groups {

    my $self = shift or return;

    my $id = shift
      or
      Net::Proxmox::VE::Exception->throw('No id for get_cluster_ha_groups()');
    Net::Proxmox::VE::Exception->throw(
        'id must be a scalar for get_cluster_ha_groups()')
      if ref $id;

    return $self->get( $BASEPATH, 'ha', 'groups', $id );

}


sub update_cluster_ha_groups {

    my $self = shift or return;

    my $id = shift
      or Net::Proxmox::VE::Exception->throw(
        'No id for update_cluster_ha_groups()');
    Net::Proxmox::VE::Exception->throw(
        'id must be a scalar for update_cluster_ha_groups()')
      if ref $id;

    my @p = @_;

    Net::Proxmox::VE::Exception->throw(
        'No arguments for update_cluster_ha_groups()')
      unless @p;
    my %args;

    if ( @p == 1 ) {
        Net::Proxmox::VE::Exception->throw(
            'Single argument not a hash for update_cluster_ha_groups()')
          unless ref $p[0] eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        Net::Proxmox::VE::Exception->throw(
            'Odd number of arguments for update_cluster_ha_groups()')
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->put( $BASEPATH, 'ha', 'groups', $id, \%args );

}


sub delete_cluster_ha_group {

    my $self = shift or return;

    my $id = shift
      or
      Net::Proxmox::VE::Exception->throw('No id for delete_cluster_ha_group()');
    Net::Proxmox::VE::Exception->throw(
        'id must be a scalar for delete_cluster_ha_group()')
      if ref $id;

    return $self->delete( $BASEPATH, 'ha', 'groups', $id );

}


sub get_cluster_log {

    my $self = shift or return;

    my @p = @_;

    Net::Proxmox::VE::Exception->throw('No arguments for get_cluster_log()')
      unless @p;
    my %args;

    if ( @p == 1 ) {
        Net::Proxmox::VE::Exception->throw(
            'Single argument not a hash for get_cluster_log()')
          unless ref $p[0] eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        Net::Proxmox::VE::Exception->throw(
            'Odd number of arguments for get_cluster_log()')
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->get( $BASEPATH, 'log', \%args );

}


sub get_cluster_nextid {

    my $self = shift or return;

    my @p = @_;

    Net::Proxmox::VE::Exception->throw('No arguments for get_cluster_nextid()')
      unless @p;
    my %args;

    if ( @p == 1 ) {
        Net::Proxmox::VE::Exception->throw(
            'Single argument not a hash for get_cluster_nextid()')
          unless ref $p[0] eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        Net::Proxmox::VE::Exception->throw(
            'Odd number of arguments for get_cluster_nextid()')
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->get( $BASEPATH, 'nextid', \%args );

}


sub get_cluster_options {

    my $self = shift or return;

    return $self->get( $BASEPATH, 'options' );

}


sub update_cluster_options {

    my $self = shift or return;

    my @p = @_;

    Net::Proxmox::VE::Exception->throw(
        'No arguments for update_cluster_options()')
      unless @p;
    my %args;

    if ( @p == 1 ) {
        Net::Proxmox::VE::Exception->throw(
            'Single argument not a hash for update_cluster_options()')
          unless ref $p[0] eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        Net::Proxmox::VE::Exception->throw(
            'Odd number of arguments for update_cluster_options()')
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->put( $BASEPATH, 'log', \%args );

}


sub get_cluster_resources {

    my $self = shift or return;

    my @p = @_;

    Net::Proxmox::VE::Exception->throw(
        'No arguments for get_cluster_resources()')
      unless @p;
    my %args;

    if ( @p == 1 ) {
        Net::Proxmox::VE::Exception->throw(
            'Single argument not a hash for get_cluster_resources()')
          unless ref $p[0] eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        Net::Proxmox::VE::Exception->throw(
            'Odd number of arguments for get_cluster_resources()')
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->get( $BASEPATH, 'resources', \%args );

}


sub get_cluster_status {

    my $self = shift or return;

    return $self->get( $BASEPATH, 'status' );

}


sub get_cluster_tasks {

    my $self = shift or return;

    return $self->get( $BASEPATH, 'tasks' );

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Proxmox::VE::Cluster - Functions for the 'cluster' portion of the API

=head1 VERSION

version 0.40

=head1 SYNOPSIS

  # assuming $obj is a Net::Proxmox::VE object

=head1 METHODS

=head2 cluster

Returns the 'Cluster index':

  @list = $obj->cluster()

Note: Accessible by all authententicated users.

=head2 cluster_backup

List vzdump backup schedule.

  @list = $obj->cluster_backup()

Note: Accessible by all authententicated users.

=head2 create_cluster_backup

Create new vzdump backup job.

  $ok = $obj->create_cluster_backup( \%args )

node is a string in pve-node format

I<%args> may contain items from the following list

=over 4

=item starttime

String. Job start time, format is HH::MM. Required.

=item all

Boolean. Backup all known VMs on this host. Required.

=item bwlimit

Integer. Limit I/O bandwidth (KBytes per second). Optional.

=item compress

Enum. Either 0, 1, gzip or lzo. Comress dump file. Optional

=item dow

String. Day of the week in pve-day-of-week-list format. Optional.

=item dumpdir

String. Store resulting files to specified directory. Optional.

=item exclude

String. Exclude specified VMs (assumes --all) in pve-vmid-list. Optional.

=item exclude-path

String. Exclude certain files/directories (regex) in string-alist. Optional.

=item ionice

Integer. Set CFQ ionice priority. Optional.

=item lockwait

Integer. Maximal time to wait for the global lock (minutes). Optional.

=item mailto

String. List of email addresses in string-list format. Optional.

=item maxfiles

Integer. Maximal number of backup files per vm. Optional.

=item mode

Enum. A value from snapshot, suspend or stop. Backup mode. Optional.

=item node

String. Only run if executed on this node in pve-node format. Optional.

=item quiet

Boolean. Be quiet. Optional.

=item remove

Boolean. Remove old backup files if there are more than 'maxfiles' backup files. Optional.

=item script

String. Use specified hook script. Optional.

=item size

Integer. LVM snapshot size in MB. Optional.

=item stdexcludes

Boolean. Exclude temporary files and logs. Optional.

=item stopwait

Integer. Maximal time to wait until a VM is stopped (minutes). Optional.

=item storage

String. Store resulting file to this storage, in pve-storage-id format. Optional.

=item tmpdir

String. Store temporary files to specified directory. Optional.

=item vmid

String. The ID of the VM you want to backup in pve-vm-list format. Optional.

=back

Note: required permissions are ["perm","/",["Sys.Modify"]]

=head2 get_cluster_backup

Read vzdump backup job definition.

  $job = $obj->get_cluster_backup( $id )

Where $id is the job ID

Note: required permissions are ["perm","/",["Sys.Audit"]]

=head2 update_cluster_backup

Update vzdump backup job definition.

  $ok = $obj->update_cluster_backup( \%args )

Where $id is the job ID

I<%args> may contain items from the following list

=over 4

=item starttime

String. Job start time, format is HH::MM. Required.

=item all

Boolean. Backup all known VMs on this host. Required.

=item bwlimit

Integer. Limit I/O bandwidth (KBytes per second). Optional.

=item compress

Enum. Either 0, 1, gzip or lzo. Comress dump file. Optional

=item dow

String. Day of the week in pve-day-of-week-list format. Optional.

=item dumpdir

String. Store resulting files to specified directory. Optional.

=item exclude

String. Exclude specified VMs (assumes --all) in pve-vmid-list. Optional.

=item exclude-path

String. Exclude certain files/directories (regex) in string-alist. Optional.

=item ionice

Integer. Set CFQ ionice priority. Optional.

=item lockwait

Integer. Maximal time to wait for the global lock (minutes). Optional.

=item mailto

String. List of email addresses in string-list format. Optional.

=item maxfiles

Integer. Maximal number of backup files per vm. Optional.

=item mode

Enum. A value from snapshot, suspend or stop. Backup mode. Optional.

=item node

String. Only run if executed on this node in pve-node format. Optional.

=item quiet

Boolean. Be quiet. Optional.

=item remove

Boolean. Remove old backup files if there are more than 'maxfiles' backup files. Optional.

=item script

String. Use specified hook script. Optional.

=item size

Integer. LVM snapshot size in MB. Optional.

=item stdexcludes

Boolean. Exclude temporary files and logs. Optional.

=item stopwait

Integer. Maximal time to wait until a VM is stopped (minutes). Optional.

=item storage

String. Store resulting file to this storage, in pve-storage-id format. Optional.

=item tmpdir

String. Store temporary files to specified directory. Optional.

=item vmid

String. The ID of the VM you want to backup in pve-vm-list format. Optional.

=back

Note: required permissions are ["perm","/",["Sys.Modify"]]

=head2 delete_cluster_backup

Delete vzdump backup job definition.

  $job = $obj->delete_cluster_backup( $id )

Where $id is the job ID

Note: required permissions are ["perm","/",["Sys.Modify"]]

=head2 cluster_ha

List ha index

  @list = $obj->cluster_ha()

Note: Required permissions are ["perm","/",["Sys.Audit"]]

=head2 get_cluster_ha_config

List ha config

  @list = $obj->get_cluster_ha_config()

Note: Required permissions are ["perm","/",["Sys.Audit"]]

=head2 get_cluster_ha_changes

List ha changes

  @list = $obj->get_cluster_ha_changes()

Note: Required permissions are ["perm","/",["Sys.Audit"]]

=head2 commit_cluster_ha_changes

Commit ha changes

  @list = $obj->commit_cluster_ha_changes()

Note: Required permissions are ["perm","/",["Sys.Modify"]]

=head2 revert_cluster_ha_changes

Revert ha changes

  @list = $obj->revert_cluster_ha_changes()

Note: Required permissions are ["perm","/",["Sys.Modify"]]

=head2 cluster_ha_groups

List resource groups

  @list = $obj->cluster_ha_groups()

Note: Required permissions are ["perm","/",["Sys.Audit"]]

=head2 create_cluster_ha_groups

Create a new resource groups.

  $ok = $obj->create_cluster_ha_groups( \%args )

I<%args> may contain items from the following list

=over 4

=item vmid

Integer. The unique id of the vm in pve-vmid format. Required.

=item autostart

Boolean. As per the API spec - "Service is started when quorum forms". Optional.

=back

Note: required permissions are ["perm","/",["Sys.Modify"]]

=head2 get_cluster_ha_groups

List resource groups

  $job = $obj->get_cluster_ha_groups( $id )

Where $id is the resource group id (for example pvevm:200)

Note: required permissions are ["perm","/",["Sys.Audit"]]

=head2 update_cluster_ha_groups

Update resource groups settings

  $ok = $obj->update_cluster_ha_groups( $id, \%args )

id is the group ID for example pvevm:200

I<%args> may contain items from the following list

=over 4

=item autostart

Boolean. As per the API spec - "Service is started when quorum forms". Optional.

=back

Note: required permissions are ["perm","/",["Sys.Modify"]]

=head2 delete_cluster_ha_group

Delete resource group

  $ok = $obj->delete_cluster_ha_group( $id )

Where $id is the group ID for example pvevm:200

Note: required permissions are ["perm","/",["Sys.Modify"]]

=head2 get_cluster_log

Read cluster log

  $job = $obj->get_cluster_log( \%args )

Note: Accessible by all authenticated users

I<%args> may contain items from the following list

=over 4

=item max

Integer. Maximum number of entries. Optional.

=back

=head2 get_cluster_nextid

Get next free VMID. Pass a VMID to assert that its free (at time of check).

  $integer = $obj->get_cluster_nextid( \%args )

Note: Accessible by all authenticated users

I<%args> may contain items from the following list

=over 4

=item vmid

Integer. The (unique) ID of the VM.

=back

=head2 get_cluster_options

Get datacenter options (this is what the API says)

  @list = $obj->get_cluster_options()

Note: Required permissions are ["perm","/",["Sys.Audit"]]

=head2 update_cluster_options

Update datacenter options (this is what the spec says)

  $job = $obj->update_cluster_options( \%args )

Note: permissions required are ["perm","/",["Sys.Modify"]]

I<%args> may contain items from the following list

=over 4

=item delete

String. A list of settings you want to delete in pve-configid-list format. Optional

=item http_proxy

String. Specify external http proxy to use when downloading, ie http://user:pass@foo:port/. Optional.

=item keyboard

Enum. Default keyboard layout for VNC sessions. Selected from pt, ja, es, no, is, fr-ca, fr, pt-br, da, fr-ch, sl, de-ch, en-gb, it, en-us, fr-be, hu, pl, nl, mk, fi, lt, sv, de. Optional

=item language

Enum. Default GUI language. Either en or de. Optional.

=back

=head2 get_cluster_resources

Resources index (cluster wide)

  @list = $obj->get_cluster_resources()

Note: Accessible by all authententicated users.

I<%args> may contain items from the following list

=over 4

=item Type

Enum. One from vm, storage or node. Optional.

=back

=head2 get_cluster_status

Get cluster status informations.

  @list = $obj->get_cluster_status()

Note: Required permissions are ["perm","/",["Sys.Audit"]]

=head2 get_cluster_tasks

List recent tasks (cluster wide)

  @list = $obj->get_cluster_tasks()

Note: Available to all authenticated users

=head1 SEE ALSO

L<Net::Proxmox::VE>

=head1 AUTHOR

Brendan Beveridge <brendan@nodeintegration.com.au>, Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Dean Hamstad.

This is free software, licensed under:

  The MIT (X11) License

=cut
