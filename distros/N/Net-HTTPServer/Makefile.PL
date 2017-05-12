use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'      => 'Net::HTTPServer',
    'PREREQ_PM' => { 'URI'  => 1.27 },
    'VERSION_FROM'  => 'lib/Net/HTTPServer.pm',
    'dist' => {
        'COMPRESS' => 'gzip --best'
    }
);
