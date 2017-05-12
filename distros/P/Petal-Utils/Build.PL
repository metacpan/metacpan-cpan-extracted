#!/usr/bin/perl

=head1 NAME

Build.PL - Build script generator for Petal::Utils

=head1 SYNOPSIS

 perl Build.PL
 ./Build test
 ./Build install

=cut

use lib 'lib';
use strict;
use warnings;
use File::Spec;
use Module::Build;

my $build = Module::Build->new
  (
   module_name        => 'Petal::Utils',
   dist_version_from  => 'lib/Petal/Utils.pm',
   create_readme      => 1,
   create_makefile_pl => 'passthrough',
   license            => 'perl',
   build_requires     => {
			  'Test::More'    => '0.01',
			  'Module::Build' => '0.20',
		         },
   requires           => {
			  'Petal'        => '1.06',
			  'Date::Format' => '0.01',
			  'URI::Escape'  => '3.0',
		         },
  );

$build->create_build_script;


__END__

=head1 AUTHOR

Steve Purkis <spurkis@cpan.org>

=cut

