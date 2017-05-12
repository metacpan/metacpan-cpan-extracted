use 5.008000;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Devel::CheckOS qw(os_is);

my ( $DEFS, $INCS, $LIBS, $DYNS, $LDFROM, $EXES, $OPTS ); 

$EXES = [];
$DYNS = {};

if ( os_is( 'MSWin32' ) ) {
    $LIBS   = '-lopengl32 -lgdi32 -lmsimg32';
}
elsif ( os_is( 'Cygwin' ) ) {
    $LIBS = '-lGL -lX11';
}
elsif ( os_is( 'MacOSX' ) ) {
    $DYNS = { 'OTHERLDFLAGS' => '-framework OpenGL' };
}
else {
    $LIBS = '-lGL -lX11';
}

# This is the final build configuration
my $build_config =
{
    'NAME'              => 'OpenGL::Array',
    'VERSION_FROM'      => 'lib/OpenGL/Array.pm',  # finds $VERSION, requires EU::MM from perl >= 5.5
    'ABSTRACT_FROM'     => 'lib/OpenGL/Array.pod', # retrieve abstract from module
    'PREREQ_PM'         => {
        'Test::More' => 0
    },
    'CONFIGURE_REQUIRES' => {
        'Devel::CheckOS' => 0,
        'ExtUtils::MakeMaker' => 6.52,  # for CONFIGURE_REQUIRES
    },
    'LICENSE'           => 'perl',
    #'PM'                => { },
    'AUTHOR'            => "Chris Marshall ".'<chm at cpan dot org>',
    'OBJECT'            => 'opengl_array$(OBJ_EXT) gl_util$(OBJ_EXT) opengl_matrix$(OBJ_EXT)', 
    'XSPROTOARG'        => '-noprototypes',
    'DEFINE'            => $DEFS,
    'INC'               => $INCS,
    'LIBS'              => $LIBS,
    'dynamic_lib'       => $DYNS,
    'LDFROM'            => '$(OBJECT) '.(defined($LDFROM)?$LDFROM:''),
    'META_MERGE'        => {
        resources       => {
            homepage    => 'http://sourceforge.net/projects/pogl/',
            bugtracker  => 'https://github.com/devel-chm/OpenGL-Array/issues',
            repository  => 'https://github.com/devel-chm/OpenGL-Array.git',
        },
    },
    'EXE_FILES'         => $EXES,
    'OPTIMIZE'          => $OPTS,
    #'clean'       => { FILES => }
};

WriteMakefile( %$build_config );                # Generate the Makefile
