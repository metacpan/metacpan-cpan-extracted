use 5.008;
use ExtUtils::MakeMaker;
use Config;

# Take hints about where GLM is. Cribbed from XML::Parser.

$glm_libpath = '';
$glm_incpath = '';

my @replacement_args;
for (@ARGV) {
    if (/^GLM(LIB|INC)PATH=(.+)/) {
        if ($1 eq 'LIB') { $glm_libpath = $2; }
        else { $glm_incpath = $2; }
    } else { push(@replacement_args,$_); }
}
@ARGV = @replacement_args;

if (not $glm_libpath and $] > 5.006001) {
    require ExtUtils::Liblist;
    ($glm_libpath) = ExtUtils::Liblist->ext('-lglm');
}


unless ($glm_libpath) {
  # Test for existence of libglm
  my $found = 0;
  foreach (split(/\s+/, $Config{libpth})) {
    if (-f "$_/libglm." . $Config{so}) {
      $found = 1;
      last;
    }
  }

  unless ($found) {
    die <<'GLM_Not_Installed';
Please install libglm, from http://devernay.free.fr/hacks/glm/ .
If it is installed, then use the following options to Makefile.PL :

   GLMLIBPATH=... To set the directory in which to find libglm
   GLMINCPATH=... To set the directory in which to find glm.h

You may also need to set LD_LIBRARY_PATH.

GLM_Not_Installed
  }
}

my $libs = "-lglm";
if ($glm_libpath) { $libs = "-L$glm_libpath $libs" }

my $inc = "-I.";
if ($glm_incpath) { $inc = "-I$glm_incpath $inc" }

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'OpenGL::GLM',
    VERSION_FROM      => 'lib/OpenGL/GLM.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/OpenGL/GLM.pm', # retrieve abstract from module
       AUTHOR         => 'Jonathan Chin <jon-opengl-glm@earth.li') : ()),
    LIBS              => $libs, # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => $inc , # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(GLM_2_SIDED GLM_COLOR GLM_FLAT GLM_MATERIAL GLM_MAX_SHININESS
		 GLM_MAX_TEXTURE_SIZE GLM_NONE GLM_SMOOTH GLM_TEXTURE));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'OpenGL::GLM',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
