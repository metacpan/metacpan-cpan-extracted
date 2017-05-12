use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PHP::Functions::File',
    VERSION_FROM      => 'lib/PHP/Functions/File.pm', # finds $VERSION
    PREREQ_PM         => {
        'Compress::Zlib' => '0',
        'LWP::UserAgent' => '0',
        'File::Spec'     => '0',
        'HTTP::Request'  => '0',
        'HTTP::Response' => '0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PHP/Functions/File.pm', # retrieve abstract from module
       AUTHOR         => 'Tomohide Nagashima <tnaga@cpan.org>') : ()),
);
