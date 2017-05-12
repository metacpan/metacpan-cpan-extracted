use strict;
$^W=1;

eval "use Test::Pod::Coverage 1.00";
if($@) {
  print "1..0 # SKIP Test::Pod::Coverage 1.00 required for testing POD coverage";
} else {
  eval "use Pod::Coverage 0.21";
  if($@) {
    print "1..0 # SKIP Pod::Coverage 0.21 required for testing POD coverage";
  } else {
    my @allmodules = all_modules('lib');
    eval 'use Test::More tests => '.($#allmodules + 1);
    pod_coverage_ok(
      $_,
      {
        'Params::Validate::Dependencies::all_or_none_of' => {
          trustme => [qr{^(join_with|name)$}]
        }
      }->{$_},
      "POD coverage OK in $_"
    ) foreach(@allmodules);
  }
}
