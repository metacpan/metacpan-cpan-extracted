#
# Copyright (c) 2002 Paul Winkeler.  All Rights Reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself.
#
package NBU::Mount;

use strict;
use Carp;

use NBU::Drive;
use NBU::Path;

BEGIN {
  use Exporter   ();
  use AutoLoader qw(AUTOLOAD);
  use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);
  $VERSION =	 do { my @r=(q$Revision: 1.13 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };
  @ISA =         qw();
  @EXPORT =      qw();
  @EXPORT_OK =   qw();
  %EXPORT_TAGS = qw();
}

sub new {
  my $class = shift;
  my $mount = {
  };

  bless $mount, $class;

  if (@_) {
    my ($job, $volume, $drive, $tm) = @_;

    #
    # The bpdbjobs output, for example, is devoid of drive
    # references hence we may not be able to record an actual
    # mount event at this time...
    if (defined($drive)) {
      $mount->drive($drive)->use($mount, $tm);
      $volume->mount($mount, $drive, $tm);
    }

    $mount->{JOB} = $job;
    $mount->{TARGET} = $volume;
    $mount->{MOUNTTIME} = $tm;
    $mount->{MOUNTDELAY} = $tm - $volume->selected
      if ($volume->selected);

  }

  return $mount;
}

sub job {
  my $self = shift;

  return $self->{JOB};
}

sub unmount {
  my $self = shift;
  my $job = $self->{JOB};

  my $tm = $self->{UNMOUNTTIME} = shift;


  if (defined($job->mount)) {
    if ($job->mount == $self) {
      $job->mount(undef);
    }

    $self->drive->free($tm, $self->usedBy)
      if ($self->drive);
  }

  return $self->{UNMOUNTTIME};
}

sub start {
  my $self = shift;

  return $self->{MOUNTTIME};
}

sub stop {
  my $self = shift;

  return $self->{UNMOUNTTIME};
}

sub startPositioning {
  my $self = shift;
  my $fileNumber = shift;
  my $tm = shift;

}

sub positioned {
  my $self = shift;
  my $tm = shift;

}

sub mountPoint {
  my $self = shift;

  if (@_) {
    $self->{MP} = shift;
  }
  return $self->{MP};
}

sub drive {
  my $self = shift;

  return $self->mountPoint(@_);
}

sub path {
  my $self = shift;

  return $self->mountPoint(@_);
}

sub target {
  my $self = shift;

  return $self->{TARGET};
}

sub volume {
  my $self = shift;

  return $self->target(@_);
}

sub file {
  my $self = shift;

  return $self->target(@_);
}

sub usedBy {
  my $self = shift;

  if (@_) {
    $self->{USEDBY} = shift;
  }
  return $self->{USEDBY};
}

sub read {
  my $self = shift;

  my ($fragmentNumber, $size, $speed) = @_;

  $self->{FRAGMENT} = $fragmentNumber;

  #
  # Grow size and keep running average speed
  $self->{SIZE} += $size;
  $self->{READINGTIME} += ($size / $speed);
  $self->{SPEED} = $self->{SIZE} / $self->{READINGTIME};

  $self->volume->read($size, $speed);

  return $self;
}

sub write {
  my $self = shift;

  my ($fragmentNumber, $size, $speed) = @_;

  $self->{FRAGMENT} = $fragmentNumber;

  #
  # Grow size and keep running average speed
  $self->{SIZE} += $size;
  $self->{WRITINGTIME} += ($size / $speed);
  $self->{SPEED} = $self->{SIZE} / $self->{WRITINGTIME};

  $self->volume->write($size, $speed);

  return $self;
}

sub speed {
  my $self = shift;

  return $self->{SPEED};
}

sub writeTime {
  my $self = shift;

  if (my $speed = $self->{SPEED}) {
    my $size = $self->{SIZE};
    return ($size / $speed);
  }
  return undef;
}

sub dataRead {
  my $self = shift;

  return $self->data(@_);
}

sub dataWritten {
  my $self = shift;

  return $self->data(@_);
}

sub data {
  my $self = shift;

  return $self->{SIZE};
}

1;

__END__

=head1 NAME

NBU::Mount - Model NetBackup mount events in the course of a backup job

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

