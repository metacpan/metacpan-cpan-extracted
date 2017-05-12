
use strict;
use ExtUtils::MakeMaker;

my $lib      = 'betweener';
my $test     = 'betweener_unit_tests';
my $cpp_path = '../cpp';
my $lib_ar   = "$cpp_path/lib$lib\$(LIB_EXT)";
my $cc       = 'g++';

WriteMakefile(
    NAME    => "SDLx::Betweener::$test",
    SKIP    => [qw(all static static_lib dynamic dynamic_lib)],
    CC      => $cc,
    LD      => '$(CC)',
    clean   => {'FILES' => $test},
    CCFLAGS => '-fPIC',
    INC     => "-I$cpp_path",
);

sub MY::top_targets {
        '
all :: static

pure_all :: static

static :: $(O_FILES)
	$(LD) $(O_FILES) '.$lib_ar.' -o '.$test.'
';
}
