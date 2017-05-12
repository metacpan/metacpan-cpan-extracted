#!/usr/bin/perl

=head1 NAME

Build.PL - Build script generator for C<Test::Approx> module

=head1 SYNOPSIS

 perl Build.PL
 ./Build
 ./Build test
 ./Build install

=cut

use strict;
use warnings;
use File::Spec;
use Module::Build;

my $build = Module::Build->new
  (
   module_name        => 'Test::Approx',
   dist_version_from  => 'lib/Test/Approx.pm',
   create_makefile_pl => 'passthrough',
   create_readme      => 1,
   license            => 'perl',
   requires           => {
			  'perl'          => '5.6.0',
			  'Text::LevenshteinXS' => '0.03',
			  'POSIX'         => '0.01',
			  'Test::Builder' => '0.01',
		         },
   build_requires     => {
			  'Test::More'    => '0.01',
			  'Test::Builder' => '0.01',
			  'Module::Build' => '0.20',
		         },

  );

$build->create_build_script;


__END__

=head1 AUTHOR

Steve Purkis <spurkis@cpan.org>

=cut

