#
# Copyright (c) 2002 Paul Winkeler.  All Rights Reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself.
#
package NBU::License;

use Date::Parse;

use strict;
use Carp;

BEGIN {
  use Exporter   ();
  use AutoLoader qw(AUTOLOAD);
  use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);
  $VERSION =	 do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };
  @ISA =         qw();
  @EXPORT =      qw();
  @EXPORT_OK =   qw();
  %EXPORT_TAGS = qw();
}

my %legit;
my %licenses;
my %featureDescriptions;
my %productDescriptions;

sub new {
  my $proto = shift;
  my $License = { };

  bless $License, $proto;

  if (@_) {
    my $server = shift;
    my $key = shift;


    if (exists($licenses{$key})) {
      return $licenses{$key};
    }

    $License->{KEY} = $key;
    $License->{BASEKEY} = shift;

    $License->{FEATURES} = [];

    $License->{INSTALLS} = {};

    $licenses{$key} = $License;
  }

  return $License;
}

sub populate {
  my $proto = shift;
  my $master = shift;
  my $mmOnlyP = shift;
  my @masters;

  if (!defined($master)) {
    @masters = NBU->masters;
  }
  else {
    push @masters, $master;
  }


  for $master (@masters) {
    next if (exists($legit{$master->name}));

    $legit{$master->name} = 0;
    die "Could not open license pipe\n" unless my $pipe = NBU->cmd("bpminlicense -M ".$master->name." -nb_features -verbose |");
    my $l;
    my ($baseKey, $key);
    my ($installHost, $installDate);
    while (<$pipe>) {
      chop; s/[\s]*$//;
      if (/^[\S]+/) {
        $l->install($installHost, $installDate) if (defined($l));
	($baseKey, $key) = split;
	$l = $proto->new($master, $baseKey, $key);
	next;
      }
      if (/^  file version[\s]+= ([\S]+)$/) {
	$l->{FILEVERSION} = $1;
	next;
      }

      if (/^  time added[\s]+= ([\S]+) (.*)$/) {
	$installDate = str2time($2);
	next;
      }
      if (/^  hostname[\s]+= ([\S]+)$/) {
	$installHost = NBU::Host->new($1);
	next;
      }

      if (/^  product ID[\s]+= ([\S]+) (.*)$/) {
	my $id = $1;
	my $description = $2;
	$l->{PRODUCT} = $id;
	$productDescriptions{$id} = $description;
	next;
      }
      if (/^  serial number[\s]+= ([\S]+)$/) {
	$l->{SERIALNUMBER} = $1;
	next;
      }
      if (/^  key version[\s]+= ([\S]+)$/) {
	$l->{KEYVERSION} = $1;
	next;
      }
      if (/^  count[\s]+= ([\S]+)$/) {
	$l->{COUNT} = $1;
	next;
      }
      if (/^  server platform[\s]+= ([\S]+) (.*)$/) {
	$l->{SERVERPLATFORM} = $1;
	next;
      }
      if (/^  client platform[\s]+= ([\S]+) (.*)$/) {
	$l->{CLIENTPLATFORM} = $1;
	next;
      }
      if (/^  server tier[\s]+= ([\S]+) (.*)$/) {
	$l->{SERVERTIER} = $1;
	next;
      }
      if (/^  client tier[\s]+= ([\S]+) (.*)$/) {
	$l->{CLIENTTIER} = $1;
	next;
      }
      if (/^  license type[\s]+= ([\S]+) (.*)$/) {
	$l->{TYPE} = $1;
	next;
      }
      if (/^  Site ID[\s]+= ([\S]+) (.*)$/) {
	$l->{SITEID} = $1;
	next;
      }
      if (/^  Feature ID[\s]+= ([\S]+) (.*)$/) {
	my $id = $1;
	my $description = $2;
	my $fRef = $l->{FEATURES};
	push @$fRef, $id;
	$featureDescriptions{$id} = $description;
	next;
      }
      if (/^  Expiration[\s]+= (Not e|E)xpired (.*)$/) {
	$l->{EXPIRATION} = str2time($2);
	next;
      }
      if (/^  Time Left[\s]+=/) {
	next;
      }
      if (/^  Firm Expiration[\s]+=/) {
	next;
      }
      print STDERR "Unknown line in bpminlicense output: \"$_\"\n";
      $legit{$master->name} += 1;
    }
    $l->install($installHost, $installDate);
    close($pipe);


    #
    # If we're inspecting a master, retrieve license keys from active
    # media managers as well
    next if ($mmOnlyP);
    foreach my $ms (NBU::StorageUnit->mediaServers($master)) {
      next if (exists($legit{$ms->name}));
      NBU::License->populate($ms, 1);
    }

  }
}

sub install {
  my $self = shift;
  my ($host, $date) = @_;

  my $installs = $self->{INSTALLS};
  $$installs{$host->name} = $date;
}

sub hosts {
  my $self = shift;
  my $installs = $self->{INSTALLS};

  return (keys %$installs);
}

sub key {
  my $self = shift;

  return $self->{KEY};
}

sub list {
  my $proto = shift;

  return (values %licenses);
}

sub product {
  my $self = shift;

  return $self->{PRODUCT};
}

sub type {
  my $self = shift;

  return $self->{TYPE};
}

sub serverTier {
  my $self = shift;

  return $self->{SERVERTIER};
}

sub expiration {
  my $self = shift;

  return defined($self->{EXPIRATION}) ? $self->{EXPIRATION} : undef;
}

sub features {
  my $self = shift;

  my $fRef = $self->{FEATURES};
  return (@$fRef);
}

sub demonstration {
  my $self = shift;

  # as gleaned from get_license_key script
  return ($self->{TYPE} == 0) || ($self->{TYPE} == 5);
}


my %class2feature = (
  0 => 20,		# Standard
#  3 => "Apollo_WBAK",
  4 => 36,		# Oracle
#  6 => "Informix",
#  7 => "Sybase",
#  10 => "NetWare",
#  11 => "BackTrack",
#  12 => "Auspex_Fastback",
  13 => 20,		# Windows_NT
  14 => 20,		# OS2
#  15 => "SQL_Server",
#  16 => "Exchange",
  17 => 40,		# SAP
#  18 => "DB2",
#  19 => "NDMP",
#  20 => "FlashBackup",
#  21 => "SplitMirror",
#  22 => "AFS",
);

my $blanketFeatureCode = 21;
sub licenseForClass {
  my $proto = shift;
  my $classType = shift;
  my $host = shift;

  if (defined(my $featureCode = $class2feature{$classType})) {
  }
}

#
# Given a feature code, return all license (on the optional host) that
# provide the requested feature
sub licensesForFeature {
  my $proto = shift;
  my $featureCode = shift;
  my $host = shift;

  my %list;

  $proto->populate($host);
  for my $l (values %licenses) {
    next if (defined($host) && ($l->host != $host));

    for my $f ($l->features) {
      $list{$l->key} = $l if ($f == $featureCode);
    }
  }
  return (values %list);
}

sub productDescription {
  my $proto = shift;
  my $productCode = shift;

  return $productDescriptions{$productCode};
}

sub featureDescription {
  my $proto = shift;
  my $featureCode = shift;

  return $featureDescriptions{$featureCode};
}

1;

__END__

=head1 NAME

NBU::License - Support for NetBackup licensing information gathering

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

