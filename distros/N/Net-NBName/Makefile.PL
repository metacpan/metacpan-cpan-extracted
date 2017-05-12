use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME' => 'Net::NBName',
    'VERSION_FROM' => 'lib/Net/NBName.pm', # finds $VERSION
    'PREREQ_PM' => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ? ## Add these new keywords supported since 5.005
    (ABSTRACT => 'NetBIOS Name Service Requests',
     AUTHOR => 'James Macfarlane') : ()),
    # *.pm files will be automatically picked up from . or ./lib
    'EXE_FILES' => ['bin/namequery.pl', 'bin/nodestat.pl', 'bin/nodescan.pl'],
);
