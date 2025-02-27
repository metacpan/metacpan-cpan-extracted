use 5.036000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
use Oh;
WriteMakefile(
    NAME              => 'Oh',
    VERSION_FROM      => 'lib/Oh.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT          => "Lisp interpreter with the power of cpan.", 
    AUTHOR            => '.:VMS:. <vmsisnice@pause.org>',
    LICENSE           => 'unrestricted',
    EXE_FILES         => ['./bin/oh'],
    META_MERGE => { provides => { 'Oh' => { file => 'lib/Oh.pm', version => $Oh::VERSION } } }

);
