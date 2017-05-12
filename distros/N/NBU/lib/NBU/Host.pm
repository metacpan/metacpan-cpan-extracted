#
# Copyright (c) 2002 Paul Winkeler.  All Rights Reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself.
#
package NBU::Host;

use strict;
use Carp;

my %hostList;

BEGIN {
  use Exporter   ();
  use AutoLoader qw(AUTOLOAD);
  use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);
  $VERSION =	 do { my @r=(q$Revision: 1.33 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };
  @ISA =         qw();
  @EXPORT =      qw();
  @EXPORT_OK =   qw();
  %EXPORT_TAGS = qw();
}

my %aliases;
sub loadAlias {
  my $proto = shift;
  my ($alias, $canonical) = @_;

  $aliases{$alias} = $canonical;
}

sub new {
  my $proto = shift;
  my $host;

  if (@_) {
    my $name = shift;
    $name = $aliases{$name} if (exists($aliases{$name}));
#    my $keyName = substr($name, 0, 12);
    my $keyName = $name;

    if (!($host = $hostList{$keyName})) {
      $host = {};
      bless $host, $proto;
      $host->{NAME} = $name;

      $hostList{$keyName} = $host;

      $host->{ENROLLED} = 0;
      $host->{MM} = 0;
      $host->{MMTYPE} = 0;
    }
  }
  return $host;
}

sub populate {
  my $proto = shift;

  my $pipe = NBU->cmd("bpclclients -allunique -noheader |");
  while (<$pipe>) {
    my ($platform, $os, $name) = split;
    my $host = NBU::Host->new($name);

    $host->os($os);
    $host->platform($platform);
  }
  close($pipe);
}

sub byName {
  my $proto = shift;
  my $name = shift;
  my $keyName = substr($name, 0, 12);

  if (my $host = $hostList{$keyName}) {
    return $host;
  }
  return undef;
}

sub list {
  my $proto = shift;

  return (values %hostList);
}

sub enrolled {
  my $self = shift;

  $self->{ENROLLED} = 1;
}

sub mediaManager {
  my $self = shift;

  if (@_) {
    $self->{MM} = shift;
  }
  return $self->{MM};
}

sub roboticMediaManager {
  my $self = shift;

  if (@_) {
    $self->{MMTYPE} = shift;
  }
  return $self->{MMTYPE};
}

sub loadClasses {
  my $self = shift;

  NBU::Pool->populate;

  my $pipe = NBU->cmd("bpcllist -byclient ".$self->name." -l |");
  NBU::Class->loadClasses($pipe, "CLIENT", $self->clientOf);

  close($pipe);
}

sub makeClassMember {
  my $self = shift;
  my $newClass = shift;

  if (!defined($self->{CLASSES})) {
    $self->{CLASSES} = [];
  }

  my $classesR = $self->{CLASSES};
  push @$classesR, $newClass;

  return $newClass;
}

sub classes {
  my $self = shift;

  $self->loadClasses if (!$self->{ENROLLED});

  my $classesR = $self->{CLASSES};
  if (defined($classesR)) {
    return (@$classesR);
  }
  return ();
}

sub name {
  my $self = shift;

  return $self->{NAME};
}

