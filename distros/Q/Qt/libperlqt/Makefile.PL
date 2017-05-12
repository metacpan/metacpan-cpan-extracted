use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'libperlqt',
    'VERSION'	=> '0.03',
    'CC'	=> 'g++',
    'INC'	=> '-I$(QTDIR)/include -I../libperlqt/include',
    'OBJECT'	=> q{libperlqt$(OBJ_EXT)
		     virtual$(OBJ_EXT)
		     sigslot$(OBJ_EXT)
		     QLabel$(OBJ_EXT)
		     QObject$(OBJ_EXT)
		     QWidget$(OBJ_EXT)},
);

sub MY::install {
    '
install: all
	cp $(INST_DYNAMIC) /usr/local/lib
'
}
