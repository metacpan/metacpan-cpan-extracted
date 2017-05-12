#
# Copyright (c) 2002 Paul Winkeler.  All Rights Reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself.
#
package NBU::Class;

use strict;
use Carp;

use NBU::Host;
use NBU::Schedule;

my %classRoom;

BEGIN {
  use Exporter   ();
  use AutoLoader qw(AUTOLOAD);
  use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);
  $VERSION =	 do { my @r=(q$Revision: 1.29 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };
  @ISA =         qw();
  @EXPORT =      qw();
  @EXPORT_OK =   qw();
  %EXPORT_TAGS = qw();
}

sub new {
  my $proto = shift;
  my $class;

  if (@_) {
    my $name = shift;
    my $type = shift;
    my $master = shift;

    if (!exists($classRoom{$name})) {
      $class = {
        CLIENTS => [],
      };
      bless $class, $proto;

      $classRoom{$class->{NAME} = $name} = $class;
      $class->{TYPE} = $type;
      $class->{LOADED} = 0;
    }
    elsif (!defined($class = $classRoom{$name}) || ($class->{TYPE} ne $type)) {
      $class = {
        CLIENTS => [],
      };
      bless $class, $proto;

      $classRoom{$class->{NAME} = $name} = undef;
      $class->{TYPE} = $type;
      $class->{LOADED} = 0;
    }
    $class->{MASTER} = $master;
  }
  return $class;
}

my %classTypes = (
  0 => "Standard",
  3 => "Apollo_WBAK",
  4 => "Oracle",
  6 => "Informix",
  7 => "Sybase",
  10 => "NetWare",
  11 => "BackTrack",
  12 => "Auspex_Fastback",
  13 => "Windows_NT",
  14 => "OS2",
  15 => "SQL_Server",
  16 => "Exchange",
  17 => "SAP",
  18 => "DB2",
  19 => "NDMP",
  20 => "FlashBackup",
  21 => "SplitMirror",
  22 => "AFS",
  29 => "VCB",
  30 => "Vault",
  35 => "NBU-Catalog",
);

my $rollCalled = 0;
sub populate {
  my $proto = shift;
  my $self = ref($proto) ? $proto : undef;;
  my $master = shift;

  if (!defined($master)) {
    my @masters = NBU->masters;  $master = $masters[0];
  }

  NBU::Pool->populate;

  my $source = defined($self) ? $self->name : "-allclasses";
  my $pipe = NBU->cmd("bpcllist $source -l -M ".$master->name." |");

  $proto->loadClasses($pipe, defined($self) ? "CLASS" : "ALL", $master);

  #
  # If the entire class was being loaded, we'll consider the roll to
  # have been called.
  $rollCalled = !defined($self);
}

sub loadClasses {
  my $proto = shift;
  my $pipe = shift;
  my $focus = shift;
  my $master = shift;

  my $class;
  my $className;
  my $schedule;

  while (<$pipe>) {
    chop;
    if (/^CLASS/) {
      #
      # Simply remember the initial class name and defer creating it until we know its
      # type on the next INFO line.  Just to be safe, we'll set the running class variable
      # to null...
      my ($tag, $name, $ptr1, $u1, $u2, $u3, $ptr2) = split;
      $className = $name;
      $class = undef;
      next;
    }
    if (/^NAMES/) {
      next;
    }
    if (/^INFO/) {
      my ($tag, $type, $networkDrives, $clientCompression, $priority, $ptr1,
	  $u2, $u3, $maxJobs, $crossMounts, $followNFS,
	  $inactive, $TIR, $u6, $u7, $restoreFromRaw, $multipleDataStreams, $ptr2) = split;

      $class = NBU::Class->new($className, $type, $master);
      $class->{LOADED} = $focus =~ /CLASS|ALL/;

      $class->{NETWORKDRIVES} = $networkDrives;
      $class->{COMPRESSION} = $clientCompression;
      $class->{PRIORITY} = $priority;
      $class->{MAXJOBS} = $maxJobs;
      $class->{CROSS} = $crossMounts;
      $class->{FOLLOW} = $followNFS;
      $class->{ACTIVE} = !$inactive;
      $class->{TIR} = $TIR;
      $class->{RESTOREFROMRAW} = $restoreFromRaw;
      $class->{MDS} = $multipleDataStreams;
      next;
    }
    if (/^KEY /) {
      my ($tag, @keys) = split;;
      $class->{KEYS} = \@keys unless ($keys[0] eq "*NULL*");
      next;
    }
    if (/^BCMD /) {
      next;
    }
    if (/^RCMD /) {
      next;
    }
    if (/^RES /) {
      my ($tag, @residences) = split;
      $class->{RESIDENCE} = NBU::StorageUnit->byLabel($residences[0]) unless ($residences[0] eq "*NULL*");
      next;
    }
    if (/^POOL /) {
      my ($tag, @pools) = split;
      $class->{POOL} = NBU::Pool->byName($pools[0]) unless ($pools[0] eq "*NULL*");
      next;
    }
    if (/^CLIENT /) {
      my ($tag, $name, $platform, $os) = split;
      my $client = NBU::Host->new($name);
      $class->loadClient($client);
      $client->makeClassMember($class);
      $client->enrolled if ($focus =~ /CLIENT|ALL/);
      next;
    }
    if (/^INCLUDE /) {
      my ($tag, $path) = split(/[\s]+/, $_, 2);
      $class->include($path);
      next;
    }
    if (/^EXCLUDE /) {
      my ($tag, $path) = split(/[\s]+/, $_, 2);
      $class->exclude($path);
      next;
    }
    if (/^SCHED /) {
      my ($tag, $name, $type, @schedAttr) = split;
      $schedule = $class->loadSchedule(NBU::Schedule->new($class, $name, $type, $pipe, @schedAttr));
      next;
    }
  }
  close($pipe);
}

