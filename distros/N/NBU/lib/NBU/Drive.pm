#
# Copyright (c) 2002 Paul Winkeler.  All Rights Reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself.
#
package NBU::Drive;

use strict;
use Carp;

BEGIN {
  use Exporter   ();
  use AutoLoader qw(AUTOLOAD);
  use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);
  $VERSION =	 do { my @r=(q$Revision: 1.24 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };
  @ISA =         qw();
  @EXPORT =      qw();
  @EXPORT_OK =   qw();
  %EXPORT_TAGS = qw();
}

#
# Drive indices are unique only local to a media manager, hence
# the key into the Index pool has to be a combination of
# index and host.
# Same for drive names.
my %driveIndexPool;
my %driveNamePool;

sub new {
  my $proto = shift;
  my $drive = {};

  bless $drive, $proto;

  if (@_) {
    my $index = shift;
    $drive->{INDEX} = $index;

    my $mmHost = shift;
    if (!defined($mmHost)) {
      $mmHost = NBU::Host->new("localhost");
    }

    $driveIndexPool{$mmHost->name.":".$index} = $drive;

    $drive->{STATUS} = "DOWN";
    $drive->{CONTROL} = "DOWN-TLD";
    $drive->{HANDLERS} = {};
  }
  return $drive;
}

#
# Drive objects return 2, just as Media Manager storage units do
sub type {
  my $self = shift;

  return 2;
}

sub byIndex {
  my $proto = shift;
  my $index = shift;
  my $mmHost = shift;
  my $drive;

  if (!defined($mmHost)) {
    $mmHost = NBU::Host->new("localhost");
  }

  if (defined($index) && !($drive = $driveIndexPool{$mmHost->name.":".$index})) {
    $drive = NBU::Drive->new($index, $mmHost);
  }
  return $drive;
}

sub byName {
  my $proto = shift;
  my $driveName = shift;
  my $drive;

  $drive = $driveNamePool{$driveName} if (defined($driveName));
  return $drive;
}

my %driveHosts;
sub populate {
  my $proto = shift;
  my $server = shift;

  return if (!$server->roboticMediaManager());

  if (!exists($driveHosts{$server->name})) {
    my $driveCount = 0;
    my $pipe = NBU->cmd("vmoprcmd -h ".$server->name." -xdraw ds |");
    while (<$pipe>) {
      next unless (/^DRIVESTATUS/);
      my ($marker, $index, $density, $control, $user, $rvsn, $evsn, $request,
	  $robotType, $robotNumber, $state, $name, $assigned, $ignore2, $lastCleaned, $comment
	) = split(/\s+/, $_, 16);
      chop $comment;

      my $drive = NBU::Drive->byIndex($index, $server);
      if ($robotType ne "-") {
        my $robot = NBU::Robot->new($robotNumber, $robotType);
        $drive->{ROBOT} = $robot;  $robot->controlDrive($drive);
      }
      $drive->{HOST} = $server;
      $driveNamePool{$drive->{NAME} = $name} = $drive;
      $drive->{LASTCLEANED} = $lastCleaned;
      $drive->{COMMENT} = $comment;

      $drive->{CONTROL} = $control;
      $drive->{STATUS} = ($control !~ /DOWN/) ? "UP" : "DOWN";

      $drive->{INUSE} = ($state & 0x000f);

      #
      # If the drive is busy, and the media has no recorded ID yet, but it
      # does have an external ID, then this media is being used for the first
      # time and it will have its external ID recorded henceforth.  So here we
      # simply jump the gun a little...
      if ($drive->busy && ($rvsn eq "-") && ($evsn ne "-")) {
        $rvsn = $evsn;
      }
      if ($rvsn ne "-") {
	# Unfortunately there is no way to find out which job is using this drive :-(
	if (defined(my $volume = NBU::Media->new($rvsn))) {
	  my $mount = NBU::Mount->new(undef, $volume, $drive, time);
          $drive->use($mount, time);
	}
else {die("Cannot located media $rvsn?\n");}
      }

      $driveCount++;
    }
    close($pipe);
    $driveHosts{$server->name} = $driveCount;
  }
  return $driveHosts{$server->name};
}

