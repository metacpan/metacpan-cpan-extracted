use strict;
use warnings;
use Test::More;

plan( skip_all => 'Set TEST_AUTHOR to a true value to run.' )
  unless $ENV{TEST_AUTHOR};

eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage"
  if $@;

eval "use Pod::Coverage::TrustPod";
plan skip_all => "Pod::Coverage::TrustPod required for testing POD coverage"
  if $@;

# Skip ::Linux unless we are on a linux box
# Skip ::Mac unless we are on OS/X
# Don't require any pod of Moose BUILD subs
pod_coverage_ok( $_,
    { trustme => ['BUILD'], coverage_class => 'Pod::Coverage::TrustPod' } )
  for grep {
    ( $^O ne 'linux' && $_ !~ /Linux$/ )
      or $^O ne 'darwin'
      && $_ !~ /Mac$/
  } all_modules();

done_testing();
