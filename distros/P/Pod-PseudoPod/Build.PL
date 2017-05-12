use Module::Build;
my $build = Module::Build->new (
    module_name => 'Pod::PseudoPod',
    license => 'perl',
    build_requires => {
        'Test::More'    => 0,
    },
    requires => {
        'Pod::Simple'    => 3.02,
        'Text::Wrap'     => 98.112902,
        'HTML::Entities' => 0,
    },
    script_files         => [ 'bin/ppod2html',
                              'bin/ppod2txt',
                              'bin/ppod2docbook',
                              'bin/ppodchecker'
                            ],
    recursive_test_files => 1,
    dist_author          => 'Allison Randal (allison@perl.org)',
    dist_abstract        => "A framework for parsing PseudoPod",
);
$build->create_build_script;
