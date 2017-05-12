#!/usr/bin/perl

=head1 NAME

Build.PL - Build script generator for C<TAP::Formatter::HTML> module

=head1 SYNOPSIS

 perl Build.PL
 ./Build
 ./Build test
 ./Build install

=cut

use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new
  (
   module_name        => 'TAP::Formatter::HTML',
   dist_version_from  => 'lib/TAP/Formatter/HTML.pm',
   create_makefile_pl => 'passthrough',
   create_readme      => 1,
   license            => 'perl',
   requires           => {
			  'perl'        => '5.6.0',
			  'accessors'   => '0.02',
			  'URI'         => '1.35',
			  'Template'    => '2.14',
			  'TAP::Parser' => '3.10',
			  'File::Temp'  => '0.17',
			  'Test::Harness' => '3.17',
		         },
   build_requires     => {
			  'Test::More'    => '0.01',
			  'Module::Build' => '0.20',
		         },
  );

$build->add_build_element("tt2");
$build->add_build_element("css");
$build->add_build_element("js");

$build->create_build_script;


__END__

=head1 AUTHOR

Steve Purkis <spurkis@cpan.org>

=cut

