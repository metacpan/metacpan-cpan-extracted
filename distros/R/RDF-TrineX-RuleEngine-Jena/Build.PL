use JenaRuleEngineBuild;
my $build_requires = {
    'Archive::Extract' => '0.48',
    'LWP::UserAgent' => '6.03',
    'Module::Build' => '0.38',
    'MooseX::NonMoose' => '0.16',
    'Pod::Readme' => '0.11',
    'Pod::Select' => '1.36',
    'POSIX' => '1.24',
};
my $build = JenaRuleEngineBuild->new(
    module_name => 'RDF::TrineX::RuleEngine::Jena',
    license => 'perl',
    JENAROOT_share => 'share/JENAROOT',
    dist_abstract => 'Wrapper around the Jena rule engine command line interface',
    dist_author => 'konstantin baierer <kba@cpan.org>',
    dist_version_from   => 'lib/RDF/TrineX/RuleEngine/Jena.pm',
    license     => 'perl',
    requires    => {
        'Archive::Zip' => '1.30',
        'Carp' => '1.20',
        'Data::Dumper' => '2.130_02',
        'English' => '1.04',
        'File::Copy' => '2.21',
        'File::Find' => '1.19',
        'File::Share' => '0.02',
        'File::Slurp' => '9999.19',
        'File::Temp' => '0.22',
        'IO::CaptureOutput' => '1.1102',
        'Moose' => '2.0205',
        'Path::Class' => '0.18',
        'RDF::Trine' => '0.136',
        'Try::Tiny' => '0.09',
    },
    build_requires => $build_requires,
    configure_requires => $build_requires,
    # create_makefile_pl => 'passthrough',
);
$build->clean_JENAROOT_share;
$build->create_build_script;
