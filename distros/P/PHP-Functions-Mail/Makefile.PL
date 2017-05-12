use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PHP::Functions::Mail',
    VERSION_FROM      => 'lib/PHP/Functions/Mail.pm', # finds $VERSION
    PREREQ_PM         => {
        'Net::SMTP' => '0',
        'Jcode' => '0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PHP/Functions/Mail.pm', # retrieve abstract from module
       AUTHOR         => 'Kazuhiro Osawa <ko@yappo.ne.jp>') : ()),
);
