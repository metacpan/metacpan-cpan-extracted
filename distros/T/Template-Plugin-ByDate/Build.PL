use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Template::Plugin::ByDate',
    license             => 'perl',
    dist_author         => 'Darin McBride <dmcbride@cpan.org>',
    dist_version_from   => 'lib/Template/Plugin/ByDate.pm',
    build_requires => {
        'Test::More' => 0,
        'Template::Plugin' => 0,
        'List::MoreUtils' => 0.19,
        'Date::Parse' => 2.27,
    },
    add_to_cleanup      => [ 'Template-Plugin-ByDate-*' ],
);

$builder->create_build_script();
