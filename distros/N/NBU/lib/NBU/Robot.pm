#
# Copyright (c) 2002 Paul Winkeler.  All Rights Reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself.
#
package NBU::Robot;

use strict;
use Carp;

BEGIN {
  use Exporter   ();
  use AutoLoader qw(AUTOLOAD);
  use vars       qw(%robotLevel);
  use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);
  $VERSION =	 do { my @r=(q$Revision: 1.23 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };
  @ISA =         qw();
  @EXPORT =      qw(%robotLevel);
  @EXPORT_OK =   qw();
  %EXPORT_TAGS = qw();
}

my @farm;

my %robotTypes = (
  1 => 'ACS',
  2 => 'TS8',
  3 => 'TC8',
  5 => 'ODL',
  6 => 'TL8',
  7 => 'TL4',
  8 => 'TLD',
  9 => 'TC4',
  10 => 'TSD',
  11 => 'TSH',
  12 => 'TLH',
  13 => 'TLM',
  17 => 'LMF',
  0 => '-',
);

#
# new(robot-number, robot-type [, robot-host-name])
sub new {
  my $Class = shift;
  my $robot = {};


  if (@_) {
    my $id = shift;

    my $type = shift;
    if ($type =~ /^[\d]+$/) {
      if (!exists($robotTypes{$type}) || ($type == 0)) {
        return undef;
      }
      else {
	$type = $robotTypes{$type};
      }
    }
    else {
      return undef if ($type eq "-");
    }

    if ($farm[$id]) {
      $robot =  $farm[$id];
    }
    else {
      bless $robot, $Class;
      $robot->{ID} = $id;
      $farm[$id] = $robot;

      $robot->{DEVICEPATH} = undef;
      $robot->{MAILSLOTSIZE} = 14;
      $robot->{SLOTS} = {};
      $robot->{DRIVES} = [];
      $robot->{KNOWNTO} = [];
      $robot->{TYPE} = $type;
    }
  }

  return $robot;
}

sub populate {
  my $self = shift;

  my $lastSlot;

  my $type = $self->type;
  $type =~ tr/A-Z/a-z/;

  if (!defined($self->host)) {
    $lastSlot = 0;
  }
  else {
    my $pipe = NBU->cmd("vmcheckxxx ".
	  " -rt $type".
	  " -rn ".$self->id.
	  " -rh ".$self->host->name.
	  " -list |");

    if ($self->host->NBUVersion eq "3.2.0") {
      while (<$pipe>) {
	if (/^Slot = [\s]*([\d]+), Barcode = ([\S]+)$/) {
	  if (defined(my $volume = NBU::Media->byBarcode($2))) {
	    $self->insert($1, $volume);
	  }
	  else {
	    print STDERR "Unknown barcode $2 in slot $1 of robot ".$self->id."\n";
	    $self->empty($1);
	  }
	  $lastSlot = $1;
	}
	elsif (/^Slot = [\s]*([\d]+), <EMPTY>/) {
	  $self->empty($1);
	  $lastSlot = $1;
	}
	else {
	  print STDERR "Ignoring $_";
	}
      }
    }
    elsif (($self->host->NBUVersion eq "3.4.0")
        || ($self->host->NBUVersion eq "4.5.0")
        || ($self->host->NBUVersion eq "5.1.0")
        || ($self->host->NBUVersion eq "6.5.0")
                                               ) {
      while (<$pipe>) {
	last if (/^===/);
      }
      while (<$pipe>) {
	if (/^[\s]*([\d]+)[\s]+[\S]+[\s]+([\S]+)/) {
	  if (defined(my $volume = NBU::Media->byBarcode($2))) {
	    $self->insert($1, $volume);
	  }
	  else {
	    print STDERR "Unknown barcode $2 in slot $1 of robot ".$self->id."\n";
	    $self->empty($1);
	  }
	  $lastSlot = $1;
	}
	elsif (/^[\s]*([\d]+)[\s]+No/) {
	  $self->empty($1);
	  $lastSlot = $1;
	}
	else {
	  print STDERR "Ignoring $_";
	}
      }
    }
    else {
      print STDERR "Unknown NetBackup version \"".$self->host->NBUVersion."\"\n";
      $lastSlot = 0;
    }
  }

  $self->{CAPACITY} = defined($lastSlot) ? $lastSlot : 0;
}

sub byID {
  my $class = shift;
  my $id = shift;

  return $farm[$id];
}

sub id {
  my $self = shift;

  return $self->{ID};
}

sub type {
  my $self = shift;

  $self->loadRobotDetail if (!defined($self->{DETAILED}));
  if (@_) {
    $self->{TYPE} = shift;
  }
  return $self->{TYPE};
}

