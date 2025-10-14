#!/usr/bin/env perl
# inspired by:
# http://perltricks.com/article/208/2016/1/5/Save-time-with-compile-tests
use strict;
use Test::More;

my @modules = qw<
   QRCode::Encoder
   QRCode::Encoder::Matrix
   QRCode::Encoder::QRSpec
>;
for my $module (@modules) {
   require_ok($module)
     or BAIL_OUT("can't load $module");
} ## end while (my $path = $iter->...)

diag("Testing QRCode::Encoder $QRCode::Encoder::VERSION");
done_testing();
