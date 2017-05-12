#!/usr/local/bin/perl -w

use strict;

use Getopt::Std;

use NBU;

my %opts;
getopts('?vnbadfRl:c:', \%opts);

if ($opts{'?'}) {
  print <<EOT;
history.pl [-a] [-f] [-R [-l <levels>]] [-c <class-regexp>] <client-name>
EOT
  exit 0;
}

sub dispInterval {
  my $i = shift;

  return "--:--:--" if (!defined($i));

  my $seconds = $i % 60;  $i = int($i / 60);
  my $minutes = $i % 60;
  my $hours = int($i / 60);

  my $fmt = sprintf("%02d", $seconds);
  $fmt = sprintf("%02d:", $minutes).$fmt;
  $fmt = sprintf("%02d:", $hours).$fmt;
  return $fmt;
}

#
# Activate internal debugging if -d was specified
NBU->debug($opts{'d'});

#
# The remaining arguments are the names of hosts whose image history
# is to be analyzed
push @ARGV, NBU->me->name if (@ARGV == 0);
my $displayHostName = ($#ARGV > 0);
for my $clientName (@ARGV) {

  print "$clientName\:\n" if ($displayHostName);
  my $h = NBU::Host->new($clientName);

  my $n = 0;
  my %found;
  foreach my $image (sort { $b->ctime <=> $a->ctime} $h->images) {
    $n++;

    if ($opts{'c'}) {
      my $classPattern = $opts{'c'};
      next unless ($image->class->name =~ /$classPattern/);
    }
    my $key = $image->class->name."/".($opts{'n'} ? $image->schedule->name : $image->schedule->type);
    next if (!$opts{'a'} && exists($found{$key}));

    $found{$key} += 1;

    printf("%4u:", $n);

    my $id = $key;
    if ($opts{'b'}) {
      $id .= " (".$image->id.")";
    }

    print substr(localtime($image->ctime), 4)." $id";
    print " wrote ".$image->size if (defined($image->size));
    print " in ".dispInterval($image->elapsed) if ($opts{'v'});
    print " Expires ".substr(localtime($image->expires), 4);
    print "\n";
    if ($opts{'f'}) {
      for my $f ($image->fragments) {
	print "     ".$f->number.": File ".$f->fileNumber.", ".$f->size." on ".$f->volume->id." drive ".$f->driveWrittenOn." of ".$f->volume->mmdbHost->name."\n";
      }
    }
    if ($opts{'R'}) {
      $image->fileRecursionDepth($opts{'l'}) if (defined($opts{'l'}));
      for my $f ($image->fileList) {
	print "      $f\n";
      }
    }
  }
}

=head1 NAME

history.pl - Display host backup history

=head1 SYNOPSIS

history.pl [options...] <hostname>

=head1 DESCRIPTION

Using a variety of NetBackup command line tools, B<history.pl> pulls together a complete history
of all images currently in the NetBackup catalog pertaining to the referenced host.  By default
this listing will show only the most recent run of each policy/schedule combination.  The B<-a>
option will cause all images to get listed.

=head1 OPTIONS

=over 4

=item L<-a|-a>

List all occurrences of each policy/schedule combination rather than just the first one.

=item L<-n|-n>

For the purposes of determining policy/schedule combinations, the default is to key off
each schedule's type.  This option will use schedule names instead.

=item L<-b|-b>

In the image listing, include the backupid of each image.  This is useful if you are
constructing a restore command line.

=item L<-f|-f>

For each image the individual fragments are listed out.  Note that in environments where
storage units limit images to small fragment sizes this output can be quite voluminous.  However,
this option is a convenient way to get at the list of tapes used by each image.

=item L<-R|-R>

Recursively list out all the files backed up as part of this image.

=item L<-l depth|-ldepth>

By default file recursion depth is set to 1.  This means that path list entries that explictly
start at a depth already greater than 1, will not show at all!  Setting the depth to large values
will result in very long listings.

=item L<-c pattern|-cpattern>

The pattern will be applied to each policy name and only the matching policies will be displayed.  Note
that the (arbitrary) image counter still counts each and every image.

=back

=head1 SEE ALSO

=over 4

=item L<toc.pl|toc.pl>

=back

=head1 AUTHOR

Winkeler, Paul pwinkeler@pbnj-solutions.com

=head1 COPYRIGHT

Copyright (C) 2002 Paul Winkeler

=cut
