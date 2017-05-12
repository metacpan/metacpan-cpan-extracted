
use strict;
use ExtUtils::MakeMaker;

my $lib_name = 'betweenerperl';
my $lib_file = "lib$lib_name\$(LIB_EXT)";
my $cpp_path = '../cpp';
my $cc       = 'g++';

WriteMakefile(
    NAME    => "SDLx::Betweener::$lib_name",
    SKIP    => [qw(all static static_lib dynamic dynamic_lib)],
    clean   => {'FILES' => $lib_file},
    CC      => $cc,
    LD      => '$(CC)',
    INC     => "-I$cpp_path",
    CCFLAGS => '-fPIC',
);

sub MY::top_targets {
        '
all :: static

pure_all :: static

static :: '.$lib_file.'

'.$lib_file.': $(O_FILES)
	$(AR) cr '.$lib_file.' $(O_FILES)
	$(RANLIB) '.$lib_file.'
';
}
