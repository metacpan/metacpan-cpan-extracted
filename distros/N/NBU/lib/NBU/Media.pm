#
# Copyright (c) 2002 Paul Winkeler.  All Rights Reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself.
#
package NBU::Media;

use strict;
use Carp;

use Date::Parse;

use NBU::Robot;

BEGIN {
  use Exporter   ();
  use AutoLoader qw(AUTOLOAD);
  use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);
  use vars       qw(%densities %mediaTypes);
  $VERSION =	 do { my @r=(q$Revision: 1.45 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };
  @ISA =         qw();
  @EXPORT =      qw(%densities);
  @EXPORT_OK =   qw();
  %EXPORT_TAGS = qw();
}

%densities = (
  13 => "dlt",
  16 => "8mm",
  12 => "4mm",
  6 => "hcart",
  19 => "dtf",
  9 => "odiskwm",
  10 => "odiskwo",
  0 => "qscsi",
  15 => "dlt2",
  14 => "hcart2",
  20 => "hcart3",
  21 => "dlt3",
);

my %mediaCodes = (
  'DLT' => 11,
  'DLT_CLN'=> 12,
  'DLT2' => 16,
  'DLT2_CLN' => 17,
  'DLT3' => 26,
  'DLT3_CLN' => 27,
  'HCART' => 6,
  'HC_CLN' => 13,
  'HCART2' => 14,
  'HC2_CLN' => 15,
  'HCART3' => 24,
  'HC3_CLN' => 25,
  '4MM' => 9,
  '4MM_CLN' => 10,
  '8MM' => 4,
  '8MM_CLN' => 5,
#  '8MM2' => 
#  '8MM2_CLN' => 
#  'D2' => 
#  'D2_CLN' => 
  'DTF' => 22,
  'DTF_CLN' => 23,
  'DEFAULT' => 0,
);

%mediaTypes = (
  0  => "DEFAULT",
  11 => "DLT cartridge tape",
  12 => "DLT cleaning tape",
  16 => "DLT cartridge tape 2",
  17 => "DLT cleaning tape 2",
  26 => "DLT cartridge tape 3",
  27 => "DLT cleaning tape 3",
  6  => "1/2\" cartridge tape",
  13 => "1/2\" cleaning tape",
  14 => "1/2\" cartridge tape 2",
  15 => "1/2\" cleaning tape 2",
  24 => "1/2\" cartridge tape 3",
  25 => "1/2\" cleaning tape 3",
  4  => "8MM cartridge tape",
  5  => "8MM cleaning tape",
  9  => "4MM cartridge tape",
  10 => "4MM cleaning tape",
  22 => "DTF cartridge tape",
  23 => "DTF cleaning tape",
  1  => "Rewritable optical disk",
  2  => "WORM optical disk",
  8  => "QIC - 1/4\" cartridge tape",
);

my %mediaList;
my %barcodeList;

sub new {
  my $proto = shift;
  my $media = {};

  bless $media, $proto;

  if (@_) {
    my $mediaID = shift;
    my $voldbHost = shift;

    if (exists($mediaList{$mediaID})) {
      $media = $mediaList{$mediaID};
    }
    else {
      $media->{VOLDBHOST} = $voldbHost;
      $media->{RVSN} = $mediaID;
      $mediaList{$media->{RVSN}} = $media;
    }
    if (@_) {
      my $removable = shift;
      $media->{REMOVABLE} = $removable;
    }
    else {
      $media->{REMOVABLE} = 1;
    }
  }
  return $media;
}

