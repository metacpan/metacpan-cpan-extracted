use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	=> 'RCU::Irman',
    VERSION_FROM=> 'Irman.pm',
    LIBS	=> ['-lirman'],
    EXE_FILES	=> ['rcu-irman-helper'],
    DEFINE	=> '',
    INC		=> '',
);

sub MY::postamble {
   <<'EOF';

all :: rcu-irman-helper

rcu-irman-helper: rcu-irman-helper.c ../helper.c
	$(CC) -o rcu-irman-helper $(CCFLAGS) $(OPTIMIZE) $(DEFINE) $(INC) rcu-irman-helper.c $(LDFLAGS) $(EXTRALIBS)

EOF
}
