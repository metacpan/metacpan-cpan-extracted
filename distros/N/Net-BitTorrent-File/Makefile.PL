use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Net::BitTorrent::File',
    VERSION_FROM => 'lib/Net/BitTorrent/File.pm', # finds $VERSION
    AUTHOR       => 'R. Kyle Murphy (orclev@rejectedmaterial.com)',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Digest::SHA1' => 2.00,
                     'Convert::Bencode' => 1.03,
                    },
);
