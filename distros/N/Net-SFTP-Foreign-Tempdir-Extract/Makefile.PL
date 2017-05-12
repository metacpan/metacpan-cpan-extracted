use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Net::SFTP::Foreign::Tempdir::Extract',
    VERSION_FROM => 'lib/Net/SFTP/Foreign/Tempdir/Extract.pm',
    AUTHOR       => 'Michael R. Davis (mdavis@stopllc.com)',
    ABSTRACT_FROM=> 'lib/Net/SFTP/Foreign/Tempdir/Extract.pm',
    LICENSE      => "perl",
    PREREQ_PM    => {
                     'Test::Simple'       => 0.44,
                     'Package::New'       => 0,
                     'Net::SFTP::Foreign' => 0,
                     'File::Tempdir'      => 0,
                     'Path::Class'        => 0,
                     'Archive::Zip'       => 0,
                    },
);
