use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'      => 'Net::Jabber',
    'VERSION_FROM' => 'lib/Net/Jabber.pm',
    'PREREQ_PM' => {
        'Net::XMPP' => 1.0,
    },
    'dist' => {
        'COMPRESS' => 'gzip --best'
    }
);