sub byName {
  my $proto = shift;
  my $name = shift;

  $proto->populate if (!$rollCalled);
  if (my $class = $classRoom{$name}) {
    return $class;
  }
  return undef;
}

sub list {
  my $proto = shift;

  $proto->populate if (!$rollCalled);

  return (values %classRoom);
}

sub create {
  my $proto = shift;

}

sub clone {
  my $self = shift;

}

sub update {
  my $self = shift;

  return $self;
}

sub delete {
  my $self = shift;

  return $self;
}

sub loadClient {
  my $self = shift;
  my $newClient = shift;

  my $clientListR = $self->{CLIENTS};
  push @$clientListR, $newClient;

  return $newClient;
}

sub clients {
  my $self = shift;

  $self->populate if (!$self->{LOADED});
  my $clientListR = $self->{CLIENTS};
  return (defined($clientListR) ? (@$clientListR) : ());
}

sub master {
  my $self = shift;

  return $self->{MASTER};
}

sub loadSchedule {
  my $self = shift;
  my $newSchedule = shift;
  my $listR;

print "Policy ".$self->name." has undefined schedule?\n" if (!defined($newSchedule));
  if ($self->policyAware && ($newSchedule->type eq "UBAK")) {
    if (!defined($self->{POLICIES})) {
      $self->{POLICIES} = [];
    }
    $listR = $self->{POLICIES};
  }
  else {
    if (!defined($self->{SCHEDULES})) {
      $self->{SCHEDULES} = [];
    }
    $listR = $self->{SCHEDULES};
  }

  push @$listR, $newSchedule;

  return $newSchedule;
}

sub schedules {
  my $self = shift;

  $self->populate if (!$self->{LOADED});
  my $schedulesR = $self->{SCHEDULES};
  return (defined($schedulesR) ? (@$schedulesR) : ());
}

sub policies {
  my $proto = shift;
  my $self = ref($proto) ? $proto : undef;;

  $proto->populate if (!$self->{LOADED});
  my $policiesR = $proto->{POLICIES};
  return (defined($policiesR) ? (@$policiesR) : ());
}

sub exclude {
  my $self = shift;

  $self->populate if (!$self->{LOADED});
  if (@_) {
    if (!defined($self->{EXCLUDE})) {
      $self->{EXCLUDE} = [];
    }
    my $excludeListR = $self->{EXCLUDE};
    my $newExclude = shift;

    push @$excludeListR, $newExclude;
  }
  my $excludeListR = $self->{EXCLUDE};
  
  return (defined($excludeListR) ? (@$excludeListR) : ());
}

sub include {
  my $self = shift;

  $self->populate if (!$self->{LOADED});
  if (@_) {
    if (!defined($self->{INCLUDE})) {
      $self->{INCLUDE} = [];
    }
    my $includeListR = $self->{INCLUDE};
    my $newInclude = shift;

    push @$includeListR, $newInclude;
  }
  my $includeListR = $self->{INCLUDE};
  
  return (defined($includeListR) ? (@$includeListR) : ());
}

sub pool {
  my $self = shift;

  $self->populate if (!$self->{LOADED});
  if (@_) {
    print $self->name." already has a pool: ".$self->{POOL}."\n" if ($self->{POOL});
    $self->{POOL} = shift;
  }

  return $self->{POOL};
}

sub residence {
  my $self = shift;

  $self->populate if (!$self->{LOADED});
  if (@_) {
    print $self->name." already has a residence: ".$self->{RESIDENCE}."\n" if ($self->{RESIDENCE});
    $self->{RESIDENCE} = shift;
  }

  return $self->{RESIDENCE};
}

sub storageUnit {
  my $self = shift;

  return $self->residence(@_);
}

