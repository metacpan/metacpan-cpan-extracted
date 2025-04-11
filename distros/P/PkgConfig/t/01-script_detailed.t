use strict;
use warnings;
use Test::More;
use FindBin;
use lib $FindBin::Bin;
use PkgConfigTest;

run_common("glib-2.0"); ok($RV == 0, "package name exists");

run_common(qw(--exists glib-2.0)); ok($RV == 0, "package name (--exists)");

run_common(qw(--libs glib-2.0)); like($S, qr/-lglib-2\.0/, "Got expected libs");
ok($S !~ /-L/, "No -L directive for standard search path");

run_common(qw(--cflags glib-2.0));
expect_flags("-I/usr/include/glib-2.0 -I/usr/lib/glib-2.0/include",
             "Got expected include flags");

if (eval { symlink("",""); 1 }) {
  # symlink to simulate place-with-space
  require File::Temp;
  require File::Spec;
  require Text::ParseWords;
  my $dir = File::Temp::tempdir( CLEANUP => 1 );
  my $sub = File::Spec->catdir($dir, 'in space');
  my $exp_stub = "-I".File::Spec->rel2abs($sub)."/../../include";
  $exp_stub =~ s|\\|/|g; # standard behaviour of this module
  symlink File::Spec->rel2abs(File::Spec->catdir(qw(t data strawberry c lib pkgconfig))), $sub;
  local $ENV{PKG_CONFIG_PATH} = $sub;
  require PkgConfig; # after the environment variable is set
  for (['freetype2','/freetype2'], ['gsl',''], ['libxml-2.0','/libxml2'], ['libexslt',['','/libxml2']]) {
    my ($lib, $suffix) = @$_;
    run_common(qw(--cflags), $lib);
    chomp(my $out = $PkgConfigTest::S);
    like $out, qr/^"/, "$lib cflags should be quote-protected to survive make";
    ($out) = Text::ParseWords::shellwords($out);
    is $out, $exp_stub.(ref $suffix ? $suffix->[0] : $suffix), "$lib survived being in space";
    my $pkg = PkgConfig->find($lib);
    my $arr = [$pkg->get_cflags];
    my $exp = ref $suffix ? [map "$exp_stub$_", @$suffix] : ["$exp_stub$suffix"];
    is_deeply $arr, $exp, "$lib get_cflags" or diag explain [$arr,$exp];
  }
}

done_testing();
