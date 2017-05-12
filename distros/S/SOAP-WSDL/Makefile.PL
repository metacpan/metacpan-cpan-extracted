use 5.010000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'SOAP::WSDL',
    VERSION_FROM      => 'lib/SOAP/WSDL.pm',
    PREREQ_PM         => {
        'Class::Std::Fast'        => q(0.000005),
        'Cwd'                     => 0,
        'Data::Dumper'            => 0,
        'Date::Format'            => 0,
        'Date::Parse'             => 0,
        'File::Basename'          => 0,
        'File::Path'              => 0,
        'File::Spec'              => 0,
        'Getopt::Long'            => 0,
        'LWP::UserAgent'          => 0,
        'List::Util'              => 0,
        'Module::Build'           => 0,
        'Storable'                => 0,
        'Template'                => q(2.18),
        'Term::ReadKey'           => 0,
        'Test::More'              => 0,
        'URI'                     => 0,
        'XML::Parser::Expat'      => 0,
        'Class::Load'             => 0.20,
        'perl'                    => q(5.008),
    },
    test => { RECURSIVE_TEST_FILES => 1, },
    ABSTRACT_FROM  => 'lib/SOAP/WSDL.pm',
    AUTHOR       => 'Scott Walters <scott@slowass.net>',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
    'meta-spec' => { version => 2 },
     resources => {
         repository => {
             type => 'git',
             url  => 'https://github.com/scrottie/SOAP-WSDL.git',
             web  => 'https://github.com/scrottie/SOAP-WSDL',
         },
     }})
     : ()
   ),
);

