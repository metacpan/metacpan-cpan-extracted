use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Test::A8N',
    VERSION_FROM      => 'lib/Test/A8N.pm',
    EXE_FILES         => [glob("scripts/*")],
    LICENSE           => 'perl',
    PREREQ_PM         => {
        'Test::FITesque' => '0.01',
        'Test::Deep'     => 0,
        'Moose'          => '0.33',
        'File::Find'     => 0,
        'YAML::Syck'     => '0.94',
        'Module::Load'   => 0,
        'Pod::Usage'     => 0,
        'File::Find'     => 0,
        'Test::Builder'  => 0,
        'Test::More'     => 0,
        'WWW::Selenium'  => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Test/A8N.pm', # retrieve abstract from module
       AUTHOR         => 'Michael Nachbaur <mike@nachbaur.com>') : ()),
);
