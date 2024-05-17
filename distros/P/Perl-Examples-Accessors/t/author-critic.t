#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.006

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Perl/Examples/Accessors.pm','lib/Perl/Examples/Accessors/Array.pm','lib/Perl/Examples/Accessors/ClassAccessor.pm','lib/Perl/Examples/Accessors/ClassAccessorArray.pm','lib/Perl/Examples/Accessors/ClassAccessorArraySlurpy.pm','lib/Perl/Examples/Accessors/ClassAccessorPackedString.pm','lib/Perl/Examples/Accessors/ClassAccessorPackedStringSet.pm','lib/Perl/Examples/Accessors/ClassInsideOut.pm','lib/Perl/Examples/Accessors/ClassStruct.pm','lib/Perl/Examples/Accessors/ClassTiny.pm','lib/Perl/Examples/Accessors/ClassXSAccessor.pm','lib/Perl/Examples/Accessors/ClassXSAccessorArray.pm','lib/Perl/Examples/Accessors/Hash.pm','lib/Perl/Examples/Accessors/Mo.pm','lib/Perl/Examples/Accessors/MojoBase.pm','lib/Perl/Examples/Accessors/MojoBaseXS.pm','lib/Perl/Examples/Accessors/Moo.pm','lib/Perl/Examples/Accessors/Moops.pm','lib/Perl/Examples/Accessors/Moos.pm','lib/Perl/Examples/Accessors/Moose.pm','lib/Perl/Examples/Accessors/Mouse.pm','lib/Perl/Examples/Accessors/ObjectPad.pm','lib/Perl/Examples/Accessors/ObjectSimple.pm','lib/Perl/Examples/Accessors/ObjectTiny.pm','lib/Perl/Examples/Accessors/ObjectTinyRW.pm','lib/Perl/Examples/Accessors/ObjectTinyRWXS.pm','lib/Perl/Examples/Accessors/ObjectTinyXS.pm','lib/Perl/Examples/Accessors/Scalar.pm','lib/Perl/Examples/Accessors/SimpleAccessor.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
