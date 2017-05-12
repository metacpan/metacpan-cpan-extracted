
use strict;
use warnings;

use PDLA;
use PDLA::Config;
use File::Temp 'tempdir';
use File::Spec;

use Test::More tests => 4;
use Test::Exception;

# Temp directory name.  The catfile() call adds a trailing dir
# separator (e.g. "/" on POSIX).
my $d = File::Spec->catfile(tempdir(CLEANUP=>1),"");

##1 Make sure the library loads

use PDLA::DiskCache;

##2 Make a DiskCache object
##exercises STORE, sync, and DESTROY

lives_ok {
  my($pa) = diskcache(["${d}1","${d}2","${d}3"],{verbose=>1});
  $pa->[0] = zeroes(10,10);
  $pa->[1] = xvals(10,10);
  $pa->[2] = yvals(10,10);
  1;
};

ok( (-e "${d}1") && (-e "${d}2") && (-e "${d}3") );

my $pb;
lives_ok {
  ($pb) = diskcache(["${d}1","${d}2","${d}3"],{ro=>1});
};
ok( ($pb->[0]->sum == 0) && ($pb->[1]->sum == xvals(10,10)->sum) );


# end

