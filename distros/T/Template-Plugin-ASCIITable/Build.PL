#!/usr/bin/perl
use Module::Build;
my $build=Module::Build
  ->new(
        module_name=>'Template::Plugin::ASCIITable',
        dist_author=>'dakkar <dakkar@tehanutilus.net>',
        license=>'perl',
        dist_abstract=><<'END_ABSTRACT',
Allows you to use Text::ASCIITable in your templates.
END_ABSTRACT
        requires=>{
                   Text::ASCIITable=>0,
                   Template=>0,
                  },
        build_requires=>{
                         Test::More=>0,
                        },
        create_makefile_pl =>'traditional',
        sign=>1,
       );
$build->create_build_script;
