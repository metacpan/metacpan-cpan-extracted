=pod

The standard test is called without argument and without option. Here
we just create a small, fresh tree of files only containing 0 or 1
(simply modulo the counter that counts the files), run trimtrees.pl on
it and prove that we have saved the gain we can expect.

More refined (and time consuming) tests can be run by giving arguments
and options.

Called with an argument, we use the tree in ./tmp/ instead of building
a new one. We add $ARGV[0] new files to that tree and then let
trimtrees.pl run.

In either case, we then create an overview of all inodes found in the
tree, linkcount and one example file. This overview should tell the
educated tester if trimtrees has worked correctly.

For example, if we are on a filesystem with a give maximum linkcount
of 32000 (on my ext3 filesystem), then

  perl t/trimtrees.t 64000

should create 2 files with linkcount being 32000 for each. Then

  perl t/trimtrees.t -maxlinks 16000 0

should alter the tree to contain 4 files with linkcount 16000. After
that

  perl t/trimtrees.t -maxlinks 8000 0

should alter the tree to contain 8 files with linkcount 8000. After
that

  perl t/trimtrees.t 0

should again put the tree back to 2 x 32000 as after the first call.

  perl t/trimtrees.t -maxlinks 8000 0

produces again 8 x 8000,

  perl t/trimtrees.t -maxlinks 16000 0

produces again 4 files with 16000 linkcount foreach

This allows us to run

  cp -al tmp tmp2

without an error. Then the following also gives no error:

  perl t/trimtrees.t -maxlinks 16000 0
  cp -al tmp tmp3

But then

  cp -al tmp tmp4

immediately produces errors.

=cut



use strict;
use warnings;

use File::Find;
use File::Path;
use File::Spec;
use File::Temp qw(tempfile);
use Test::More qw();
use Getopt::Long;
our %Opt;
GetOptions(\%Opt,
          "maxlinks=i",
          ) or die;
my @Opt;
while (my($k,$v) = each %Opt) {
  push @Opt, "--$k='$v'";
}

# check link counts
sub clc {
  my($seen) = @_;
  $seen = {} unless defined $seen;
  find(
       sub {
         my @stat = stat;
         return if -d _;
         return if $seen->{$stat[1]}++;
         print "# inode[$stat[1]]linkcnt[$stat[3]]name[$File::Find::name]\n";
       },
       "tmp",
      );
}

my $files;
my $cleanup;
my $tests;
if (@ARGV) { # run it as interactive test
  $files = shift;
  $cleanup = 0;
  $tests = 3;
} else { # usually 'make test'
  $files = 2**12;
  rmtree "tmp";
  $cleanup = 1;
  $tests = 6;
}
Test::More->import(tests => $tests);

mkpath("tmp");
for (my $i = 0; $i < $files; $i++) {
  my $dir = File::Spec->catdir("tmp",split //, $i);
  mkpath $dir;
  my($fh,$file) = tempfile("TXXXXXX", DIR => $dir);
  print $fh $i%2;
}
ok(1,"$files files injected into ./tmp/");
# do something with
open my $fh, "'$^X' eg/trimtrees.pl @Opt tmp|" or die;
local $/ = "\r";
local $| = 1;
my $saved;
while (<$fh>) {
  print;
  $saved = $1 if /saved\[([\-\d_]+)\]/;
}
ok(close $fh, "'trimtrees @Opt tmp' successfully completed");
$saved =~ s/_//g;
if ($cleanup) {
  is($saved,$files-2,"saved all but two bytes");
}
# do something with
my %seen;
clc(\%seen);
my $seen = keys %seen;
my $expected = $files > 2 ? 2 : $files;
ok($seen >= $expected, "at least $expected inodes occupied ($seen)");

if ($cleanup) {
  my $baddir = "tmp/0";
  for my $i (0..3) {
    my $badfile = "$baddir/BAD\nNL$i";
    open my $badfh, ">", $badfile or die "Could not open '$badfile': $!";
    print $badfh "who's failing?";
    close $badfh or die;
    chmod 0444, $badfile or die;
  }
  chmod 0, "$baddir/BAD\nNL3" or die;
  chmod 0555, $baddir or die;
  open my $fh, "'$^X' eg/trimtrees.pl tmp 2>&1 |" or die;
  local $/ = "\r";
  local $| = 1;
  my $ttout = "";
  while (<$fh>) {
    Test::More::diag $_;
    $ttout .= $_;
  }
  ok(close $fh, "'trimtrees tmp' successfully completed");
  my(@skip) = $ttout =~ /(Skipping)/g;
  ok(@skip==3, sprintf "Found %d expected error messages", scalar @skip);
  clc();
  rmtree "tmp";
}

__END__

	Local Variables:
	mode: cperl
	cperl-indent-level: 2
	End:
