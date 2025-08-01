#!/usr/bin/env perl

use v5.14.4;
use warnings;

our $VERSION = '9999.99.99_99'; # VERSION

use File::Spec;
use Test::More;

plan skip_all => 'these tests are for testing by the author'
  unless $ENV{AUTHOR_TESTING};

use Test::Perl::Critic::Progressive qw(progressive_critic_ok set_history_file);

if ( $ENV{CI} ) {
  my $history_dir  = File::Spec->catfile( File::Spec->tmpdir(), 'cache' );
  my $history_file = File::Spec->catfile( $history_dir, '.perlcritic-history' );

  mkdir $history_dir;

  set_history_file($history_file);
}

my @files       = qw(xt/author/critic-progressive.t xt/author/perltidy.t);
my @directories = qw(lib bin t);

progressive_critic_ok( @files, @directories );
