# -*-cperl-*-

use strict;
use warnings;
use Module::Build;
use File::Spec;

# Can not read a VERSION from a .PL file

my $build = Module::Build->new
  (
   module_name => "PDL::IO::NDF",
   license => "perl",
   dist_version => '1.06',
   dist_abstract => 'Read PDLs from NDF files and write PDLs to NDF files',
   dist_author => [
                   'Tim Jenness <tjenness@cpan.org>',
                   'Douglas Burke <dburke@cfa.harvard.edu>',
                  ],
   meta_merge => {
               resources =>  {
                              repository => "git://github.com/Starlink/perl-PDL-IO-NDF.git",
                              homepage => "https://github.com/Starlink/perl-PDL-IO-NDF",
                             },
                },
   requires => {
                'Astro::FITS::Header' => 3.0,
                'PDL' => "2.4.0",
                'NDF' => 1.51,
                },
   configure_requires => {
                          "Module::Build" => 0.3,
                         },
   build_requires => {
                      "Test::More" => 0,
                      "Test::Number::Delta" => 0,
                     },
  );

$build->create_build_script;
