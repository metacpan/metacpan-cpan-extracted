#!/usr/bin/perl

=head1 Progcopy.PL

I like to keep my perl programs in files named C<*.pl> since this
makes it easy to find and work with them.  However it is better to
install them as normal programs.  This does that.

The other key thing this does is sets up the scripts to call the perl
interpreter correctly.  I really needed this since I was working with
self compiled versions of perl in my home directory and not wanting to
disturb the main installation

This ought to be possible through standard Makefile.PL, but I don't
know how.

I also set this up to install the documentation appropriately.

=cut

use File::Find;
use Config;
use Cwd;

$File::Find::dont_use_nlink=1; # I had problems

my $perlint=$Config{"startperl"};
die "can't find out how to start interpreter" unless $perlint;

my $target_dir = "blib/script";
my $man_dir = "blib/man1";
die "no blib to install into" unless -d "blib";
mkdir $target_dir, 0750 unless -e $target_dir;
die "$target_dir is not a directory" unless -d $target_dir;
$target_dir = cwd() . '/' . $target_dir . '/'; #so we can find it later
mkdir $man_dir, 0750 unless -e $man_dir;
die "$man_dir is not a directory" unless -d $man_dir;
$man_dir = cwd() . '/' . $man_dir . '/'; #so we can find it later

sub work {
  -d && do { m/^((blib)|(old))$/ and $File::Find::prune = 1;
	     return; };
  return unless m/^[^.].*.pl$/;
  my $save=$_;
  ($name=$_) =~ s/.pl$//;
  my $target=$target_dir . $name;

  if (-e $target) {
    my @origstat=stat $_;
    my @targetstat=stat $target;
    if ($targetstat[9] > $origstat[9]) {
      print STDERR "$target up to date.. ignoring\n";
      return;
    }
  } 

  print STDERR ( "copying " . cwd() . '/' . $_
		 . " to " . $target . "\n");
  open (INFILE, "<" . $_) or die "failed to open to read $_";
  open (OUTFILE, ">" . $target) 
    or die "failed to open $target_dir$name to write";
  $_ = <INFILE>;
  s/#!\S*perl/$perlint/ or print OUTFILE $perlint, "\n";
  
  print OUTFILE $_;
  while (<INFILE>) {
    print OUTFILE $_;
  }
  close INFILE;
  close OUTFILE;
  chmod 0755, $target; #FIXME... what if they don't want
  system "pod2man $name.pl > $man_dir$name.1";
  $_=$save;
}

find(\&work, '.' );


