use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MooseX::SingletonMethod',
    license             => 'perl',
    dist_author         => 'Barry Walsh <draegtun@cpan.org>',
    dist_version_from   => 'lib/MooseX/SingletonMethod.pm',
    build_requires => {
        'Test::More'    => 0,
        'Moose::Role'   => 0,
        'Moose'         => 0,
    },
    add_to_cleanup      => [ 'MooseX-SingletonMethod-*' ],
    
    meta_merge => {  
      resources => {  
          bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-SingletonMethod',  
          repository => 'http://github.com/draegtun/MooseX-SingletonMethod/tree/master', 
      }  
    },
);

$builder->create_build_script();
