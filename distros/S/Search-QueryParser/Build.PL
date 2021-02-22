use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Search::QueryParser',
    license             => 'perl',
    dist_author         => 'Laurent Dami <dami AT cpan.org>',
    dist_version_from   => 'lib/Search/QueryParser.pm',
    requires => {
      perl                 => 5.008,
      constant             => 0,
    },
    build_requires => {
      'Test::More'     => 0,
    },

    add_to_cleanup      => [ 'Search-QueryParser-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/Search-QueryParser',
       }
     },
);
$builder->create_build_script();


      
