#!/usr/bin/perl
require v5.26;
use Module::Build;

my $b = Module::Build->new
 (module_name   => 'String::Trim::Regex',
  dist_author   => 'contact@mikelimberger.com',
  dist_abstract => 'Trims the spaces off the leading / trailing string.',
  license       => 'perl',
  requires      =>
   {'Carp'                =>0,
    'Data::Dump'          =>0,
    'feature'             =>0,
    'Test2::API'          =>0,
    'Test::More'          =>0,
   },
  configure_requires => {'Module::Build' => 0.4224},
  meta_merge =>
   {resources =>
     {repository => 'https://github.com/8BitMiker/String-Trim-Regex',
      bugtracker => 'https://github.com/8BitMiker/String-Trim-Regex/issues'
     }
   },
  create_readme =>  0,
  perl          => '5.26.0',
 );

$b->create_build_script();
