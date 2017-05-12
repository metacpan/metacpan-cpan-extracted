use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Net::Safari',
    VERSION_FROM => 'lib/Net/Safari.pm', # finds $VERSION
    AUTHOR       => 'Tony Stubblebine (tonys@oreilly.com)',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Test::Simple'    => 0.44,
                     'XML::Simple'     => 0,
                     'LWP::UserAgent'  => 0,
                     'URI::Escape'     => 0,
                     'Class::Accessor' => 0,
                     'Class::Fields'   => 0,
                     'Data::Dumper'    => 0,
                     'Test::More'      => 0,
                    },
);
