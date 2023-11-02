#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
use v5.34;
use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Silicon::Chip',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Design a silicon chip by combining gates and sub chips.',
  license       => 'perl',
  requires      =>
   {'Carp'             => 0,
    'Data::Table::Text'=> 20201029,
    'Svg::Simple'      => 20231028,
    'Test2::API'       => 0,
    'Test::More'       => 0,
   },
  configure_requires => {'Module::Build' => 0.4224},
  create_readme =>  0,
  meta_merge =>
   {resources =>
     {repository => 'https://github.com/philiprbrenan/SiliconChip',
      bugtracker => 'https://github.com/philiprbrenan/SiliconChip/issues'
     }
   },
 );

$b->create_build_script();
