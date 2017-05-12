#!/usr/bin/perl

=head1 NAME

Build.PL - Build script generator for OpenFrame::WebApp

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
   module_name        => 'OpenFrame::WebApp',
   dist_version_from  => 'lib/OpenFrame/WebApp.pm',
   create_makefile_pl => 'passthrough',
   license            => 'perl',
   build_requires     => {
			  'Test::More' => '0.01',
			  'Module::Build' => '0.19',
		         },
   requires           => {
			  'Cache::Cache'    => '1.01',
			  'OpenFrame'       => '3.00',
			  'Pipeline'        => '3.04',
			  'Time::ParseDate' => '2003.0',
			 },
  );

$build->create_build_script;


__END__

=head1 VERSION

$Id: Build.PL,v 1.1 2003/08/01 00:21:46 spurkis Exp $

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=cut

