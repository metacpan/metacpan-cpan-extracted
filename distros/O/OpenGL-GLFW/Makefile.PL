use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence

my $libs = qx(pkg-config glfw3 --libs --static);
my $incs = qx(pkg-config glfw3 --cflags);

# Try something if the pkg-config failed
my $LIBS = ($libs ? $libs : '-lglfw3');
my $INCS = ($incs ? $incs : '');

# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'OpenGL::GLFW',
    VERSION_FROM      => 'lib/OpenGL/GLFW.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'ExtUtils::MakeMaker' => 6.64,         # needed for TEST_REQUIRES
    },
    MIN_PERL_VERSION => '5.010',
    TEST_REQUIRES     => {
        'OpenGL::Modern' => '0.0401',
    },
    ABSTRACT_FROM     => 'lib/OpenGL/GLFW.pm', # retrieve abstract from module
    AUTHOR            => 'Chris Marshall <chm@cpan.org>',
    LICENSE           => 'perl',
    LIBS              => ["$LIBS"],            # e.g., '-lm'
    DEFINE            => '',                   # e.g., '-DHAVE_SOMETHING'
    INC               => "$INCS",              # e.g., '-I. -I/usr/include/other'
    # Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)',       # link all the C files too
    META_MERGE        => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/devel-chm/OpenGL-GLFW.git',
                web => 'https://github.com/devel-chm/OpenGL-GLFW.git',
            },
        },
    },
);
