use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Net::MarkLogic::XDBC',
    VERSION_FROM => 'lib/Net/MarkLogic/XDBC.pm', # finds $VERSION
    AUTHOR       => 'Tony Stubblebine (tonys@oreilly.com)',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'LWP::UserAgent' => 0,
                     'HTTP::Headers' => 0,
                     'Class::Accessor' => 0,
                     'Class::Fields' => 0,
                     'Template' => 0,
                    },
);
