#!/usr/local/bin/perl -w

use strict;

use Getopt::Std;

use NBU;

my %opts;
getopts('dal?bRUe:', \%opts);

NBU->debug($opts{'d'});
NBU::Image->showEmptyFragments(defined($opts{'a'}));


if ($opts{'?'} || ($#ARGV < 0)) {
  print STDERR <<EOT;
Usage: toc.pl [-bRU] [-e <n>] <volume-label> [volume-label ...]
Options:
  -b          List backupid for each image

  -R          Recurse into image file list
  -U          Do NOT sort file list alphabetically

  -e          Extend expiration of all images by <n> days
EOT
  exit;
}

foreach my $label (@ARGV) {
  my $m = NBU::Media->new($label);

  my $n = 0;

  my $prefix = "";
  $prefix .= $label if ($opts{'l'});
  $prefix .= ":" if ($prefix ne "");

  foreach my $mpxList ($m->tableOfContents) {
    $n++;

    next if (!defined($mpxList));

    my $mpx = 0;
    foreach my $fragment (@$mpxList) {
      if (@$mpxList > 1) {
	print $prefix; printf("%3u.%02u:", $n, ++$mpx);
      }
      else {
	print $prefix; printf("%3u:", $n);
      }

      my $image = $fragment->image;
      print "${prefix}Fragment ".$fragment->number." of ".$image->class->name.
	    ($opts{'b'} ? " (".$image->id.")" : "").
	    " written on ".$fragment->driveWrittenOn." from ".$image->client->name.": ";
      print $fragment->offset."/".$fragment->size.": ";
      print "Created ".substr(localtime($image->ctime), 4)."; ";
      print "Expires ".substr(localtime($image->expires), 4)."\n";

      if ($opts{'e'}) {
	my $newExpiration = $image->expires + ($opts{'e'} * 60 * 60 * 24);
	print "bpexpdate -backupid ".$image->id." -client ".$image->client->name." -d ".NBU->date($newExpiration)."\n";
      }

      if ($opts{'R'}) {
	my @list = $image->fileList;
	@list = (sort @list) unless ($opts{'U'});
	for my $f (@list) {
	  print "$prefix      $f\n";
	}
      }
    }
  }
}

=head1 NAME

toc.pl - Volume table of contents listing

=head1 SYNOPSIS

    toc.pl [-bRU] [-e <n>] <volume-label> [volume-label ...]

=head1 DESCRIPTION

NetBackup's catalog of backups is maintained in the form of images where each
image maps one-to-one to a backup stream written to tape.  A volume's table
of contents then is anothing more than a list of the images contained on it.
Each entry on the tape is listed in this form:

S<E<lt>image#E<gt>[.E<lt>mpx#E<gt>]:Fragment E<lt>frag#E<gt> of E<lt>policyE<gt> written on E<lt>driveE<gt> from E<lt>serverE<gt>: E<lt>offsetE<gt>/E<lt>sizeE<gt>: Created E<lt>dateE<gt>; Expires E<lt>dateE<gt>>

Set the B<-b> option and you'll also see the image backupid value.  This is helpful when expiring specific images from a tape.

=head1 OPTIONS

=over 4

=item B<-R>

To peer inside the fragments themselves and see what files were backed up inside each of them, use
the B<-R> option.  By default the file list will be sorted alphabetically.

=item B<-U>

Setting the B<-U> option will leave the fragment's file list in its unsorted native order.

=item B<-e> E<lt>nE<gt>

All active images on a tape have their expiration extended by <n> days.  (Simply freezing a tape prevents it from being
over-written but does not keep NetBackup from expiring the images!)

=back

=head1 SEE ALSO

=over 4

=item L<volume-list.pl|volume-list.pl>, L<volume-status.pl|volume-status.pl>

=back

=head1 AUTHOR

Winkeler, Paul pwinkeler@pbnj-solutions.com

=head1 COPYRIGHT

Copyright (C) 2002 Paul Winkeler

=cut
