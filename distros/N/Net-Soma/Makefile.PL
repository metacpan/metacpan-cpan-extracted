use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	    => 'Net::Soma',
    'ABSTRACT_FROM' => 'Soma.pm',
    'AUTHOR'        => 'Jeff Finucane <jeff-net-soma@weasellips.com>',
    'VERSION_FROM'  => 'Soma.pm', # finds $VERSION
    'PREREQ_PM'     => { SOAP::Lite => 0.71 },
);
