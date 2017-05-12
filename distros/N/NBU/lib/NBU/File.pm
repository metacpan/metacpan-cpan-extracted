#
# Copyright (c) 2004 Paul Winkeler.  All Rights Reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself.
#
package NBU::File;

use strict;
use Carp;

use Date::Parse;

BEGIN {
  use Exporter   ();
  use AutoLoader qw(AUTOLOAD);
  use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);
  $VERSION =	 do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };
  @ISA =         qw();
  @EXPORT =      qw(%densities);
  @EXPORT_OK =   qw();
  %EXPORT_TAGS = qw();
}

my %fileList;

sub new {
  my $proto = shift;
  my $file = {};

  bless $file, $proto;

  if (@_) {
    my $baseName = shift;

    if (exists($fileList{$baseName})) {
      return $fileList{$baseName};
    }

    $file->{BASENAME} = $baseName;
    $fileList{$file->{BASENAME}} = $file;
  }
  return $file;
}

sub listIDs {
  my $proto = shift;

  return (keys %fileList);
}

sub listFiles {
  my $proto = shift;

  return (values %fileList);
}

sub list {
  my $proto = shift;

  return ($proto->listFiles);
}

sub id {
  my $self = shift;

  if (@_) {
    $self->{BASENAME} = shift;
    $fileList{$self->{BASENAME}} = $self;
  }

  return $self->{BASENAME};
}

sub baseName {
  my $self = shift;

  return $self->id(@_);
}

#
# Unlike the process of choosing a particular tape volume for a backup,
# selecting a file has no meaning
sub selected {
  my $self = shift;

  return undef;
}

sub retention {
  my $self = shift;

  if (@_) {
    my $retention = shift;
    $self->{RETENTION} = $retention;
  }

  return $self->{RETENTION};
}

sub mount {
  my $self = shift;

  if (@_) {
    my ($mount, $path) = @_;
    $self->{MOUNT} = $mount;
    $self->{PATH} = $path;
  }
  return $self->{MOUNT};
}

sub path {
  my $self = shift;

  return $self->{PATH};
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

#
# Insert a single fragment into this volume's table of contents
sub insertFragment {
  my $self = shift;
  my $index = shift;
  my $fragment = shift;
  
  $self->{TOC} = [] if (!defined($self->{TOC}));

  my $toc = $self->{TOC};

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
#    NBU::Image->loadImages(NBU->cmd("bpimmedia -l -mediaid ".$self->id." |"));
print STDERR "Cannot load images of a file!\n";
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

NBU::File - Support for data on individually backed up files

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