#
# Try to get more detail on this drive.
# If the host to query is not specified, first look to the drive's
# host or else the local master server for this information
sub loadDriveDetail {
  my $self = shift;
  my $server = shift;

  if (!defined($server)) {
    $server = $self->host;
  }
  if (!defined($server)) {
    my @masters = NBU->masters;  $server = $masters[0];
  }

  my $pipe = NBU->cmd("vmglob -h ".$server->name." -listall -java |");
  while (<$pipe>) {
    next unless (/VMGLOB... drive /);
    chop;

    my($key, $d, $driveName, $serial, $host, $volumeDBHost, $robotNumber, $robotDriveIndex, $density, $flags, $wwName) =
      split;

    if (my $drive = NBU::Drive->byName($driveName)) {
      $drive->{SERIALNUMBER} = $serial;
      $drive->{ROBOTDRIVEINDEX} = $robotDriveIndex;
      $drive->{WWNAME} = $wwName if ($wwName ne "-");

      $drive->{DETAILED} = 1;
    }
  }
  $self->{DETAILED} = 1;
}

#
# Here known refers to whether the drive is known to NetBackup, i.e. whether
# it is part of a storage unit definition and thus could be used for backups.
sub known {
  my $self = shift;

  if (defined(my $stu = $self->{STU})) {
    return ($stu);
  }
  elsif (defined(my $robot = $self->robot)) {
    return ($robot->known);
  }
  return ();
}

sub updateStatus {
  my $proto = shift;
  my $server = shift;

  #
  # Only applies to robotic media managers
  return if (!$server->roboticMediaManager());

  my $pipe = NBU->cmd("vmoprcmd -h ".$server->name." -xdraw ds |");
  while (<$pipe>) {
    next unless (/^DRIVESTATUS/);
    my ($ignore, $id, $density, $control, $user, $rvsn, $evsn, $request,
	$robotType, $robotNumber, $state, $name, $assigned, $ignore2, $lastCleaned, $comment
      ) = split(/\s+/, $_, 16);
    chop $comment;

    my $drive = NBU::Drive->byIndex($id, $server);

    $drive->comment($comment);
    $drive->{LASTCLEANED} = $lastCleaned;

    $drive->{INUSE} = ($state & 0x000f);

    $drive->status($control);

    if ($drive->busy) {
      my $mount = $drive->mount;
      if (($rvsn eq "-") && ($evsn ne "-")) {
        $rvsn = $evsn;
      }

      if ($rvsn eq "-") {
        $drive->free(time);
      }
      elsif ($mount->volume->rvsn ne $rvsn) {
        $drive->free(time);
	$mount = NBU::Mount->new(undef, NBU::Media->new($rvsn), $drive, time);
	$drive->use($mount, time);
      }
    }
    elsif (!$drive->busy && ($rvsn ne "-")) {
      my $mount = NBU::Mount->new(undef, NBU::Media->new($rvsn), $drive, time);
      $drive->use($mount, time);
    }
  }
  close($pipe);
}

sub pool {
  my $proto = shift;

  return (values %driveIndexPool);
}

sub status {
  my $self = shift;

  if (@_) {
    my $oldStatus = $self->{STATUS};
    my $control = $self->{CONTROL} = shift;
    my $newStatus = ($control !~ /DOWN/) ? "UP" : "DOWN";

    if ($oldStatus ne $newStatus) {
      my $handlers = $self->{HANDLERS};

      if (exists($$handlers{$newStatus})) {
	my $handler = $$handlers{$newStatus};
	&$handler($self, $newStatus);
      }
    }

    $self->{STATUS} = $newStatus;
  }
  return $self->{STATUS};
}

sub control {
  my $self = shift;

  return $self->{CONTROL};
}


#
# If the drive is not up, try to change its state to up.  Then,
# if an argument is provided the host will be queried to see if the
# drive indeed came back up.  Without argument the code assumes all
# went as planned.
sub up {
  my $self = shift;


  if (@_) {
    if ($self->{STATUS} ne "UP") {
      system($NBU::prefix."volmgr/bin/vmoprcmd -up ".$self->id." -h ".$self->host->name."\n");
      $self->updateStatus($self->host);
    }
  }

  return $self->{STATUS} eq "UP";
}

#
# Same story as the up routine just above
sub down {
  my $self = shift;

  if (@_) {
    if ($self->{STATUS} ne "DOWN") {
      system($NBU::prefix."volmgr/bin/vmoprcmd -down ".$self->id." -h ".$self->host->name."\n");
      $self->updateStatus($self->host);
    }
  }

  return $self->{STATUS} eq "DOWN";
}

sub busy {
  my $self = shift;

  return $self->{INUSE};
}

sub index {
  my $self = shift;

  return $self->id(@_);
}