my $filled;
sub populate {
  my $proto = shift;
  my $volume;
  my $updateRobot = shift;

  my $pipe;

  $filled = 0;

  #
  # Have to force the pool information to load or we dead-lock.  It appears
  # the VM database deamon is single threaded and won't answer a pool query
  # until the volume listing is completed...
  NBU::Pool->populate;

  #
  # The rule is to populate with information from all the volume databases
  # maintained by the master and its active media servers (allowing for the
  # master in fact not to be a media server).
  my %voldbHosts;
  my @masters = NBU->masters;  my $master = $masters[0];
  $voldbHosts{$master->name} = $master;
  foreach my $ms (NBU::StorageUnit->mediaServers($master)) {
    if (defined(my $EMMserver = $ms->EMMserver)) {
      $voldbHosts{$EMMserver->name} = $EMMserver;
    }
    else {
      $voldbHosts{$ms->name} = $ms;
    }
  }

  foreach my $voldbHost (values %voldbHosts) {
    $pipe = NBU->cmd("vmquery -a -w -h ".$voldbHost->name." |");
    $_ = <$pipe>; $_ = <$pipe>; $_ = <$pipe>;
    while (<$pipe>) {
      my ($id,
	  $opticalPartner,
	  $mediaCode,
	  $barcode, $barcodePartner,
	  $robotHostName, $robotType, $robotNumber, $slotNumber,
	  $side,
	  $volumeGroup,
	  $volumePool, $volumePoolNumber, $previousVolumePool,
	  $mountCount, $maxMounts, $cleaningCount,
	  $creationDate, $creationTime,
	  $assignDate, $assignTime,
	  $firstMountDate, $firstMountTime,
	  $lastMountDate, $lastMountTime,
	  $expirationDate, $expirationTime,
	  $status,
	  $offsiteLocation,
	  $offsiteSentDate, $offsiteSentTime,
	  $offsiteReturnDate, $offsiteReturnTime,
	  $offsiteSlot,
	  $offsiteSessionID,
	  $version,
	  $description,
	)
	= split(/[\s]+/, $_, 37);

      #
      # "Normal" installations will not use the same serial number in more than 
      # one volume database.  Thus our test here more or less expects not to
      # find this id:
      $volume = NBU::Media->byID($id, $voldbHost);
      if (defined($volume)) {
	if (NBU->debug) {
	  print STDERR "Volume $id in voldb on ".$voldbHost->name." conflicts with existing volume\n";
	  print STDERR "  Host: ".$volume->voldbHost."\n";
	}
	next;
      }
      else {
	$volume = NBU::Media->new($id, $voldbHost);

	$filled += 1;
      }

      $volume->barcode($barcode);

      if (!exists($mediaCodes{$mediaCode})) {
      }
      $volume->{MEDIATYPE} = $mediaCodes{$mediaCode};

      $volume->{CLEANINGCOUNT} = $cleaningCount;
      $volume->{MOUNTCOUNT} = $mountCount;
      $volume->{MAXMOUNTS} = $maxMounts;
      $volume->{GROUP} = ($volumeGroup eq "---") ? undef : $volumeGroup,


      $volume->{POOL} = NBU::Pool->byID($volumePoolNumber);
      $volume->{PREVIOUSPOOL} = NBU::Pool->byName($previousVolumePool);

      $volume->{OFFSITELOCATION} = $offsiteLocation unless ($offsiteLocation eq "-");
      $volume->{OFFSITESLOT} = $offsiteSlot unless (($offsiteSlot eq "-") || ($offsiteSlot == 0));
      $volume->{OFFSITESESSIONID} = $offsiteSessionID unless (($offsiteSessionID eq "-") || ($offsiteSessionID == 0));

      my $rd = $offsiteReturnDate." ".$offsiteReturnTime;  $rd = str2time($rd);
      $volume->{OFFSITERETURN} = $rd if (defined($rd));

      $volume->{VERSION} = $version;
      $volume->{DESCRIPTION} = $description;

      if ($updateRobot && ($robotType ne "NONE")) {
	my $robot;
	if (!defined($robot = NBU::Robot->byID($robotNumber))) {
	  $robot = NBU::Robot->new($robotNumber, $robotType);
	}
	$robot->insert($slotNumber, $volume);
	$volume->robot($robot);
	$volume->slot($slotNumber);
      }

      $volume->{NETBACKUP} = ($status == 1);
    } 
    close($pipe);
  }

  $pipe = NBU->cmd("bpmedialist -L |");
  my $mmdbHost;
  while (<$pipe>) {

    if (/^Server Host = ([\S]+)[\s]*$/) {
      $mmdbHost = NBU::Host->new($1);
      next;
    }

    if (/^media_id = ([A-Z0-9]+), partner_id.*/) {
      if ($volume) {
        print STDERR "New media $1 encountered when old one ".$volume->id." still active!\n";
        exit 0;
      }
      $volume = NBU::Media->byID($1);
      if (!defined($volume)) {
	print STDERR "Media id $1 in mmdb on ".$mmdbHost->name." was not found in any voldb!\n" if (NBU->debug);
	$volume = NBU::Media->new($1);
	$filled += 1;
      }
      $volume->{MMLOADED} = 1;
      $volume->{MMDBHOST} = $mmdbHost;

      $filled += 1;
      next;
    }

    if (/^density = ([\S]+) \(([\d]+)\)/) {
      $volume->{DENSITY} = $2;
      next;
    }
    if (/^allocated = .* \(([0-9]+)\)/) {
      $volume->{ALLOCATED} = $1;
      next;
    }
    if (/^last_written = .* \(([0-9]+)\)/) {
      $volume->{LASTWRITTEN} = $1;
      next;
    }
    if (/^expiration = .* \(([0-9]+)\)/) {
      $volume->{LASTIMAGEEXPIRES} = $1;
      next;
    }
    if (/^last_read = .* \(([0-9]+)\)/) {
      $volume->{LASTREAD} = $1;
      next;
    }

    if (/retention_level = ([\d]+), num_restores = ([\d]+)/) {
      $volume->retention(NBU::Retention->byLevel($1));
      $volume->{RESTORECOUNT} = $2;
      next;
    }

    if (/^kbytes = ([\d]+), nimages = ([\d]+), vimages = ([\d]+)/) {
      $volume->{SIZE} = $1;
      $volume->{IMAGECOUNT} = $2;
      $volume->{VIMAGECOUNT} = $3;
      next;
    }

    if (/^status = 0x([0-9A-Fa-f]+)/) {
      my $status = $1;
      my $result = 0;
      foreach my $d (split(/ */, $status)) {
	$d =~ tr/a-z/A-Z/;  $d = (ord($d) - ord('A') + 10) if ($d =~ /[A-F]/);
        $result *= 16;
        $result += $d;
      }
      $volume->{STATUS} = $result;
      next;
    }

    if (/^res1 = /) {
      next;
    }

    if (/^vmpool = /) {
      next;
    }

    if (/^[\s]*$/) {
      $volume = undef;
      next;
    }
print STDERR "Unknown line\n \"$_\"\n";
  }
  close($pipe);
}

