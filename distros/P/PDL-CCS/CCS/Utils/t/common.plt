# -*- Mode: CPerl -*-
# File: t/common.plt
# Description: re-usable test subs for Math::PartialOrder

##-- common subs
BEGIN {
  use File::Basename;
  use Cwd;
  my $topdir = Cwd::abs_path(dirname(__FILE__)."/../../..");
  do "$topdir/t/common.plt" or die("$0: failed to load $topdir/t/common.plt: $@");
}

print "loaded ", __FILE__, "\n";
1;

