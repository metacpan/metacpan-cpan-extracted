use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'Net::Yadis',
    'AUTHOR' => 'Dag Arneson <dag@janrain.com>',
    'VERSION_FROM' => 'lib/Net/Yadis.pm',
    'PREREQ_PM' => {
                    'LWP::UserAgent' => 0,
                    'XML::XPath' => 0,
                   },
    );
