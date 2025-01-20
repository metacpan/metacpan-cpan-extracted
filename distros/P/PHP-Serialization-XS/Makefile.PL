#use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $ccflags = $Config::Config{ccflags} || '';
WriteMakefile(
    NAME              => 'PHP::Serialization::XS',
    VERSION_FROM      => 'lib/PHP/Serialization/XS.pm', # finds $VERSION
    PREREQ_PM         => { 'PHP::Serialization' => '0.33' }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PHP/Serialization/XS.pm', # retrieve abstract from module
       AUTHOR         => 'Darren Kulp <darren@kulp.ch>') : ()),
    LIBS              => [ ],
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I. -Iphpserialize/parser', # e.g., '-I. -I/usr/include/other'
    OBJECT            => '$(O_FILES) phpserialize/parser/stringstore.o phpserialize/parser/ps_parser.o',
    LDFROM            => '$(O_FILES) stringstore.o ps_parser.o', # link all the C files too
    # TODO switch to C89 or otherwise permit building on Solaris
    CCFLAGS           => "-std=c99 $ccflags",
);

