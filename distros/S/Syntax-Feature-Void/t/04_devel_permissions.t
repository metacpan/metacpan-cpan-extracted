#!perl

use strict;
use warnings;

use FindBin qw( $RealBin );

use Test::More;

BEGIN {
   $ENV{DEVEL_TESTS}
      or plan skip_all => "Permission checks are only performed when DEVEL_TESTS=1";

   $^O ne 'Win32'
      or plan skip_all => "Permission checks can't be performed on Win32";
}

sub read_manifest {
   open(my $fh, '<', 'MANIFEST')
      or die("Can't open \"MANIFEST\": $!\n");

   my @manifest = <$fh>;
   chomp @manifest;
   return @manifest;
}

{
   chdir("$RealBin/..") or die $!;

   my @qfns = read_manifest();

   plan tests => 3*@qfns;

   for my $qfn (@qfns) {
      my @stat = stat($qfn)
         or die("Can't stat \"$qfn\": $!\n");

      my $mode = $stat[2];
      is(sprintf("%04o", $mode & 0400), '0400', "$qfn is readable");
      is(sprintf("%04o", $mode & 0002), '0000', "$qfn isn't world writable");
      if ($qfn =~ /\.(t|pl|PL)\z/) {
         is(sprintf("%04o", $mode & 0100), '0100', "$qfn is executable");
      } else {
         is(sprintf("%04o", $mode & 0111), '0000', "$qfn isn't executable");
      }
   }
}
