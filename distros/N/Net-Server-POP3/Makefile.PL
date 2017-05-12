use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Net::Server::POP3',
    VERSION_FROM => 'lib/Net/Server/POP3.pm', # finds $VERSION
    AUTHOR       => 'Jonadab the Unsightly One (Nathan Eady) (jonadab@bright.net)',
    ABSTRACT     => 'Net::Server::POP3 implements the server side of the POP3 mail protocol for allowing client applications to retrieve email.',
    PREREQ_PM    => {
                     Test::Simple => 0.44,
                     Net::Server  => 0.87,
                     Exporter     => 0,
                     # Some of the scripts in the distribution also
                     # use other modules, including Mail::POP3Client
                     # and DateTime::Format::Mail, but the module
                     # itself does not require these.
                    },
);