my $mediaErrors = "/usr/local/etc/media-errors.csv";
sub loadErrors {
  my $proto = shift;
  my $errorCount;

  if (open(PIPE, "<$mediaErrors")) {
    # Place this use directive inside an eval to postpone missing
    # module diagnostics until run-time
    eval "use Text::CSV_XS";
    my $csv = Text::CSV_XS->new();

    # Throw the header line away and read the remaining error lines
    $_ = <PIPE>;
    while (<PIPE>) {
      if ($csv->parse($_)) {
	my @fields = $csv->fields;
	my $volume = NBU::Media->byID($fields[1]);
	if ($volume) {
	  $volume->logError($fields[0], $fields[5]);
	  $errorCount += 1;
	}
      }
    }
    close(PIPE);
  }
  elsif (NBU->debug) {
    print STDERR "Could not load media errors from $mediaErrors\n";
  }
  return $errorCount;
}

sub listIDs {
  my $proto = shift;

  return (keys %mediaList);
}

sub listVolumes {
  my $proto = shift;

  return (values %mediaList);
}

sub list {
  my $proto = shift;

  return ($proto->listVolumes);
}

sub voldbHost {
  my $self = shift;

  if (@_) {
    $self->{VOLDBHOST} = shift;
  }
  return $self->{VOLDBHOST};
}

sub mmdbHost {
  my $self = shift;

  if (@_) {
    $self->{MMDBHOST} = shift;
  }
  return $self->{MMDBHOST};
}

sub density {
  my $self = shift;

  if (@_) {
    my $density = shift;
    $self->{DENSITY} = $density;
  }

  return $self->removable ? $densities{$self->{DENSITY}} : "disk";
}

sub retention {
  my $self = shift;

  if (@_) {
    my $retention = shift;
    $self->{RETENTION} = $retention;
  }

  return $self->{RETENTION};
}

sub barcode {
  my $self = shift;

  if (@_) {
    if (my $oldBarcode = $self->{EVSN}) {
      delete $barcodeList{$oldBarcode};
      $self->{EVSN} = undef;
    }
    if (my $barcode = shift) {
      $barcodeList{$barcode} = $self;
      $self->{EVSN} = $barcode;
    }
  }
  return $self->{EVSN};
}