sub loadConfig {
  my $self = shift;

  return 1 if ($self->{CONFIGLOADED});
  $self->{PLATFORM} = undef;
  $self->{OS} = undef;
  $self->{NBUVERSION} = undef;
  $self->{RELEASE} = undef;
  $self->{RELEASEID} = undef;
  $self->{CONFIGLOADED} = 1;

  my $pipe = NBU->cmd("bpgetconfig -g ".$self->name." |");
  unless (defined($_ = <$pipe>)) { close($pipe); return; } chop;  s/[\s]*$//;
  if (/Client of ([\S]+)/) {
    $self->{MASTER} = NBU::Host->new($1);
    NBU->addMaster($self->{MASTER});
  }
  else {
    $self->{MEDIASERVER} = 1;
  }

  # OS on this machine
  unless (defined($_ = <$pipe>)) { close($pipe); return; } chop;  s/[\s]*$//;
  if (/^([\S]+), ([\S]+)$/) {
    $self->{PLATFORM} = $1;
    $self->{OS} = $2;
  }
  else {
    $self->{PLATFORM} = $self->{OS} = $_;
  }

  # Now get the NetBackup version information
  # All the hosts in the cluster better be running the same version
  # but we're not checking for that at this time.
  unless (defined($_ = <$pipe>)) { close($pipe); return; } chop;  s/[\s]*$//;
  $self->{NBUVERSION} = $_;

  # Product identifier
  unless (defined($_ = <$pipe>)) { close($pipe); return; } chop;  s/[\s]*$//;

  if (defined($_ = <$pipe>)) {
    chop;  s/[\s]*$//;
    $self->{RELEASE} = $_;
  }

  if (defined($_ = <$pipe>) && ($_ !~ /^[\s]*$/)) {
    chop;  s/[\s]*$//;
    $self->{RELEASEID} = $_;
  }
  else {
    $self->{RELEASEID} = "000000";
  }

  if ($self->releaseID >= "450000") {
    # Install path
    return unless defined($_ = <$pipe>);  chop;  s/[\s]*$//;
    # Detailed OS
    return unless defined($_ = <$pipe>);  chop;  s/[\s]*$//;
    my ($os, $v) = split;
    $self->{OS} = $os;
  }
 
  close($pipe);

  # The -f option used to tell us, when we were media managers,
  # which host was our master with the "Client of" line.  With 4.5 this
  # feature has been removed.  Now we run bpgetconfig against ourselves
  # and use the "first server in the list must be the master" rule.
  $pipe = NBU->cmd("bpgetconfig -X |");
  while (<$pipe>) {
    if ((/SERVER = ([\S]+)/) && !defined($self->{MASTER})) {
      $self->{MASTER} = NBU::Host->new($1);
    }
    if (/EMMSERVER = ([\S]+)/) {
      $self->{EMMSERVER} = NBU::Host->new($1);
    }
  }
  close($pipe);

  my $detailAvailable;
  $pipe = NBU->cmd("bpclient -All -FI |");
  unless (defined($_ = <$pipe>)) { close($pipe); return; } chop;  s/[\s]*$//;
  while (<$pipe>) {
    if (/$self->name/i) {
      $detailAvailable = 1;
      last;
    }
  }
  close($pipe);

  if ($detailAvailable) {
    $pipe = NBU->cmd("bpclient -client ".$self->name." -l |");
    unless (defined($_ = <$pipe>)) { close($pipe); return; } chop;  s/[\s]*$//;
    close($pipe);
  }
}

sub clientOf {
  my $self = shift;

  $self->loadConfig;
  return $self->{MASTER};
}

sub EMMserver {
  my $self = shift;

  $self->loadConfig;
  return $self->{EMMSERVER};
}

sub platform {
  my $self = shift;

  if (@_) {
    $self->{PLATFORM} = shift;
  }
  else {
    $self->loadConfig;
  }

  return $self->{PLATFORM};
}

sub os {
  my $self = shift;

  if (@_) {
    $self->{OS} = shift;
  }
  else {
    $self->loadConfig;
  }

  return $self->{OS};
}

sub NBUVersion {
  my $self = shift;

  if (@_) {
    $self->{NBUVERSION} = shift;
  }
  else {
    $self->loadConfig;
  }

  return $self->{NBUVERSION};
}

sub NBUmajorVersion {
  my $self = shift;

  $self->NBUVersion =~ /^([\d])\.([\d\.]*$)/;
  return $1;
}

sub IPaddress {
  my $self = shift;

  if (!defined($self->{IPADDRESS})) {
    my $rawAddress = (gethostbyname($self->name))[4];
    my @octets = unpack("C4", $rawAddress);
    $self->{IPADDRESS} = join(".", @octets);
  }

  return $self->{IPADDRESS};
}

