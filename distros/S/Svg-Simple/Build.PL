#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
use v5.34.0;
use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Svg::Simple',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Write SVG using Perl syntax.',
  license       => 'perl',
  requires      =>
   {'Carp'             =>0,
    'Data::Table::Text'=> 20201029,
     perl              => '5.34.0',
    'Test2::API'       =>0,
    'Test::More'       =>0,
   },
  configure_requires => {'Module::Build' => 0.4224},
  create_readme =>  0,
  perl          => '5.34.0',
  meta_merge =>
   {resources =>
     {repository => 'https://github.com/philiprbrenan/SvgSimple',
      bugtracker => 'https://github.com/philiprbrenan/SvgSimple'
     }
   },
 );

$b->create_build_script();
