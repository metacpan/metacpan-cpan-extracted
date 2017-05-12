use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Module::Release::CSJEWELL',
    license             => 'perl',
    dist_author         => 'Curtis Jewell <CSJewell@cpan.org>',
    dist_version_from   => 'lib/Module/Release/CSJEWELL.pm',
    create_readme       => 1,
    create_license      => 1,
    create_makefile_pl  => 'passthrough',
    configure_requires  => {
        'Module::Build'     => '0.33',
    },
    requires => {
        'perl'              => 5.008001,
        'Module::Release'   => '2.05',
        'parent'            => '0.221',
        'Net::Twitter'      => '3.04006',
        'Archive::Tar'      => '1.52',
    },
    build_requires      => {
        'Test::More'        => '0.61',
    },
    meta_merge     => {
        resources => {
            homepage    => 'http://csjewell.comyr.com/perl/',
            bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Release-CSJEWELL',
            repository  => 'http://svn.ali.as/cpan/trunk/Module-Release-CSJEWELL/'
        },
    },
	script_files        => 'script/release-csjewell.pl',
    add_to_cleanup      => [ 'Module-Release-CSJEWELL-*', ],
);

$builder->create_build_script();
