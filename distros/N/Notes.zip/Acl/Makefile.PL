use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	   =>   'Notes::Acl',
    'VERSION_FROM' =>   'Acl.pm',         # finds $VERSION
    'DL_FUNCS'     => { 'Notes::Acl' => [ qw( enum_has_entryname
                                              enum_xpush_all_entrynames
                                        ) ]
                      },
    'TYPEMAPS'     => [ '../ln_typemap' ],

    'LIBS'         => [ q(-Lc:\Programme\vcpp42\lib
                          -Lc:\Programme\notes\apic461\lib\mswin32
                          -lnotes)
                      ],
#                          -Ld:\zmar\programs\vcpp42\lib
#                          -Ld:\zmar\notes\apic461\lib\mswin32
#                          -Lc:\notes\apic461\lib\mswin32
                                          # Win32/C-Runtime/Notes C API
                                          # libpaths and libraries

    'DEFINE'	   =>   ' -DW32 ',        # needed by Notes C API

    'CCFLAGS'      =>   ' -Zp -G3 -W3 '   # align structures on
                                          #   1-byte boundaries
                                          #   as needed by Notes C API
                                          # NOTE: It is unclear, wether
                                          #       we must rebuild the
                                          #       CORE perl with -Zp

                      . ' -Od -MD '       # standard Perl-build defines
                      . ' -DNDEBUG '
                      . ' -DWIN32 '
                      . ' -D_CONSOLE '
                      . ' -DNO_STRICT ',

    'INC'          => join( ' ', '-I..',
                                 '-Ic:\Programme\notes\apic461\include',
#                                 '-Ic:\notes\apic461\include',
#                                 '-Id:\zmar\notes\apic461\include'
                      ),
                                          # parent dir for our ln_*.h's
                                          # and Notes C API include dir
);
