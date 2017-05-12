#!/usr/bin/perl -w

my($hdr) = @ARGV;
die qq
{
  Usage: hdr_diff OPENGL_HEADER
} if (!$hdr);

my $cmp = '../gl_const.h';
die "Const file not found: '$cmp'\n" if (!open(CMP,$cmp));
my $compare;
$compare .= $_ while (<CMP>);
close(CMP);
$compare =~ s|[\r\n]+| |gs;

my $src = "../include/GL/$hdr.h";
die "Header not found: '$src'\n" if (!open(SRC,$src));

my $cnt = 0;
my $missing = 0;
foreach my $line (<SRC>)
{
  if ($line =~ m|(/\* [^\s\*]+ \*/)|)
  {
    print "$1\n";
    next;
  }
  next if ($line !~ m|\#define ([^\s]+)[^\w\r\n]|);
  my $const = $1;
  next if ($const =~ m|GL_VERSION_|);
  if ($const ne uc($const))
  {
    print "* $1\n";
    next;
  }
  $cnt++;

  next if ($compare =~ m|i\($const\)|);
  print "\ti($const)\n";
  $missing++;
}
close(SRC);

print "Missing: $missing of $cnt; ".($cnt - $missing)." found\n";
