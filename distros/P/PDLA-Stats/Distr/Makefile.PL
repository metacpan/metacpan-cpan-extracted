use PDLA::Core::Dev;
use ExtUtils::MakeMaker;
PDLA::Core::Dev->import();

$package = ["distr.pp",Distr,PDLA::Stats::Distr];
%hash = pdlpp_stdargs($package);

chomp( my $libgsl = `gsl-config --libs` );
chomp( my $cflags = `gsl-config --cflags` );

if ($libgsl) {
  unshift @{ $hash{'LIBS'} }, $libgsl;
  $hash{'INC'} .= " $cflags";
  WriteMakefile( %hash );
  sub MY::postamble {pdlpp_postamble($package)};
}
else {
  my $msg = "no GSL lib, skip $package->[-1]";
  warn $msg . "\n";
  write_dummy_make( $msg );
}
