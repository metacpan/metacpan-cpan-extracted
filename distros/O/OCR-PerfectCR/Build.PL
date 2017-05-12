#!/usr/bin/perl
use warnings;
use strict;
use Module::Build;

my $build = Module::Build->new
  (
   module_name => "OCR::PerfectCR",
   dist_author => "James Mastros <james\@mastros.biz>",
   dist_version_from => "lib/OCR/PerfectCR.pm",
   license => "perl",
   requires => {
                # These are the things I require.  The Module::Build
                # documentation just says "modules" without specifing
                # anything about core or non-core; if your tool fails
                # because of this, it is a bug in your tool, or in
                # Module::Build's documentation; please send your bug
                # report to the approprate person.
                "strict"    => 0,
                "warnings"  => 0,
                "IO::File"  => 0,
                "Test::More"=> 0,
                "GD"        => 0,
                "Digest::MD5" => 0,
                "Graphics::ColorObject" => 0
               },
   # If Build.PL works but Makefile.PL does not, please send your bug
   # report to the Module::Build::Compat people.
   create_makefile_pl => 'traditional',
  );
$build->create_build_script;
