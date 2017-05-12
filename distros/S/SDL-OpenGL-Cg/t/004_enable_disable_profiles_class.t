use Test::More tests => 8;
use strict;
use warnings;

BEGIN { use_ok ('SDL::OpenGL::Cg') };

test_profiles();

sub test_profiles {
  my %profiles = (
    FP20    => SDL::OpenGL::Cg::CG_PROFILE_FP20(),
    FP30    => SDL::OpenGL::Cg::CG_PROFILE_FP30(),
    ARBFP1  => SDL::OpenGL::Cg::CG_PROFILE_ARBFP1(),
    VP20    => SDL::OpenGL::Cg::CG_PROFILE_VP20(),
    VP30    => SDL::OpenGL::Cg::CG_PROFILE_VP30(),
    ARBVP1  => SDL::OpenGL::Cg::CG_PROFILE_ARBVP1(),
    INVALID => 0,
  );

  for my $profile (keys %profiles) {
    my $id = $profiles{$profile};
    if (SDL::OpenGL::Cg::cgIsProfileSupported($id)) {
     if (SDL::OpenGL::Cg::cgEnableProfile($id)) {
       pass("Enable valid profile $profile");
     } else {
       fail("Enable valid profile $profile");
     }
    } else {
     if (SDL::OpenGL::Cg::cgEnableProfile($id)) {
       fail("Enable invalid profile $profile");
     } else {
       pass("Enable invalid profile $profile");
     }
    }
  }
}
