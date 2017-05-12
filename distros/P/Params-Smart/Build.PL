use Module::Build;

my $build = Module::Build->new
    (
     module_name => 'Params::Smart',
     license => 'perl',
     requires => {
       'perl'             => '5.6.0',
       'Carp'             => 0,
       'Regexp::Common'   => 1.8,
     },
     recommends => {
       'Pod::Readme'      => 0.02,
#        'Test::Pod::Coverage' => 0,
#        'Test::Pod'      => 1.00,
#        'Test::Prereq'   => 0,
     },
     build_requires => {
       'Test::More'     => 0,
     },
     create_readme      => ($Module::Build::VERSION >= 0.2702),
     create_makefile_pl => 'traditional',
     dist_author        => 'Robert Rothenberg <rrwo at cpan.org>',
     sign               => 0,
);

$build->create_build_script;

