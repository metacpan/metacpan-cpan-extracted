use Module::Build;
use strict;
use warnings;

my %requires = (
                 'perl'                     => '5.000',
                 'Carp'                     => '0',
                 'IO::File'                 => '0',
               );
my %build_mods = (
                 'Test::Inter'              => '0',
                 'Test::Pod'                => '0',
                 'Test::Pod::Coverage'      => '0',
               );


my $build = Module::Build->new(
        license            => 'perl',
        dist_version       => '1.06',
        dist_author        => 'Sullivan Beck <sbeck@cpan.org>',
        module_name        => 'Set::Files',
        dist_abstract      => 'routines to work with files, each definining a single set',
        requires           => \%requires,
        build_requires     => \%build_mods,
        sign               => 1,
);

$build->create_build_script;