sub previousPool {
  my $self = shift;

  return $self->{PREVIOUSPOOL};
}

sub pool {
  my $self = shift;

  if (@_) {
    my $newPool = shift;

    if ((my $oldPool = $self->{POOL}) != $newPool) {
      my @masters = NBU->masters;  my $master = $masters[0];
      NBU->cmd("vmchange".
	      " -h ".$master->name.
	      " -m ".$self->id.
	      " -p ".$newPool->id);
      $self->{PREVIOUSPOOL} = $oldPool;
      $self->{POOL} = $newPool;
    }
  }
  return $self->{POOL};
}

sub group {
  my $self = shift;

  if (@_) {
    my $group = shift;
    my $update;

    if (defined($group)) {
      $update = !defined($self->{GROUP}) || ($group ne $self->{GROUP});
    }
    else {
      $update = defined($self->{GROUP});
    }
    if ($update) {
      my @masters = NBU->masters;  my $master = $masters[0];
      NBU->cmd("vmchange".
	      " -h ".$master->name.
	      " -m ".$self->id.
	      " -new_v ".(defined($group) ? $group : "---"), 0);
      $self->{GROUP} = $group;
    }
  }
  else {
    $self->populate if (!defined($filled));
  }
  return $self->{GROUP};
}

sub type {
  my $self = shift;

  if (@_) {
    $self->{MEDIATYPE} = shift;
  }

  return $self->{MEDIATYPE};
}

sub logError {
  my $self = shift;
  my ($eDate, $eType) = @_;
  $eDate = str2time($eDate);

  if (!defined($self->{ERRORHIST})) {
    $self->{ERRORHIST} = {};
  }
  my $ehR = $self->{ERRORHIST};
  $$ehR{$eDate} = $eType;

  $self->{LASTERRORDATE} = $eDate;
  $self->{LASTERRORTYPE} = $eType;

  return $self->{ERRORCOUNT} += 1;
}

sub lastError {
  my $self = shift;

  if ($self->{ERRORCOUNT} > 0) {
    return ($self->{LASTERRORDATE}, $self->{LASTERRORTYPE});
  }
  else {
    return (0, undef);
  }
}

sub errorList {
  my $self = shift;
  if (!defined($self->{ERRORHIST})) {
    $self->{ERRORHIST} = {};
  }
  my $ehR = $self->{ERRORHIST};
  return %$ehR;
}

sub errorCount {
  my $self = shift;

  return $self->{ERRORCOUNT};
}

my %cleaningTypes = (
  12 => 1,
  17 => 1,
  27 => 1,
  13 => 1,
  15 => 1,
  25 => 1,
  5 => 1,
  9 => 1,
  23 => 1,
);
sub cleaningTape {
  my $self = shift;

  return exists($cleaningTypes{$self->type});
}

sub cleaningCount {
  my $self = shift;

  if (@_ && $self->cleaningTape) {
    my $newCount = shift;
    NBU->cmd("vmchange -m ".$self->id." -n $newCount", 0);
    $self->{CLEANINGCOUNT} = $newCount;
  }
  return $self->{CLEANINGCOUNT};
}

sub mountCount {
  my $self = shift;

  if ($self->cleaningTape) {
    return $self->{CLEANINGCOUNT};
  }
  else {
    return $self->{MOUNTCOUNT};
  }
}

sub firstMounted {
  my $self = shift;

  if (@_) {
    if (@_ > 1) {
      # convert date and time to epoch seconds first
    }
    else {
      $self->{FIRSTMOUNTED} = shift;
    }
  }

  return $self->{FIRSTMOUNTED};
}

sub lastMounted {
  my $self = shift;

  if (@_) {
    if (@_ > 1) {
      # convert date and time to epoch seconds first
    }
    else {
      $self->{LASTMOUNTED} = shift;
    }
  }

  return $self->{LASTMOUNTED};
}

sub byBarcode {
  my $proto = shift;
  my $barcode = shift;


  if (my $volume = $barcodeList{$barcode}) {
    return $volume;
  }
  return undef;
}

