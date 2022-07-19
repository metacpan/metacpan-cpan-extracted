use strict;
use warnings;

use ExtUtils::MakeMaker::CPANfile;
use ExtUtils::PkgConfig;
use File::Spec;
use File::Temp;

my $pc_name = 'libnfs';

my $min_major_version = 5;

my $cflags = ExtUtils::PkgConfig->cflags($pc_name) || q<>;
my $pc_ldflags = ExtUtils::PkgConfig->libs($pc_name);

my $use_dynamic;

if ($pc_ldflags) {
    my $modversion = ExtUtils::PkgConfig->modversion($pc_name);
    print "I found a shared libnfs version $modversion.\n";

    my ($major) = $modversion =~ m<(\d+)>;

    if ($major >= $min_major_version) {
        print "That’s recent enough for us, so we’ll use it.\n";
    }
    else {
        print "That’s too old for us; we need at least version $min_major_version.\n";
    }
}

my @link_args;

my $cmake_path;

my $build_path = File::Spec->catdir(qw(libnfs build));

my $STATIC_INSTALL_DIR = do {
    File::Spec->catdir(Cwd::getcwd(), 'libnfs-install');
};

if ($use_dynamic) {
    print "I found a shared libnfs, so I’ll use it:\n";
    print "    libs: $pc_ldflags\n";
    print "    cflags: $cflags\n";

    push @link_args, ( LIBS => $pc_ldflags );
}
else {
    print "I found no usable shared libnfs, so I’ll try to make a static one.\n";

    mkdir $build_path or do {
        die "mkdir($build_path): $!" if !$!{'EEXIST'};
    };

    if (eval { require Alien::cmake3 }) {
        print "You have Alien::cmake3. We’ll use its cmake.\n";
        $cmake_path = File::Spec->catfile(
            Alien::cmake3->bin_dir(),
            Alien::cmake3->exe(),
        );
    }
    else {
        print "You don’t seem to have Alien::cmake3; do you maybe have your own cmake binary?\n";
        require File::Which;
        $cmake_path = File::Which::which('cmake');
    };

    if (!$cmake_path) {
        die "No cmake found; can’t proceed.\n";
    }

    print "cmake found: $cmake_path\n";

    $cflags = join(
        q< >,
        map { '-I' . File::Spec->catdir(@$_) } (
            [ $STATIC_INSTALL_DIR, 'include' ],
        ),
    );

    push @link_args, (
        OBJECT => join(
            q< >,
            '$(BASEEXT)$(OBJ_EXT)',
            File::Spec->catfile( $STATIC_INSTALL_DIR, qw(lib libnfs.a) ),
        ),
    );
}

my $main_pm = File::Spec->catfile( qw( lib Net LibNFS.pm ) );

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::LibNFS',
    VERSION_FROM      => $main_pm,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => $main_pm,
       AUTHOR         => [
            'Felipe Gasper (FELIPE)',
        ],
      ) : ()
    ),
    LICENSE => "perl_5",

    INC => join(
        q< >,
        '-Wall',
        '-std=c99',
        $cflags,
    ),

    @link_args,

    PMLIBDIRS => ['lib'],

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/FGasper/p5-Net-LibNFS.git',
                web => 'https://github.com/FGasper/p5-Net-LibNFS',
            },
            bugtracker => {
                web => 'https://github.com/FGasper/p5-Net-LibNFS/issues',
            },
        },
    },
);

# ----------------------------------------------------------------------

package MY;

use Config;

sub postamble {
    return q<> if $use_dynamic;

    my @cflags = (
        '-fPIC',
    );

    my @cmake_opts = (
        -D => qq/CMAKE_C_FLAGS='@cflags'/,
        -D => qq/BUILD_SHARED_LIBS=OFF/,
        -D => qq/CMAKE_INSTALL_PREFIX=$STATIC_INSTALL_DIR/,
        -D => qq/CMAKE_MAKE_PROGRAM=$Config{make}/,
    );

    if ($^O eq 'MSWin32') {
        push @cmake_opts, -G => q<'MinGW Makefiles'>,
    }

    # NB: $cmake_path might have a space; ergo, we quote it.
    return <<"MAKE_FRAG"

.PHONY:
build-libnfs:
\t'$cmake_path' @cmake_opts -S libnfs -B $build_path
\t\$(MAKE) -C $build_path install
MAKE_FRAG
}

my $orig_top_targets;
BEGIN {
$orig_top_targets = __PACKAGE__->can('top_targets');
}

sub top_targets {
    my $out = $orig_top_targets->(@_);

    if (!$use_dynamic) {
        $out =~ s<^(all\s*:+s*)><$1 build-libnfs >;
    }

    return $out;
}
