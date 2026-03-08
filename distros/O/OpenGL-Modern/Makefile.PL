use strict;
use ExtUtils::MakeMaker;
use Devel::CheckLib 'assert_lib';
use Config;

my $include = "-Ilib/OpenGL/Modern -Iinclude";
my $libs;
my $define = "-DGLEW_NO_GLU -DGLEW_STATIC";
my $DYNS;
if ( $^O eq 'MSWin32' ) {
  $libs   = '-lopengl32 -lgdi32 -lmsimg32';
  $define .= " -D_WIN32",
} elsif ( $^O eq 'cygwin' ) {
  $libs = '-lGL -lX11';
} elsif ( $^O eq 'darwin' ) {
  $DYNS = { 'OTHERLDFLAGS' => '-framework OpenGL' };
  $define .= " -Wno-compound-token-split-by-macro -DGL_SILENCE_DEPRECATION";
} else {
  $libs = '-lGL -lX11';
}
my %buildargs = (
  !$libs ? () : (LIBS => $libs),
  DEFINE           => $define,
  INC              => $include,
  !$DYNS ? () : ( dynamic_lib => $DYNS ),
);
die "$@\nOS unsupported\n" if !eval { assert_lib %buildargs; 1 };
WriteConfigPM({ LIBS => $libs || $DYNS->{OTHERLDFLAGS}, DEFINE => $define });

WriteMakefile(
  NAME => 'OpenGL::Modern',
  VERSION_FROM => 'lib/OpenGL/Modern.pm',
  ABSTRACT_FROM => 'lib/OpenGL/Modern.pod',
  AUTHOR => 'Chris Marshall <chm@cpan.org>',
  LICENSE => 'perl',
  PREREQ_PM => {
  },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '7.72',
    'Devel::CheckLib' => 0,
  },
  TEST_REQUIRES => {
    'Test::More' => '0.88',
  },
  TYPEMAPS => [qw(lib/OpenGL/Modern/Install/typemap)],
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      bugtracker  => {web=>'https://github.com/Perl-GPU/OpenGL-Modern/issues'},
      repository => {
        web  => 'https://github.com/Perl-GPU/OpenGL-Modern',
        url  => 'https://github.com/Perl-GPU/OpenGL-Modern.git',
        type => 'git',
      },
      x_IRC => 'irc://irc.perl.org/#pogl',
    },
  },
  MIN_PERL_VERSION => '5.016',
  XSPROTOARG       => '-noprototypes',
  XSMULTI => 1,
  XSBUILD => {
    xs => {
      'lib/OpenGL/Modern' => {
        OBJECT => join(' ', map "lib/OpenGL/Modern$_\$(OBJ_EXT)", '', qw(/glew /gl_counts /oglm)),
      },
      'lib/OpenGL/Modern/Const' => {
        OBJECT => join(' ', map "lib/OpenGL/Modern/$_\$(OBJ_EXT)", qw(Const glew oglm)),
      },
    },
  },
  depend           => {
    'lib/OpenGL/Modern$(OBJ_EXT)' => join(' ',
      qw(auto-xs.inc include/GL/glew.h include/GL/wglew.h),
      map "lib/OpenGL/Modern/$_", qw(
        glew-context.c gl_counts.h gl_errors.h Install/typemap oglm.h
    )), # first and last are not accurate but forced by XSMULTI which has no intermediate .c target
    'lib/OpenGL/Modern/Const$(OBJ_EXT)' => join(' ',
      qw(auto-xs-enums.inc auto-xs-var.inc include/GL/glew.h include/GL/wglew.h),
      map "lib/OpenGL/Modern/$_", qw(
        const.h oglm.h
    )),
    'lib/OpenGL/Modern/gl_counts$(OBJ_EXT)' => 'include/GL/glew.h',
  },
  clean => { FILES => 'auto-xs.inc auto-xs-enums.inc auto-xs-var.inc '.join ' ', map qq{lib/OpenGL/Modern/$_},
    qw(const.h Config.pm glew$(OBJ_EXT) gl_counts$(OBJ_EXT) oglm$(OBJ_EXT)) },
  %buildargs,
);

{
package MY; # so that "SUPER" works right
sub postamble {
  my ($self) = @_;
  my $deps = join ' ', 'lib/OpenGL/Modern/Registry.pm utils/generate-XS.pl utils/common.pl', glob 'include/GL/*.h';
  my $const_cmd = $self->oneliner(
    'print " OGL_CONST_i($_)\n" for @OpenGL::Modern::Registry::glconstants;',
    [qw(-Ilib -MOpenGL::Modern::Registry)],
  );
  <<EOF;
auto-xs.inc : $deps
\t\$(PERLRUN) -Ilib utils/generate-XS.pl

auto-xs-enums.inc auto-xs-var.inc : auto-xs.inc

lib/OpenGL/Modern/const.h : lib/OpenGL/Modern/Registry.pm
\t$const_cmd >\$@
EOF
}
sub init_PM {
  my ($eumm) = @_;
  $eumm->SUPER::init_PM;
  my $pm = $eumm->{PM};
  delete @$pm{grep /(?:\.(?:c|xs|bs)|\Q$::Config{obj_ext}\E)$/, keys %$pm};
  delete @$pm{grep /\.(?:pl|h)$/, keys %$pm};
}
}

sub WriteConfigPM {
  my($config) = @_;
  die "Unable to write to Config.pm\n" if !open my $fh, ">", "lib/OpenGL/Modern/Config.pm";
  print $fh q{# This is the Perl OpenGL build configuration file.
# It contains the final OpenGL build arguments from
# the configuration process.  Access the values by
# use OpenGL::Modern::Config which defines the variable
# $OpenGL::Modern::Config containing the hash arguments needed for
# WriteMakefile()
};
  require Data::Dumper;
  { no warnings; $Data::Dumper::Sortkeys = 1; } # deterministic output
  print $fh Data::Dumper->Dump( [$config], [qw(OpenGL::Modern::Config)] );
  print $fh qq{1;\n};
}