#
# The Recorded Volume Serial Number (rvsn) is the same as the media ID hence
# the two variants of id and byID.
sub byID {
  my $proto = shift;
  my $mediaID = shift;
  my $voldbHost = shift;


  if (my $volume = $mediaList{$mediaID}) {
    return $volume;
  }
  return undef;
}

sub byRVSN {
  my $self = shift;

  return $self->byID(@_);
}

sub id {
  my $self = shift;

  if (@_) {
    $self->{RVSN} = shift;
    $mediaList{$self->{RVSN}} = $self;
  }

  return $self->{RVSN};
}
sub rvsn {
  my $self = shift;

  return $self->id(@_);
}

#
# This is the External Volume Serial Number which can sometimes be
# different than the Recorded Volume Serial Number (RVSN).
sub evsn {
  my $self = shift;

  if (@_) {
    $self->{EVSN} = shift;
  }

  return $self->{EVSN};
}

sub robot {
  my $self = shift;

  if (@_) {
    $self->{ROBOT} = shift;
  }

  return $self->{ROBOT};
}

sub slot {
  my $self = shift;

  if (@_) {
    $self->{SLOT} = shift;
  }

  return $self->{SLOT};
}

sub selected {
  my $self = shift;

  if (@_) {
    $self->{SELECTED} = shift;
  }
  return $self->{SELECTED};
}

sub mount {
  my $self = shift;

  if (@_) {
    my ($mount, $drive) = @_;
    $self->{MOUNT} = $mount;
    $self->{DRIVE} = $drive;
  }
  return $self->{MOUNT};
}

sub drive {
  my $self = shift;

  return $self->{DRIVE};
}

sub unmount {
  my $self = shift;
  my ($tm) = @_;

  if (my $mount = $self->mount) {
    $mount->unmount($tm);
  }

  $self->mount(undef, undef);
  return $self;
}

sub read {
  my $self = shift;

  my ($size, $speed) = @_;

  $self->{SIZE} += $size;
  $self->{READTIME} += ($size / $speed);
}

sub write {
  my $self = shift;

  my ($size, $speed) = @_;

  $self->{SIZE} += $size;
  $self->{WRITETIME} += ($size / $speed);
}

sub writeTime {
  my $self = shift;

  return $self->{WRITETIME};
}

sub dataWritten {
  my $self = shift;

  if (@_) {
    $self->{SIZE} = shift;
  }
  return $self->{SIZE};
}

sub allocated {
  my $self = shift;

  if (@_) {
    $self->{ALLOCATED} = shift;
  }

  return $self->{ALLOCATED};
}

sub lastWritten {
  my $self = shift;

  if (@_) {
    $self->{LASTWRITTEN} = shift;
  }

  return $self->{LASTWRITTEN};
}

sub lastRead {
  my $self = shift;

  if (@_) {
    $self->{LASTREAD} = shift;
  }

  return $self->{LASTREAD};
}

#
# This refers to the date on which the youngest image on the volume expires
# and hence the earliest date on which the volume can be de-allocated
# Note to be confused with date on which the media itself expires and henceforth
# cano no longer be used for backups altogether.
sub expires {
  my $self = shift;

  if (@_) {
    $self->{LASTIMAGEEXPIRES} = shift;
  }

  return $self->{LASTIMAGEEXPIRES};
}

sub status {
  my $self = shift;

  if (@_) {
    $self->{STATUS} = shift;
  }

  return $self->{STATUS};
}

sub maxMounts {
  my $self = shift;

  if (@_) {
    my $maxMounts = shift;
    NBU->cmd("vmchange".
            " -m ".$self->id.
            " -maxmounts $maxMounts", 0);
    $self->{MAXMOUNTS} = $maxMounts;
  }

  return $self->{MAXMOUNTS};
}

sub frozen {
  my $self = shift;

  return $self->allocated ? ($self->{STATUS} & 0x1) : undef;
}

sub freeze {
  my $self = shift;

  if ($self->allocated && !($self->{STATUS} & 0x1)) {
    # issue freeze command:
    NBU->cmd("bpmedia".
            " -h ".$self->mmdbHost->name.
            " -ev ".$self->id.
            " -freeze\n");
    $self->{STATUS} |= 0x1;
  }
  return $self;
}

