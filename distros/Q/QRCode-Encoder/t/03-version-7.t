#!/usr/bin/env perl
use strict;
use warnings;

#use Test::More tests => 1; # last test to print
use Test::More 'no_plan';  # substitute with previous line when done
use QRCode::Encoder qw< qr_encode qr_best_params >;

my $octets = '1' x 18;

{
   my %params = qr_best_params($octets, version => 7);
   is_deeply \%params, {
      version => 7,
      level   => 'H',
      mode    => 'numeric',
      octets  => $octets,
   }, 'qr_best_params no min_level';
   my $encoded = qr_encode($octets, version => 7);
   is $encoded->{level}, 'H', 'H level was selected with no min_level';
}

done_testing();
