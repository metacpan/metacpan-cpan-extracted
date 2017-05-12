#!/usr/bin/perl

use lib '../lib/blib';
use Stat::lsMode qw(format_mode file_mode);

print "1..14\n";

foreach $i (0 .. 7) {
  my $t = $i * 73;
  my $mode = format_mode(oct("0$i$i$i"));
  $mode =~ s/^\?//;
  $mode =~ tr/-/0/;
  $mode =~ tr/0/1/c;
  my $total = 0;
  foreach $bit (split //, $mode) {
    $total = $total * 2 + $bit;
  }
  if ($total/73 != $i) {
    print "not ok ", $i+1, "\n";
  } else {
    print "ok ", $i+1, "\n";
  }
}

umask 000;
$dir = "/tmp/SlsM.$$." . time;

if (mkdir $dir, 0700) {
  print (((file_mode($dir) eq 'drwx------') ? '' : 'not '), "ok 9\n");
} else {
  print "not ok 9\n";
}


if (open F, "> $dir/file") {
  print (((file_mode("$dir/file") eq '-rw-rw-rw-') ? '' : 'not '), "ok 10\n");
} else {
  print "not ok 10\n";
}

umask 022;
if (open F, "> $dir/file2") {
  print (((file_mode("$dir/file2") eq '-rw-r--r--') ? '' : 'not '), "ok 11\n");
} else {
  print "not ok 11\n";
}

if (symlink "$dir/file2", "$dir/link") {
  print (((file_mode("$dir/link") =~ /^l/) ? '' : 'not '), "ok 12\n");
} else {
  print "not ok 12\n";
}

# Test with a umask
if (mkdir "$dir/dir", 0236) {
  print (((file_mode("$dir/dir") eq 'd-w---xr--') ? '' : 'not '), "ok 13\n");
} else {
  print "not ok 13\n";
}

umask 0;
if (mkdir "$dir/dir2", 0236) {
  print (((file_mode("$dir/dir2") eq 'd-w--wxrw-') ? '' : 'not '), "ok 14\n");
} else {
  print "not ok 14\n";
}