sub unfreeze {
  my $self = shift;

  if ($self->allocated && ($self->{STATUS} & 0x1)) {
    # issue unfreeze command:
    NBU->cmd("bpmedia".
            " -h ".$self->mmdbHost->name.
            " -ev ".$self->id.
            " -unfreeze\n");
    $self->{STATUS} &= ~0x11;
  }
  return $self;
}

sub suspended {
  my $self = shift;

  return $self->allocated ? ($self->{STATUS} & 0x2) : undef;
}

sub unsuspend {
  my $self = shift;

  if ($self->allocated && ($self->{STATUS} & 0x2)) {
    # issue unfreeze command:
    NBU->cmd("bpmedia".
            " -h ".$self->mmdbHost->name.
            " -ev ".$self->id.
            " -unfreeze\n");
    $self->{STATUS} &= ~0x2;
  }
  return $self;
}

#
# If a Media Manager allocates a volume only to fail to write to it,
# it is possible for the volume to be frozen without having any data
# written to it, i.e. it does not even have a valid header.  This state of
# the volume is identified by status bit 4.
# This author has only observed this bit in conjunction with bit 0.  As a
# matter of fact, unfreezing such a volume will also remove bit 4
sub unmountable {
  my $self = shift;

  return (defined($self->{STATUS}) ? $self->{STATUS} & 0x10 : 0);
}

sub multipleRetentions {
  my $self = shift;

  return (defined($self->{STATUS}) ? $self->{STATUS} & 0x40 : 0);
}

sub imported {
  my $self = shift;

  return (defined($self->{STATUS}) ? $self->{STATUS} & 0x80 : 0);
}

sub mpx {
  my $self = shift;

  return (defined($self->{STATUS}) ? $self->{STATUS} & 0x200 : 0);
}

sub offsiteSessionID {
  my $self = shift;

  if (@_) {
    my $offsiteSessionID = shift;
    my $update;

    if (defined($offsiteSessionID)) {
      $update = !defined($self->{OFFSITESESSIONID}) || ($offsiteSessionID ne $self->{OFFSITESESSIONID});
    }
    else {
      $update = defined($self->{OFFSITESESSIONID});
    }
    if ($update) {
      my @masters = NBU->masters;  my $master = $masters[0];
      NBU->cmd("vmchange".
	      " -h ".$master->name.
	      " -m ".$self->id.
	      " -offsid ".(defined($offsiteSessionID) ? $offsiteSessionID : "-"), 0);
      $self->{OFFSITESESSIONID} = $offsiteSessionID;
    }
  }
  return $self->{OFFSITESESSIONID};
}

sub offsiteReturnDate {
  my $self = shift;

  if (@_) {
    my $offsiteReturnDate = shift;
    my $update;

    if (defined($offsiteReturnDate)) {
      $update = !defined($self->{OFFSITERETURN}) || ($offsiteReturnDate ne $self->{OFFSITERETURN});
    }
    else {
      $update = defined($self->{OFFSITERETURN});
    }
    if ($update) {
      my @masters = NBU->masters;  my $master = $masters[0];
      NBU->cmd("vmchange".
	      " -h ".$master->name.
	      " -m ".$self->id.
	      " -offreturn ".(defined($offsiteReturnDate) ? NBU->date($offsiteReturnDate) : "0"), 0);
      $self->{OFFSITERETURN} = $offsiteReturnDate;
    }
  }
  return $self->{OFFSITERETURN};
}

sub offsiteSentDate {
  my $self = shift;

  if (@_) {
    my $offsiteSentDate = shift;
    my $update;

    if (defined($offsiteSentDate)) {
      $update = !defined($self->{OFFSITESENT}) || ($offsiteSentDate ne $self->{OFFSITESENT});
    }
    else {
      $update = defined($self->{OFFSITESENT});
    }
    if ($update) {
      my @masters = NBU->masters;  my $master = $masters[0];
      NBU->cmd("vmchange".
	      " -h ".$master->name.
	      " -m ".$self->id.
	      " -offsent ".(defined($offsiteSentDate) ? NBU->date($offsiteSentDate) : "0"), 0);
      $self->{OFFSITESENT} = $offsiteSentDate;
    }
  }
  return $self->{OFFSITESENT};
}

