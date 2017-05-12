use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Parse::ExuberantCTags::Merge',
    VERSION_FROM      => 'lib/Parse/ExuberantCTags/Merge.pm', # finds $VERSION
    PREREQ_PM         => {
      'Class::XSAccessor' => '1.03',
      'Sort::External'    => '0',
      'File::Copy'        => '0',
      'File::Temp'        => '0',
      'Getopt::Long'      => '0',
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Parse/ExuberantCTags/Merge.pm', # retrieve abstract from module
    AUTHOR            => 'Steffen Mueller <smueller@cpan.org>',
    #LIBS              => [''], # e.g., '-lm'
    #DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    #INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    #OBJECT            => '$(O_FILES)', # link all the C files too
    #'TYPEMAPS'        => ['perlobject.map', 'typemap'],
    EXE_FILES => [qw(bin/ctags-merger)],
);
