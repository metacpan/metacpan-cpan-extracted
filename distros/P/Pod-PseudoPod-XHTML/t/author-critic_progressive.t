#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use strict;
use warnings;

use lib '../lib';
use lib 'lib';

use Test::More;
use Try::Tiny;
use Path::Class qw(file);

try {
  require Test::Perl::Critic::Progressive;
  Test::Perl::Critic::Progressive->import( ':all' );
}
catch {
  plan skip_all => 'T::P::C::Progressive required for this test' if $@;
};

my $root_path = q</home/harleypig/projects/lib/Pod-PseudoPod-XHTML>;
my $step_size = 0;
my $severity  = 0;
my $exclude   = [ qw<  > ];

my $history_file = q<.perlcritic_history>;
$history_file = qq<$root_path/$history_file> if file( $history_file )->is_relative;

my $profile = q<>;
$profile = qq<$root_path/$profile> if $profile and file( $profile )->is_relative;

run_test( $history_file, $step_size, $exclude, $severity, $profile );

exit;

sub run_test {
  my ( $history_file, $step_size, $exclude, $severity, $profile ) = @_;

  set_history_file( $history_file );
  set_total_step_size( $step_size );

  my %args;
  $args{ -severity } = $severity if $severity;
  $args{ -profile }  = $profile  if $profile;
  $args{ -exclude }  = $exclude  if $exclude;

  set_critic_args( %args ) if keys %args;

  progressive_critic_ok();

  return;
}