sub offsiteLocation {
  my $self = shift;

  if (@_) {
    my $offsiteLocation = shift;
    my $update;

    if (defined($offsiteLocation)) {
      $update = !defined($self->{OFFSITELOCATION}) || ($offsiteLocation ne $self->{OFFSITELOCATION});
    }
    else {
      $update = defined($self->{OFFSITELOCATION});
    }
    if ($update) {
      my @masters = NBU->masters;  my $master = $masters[0];
      NBU->cmd("vmchange".
	      " -h ".$master->name.
	      " -m ".$self->id.
	      " -offloc ".(defined($offsiteLocation) ? $offsiteLocation : "-"), 0);
      $self->{OFFSITELOCATION} = $offsiteLocation;
    }
  }
  return $self->{OFFSITELOCATION};
}

sub offsiteSlot {
  my $self = shift;

  if (@_) {
    my $offsiteSlot = shift;
    my $update;

    if (defined($offsiteSlot)) {
      $update = !defined($self->{OFFSITESLOT}) || ($offsiteSlot ne $self->{OFFSITESLOT});
    }
    else {
      $update = defined($self->{OFFSITESLOT});
    }
    if ($update) {
      my @masters = NBU->masters;  my $master = $masters[0];
      NBU->cmd("vmchange".
	      " -h ".$master->name.
	      " -m ".$self->id.
	      " -offslot ".(defined($offsiteSlot) ? $offsiteSlot : "-"), 0);
      $self->{OFFSITESLOT} = $offsiteSlot;
    }
  }
  return $self->{OFFSITESLOT};
}

#
# Return true, that is a non-zero value, if the tape is indeed full.
sub full {
  my $self = shift;

  return (defined($self->{STATUS}) ? $self->{STATUS} & 0x8 : 0);
}

#
# Is the volume allocated to backing up NetBackup itself?  If not, then
# it is "available" to the media managers
sub netbackup {
  my $self = shift;

  return $self->{NETBACKUP};
}
sub available {
  my $self = shift;

  return !$self->{NETBACKUP};
}

#
# The particular value returned is the number of seconds elapsed since
# the tape was taken into service (ALLOCATED) and when it was last written.
# Think of this as the volume's retirement age :-)
# Note that this value can in fact be zero even if the tape is full.
sub fillTime {
  my $self = shift;

  return $self->full ? ($self->{LASTWRITTEN} - $self->{ALLOCATED}) : undef;
}

sub eject {
  my $self = shift;

  if ($self->robot) {
    NBU->cmd("vmchange -res"." -m ".$self->id." -mt ".$self->id.
	      " -rn ".$self->robot->id." -rc1 ".$self->slot.
	      " -rh ".$self->robot->host->name.
	      " -e -sec 1", 0);
    return $self;
  }
  else {
    return undef;
  }
}

sub removable {
  my $self = shift;

  return (defined($self->{REMOVABLE}) ? $self->{REMOVABLE} : 0);
}

#
# Insert a single fragment into this volume's table of contents
sub insertFragment {
  my $self = shift;
  my $index = shift;
  my $fragment = shift;
  
  #
  # The table of contents has one entry per file on the tape
  $self->{TOC} = [] if (!defined($self->{TOC}));
  my $toc = $self->{TOC};

  #
  # Non-removable media means disk storage unit "media".  These only
  # contain a single fragment so we force the index to zero.
  $index = 0 if (!$self->removable);

  #
  # In turn, a file on the tape can contain multiple fragments of images
  # whenever multiplexing is enabled, hence we keep so-called mpx lists for each
  # file.
  $$toc[$index] = [] if (!defined($$toc[$index]));
  my $mpxList = $$toc[$index];
  push @$mpxList, $fragment;
}

#
# Load the list of fragments for this volume into its table of
# contents.
sub loadImages {
  my $self = shift;

  $self->{TOC} = [] if (!defined($self->{TOC}));

  if (!$self->{MMLOADED} || ($self->allocated && ($self->expires > time))) {
    NBU::Image->loadImages(NBU->cmd("bpimmedia -l -mediaid ".$self->id." |"));
  }
  return $self->{TOC};
}

sub tableOfContents {
  my $self = shift;

  if (!defined($self->{TOC})) {
    $self->loadImages;
  }

  my $toc = $self->{TOC};
  return (@$toc);
}

1;

__END__

=head1 NAME

NBU::Media - Every backup volume is represented by an NBU::Media object

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

