#
# Copyright (c) 2002 Paul Winkeler.  All Rights Reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself.
#
package NBU::Image;

use strict;
use Carp;

use NBU::Media;

my %imageList;

my $fileRecursionDepth = 1;
my $showEmptyFragments = 0;

BEGIN {
  use Exporter   ();
  use AutoLoader qw(AUTOLOAD);
  use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);
  $VERSION =	 do { my @r=(q$Revision: 1.39 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };
  @ISA =         qw();
  @EXPORT =      qw();
  @EXPORT_OK =   qw();
  %EXPORT_TAGS = qw();
}

sub new {
  my $proto = shift;
  my $image;

  if (@_) {
    my $backupID = shift;
    if (exists($imageList{$backupID})) {
      $image = $imageList{$backupID};
    }
    else {
      $image = { };
      bless $image, $proto;
      $imageList{$image->id($backupID)} = $image;
    }
  }
  return $image;
}

sub populate {
  my $proto = shift;

  $proto->loadImages(NBU->cmd("bpimmedia -l |"));
}

sub byID {
  my $proto = shift;
  my $backupID = shift;

  if (exists($imageList{$backupID})) {
    return $imageList{$backupID};
  }

  return undef;
}

sub list {
  my $proto = shift;

  return (values %imageList);
}

sub id {
  my $self = shift;

  if (@_) {
    $self->{BACKUPID} = shift;
    # The backup ID of an image in part encodes the time the image was
    # created
    $self->{CTIME} = substr($self->{BACKUPID}, -10);
  }
  return $self->{BACKUPID};
}

sub ctime {
  my $self = shift;

  return $self->{CTIME};
}

sub client {
  my $self = shift;

  if (@_) {
    my $host = shift;
    if (defined($self->{CLIENT})) {
      if ((my $oldHost = $self->{CLIENT}) == $host) {
	return $host;
      }
      else {
#	$oldHost->removeImage($self);
      }
    }
    $host->addImage($self);
    $self->{CLIENT} = $host;
  }
  return $self->{CLIENT};
}

sub class {
  my $self = shift;

  return $self->policy(@_);
}

sub policy {
  my $self = shift;

  if (@_) {
    $self->{POLICY} = shift;
  }
  return $self->{POLICY};
}

sub schedule {
  my $self = shift;

  if (@_) {
    $self->{SCHEDULE} = shift;
  }
  return $self->{SCHEDULE};
}

sub expires {
  my $self = shift;

  if (@_) {
    $self->{EXPIRES} = shift;
  }
  return $self->{EXPIRES};
}

sub loadDetail {
  my $self = shift;

  #
  # Layout of this output divined from 
  # http://mailman.eng.auburn.edu/pipermail/veritas-bu/2001-May/003861.html
  my $pipe = NBU->cmd("bpimagelist -l -backupid ".$self->id." |");
  while (<$pipe>) {
    next if (/^HIST/);
    next if (/^FRAG/);
    if (/^IMAGE/) {
      my ($tag, $clientName,
	  $u3, $u4, $u5,
	  $id, $className,
	  $u8, $u9, $u10,
	  $scheduleName,
	  $u12, $u13, $u14,
	  $elapsed,
	  $u16, $u17, $u18,
	  $kbWritten,
	  $fileCount, $copyCount, $fragmentCount,
	  $compressed, $u24,
	  $softwareVersion, $u26, $u27,
	  $primary,
	  $imageType, $TIRInfo, $TIRExpiration,
	  $keywords
      ) = split;
      $self->{ELAPSED} = $elapsed;
    }
  }
  $self->{DETAILED} = 1;
  close($pipe);
}

sub elapsed {
  my $self = shift;

  $self->loadDetail if (!defined($self->{DETAILED}));

  return $self->{ELAPSED};
}

sub retention {
  my $self = shift;

  if (@_) {
    $self->{RETENTION} = shift;
  }
  return $self->{RETENTION};
}


sub size {
  my $self = shift;
  my $size;

  for my $f ($self->fragments) {
    next unless defined($f);
    $size += $f->size;
  }

  return $size;
}

#
# Add another fragment to the referenced copy of this image
sub insertFragment {
  my $self = shift;
  my $copy = shift;
  my $fragment = shift;
  
  my $fragmentListR = $self->{FRAGMENTLISTS};
  if (!defined(@$fragmentListR[$copy])) {
    @$fragmentListR[$copy] = [];
  }
  my $toc = @$fragmentListR[$copy];;

  return $$toc[$fragment->number - 1] = $fragment;
}

sub fragments {
  my $self = shift;

  my $fragmentListR = $self->{FRAGMENTLISTS};
  if (@_) {
    my $copy = shift;
    if (!defined(@$fragmentListR[$copy])) {
      return ();
    }
    my $toc = @$fragmentListR[$copy];;
    return @$toc;
  }

  my @toc;
  foreach my $copy (1..$self->copies) {
    if (defined(@$fragmentListR[$copy])) {
      my $copytoc = @$fragmentListR[$copy];
      @toc = (@toc, @$copytoc);
    }
  }
  return @toc;
}

