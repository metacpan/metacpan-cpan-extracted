#!perl

use strict;
use warnings;

use FindBin qw( $RealBin );

use Test::More;

BEGIN {
   $ENV{DEVEL_TESTS}
      or plan skip_all => "Mark checks are only performed when DEVEL_TESTS=1";
}

sub slurp_file {
   my ($qfn) = @_;
   open(my $fh, '<', $qfn)
      or die("Can't open \"$qfn\": $!\n");

   local $/;
   return <$fh>;
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

   plan tests => 0+@qfns;

   for my $qfn (@qfns) {
      my $file = slurp_file($qfn);
      ok( $file !~ /~{3}|&{3}/, "$qfn - Has no developer bookmarks" );
   }
}
