use strict;
use warnings;
use Module::Build;

my $builder = Module::Build
  ->new( module_name          => 'Template::Plugin::Filter::MinifyHTML'
         , dist_author        => 'Jarrod Linahan <txh@cpan.org>',
         , license            => 'perl'
         , requires           => { 
            'Template::Plugin::Filter' => 0
         }
         , configure_requires => {
            'Module::Build' => "0.3601",
         }
         , dist_version => '0.02'
         , create_makefile_pl => 'traditional'
       );
$builder->create_build_script;  #generate Build