my %policyAware = (
  4 => "Oracle",
  6 => "Informix",
  7 => "Sybase",
  15 => "SQL_Server",
  16 => "Exchange",
  17 => "SAP",
  18 => "DB2",
);
sub policyAware {
  my $self = shift;

  $self->populate if (!$self->{LOADED});
  return exists($policyAware{$self->{TYPE}});
}

sub type {
  my $self = shift;

  $self->populate if (!$self->{LOADED});
  if (@_) {
    $self->{TYPE} = shift;
  }
  print STDERR "Asked to return unknown type ".$self->{TYPE}." for ".$self->{NAME}."\n"
   if !defined($classTypes{$self->{TYPE}});
  return $classTypes{$self->{TYPE}};
}

sub license {
  my $self = shift;

  return NBU::Licenses->licenseForClass($self->{TYPE}, $self->master);
}

sub keywords {
  my $self = shift;

  $self->populate if (!$self->{LOADED});
  if (@_) {
    $self->{KEYWORDS} = shift;
  }
  return $self->{KEYWORDS};
}

sub DR {
  my $self = shift;

  $self->populate if (!$self->{LOADED});
  if (@_) {
    $self->{DR} = shift;
  }
  return $self->{DR};
}

sub maxJobs {
  my $self = shift;

  $self->populate if (!$self->{LOADED});
  if (@_) {
    $self->{MAXJOBS} = shift;
  }
  return $self->{MAXJOBS};
}

sub priority {
  my $self = shift;

  $self->populate if (!$self->{LOADED});
  if (@_) {
    $self->{PRIORITY} = shift;
  }
  return $self->{PRIORITY};
}

sub multipleDataStreams {
  my $self = shift;

  $self->populate if (!$self->{LOADED});
  if (@_) {
    $self->{MDS} = shift;
  }
  return $self->{MDS};
}

sub BLIB {
  my $self = shift;

  $self->populate if (!$self->{LOADED});
  if (@_) {
    $self->{BLIB} = shift;
  }
  return $self->{BLIB};
}

#
# TIR codes are:
# 0	off
# 1	on
# 2	on with move detection
sub TIR {
  my $self = shift;

  $self->populate if (!$self->{LOADED});
  if (@_) {
    $self->{TIR} = shift;
  }
  return $self->{TIR};
}

sub crossMountPoints {
  my $self = shift;

  $self->populate if (!$self->{LOADED});
  if (@_) {
    $self->{CROSS} = shift;
  }
  return $self->{CROSS};
}

sub followNFSMounts {
  my $self = shift;

  $self->populate if (!$self->{LOADED});
  if (@_) {
    $self->{FOLLOW} = shift;
  }
  return $self->{FOLLOW};
}

sub clientCompression {
  my $self = shift;

  $self->populate if (!$self->{LOADED});
  if (@_) {
    $self->{COMPRESSION} = shift;
  }
  return $self->{COMPRESSION};
}

sub clientEncrypted {
  my $self = shift;

  $self->populate if (!$self->{LOADED});
  if (@_) {
    $self->{ENCRYPTION} = shift;
  }
  return $self->{ENCRYPTION};
}

sub active {
  my $self = shift;

  $self->populate if (!$self->{LOADED});
  if (@_) {
    my $newState = shift;
    if (($newState && !$self->{ACTIVE}) || (!$newState && $self->{ACTIVE})) {
      if ($self->{ACTIVE} = $newState) {
        NBU->cmd("bpclinfo ".$self->name." -update -active");
      }
      else {
        NBU->cmd("bpclinfo ".$self->name." -update -inactive");
      }
    }
  }
  return $self->{ACTIVE};
}

sub name {
  my $self = shift;

  if (@_) {
    if (defined($self->{NAME})) {
      delete $classRoom{$self->{NAME}};
    }
    $self->{NAME} = shift;
    $classRoom{$self->{NAME}} = $self;
  }
  return $self->{NAME};
}

sub providesCoverage {
  my $self = shift;

  $self->populate if (!$self->{LOADED});
  if (@_) {
    $self->{COVERS} = shift;
  }

  return $self->{COVERS};
}

#
# Load the list of images of this class
sub loadImages {
  my $self = shift;

  NBU::Image->loadImages(NBU->cmd("bpimmedia -l -class ".$self->name." |"));
}

sub images {
  my $self = shift;

  if (!defined($self->{IMAGES})) {
    $self->loadImages;

    my @images;
    for my $client ($self->clients) {
      for my $image ($client->images) {
	push @images, $image  if ($image->class == $self);
      }
    }

    $self->{IMAGES} = \@images;
  }
  my $imageListR = $self->{IMAGES};

  return (@$imageListR);
}

1;

__END__

=head1 NAME

NBU::Class - Support for NBU Policies (formerly known as Classes)

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

