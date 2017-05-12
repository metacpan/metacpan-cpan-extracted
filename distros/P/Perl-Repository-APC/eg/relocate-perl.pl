#!/usr/bin/perl

=pod

Copy one of our perls in installed-perls to some place where we really
like to use it, say /usr/local. And correct every occurrence of the
miserable path we gave it within installed-perls to the new location.
Including, but not limited to the perl binaries and libperl.so and
whatever binary file is there.

I started out with

find /home/src/perl/repoperls/installed-perls/perl/pb0yHi3/perl-5.8.0@26561 -type f | xargs perl -nle 'if (m|/home/src/perl/repoperls/installed-perls/perl/pb0yHi3| &&!$seen{$ARGV}++) {printf "%d %s\n", -T $ARGV, substr($ARGV,45)}'

to determine which files I had to modify how to get a perl from one
path to another.

=cut

use strict;
use warnings;
use File::Rsync;
use File::Find;
use File::Path qw(mkpath);
use File::Spec;

sub Usage {
  "Usage: $0 from_dir to_dir\n";
}
my($from,$to) = @ARGV;
die Usage unless $to;
for ($from, $to) {
  s|/+$||;
}
die "to[$to] must be shorter than from[$from]" unless length($to) < length($from);
mkpath $to;
for ($from, $to) {
  die "dir[$_] not found" unless -e $_;
  die "dir[$_] not a directory" unless -d _;
  die "dir[$_] not absolute" unless File::Spec->file_name_is_absolute($_);
}
my $rsync = File::Rsync->new({ archive => 1});
$rsync->exec({src => "$from/", dest => "$to/"}) or die;
find(
     {
      wanted => sub {
        my $rel = substr($_,length($from));
        return unless $rel;
        return if -d $_;
        open my $fh, $File::Find::name or die "Could not open '$File::Find::name': $!";
        my $To = File::Spec->catfile($to,$rel);
        open my $tofh, ">", $To or die "Could not open >'$To': $!";
        if (-T $fh) {
          local $/ = "\n";
          while (<$fh>) {
            s/\Q$from\E/$to/g;
            print $tofh $_;
          }
        } else {
          local $/;
          local $_ = <$fh>;
          s/\Q$from\E([^\0]+)/ $to . $1 . ("\0"x(length($from)-length($to))) /ge;
          print $tofh $_;
        }
        close $fh;
        close $tofh;
      },
      no_chdir => 1,
     },
     $from
);
