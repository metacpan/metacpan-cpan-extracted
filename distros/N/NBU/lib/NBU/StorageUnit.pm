#
# Copyright (c) 2002 Paul Winkeler.  All Rights Reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself.
#
package NBU::StorageUnit;

use strict;
use Carp;

use NBU::Media;

BEGIN {
  use Exporter   ();
  use AutoLoader qw(AUTOLOAD);
  use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);
  $VERSION =	 do { my @r=(q$Revision: 1.21 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };
  @ISA =         qw();
  @EXPORT =      qw();
  @EXPORT_OK =   qw();
  %EXPORT_TAGS = qw();
}

my %stuList;
my %populated;

my %types = (
  1 => "Disk",
  2 => "Media Manager",
  3 => "NDMP",
);

sub new {
  my $proto = shift;
  my $stu = {};

  bless $stu, $proto;

  if (@_) {
    $stu->{LABEL} = shift;
    my $type;
    if (@_ && exists($types{$type = shift})) {
      $stu->{TYPE} = $types{$type};
    }
    else {
      $stu->{TYPE} = $type;
    }
  }

  $stuList{$stu->{LABEL}} = $stu;
  return $stu;
}

sub populate {
  my $proto = shift;
  my $targetMaster = shift;

  if (!defined($targetMaster)) {
    my @masters = NBU->masters;  $targetMaster = $masters[0];
  }

  $populated{$targetMaster->name} = 0;
  my $pipe = NBU->cmd("bpstulist -M ".$targetMaster->name." |");
  while (<$pipe>) {
    my ($label, $type, $hostName,
	$robotType, $robotNumber, $density,
	$count,
	$maxFragmentSize,
	$path,
	$onDemand,
	$maxMPXperDrive,
	$ndmpAttachHostName,
    ) = split;

    my $stu;
    $stu = NBU::StorageUnit->new($label);

    $stu->{TYPE} = $type;

    $stu->{MASTER} = $targetMaster;
    if ($hostName !~ /_STU_NO_DEV_HOST/) {
      my $mm = $stu->{HOST} = NBU::Host->new($hostName);

      $mm->mediaManager(1);

      #
      # If this is a robot storage unit, we inform the robot so it can know which storage units
      # make use of its services.
      if (defined(my $robot = $stu->{ROBOT} = NBU::Robot->new($robotNumber, $robotType, undef))) {
        $mm->roboticMediaManager(1);
	$robot->known($stu);
      }
      else {
      }
    }

    if ($type == 1) {
      $stu->{CONCURRENTJOBS} = $count;
      $stu->{PATH} = $path;
    }
    elsif ($type == 2) {
      $stu->{DRIVECOUNT} = $count;
      $stu->{DENSITY} = $density;
    }

    $stu->{ONDEMAND} = $onDemand;
    $stu->{MAXMPX} = $maxMPXperDrive;
    $stu->{MAXFRAGSIZE} = $maxFragmentSize;

    $populated{$targetMaster->name} += 0;
  }
  close($pipe);

}

sub list {
  my $proto = shift;
  my $targetMaster = shift;

  if (!defined($targetMaster)) {
    for my $master (NBU->masters) {
      $proto->populate($master) if (!exists($populated{$master->name}));
    }
    return (values %stuList);
  }
  else {
    $proto->populate($targetMaster) if (!exists($populated{$targetMaster->name}));
    my @list;
    for my $su (values %stuList) {
      push @list, $su if (defined($su->master) && ($su->master == $targetMaster));
    }
    return (@list);
  }
}

sub byLabel {
  my $proto = shift;
  my $label = shift;
  my $targetMaster = shift;

  return $stuList{$label} if (exists($stuList{$label}));

  if (!defined($targetMaster)) {
    for my $master (NBU->masters) {
      $proto->populate($master) if (!exists($populated{$master->name}));
    }
  }
  else {
    $proto->populate($targetMaster) if (!exists($populated{$targetMaster->name}));
  }

  if (!exists($stuList{$label})) {
    my $stu = $proto->new($label);
    $stu->{MASTER} = $targetMaster;
  }
  return $stuList{$label};
}

sub master {
  my $self = shift;

  return $self->{MASTER};
}

sub host {
  my $self = shift;

  return $self->{HOST};
}

#
# Return a list of all media servers known to the target master.  If no
# target master is supplied, return all known media servers.
sub mediaServers {
  my $proto = shift;
  my $targetMaster = shift;


  my %names;
  my @list;
  for my $su ($proto->list($targetMaster)) {
    next if (!defined($su->host));

    if (!exists($names{$su->host->name})) {
      push @list, $su->host;
    }
    $names{$su->host->name} += 1;
  }

  return (@list);
}

sub type {
  my $self = shift;

  return $self->{TYPE};
}

sub path {
  my $self = shift;

  if (@_) {
    my $path = shift;
    $self->{PATH} = $path;
  }

  return $self->{PATH};
}

sub density {
  my $self = shift;

  return $NBU::Media::densities{$self->{DENSITY}};
}

sub driveCount {
  my $self = shift;

  return $self->{DRIVECOUNT};
}

sub label {
  my $self = shift;

  return $self->{LABEL};
}

sub robot {
  my $self = shift;

  return $self->{ROBOT};
}

sub onDemand {
  my $self = shift;

  return $self->{ONDEMAND};
}

#
# NBU stores the maximum number of multiplexed jobs per storage unit but this routine
# maps the degenerate case to 0 so a simple test for multi-plexing can be done on its
# return value
sub mpx {
  my $self = shift;

  if ($self->{MAXPX} == 1) {
    return 0;
  }
  else {
    return $self->{MAXMPX};
  }
}

sub maximumFragmentSize {
  my $self = shift;

  return $self->{MAXFRAGSIZE};
}

1;
__END__

=head1 NAME

NBU::StorageUnit - Provide Access to NetBackup Storage Unit information and configuration

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

