use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	    => 'Net::Prizm',
    'ABSTRACT_FROM' => 'lib/Net/Prizm.pm',
    'AUTHOR'        => 'Jeff Finucane <jeff-net-prizm@weasellips.com>',
    'VERSION_FROM'  => 'lib/Net/Prizm.pm', # finds $VERSION
    'PREREQ_PM'     => { SOAP::Lite => 0.71 },
);
