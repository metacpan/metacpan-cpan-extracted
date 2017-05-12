#
# Copyright (c) 2004 Paul Winkeler.  All Rights Reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself.
#
package NBU::Path;

use strict;
use Carp;

BEGIN {
  use Exporter   ();
  use AutoLoader qw(AUTOLOAD);
  use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);
  $VERSION =	 do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };
  @ISA =         qw();
  @EXPORT =      qw();
  @EXPORT_OK =   qw();
  %EXPORT_TAGS = qw();
}

#
# Disk storage unit paths are unique to a media manager only
my %pathIndexPool;

sub new {
  my $proto = shift;
  my $path = {};

  bless $path, $proto;

  if (@_) {
    my $fp = shift;
    $path->{FP} = $fp;

    my $mmHost = shift;
    if (!defined($mmHost)) {
      $mmHost = NBU::Host->new("localhost");
    }

    $pathIndexPool{$mmHost->name.":".$fp} = $path;

  }
  $path->{INUSE} = 0;
  return $path;
}

#
# Path objects return 1, just as Disk storage units do
sub type {
  my $self = shift;

  return 1;
}

sub byFP {
  my $proto = shift;
  my $fp = shift;
  my $mmHost = shift;
  my $path;

  if (!defined($mmHost)) {
    $mmHost = NBU::Host->new("localhost");
  }

  if (defined($fp) && !($path = $pathIndexPool{$mmHost->name.":".$fp})) {
    $path = NBU::Path->new($fp, $mmHost);
  }
  return $path;
}

sub pool {
  my $proto = shift;

  return (values %pathIndexPool);
}

sub fp {
  my $self = shift;

  return $self->id(@_);
}

sub id {
  my $self = shift;

  if (@_) {
    my $fp = shift;
    $self->{FP} = $fp;

    my $mmHost = shift;
    if (!defined($mmHost)) {
      $mmHost = NBU::Host->new("localhost");
    }
    $pathIndexPool{$mmHost->name.":".$fp} = $self;
  }

  return $self->{FP};
}

sub host {
  my $self = shift;

  return $self->{HOST};
}

sub busy {
  my $self = shift;

  return $self->{INUSE};
}

sub use {
  my $self = shift;
  my ($mount, $tm) = @_;

  my $uses = $self->usage;

  my %use;
  $use{'MOUNT'} = $mount;
  $mount->usedBy(\%use);

  $self->{INUSE} += 1;

  $use{'START'} = $tm;
  push @$uses, \%use;
  return $self;
}

sub mount {
  my $self = shift;

#
# This should really return a list of *ALL* active mounts!
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
  my $use = shift;

  if (!$self->{INUSE}) {
# it is quite common for a mount to inform the drive it is no
# longer using the drive sometime after the drive has been put
# to new use already.  Hence ignore this event.
#    print "Drive ".$self->id." already free!\n";
#    exit(0);
  }
  else {
    $self->{INUSE} -= 1;

    if (!defined($use)) {
      my $uses = $self->usage;
      $use = pop @$uses;
      push @$uses, $use;
    }

    $$use{'STOP'} = $tm;
  }

  return $self;
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

1;

__END__

=head1 NAME

NBU::Path - 

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