sub loadImages {
  my $proto = shift;
  my $pipe = shift;

  my $image;
  while (<$pipe>) {
    if (/^IMAGE/) {
      my ($tag, $clientName, $clientVersion, $backupID, $className,
	$classType,
	$scheduleName,
	$scheduleType,
	$retentionLevel, $fileCount, $expires,
	$compressed, $encrypted
      ) = split;

      $image = undef;
      next if ($expires < time);

      $image = NBU::Image->new($backupID);
      $image->{ENCRYPTED} = $encrypted;
      $image->{COMPRESSED} = $compressed;
      $image->{FILECOUNT} = $fileCount;
      $image->{EXPIRES} = $expires;
      $image->{RETENTION} = NBU::Retention->byLevel($retentionLevel);
      $image->{COPYCOUNT} = 0;
      $image->{FRAGMENTLISTS} = [];

      my $class = $image->class(NBU::Class->new($className, $classType));
      $image->schedule(NBU::Schedule->new($class, $scheduleName, $scheduleType));

      my $host;
      $image->client($host = NBU::Host->new($clientName));
    }
    elsif (/^FRAG/) {
      next if (!defined($image));

      my ($tag, $copy, $number, $size, $removable,
	  $mediaType, $density, $fileNumber,
          $rest) = split(/[\s]+/, $_, 9);

      #
      # The fragment list contains failed fragments which are left-overs from
      # failed backups.  Normally we skip these, but they can be made visible
      # when running diagnostics
      # Such fragments appear to be identified by having a negative fragment number
      next if (!$showEmptyFragments && (($number < 1)));

      #
      # Is this the start of a new copy of this image?
      if ($copy > $image->{COPYCOUNT}) {
	$image->{COPYCOUNT} = $copy;
      }

      my ($mediaID, $volume);
      if (($removable == 0) && ($mediaType == 0)) {
        #
        # Non-removable media (aka disk files) occasionally have spaces in their
        # names and those will then be surrounded by double quotes...
        # Additionally we tag these "media" as removable when creating them.
        if ($rest =~ s/\"(.*)\"[\s]//) {
	  $mediaID = $1;
        }
        else {
	  $rest =~ s/([\S]+)//;
	  $mediaID = $1;
        }
        $volume = NBU::Media->new($mediaID, undef, 0);
      }
      else {
	$rest =~ s/([\S]+)//;
	$mediaID = $1;
        $volume = NBU::Media->new($mediaID, undef, 1);
        $volume->density($density);
      }
      $rest =~ s/^[\s]*//;
      my ($mmdbHostName,
	  $blockSize, $offset, $allocated, $dwo,
	  $u6, $u7,
	  $expires, $mpx
      ) = split(/[\s]+/, $rest);
      $volume->mmdbHost(NBU::Host->new($mmdbHostName));

      my $fragment = NBU::Fragment->new($number, $copy, $image, $volume, $offset, $size, $dwo, $fileNumber, $blockSize);

      $volume->insertFragment($fileNumber - 1, $fragment);
      $image->insertFragment($copy, $fragment);

      $image->{REMOVABLE} += $volume->removable;

      $image->volume($volume);
    }
  }
  close($pipe);
}

sub loadFileList {
  my $self = shift;
  my $func = shift;
  my $depth = shift;
  my @fl;
 
  my ($s, $m, $h, $dd, $mon, $year, $wday, $yday, $isdst) = localtime($self->ctime);
  my $mm = $mon + 1;
  my $yy = sprintf("%02d", ($year + 1900) % 100);

  $depth = $fileRecursionDepth if (!defined($depth));
  my $pipe = NBU->cmd("bpflist -t ANY"
    ." -option GET_ALL_FILES"
    ." -client ".$self->client->name
    ." -backupid ".$self->id
    ." -d ${mm}/${dd}/${yy}"
    ." -rl $depth"
    ." |");

  while (<$pipe>) {
    next if (/^FILES/);
    chop;
    #
    # Since file names can contain spaces and some bright soul decided to place the file
    # name in the middle of this line, we need to pick it apart in three pieces:
    #  before, filename, after
    # More details at https://forums.symantec.com/syment/board/message?board.id=21&thread.id=5475
    my ($i, $compressedFileSize, $pathLength, $u3, $offset,
            $imageMode, $rawPartitionSize,
            $largeFileSize, # only set if file over 2GB; units are in GB
            $physicalDeviceNumber,
        $rest) = split(/[\s]+/, $_, 10);
    if (!($rest =~ /^(.*)[\s]([\S]+)[\s]([\S]+)[\s]([\S]+)[\s]([\S]+)[\s]([\S]+)[\s]([\S]+)[\s]([\S]+)/)) {
      print STDERR "IMAGE filename match failed on $_\n";
      exit;
    }
    my ($name, $mode, $user, $group, $size,
               $lastAccessed, $lastModified, $lastInodeModified
       ) = ($1, $2, $3, $4, $5, $6. $7, $8);
#    next if ($name =~ /(\/|\\)$/);
    if (defined($func)) {
      &$func($name);
    }
    else {
      push @fl, $name;
    }
  }
  close($pipe);

  if (!defined($func)) {
    $self->{FLIST} = \@fl;
  }
}

sub fileList {
  my $self = shift;

  if (!$self->{FLIST}) {
    $self->loadFileList(undef, undef);
  }

  if (my $flR = $self->{FLIST}) {
    return @$flR;
  }
  return undef;
}

sub copies {
  my $self = shift;

  return $self->{COPYCOUNT};
}

#
# An image is considered removable if any of its fragments is
# is stored on removable media.  This attribute is computed during
# the loading if the image
sub removable {
  my $self = shift;

  return $self->{REMOVABLE};
}

sub density {
  my $self = shift;

  return $self->volume->density
    if ($self->volume);
  return undef;
}

sub showEmptyFragments {
  my $proto = shift;

  if (@_) {
    $showEmptyFragments = shift;
  }

  return $showEmptyFragments;
}

sub fileRecursionDepth {
  my $proto = shift;

  if (@_) {
    $fileRecursionDepth = shift;
  }

  return $fileRecursionDepth;
}

sub volume {
  my $self = shift;

  if (@_) {
    my $volume = shift;

    $self->{VOLUME} = $volume;
  }

  return $self->{VOLUME};
}

1;

__END__

=head1 NAME

NBU::Image - Support for NetBackup Images, i.e. discrete backup sets

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

