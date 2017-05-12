

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Muck',
    VERSION_FROM => 'lib/Muck.pm', # finds \$VERSION
    AUTHOR       => 'Mike Schroeder (info@muckos.org)',
    ABSTRACT     => 'manage the muck of an Amazon EC2 and S3 cloud',
    PREREQ_PM    => {
                     'Cache::Memcached' => 0,
                     'ConfigReader::Simple' => 0,
                     'DBI' => 0,
                     'Digest::HMAC_SHA1' => 0,
                     'Fuse' => 0.08, # we need 0.9 once it is out
                     'HTTP::Request' => 0,
                     'LWP::UserAgent' => 0,
                     'POE::Component::IKC::ClientLite' => 0,
                     'Test::More' => 0.44,
                     'URI::Escape' => 0,
                    },
);
