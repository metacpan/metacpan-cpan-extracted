use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'      => 'Win32::Wingraph',
    'VERSION_FROM' => 'Wingraph.pm', # finds $VERSION
    'LDFROM' => '$(OBJECT)',
    'LIBS'      => ['gdi32.lib user32.lib fm.lib'],   # e.g., '-lm'
);