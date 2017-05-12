package FindLib;

use ExtUtils::Liblist;

# As (ExtUtils::Liblist->ext())[2], but works even before 5.6.0
sub findlib {
  my $libs = shift;
  print "...Looking for libs, expect some warnings...\n";
  local @ExtUtils::Liblist::ISA = @ExtUtils::Liblist::ISA;
  push @ExtUtils::Liblist::ISA, 'xxx';
#  *xxx::lsdir = 'ExtUtils::MakeMaker'->can('lsdir');
  *xxx::lsdir = 'MY'->can('lsdir');
  *xxx::file_name_is_absolute = 'MY'->can('file_name_is_absolute');

  return (ExtUtils::Liblist->ext( $common::try_libs ))[2];
}

1;
