

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Net::Server::Mail::ESMTP::SIZE',
    VERSION_FROM => 'lib/Net/Server/Mail/ESMTP/SIZE.pm', # finds \$VERSION
    AUTHOR       => 'Jose Luis Martinez (jlmartinez@capside.com)',
    ABSTRACT     => 'add support for the SIZE ESMTP extension to Net::Server::Mail',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
		     'Test::SMTP'   => 0.02,
		     'Net::Server::Mail' => 0.13
                    },
    LICENSE      => 'perl'
);
