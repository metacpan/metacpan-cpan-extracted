use Module::Build;
# http://odyniec.net/blog/2011/11/github-friendly-readme-files-with-extutils-makemaker-and-module-build/
my $class = Module::Build->subclass(
    class => 'My::Builder',
    code => q{
        sub ACTION_docs {
            use Pod::Readme;
            use Pod::Select;
 
            my $self = shift;
            unlink 'README.pod';
            unlink 'README';
 
            podselect({ -output => 'README.pod' },
                'lib/RDF/Trine/Serializer/SparqlUpdate.pm');
 
            my $parser = Pod::Readme->new();
            $parser->parse_from_file('README.pod', 'README');
            warn "Built README";
 
            return $self->SUPER::ACTION_docs;
        }
    }
);
my $build = $class->new(
    module_name => 'RDF::Trine::Serializer::SparqlUpdate',
    license => 'perl',
    dist_abstract => 'SPARQL/Update serializer for RDF::Trine',
    dist_author => 'konstantin baierer <kba@cpan.org>',
    dist_version_from   => 'lib/RDF/Trine/Serializer/SparqlUpdate.pm',
    license     => 'perl',
    requires    => {
        'Moose' => '2.0',
        'RDF::Trine' => '0.136',
        'Try::Tiny' => '0.09',
        'IO::Handle::Iterator' => 0,
        # 'Data::UUID' => '1.217',
        # 'File::Path' => 0,
        # 'File::Temp' => 0,,
        # 'File::Slurp' => '9999.19',
        # 'RDF::RDFa::Parser' => '1.096',
        # 'Module::Load' => '0.18',
        # 'namespace::clean' => 0,
        # 'MooseX::Types' => '0.30',
        # 'MooseX::Types::URI' => '0.03',
        # 'MooseX::ClassAttribute' => '0.26',
        # # 'MooseX::Unique' => '0.005',
        # 'LWP::UserAgent' => 0,
        # 'Scalar::Util' => 0,
        # 'Set::Object' => 1.28,
        # 'URI' => 0,
        # 'RDF::NS' => '20111124',

        # 'perl'          => '5.6.1',
        # 'Some::Module'  => '1.23',
        # 'Other::Module' => '>= 1.2, != 1.5, < 2.0',
    },
    build_requires => {
        'String::Diff' => 0,
        'Term::ANSIColor' => 0,
        'RDF::Endpoint' => '0.04',
        'SUPER' => 0,
        'YAML::XS' => 0,
        'LWP::Protocol::PSGI' => 0,
        'Pod::Readme' => 0,
        'Pod::Select' => 0,
    },
    configure_requires => {
        'Pod::Readme' => 0,
        'Pod::Select' => 0,
        'Module::Build' => 0.38,
    },
    create_makefile_pl => 'traditional',
);
$build->create_build_script;