sub id {
  my $self = shift;

  if (@_) {
    my $index = shift;
    $self->{INDEX} = $index;

    my $mmHost = shift;
    if (!defined($mmHost)) {
      $mmHost = NBU::Host->new("localhost");
    }
    $driveIndexPool{$mmHost->name.":".$index} = $self;
  }

  return $self->{INDEX};
}

sub comment {
  my $self = shift;

  if (@_) {
    $self->{COMMENT} = shift;
  }

  return $self->{COMMENT};
}

sub name {
  my $self = shift;

  return $self->{NAME};
}

sub serialNumber {
  my $self = shift;

  $self->loadDriveDetail if (!defined($self->{DETAILED}));
  return $self->{SERIALNUMBER};
}

sub worldWideName {
  my $self = shift;

  $self->loadDriveDetail if (!defined($self->{DETAILED}));
  return $self->{WWNAME};
}

sub host {
  my $self = shift;

  return $self->{HOST};
}

sub use {
  my $self = shift;
  my ($mount, $tm) = @_;

  if ($self->{INUSE}) {
    $self->free($tm);
  }

  my $uses = $self->usage;

  my %use;
  $use{'MOUNT'} = $mount;
  $mount->usedBy(\%use);

  $self->{INUSE} = $use{'START'} = $tm;
  push @$uses, \%use;
  return $self;
}

sub mount {
  my $self = shift;

  if ($self->busy) {
    my $uses = $self->usage;
    my $use = $$uses[@$uses - 1];
    return $$use{'MOUNT'};
  }

  return undef;
}

sub free {
  my $self = shift;
  my $tm = shift;

  if (!$self->{INUSE}) {
# it is quite common for a mount to inform the drive it is no
# longer using the drive sometime after the drive has been put
# to new use already.  Hence ignore this event.
#    print "Drive ".$self->id." already free!\n";
#    exit(0);
  }
  $self->{INUSE} = undef;

  my $uses = $self->usage;
  my $use = pop @$uses;
  $$use{'STOP'} = $tm;
  push @$uses, $use;

  return $self;
}

sub robot {
  my $self = shift;

  return $self->{ROBOT};
}

sub robotDriveIndex {
  my $self = shift;

  $self->loadDriveDetail if (!defined($self->{DETAILED}));
  return $self->{ROBOTDRIVEINDEX};
}

sub lastCleaned {
  my $self = shift;

  return $self->{LASTCLEANED};
}

sub lastUsed {
  my $self = shift;

  my $uses = $self->usage;
  if (my $use = pop @$uses) {
    return $$use{'START'};
  }
  else {
    return 0;
  }
}

sub usage {
  my $self = shift;

  if (!$self->{USES}) {
    $self->{USES} = [];
  }

  return $self->{USES};
}

sub busyStats {
  my $self = shift;
  my $asOf = shift;
  my $endOfPeriod = shift;

  my $stepSize = 5 * 60;
  $stepSize = shift if (@_);

  my $usage = $self->usage;

  my $step = $asOf;
  my $use = shift @$usage;
  my $mount = $$use{MOUNT};
  my $job = $mount->job;
  my $du = 1;

  my @driveInUse;
  while ($step < $endOfPeriod) {
    if (!defined($use) || ($step < $$use{START})) {
      push @driveInUse, 0;
    }
    elsif ($step < $$use{STOP}) {
      push @driveInUse, $du;
    }
    else {
      $use = shift @$usage;
      if (defined($use) && defined($mount = $$use{MOUNT})) {
	$du = 1;
      }
      else {
	$du = 0;
      }
      next;
    }
    $step += $stepSize;
  }

  return ($asOf, $endOfPeriod, $stepSize, @driveInUse);
}

sub notifyOn {
  my $self = shift;
  my $target = shift;
  my $handler = shift;

  my $handlers = $self->{HANDLERS};
  $$handlers{$target} = $handler;
}

1;

__END__

=head1 NAME

NBU::Drive - Support for tape Drives

=head1 SUPPORTED PLATFORMS

=over 4

=item * 

Solaris

=item * 

Windows/NT

=back

=head1 SYNOPSIS

    To come...

=head1 DESCRIPTION

This module provides support for ...

=head1 SEE ALSO

=over 4

=item L<NBU::Media|NBU::Media>

=back

=head1 AUTHOR

Winkeler, Paul pwinkeler@pbnj-solutions.com

=head1 COPYRIGHT

Copyright (C) 2002-2007 Paul Winkeler

=cut

