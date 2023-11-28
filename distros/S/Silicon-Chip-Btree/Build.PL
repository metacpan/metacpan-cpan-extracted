#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
use v5.34;
use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Silicon::Chip::Btree',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Implement a B-Tree as a silicon chip.',
  license       => 'perl',
  requires      =>
   {'Carp'             => 0,
    'Data::Table::Text'=> 20201029,
    'Silicon::Chip'    => 20231031,
    'Test2::API'       => 0,
    'Test::More'       => 0,
   },
  configure_requires => {'Module::Build' => 0.4224},
  create_readme =>  0,
  meta_merge =>
   {resources =>
     {repository => 'https://github.com/philiprbrenan/SiliconChipBtree',
      bugtracker => 'https://github.com/philiprbrenan/SiliconChipBtree/issues'
     }
   },
 );

$b->create_build_script();
