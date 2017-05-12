#!perl

use strict;
use warnings;
use Module::Build;
use File::Spec;

my $path = File::Spec->catfile( "lib", "Pod", "LaTeX.pm" );

# Set it up.
my $build = Module::Build->new
  (
   module_name => 'Pod::LaTeX',
   license  => 'perl',
   dist_author => 'Tim Jenness <tjenness@cpan.org>',
   version_from => $path,
   abstract_from => $path,
   meta_merge => {
               resources =>  {repository => "git://github.com/timj/perl-Pod-LaTeX.git",
                              homepage => "http://github.com/timj/perl-Pod-LaTeX/tree/master",
                             },
                },
   requires => {
                'Pod::Find'  => 0,
                'Pod::Parser' => 0,
                'Pod::ParseUtils' => 0.30,
                'Pod::Select' => 0,
                'if' => 0,
               },
   PL_files => { 'pod2latex.PL' => 'pod2latex' },
   script_files => [ 'pod2latex' ],
   build_requires => {
                      'Test::More' => 0,
                     },
   installdirs => ( $] > 5.006 and $] <= 5.012 ? "core" : "site" ),
  );

$build->create_build_script;
