#!/usr/bin/perl -w
use strict;
use Module::Build;
my $build = Module::Build->new(
   module_name  => 'PDF::Tk',
   license      => 'perl',
   requires     => {
                'IO::All'    => 0,
                'IPC::Open2' => 0,
                'File::Temp' => 0
               },
    create_makefile_pl => 'passthrough',
    create_readme      => 1
  );
$build->create_build_script;

