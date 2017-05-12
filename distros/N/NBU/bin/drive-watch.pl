#!/usr/local/bin/perl

use strict;

use Getopt::Std;

my $interval = 5 * 60;

my %opts;
getopts('dM:i:n:', \%opts);
if (defined($opts{'i'})) {
  $interval = $opts{'i'};
}
my $notify = "";
$notify .= ",".$opts{'n'} if ($opts{'n'});

use NBU;
NBU->debug($opts{'d'});

my $master;
if ($opts{'M'}) {
  $master = NBU::Host->new($opts{'M'});
}
else {
  my @masters = NBU->masters;  $master = $masters[0];
}
my @mediaManagers;
foreach my $server (NBU::StorageUnit->mediaServers($master)) {
  if (NBU::Drive->populate($server)) {
    push @mediaManagers, $server;
  }
}

sub msg {
  my $self = shift;
  my $state = shift;

  #
  # Start counting down drives at one since we are about to be marked as such
  my $down = 1;
  my $total = 0;
  for my $d (NBU::Drive->pool) {
    next unless ($d->known);
    $total++;
    $down++ if ($d->down);
  }

  open (PIPE, "| /usr/bin/mailx -s \"Drive ".$self->name." went $state\" $notify");
  print PIPE "Drive ".$self->id." on ".$self->host->name." went $state, new state is ".$self->control."\n";
  print PIPE "Its comment field read: ".$self->comment."\n";

  print PIPE "\nThere are now $down drives down out of $total\n";
  close(PIPE);
}

foreach my $d (NBU::Drive->pool) {
  next unless $d->known;
  $d->notifyOn("DOWN", \&msg);
}

while (1) {
  system("sleep $interval\n");

  foreach my $server (@mediaManagers) {
    NBU::Drive->updateStatus($server);
  }
}

=head1 NAME

drive-watch.pl - Monitor NetBackup Drive Status

=head1 SYNOPSIS

drive-watch.pl B<-n> <people-who-care> B<-i> <check-interval> &

=head1 DESCRIPTION

The tape drives in a NetBackup installation are prone to going DOWN for various and sundry
reasons.  This script does not attempt to diagnose this situation but rather its goal is to
inform a set of people of such events.

By running as a daemon the script can compare the status of each drive over time and only sent
its alerts out when a transition of interest occurs.

Since a NetBackup environment can consist of many Media Managers, not all of which are active and
since each Media Manager may well have drives defined which are not active, drive-watch.pl will only report
on so-called "known" drives.  The "known" attribute is assigned to drives which are:

=over 4

=item

stand-alone drives referenced by a StorageUnit definition

=item

robotic drives housed in a robot referenced by a StorageUnit definition

=back

=head1 AUTHOR

Winkeler, Paul pwinkeler@pbnj-solutions.com

=head1 COPYRIGHT

Copyright (C) 2002 Paul Winkeler

=cut
