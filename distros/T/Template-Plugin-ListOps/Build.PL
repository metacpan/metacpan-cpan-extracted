use Module::Build;
use strict;
use warnings;

my %requires = (
                 'perl'                     => '5.004',
                 'Array::AsObject'          => '0',
                 'Template'                 => '0',
                 'Template::Plugin'         => '0',
               );
my %build_mods = (
                 'IO::File'                 => '0',
                 'Test::More'               => '0',
                 'Test::Pod'                => '0',
                 'Test::Pod::Coverage'      => '0',
               );


my $build = Module::Build->new(
        license            => 'perl',
        dist_version       => '2.01',
        dist_author        => 'Sullivan Beck <sbeck@cpan.org>',
        module_name        => 'Template::Plugin::ListOps',
        dist_abstract      => 'Plugin interface to list operations',
        requires           => \%requires,
        build_requires     => {},
        build_recommends   => \%build_mods,
        sign               => 1,
);

$build->create_build_script;