sub host {
  my $self = shift;

  $self->loadRobotDetail if (!defined($self->{DETAILED}));
  if (@_) {
    $self->{CONTROLHOST} = shift;
  }
  return $self->{CONTROLHOST};
}

sub voldbHost {
  my $self = shift;

  $self->loadRobotDetail if (!defined($self->{DETAILED}));
  if (@_) {
    $self->{VOLDBHOST} = shift;
  }
  return $self->{VOLDBHOST};
}

sub controlDrive {
  my $self = shift;
  my $drive = shift;


  my $driveList = $self->{DRIVES};
  push @$driveList, $drive;

  return $drive;
}

sub drives {
  my $self = shift;

  my $driveList = $self->{DRIVES};
  return @$driveList;
}

#
# Robots are accessed through storage units.  Every time a new robotic
# storage unit is defined, the robot in question is informed of this by
# a call to the known method.
# Without arguments a list of storage units using the robot is returned.
sub known {
  my $self = shift;

  my $stuList = $self->{KNOWNTO};
  if (@_) {
    my $stu = shift;
    push @$stuList, $stu;
  }
  return @$stuList;
}

sub insert {
  my $self = shift;
  my $slotList = $self->{SLOTS};
  my ($position, $volume) = @_;

  if (exists($$slotList{$position})) {
    if ($$slotList{$position} != $volume) {
      print STDERR "Slot $position in ".$self->id." already filled; no room for ".$volume->id."\n";
    }
    else {
    }
  }
  else {
    $$slotList{$position} = $volume;
  }
  return $$slotList{$position};
}

sub empty {
  my $self = shift;
  my $slotList = $self->{SLOTS};
  my $position = shift;

  if (exists($$slotList{$position})) {
    my $volume = $$slotList{$position};
    delete $$slotList{$position};

    $volume->robot(undef);
    $volume->slot(undef);
  }

  return undef;
}

sub nextEmptySlot {
  my $self = shift;
  my $slotList = $self->{SLOTS};

  for my $s (1..$self->capacity) {
    return $s if (!exists($$slotList{$s}));
  }
  return undef;
}

sub slot {
  my $self = shift;
  my $slotList = $self->{SLOTS};
  my $position = shift;
  

  if (@_) {
    my $volume = shift;
    return $self->insert($position, $volume);
  }
  return $$slotList{$position};
}

sub capacity {
  my $self = shift;

  if (!defined($self->{CAPACITY})) {
    $self->populate;
  }

  return $self->{CAPACITY};
}

sub slotList {
  my $self = shift;
  my $slotList = $self->{SLOTS};
  my @list;

  #
  # Undefined or unreachable robots have no capacity thus
  # should result in completely empty lists
  if (my $lastSlot = $self->capacity) {
    # slot 0 is not used but PERL arrays default to 0 based indexing...
    push @list, undef;
    for my $s (1..$lastSlot) {
      push @list, $$slotList{$s};
    }
  }

  return @list;
}

sub mediaList {
  my $self = shift;
  my $slotList = $self->{SLOTS};

  return (values %$slotList);
}

sub farm {
  my $Class = shift;

  return (@farm);
}

sub updateInventory {
  my $self = shift;
  my $importCAP = shift;

  NBU->cmd("vmupdate "." -rt ".$self->type." -rn ".$self->id." -rh ".$self->host->name
	." -use_barcode_rules"
	.((defined($importCAP) && $importCAP) ? " -empty_ie" : "")
	, 0);

  $self->populate;
}

1;

#
# Try to get more detail on this robot.
# If the host to query is not specified, first look to the robot's
# host or else the local master server for this information
sub loadRobotDetail {
  my $self = shift;
  my $server = shift;

  if (!defined($server)) {
    my @masters = NBU->masters;  $server = $masters[0];
  }

  my $pipe = NBU->cmd("vmglob -h ".$server->name." -listall -java |");
  while (<$pipe>) {
    next unless (/VMGLOB... robot /);
    chop;

    my($key, $d, $number, $serial, $host, $voldbHostName, $robotNumber, $na1, $type, $na2, $flags,
       $wwName, $wwNameType, $inquiry, $libraryName, $vendorName, $controlHostName) =
      split;

    # Any media server with drives controlled by this robot will generate an entry for this robot
    # However, we only care about the entry from the host which is the controlling host.
    next unless ($controlHostName eq "-");

    if (my $robot = NBU::Robot->byID($robotNumber)) {
      $robot->{SERIALNUMBER} = $serial;
      $robot->{VOLDBHOST} = NBU::Host->new($voldbHostName);
      $robot->{CONTROLHOST} = NBU::Host->new($host);

      $robot->{DETAILED} = 1;
    }
  }
  $self->{DETAILED} = 1;
}

__END__

=head1 NAME

NBU::Robot - Interface to NetBackup robot manipulation and querying routines

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

