#!perl -T

use strict;
use warnings;

use Test::More tests => 6;

use Scope::Upper qw<uplevel UP>;

{
 my $want;
 my @res = sub {
  uplevel {
   $want = wantarray;
  };
  return;
 }->();
 is $want, undef, 'static void context';
}

{
 my $want;
 my @res = sub {
  my $res = uplevel {
   $want = wantarray;
  };
  return;
 }->();
 is $want, '', 'static scalar context';
}

{
 my $want;
 my $res = sub {
  my @res = uplevel {
   $want = wantarray;
  };
  return;
 }->();
 is $want, 1, 'static list context';
}

{
 my $want;
 my @res = sub {
  sub {
   uplevel {
    $want = wantarray;
   } UP;
  }->();
  return;
 }->();
 is $want, undef, 'dynamic void context';
}

{
 my $want;
 my @res = sub {
  my $res = sub {
   uplevel {
    $want = wantarray;
   } UP;
  }->();
  return;
 }->();
 is $want, '', 'dynamic scalar context';
}

{
 my $want;
 my $res = sub {
  my @res = sub {
   uplevel {
    $want = wantarray;
   } UP;
  }->();
  return;
 }->();
 is $want, 1, 'dynamic list context';
}
