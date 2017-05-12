package silktest;

use FindBin;

BEGIN {
  eval { require Test::More };
  $@ && push(@INC, "$FindBin::Bin/../local");
}

use Test::More;

use strict;
use warnings;
use Carp;

use File::Temp qw( tempfile tempdir );

use vars qw( @EXPORT );
use base qw( Exporter );

@EXPORT = qw(

  t_tmp_filename

  TEST_DAT_DIR
  TEST_PMAP_DIR

  t_pmap_files
  t_pmap_files_exist

);

###

my($Test_Dat_Dir, $Test, $Test_Pmap_Dir);

BEGIN {
  $Test_Dat_Dir  = "$FindBin::Bin/dat";
  $Test_Pmap_Dir = "$Test_Dat_Dir/pmap";
}

use constant TEST_DAT_DIR  => $Test_Dat_Dir;
use constant TEST_PMAP_DIR => $Test_Pmap_Dir;

my %Test_Pmap_Files = (
  ipmap   => "$Test_Pmap_Dir/ip-map.pmap",
  ipmapv6 => "$Test_Pmap_Dir/ip-map-v6.pmap",
  ppmap   => "$Test_Pmap_Dir/proto-port-map.pmap",
);

sub t_pmap_files { %Test_Pmap_Files }

sub t_pmap_files_exist {
  foreach my $f (values %Test_Pmap_Files) {
    return 0 unless -f $f;
  }
  return 1;
}

###

my $Tmp_Dir;

sub t_tmp_filename {
  my $td = $Tmp_Dir ||= tempdir( CLEANUP => 1 );
  my($fh, $filename) = tempfile( DIR => $td, UNLINK => 0 );
  unlink $filename;
  $filename;
}

###

1;
