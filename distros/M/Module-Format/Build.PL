use strict;
use warnings;

use lib "./inc";

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name         => 'Module::Format',
    license             => 'mit',
    dist_author         => q{Shlomi Fish <shlomif@cpan.org>},
    dist_version_from   => 'lib/Module/Format.pm',
    requires =>
    {
        'Getopt::Long' => '2.36',
        'Pod::Usage' => 0,
        'perl' => '5.006',
        'strict' => 0,
        'warnings' => 0,
    },
    build_requires =>
    {
        'Test::More' => 0,
        'vars' => 0,
    },
    configure_requires =>
    {
        'Module::Build' => 0,
    },
    add_to_cleanup      => [ 'Module-Format-*' ],
    create_makefile_pl => 'traditional',
    script_files => ["script/perlmf"],
    meta_merge =>
    {
        resources =>
        {
            repository => "http://bitbucket.org/shlomif/web-cpan",
            homepage => "http://www.shlomifish.org/open-source/projects/Module-Format/",
        },
        keywords =>
        [
            "modules",
            "formats",
            "cpan",
            "installation",
            "rpm",
            "debs",
            "debian",
            "mandriva",
            "fedora",
            "install",
            "convert",
            "apt-get",
            "urpmi",
            "yum",
            "conversion",
            "perl",
        ],
    },
);

$builder->create_build_script();
