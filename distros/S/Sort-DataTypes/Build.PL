use Module::Build;
use strict;
use warnings;

my %requires = (
                 'perl'                     => '5.000',
                 'Date::Manip'              => '0',
                 'Exporter'                 => '0',
                 'Storable'                 => '0',
               );
my %build_mods = (
                 'Test::Inter'              => '0',
               );


my $build = Module::Build->new(
        license            => 'perl',
        dist_version       => '3.01',
        dist_author        => 'Sullivan Beck <sbeck@cpan.org>',
        module_name        => 'Sort::DataTypes',
        dist_abstract      => 'Sort a list of data using methods relevant to the type of data',
        requires           => \%requires,
        build_requires     => \%build_mods,
        sign               => 1,
);

$build->create_build_script;
