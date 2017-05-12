#!perl -w
use strict;
use Module::Build;
Module::Build
  ->new( module_name => "Parse::CVSEntries",
         license     => 'perl',
         requires    => {
             'Class::Accessor::Fast' => 0,
             'Test::More' => 0,
             'Date::Parse' => 0,
         },
         create_makefile_pl => 'traditional',
        )
  ->create_build_script;