sub release {
  my $self = shift;

  if (@_) {
    $self->{RELEASE} = shift;
  }
  else {
    $self->loadConfig;
  }

  return $self->{RELEASE};
}

sub releaseID {
  my $self = shift;

  if (@_) {
    $self->{RELEASEID} = shift;
  }
  else {
    $self->loadConfig;
  }

  return $self->{RELEASEID};
}

sub loadCoverage {
  my $self = shift;
  my $name = $self->name;

  my %coverage;
  my $loadOK;

  my $pipe = NBU->cmd("bpcoverage -c $name -no_cov_header -no_hw_header |");
  while (<$pipe>) {
    if (!$loadOK) {
      if (/^CLIENT: $name/) {
	while (<$pipe>) {
          last if (/Mount Point/ || /Drive Letter/);
	}
        $_ = <$pipe>;
        $loadOK = 1;
      }
    }
    elsif ($loadOK && !(/^[\s]*$/) && !(/   Exit status/)) {
      #
      # Preserve input line in local variable because some methods called below
      # open other streams and thus clobber the global $_!
      my $l = $_;

      if ($self->os =~ /rs6000_42|SunOS|[Ss]olaris|linux|hp10.20/) {
        $_ = $l;
	my ($mountPoint, @remainder) = split;
	my ($deviceFile, $className, $status) = @remainder;

	next if ($deviceFile !~ /^\//);

        if ($className eq "UNCOVERED") {
	  $coverage{$mountPoint} = undef;
        }
        else {
	  $className =~ s/^\*//;
	  my $clR = $coverage{$mountPoint};
	  if (!$clR) {
	    $coverage{$mountPoint} = $clR = [];
	  }
	  my $class = NBU::Class->byName($className, $self->clientOf);
	  $class->providesCoverage(1);
          push @$clR, $class;
        }
      }
      elsif ($self->os =~ /Windows(NET|NT|2000|2003|XP)/) {
        $_ = $l;
        s/^[\s]*([\S].*:.)//;  my $mountPoint = $1;
        my (@remainder) = split;
	my $deviceFile;

	if ((($self->releaseID eq "451000") && defined($self->{MEDIASERVER}))) {
	  $deviceFile = shift @remainder;
	}
        my ($className, $status) = @remainder;
        if ($className eq "UNCOVERED") {
	  $coverage{$mountPoint} = undef;
        }
        else {
	  $className =~ s/^\*//;
	  my $clR = $coverage{$mountPoint};
	  if (!$clR) {
	    $coverage{$mountPoint} = $clR = [];
	  }
	  my $class = NBU::Class->byName($className, $self->clientOf);
          print STDERR "Unknown class referenced: $className\n" if (!defined($class));
	  $class->providesCoverage(1);
          push @$clR, $class;
        }
      }
      else {
        print "coverage from ".$self->os.": $_";
      }
    }
    else {
      last;
    }
  }
  close($pipe);

  $self->{COVERAGE} = \%coverage;
}

sub coverage {
  my $self = shift;

  if (!$self->{COVERAGE}) {
    $self->loadCoverage;
  }

  my $coverageR = $self->{COVERAGE};
  return (%$coverageR);
}

#
# Add an image to a host's list of backup images
sub addImage {
  my $self = shift;
  my $image = shift;
  
  $self->{IMAGES} = {} if (!defined($self->{IMAGES}));

  my $images = $self->{IMAGES};

  $$images{$image->id} =  $image;
}

#
# Load the list of images run against this host
sub loadImages {
  my $self = shift;

  if (!defined($self->{ALLIMAGES})) {
    NBU::Image->loadImages(NBU->cmd("bpimmedia -l -client ".$self->name." |"));
  }
  return ($self->{ALLIMAGES} = $self->{IMAGES});
}

sub images {
  my $self = shift;

  $self->loadImages;

  if (defined(my $images = $self->{IMAGES})) {
    return (values %$images);
  }
  else {
    return ();
  }
}

1;

__END__

=head1 NAME

NBU::Host - Implements support for clients, Media Servers and Masters alike

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

