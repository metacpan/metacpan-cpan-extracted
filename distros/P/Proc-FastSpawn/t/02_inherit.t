BEGIN { $| = 1; print "1..6\n"; }

use Proc::FastSpawn;

print +(pipe R, W) ? "" : "not ", "ok 1\n";

fd_inherit fileno R, 0;
fd_inherit fileno W, 1;

# OpenBSD has a corrupted $^X when linking aaginst -lpthread
# so use Config instead.
use Config;

my $pid = spawn $Config{perlpath}, [
   qw(perl -e),
   '
      my $gr = (open my $r, "<&" . $ARGV[0]) ? 1 : 0;
      my $gw = (open my $w, ">&" . $ARGV[1]) ? 1 : 0;

      syswrite $w, "$gr$gw";
   ',
   fileno R, fileno W
];

print $pid ? "" : "not ", "ok 2\n";

close W;
my $grw = <R>;

print +($pid == waitpid $pid, 0) ? "" : "not ", "ok 3\n";
print $? == 0x0000 ? "" : "not ", "ok 4\n";
print $grw eq "01" ? "" : "not ", "ok 5 # $grw\n";
print "ok 6\n";
