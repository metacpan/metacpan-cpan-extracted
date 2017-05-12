use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Notes::Object',
    'TYPEMAPS'          => ['../ln_typemap'],
    'VERSION_FROM'	=> 'Object.pm', # finds $VERSION
        'PREREQ_PM'		=> {},             # e.g., Module::Name => 1.1
        ($] >= 5.005 ?                         # Add these new keywords supported since 5.005
          (ABSTRACT_FROM  => 'Object.pm',     # retrieve abstract from module
           AUTHOR         => 'Christian Cloutier <christian.cloutier@eds.com>') : ()),
           DEFINE         => ' -DW32 ',        # needed by Notes C API
           OBJECT         => 'object.obj',
           LIBS           => 'notes.lib',
           CCFLAGS        => ' -Zp -G3 -W3 '   # align structures on
                                               #   1-byte boundaries
                                               #   as needed by Notes C API        
                           . ' -Od -MD '       # standard Perl-build defines
                           . ' -DNDEBUG '
                           . ' -DWIN32 '
                           . ' -D_CONSOLE '
                           . ' -DNO_STRICT '
);