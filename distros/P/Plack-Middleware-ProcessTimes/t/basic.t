#!/usr/bin/env perl

use strict;
use warnings;

use Plack::Test;
use Plack::Builder;
use Test::More;
use Time::HiRes qw(gettimeofday tv_interval sleep);
use HTTP::Request::Common;

my $num = qr/^\d+\.\d{3}$/;
my $last_env;

subtest no_measure_children => sub {
   my $app = builder {
      enable '+A::TestMW';
      enable 'ProcessTimes';

      sub { [200, [content_type => 'text/plain'], ['hello!']] };
   };

   test_psgi $app, sub {
      my $cb = shift;

      my $res = $cb->(GET '/');

      my $e = $A::TestMW::ENV;
      like($e->{'pt.real'},     $num, 'Real measured');
      like($e->{'pt.cpu-user'}, $num, 'CPU-User measured');
      like($e->{'pt.cpu-sys'},  $num, 'CPU-Sys measured');
      is(  $e->{'pt.cpu-cuser'},'-',  'CPU-CUser not measured');
      is(  $e->{'pt.cpu-csys'}, '-',  'CPU-CSys not measured');
   };
};

subtest measure_children => sub {
   my $app = builder {
      enable '+A::TestMW';
      enable 'ProcessTimes', measure_children => 1;

      sub { [200, [content_type => 'text/plain'], ['hello!']] };
   };

   test_psgi $app, sub {
      my $cb = shift;

      my $res = $cb->(GET '/');

      my $e = $A::TestMW::ENV;
      like($e->{'pt.real'},      $num, 'Real measured');
      like($e->{'pt.cpu-user'},  $num, 'CPU-User measured');
      like($e->{'pt.cpu-sys'},   $num, 'CPU-Sys measured');
      like($e->{'pt.cpu-cuser'}, $num, 'CPU-CUser measured');
      like($e->{'pt.cpu-csys'},  $num, 'CPU-CSys measured');
   };
};

my $parent = $$;
subtest 'actual numbers' => sub {
   my $app = builder {
      enable '+A::TestMW';
      enable 'ProcessTimes', measure_children => 1;

      sub {
         sleep 0.25;

         my $x = rand();
         my $t0 = [gettimeofday];

         fork for 1..3;

         while (tv_interval($t0) < 0.25) {
            $x *= rand();
            mkdir $x;
            rmdir $x;
         }
         [200, [content_type => 'text/plain'], ['hello!']]
      };
   };

   test_psgi $app, sub {
      my $cb = shift;

      my $res = $cb->(GET '/');

      exit unless $$ == $parent;

      note( $res->headers->as_string);

      my $e = $A::TestMW::ENV;
      like($e->{'pt.real'},      $num, 'Real measured');
      like($e->{'pt.cpu-user'},  $num, 'CPU-User measured');
      like($e->{'pt.cpu-sys'},   $num, 'CPU-Sys measured');
      like($e->{'pt.cpu-cuser'}, $num, 'CPU-CUser measured');
      like($e->{'pt.cpu-csys'},  $num,  'CPU-CSys measured');
   };
} if $ENV{AUTHOR_TESTING};

done_testing;

BEGIN {
package A::TestMW;

$INC{'A/TestMW.pm'} = __FILE__;

use base 'Plack::Middleware';

our $ENV;

sub call {
   my ($self, $env) = @_;

   $ENV = $env;

   $self->app->( $env );
}
}
