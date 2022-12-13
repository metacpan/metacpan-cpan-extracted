use strict;
use warnings;

use ExtUtils::MakeMaker::CPANfile;
use File::Spec;
use File::Temp;
use Config;

my $pc_name = 'libnfs';

my $min_major_version = 5;

my ($cflags, $pc_ldflags);

my $use_dynamic;

if ($ENV{'NET_LIBNFS_LINK_STATIC'}) {
    print "You asked specifically for a static libnfs.\n";
}
else {
    if (eval { require ExtUtils::PkgConfig }) {
        print "Querying pkg-config for a usable libnfs …\n";

        $pc_ldflags = ExtUtils::PkgConfig->libs($pc_name);

        if ($pc_ldflags) {
            $cflags = ExtUtils::PkgConfig->cflags($pc_name) || q<>;

            my $modversion = ExtUtils::PkgConfig->modversion($pc_name);
            print "I found a shared libnfs, version $modversion.\n";

            my ($major) = $modversion =~ m<(\d+)>;

            if ($major >= $min_major_version) {
                print "That’s recent enough for us, so we’ll use it.\n";
                $use_dynamic = 1;
            }
            else {
                print "That’s too old; we need at least version $min_major_version.\n";
            }
        }
    }
    else {
        print $@;
        print "ExtUtils::PkgConfig didn’t load, so we can’t check for a shared libnfs.\n";
    }
}

my @link_args;

my $cmake_path;

my $build_path = File::Spec->catdir(qw(libnfs build));

my $STATIC_INSTALL_DIR = do {
    File::Spec->catdir(Cwd::getcwd(), 'libnfs-install');
};

my @defines;

my @checks = (
    ( map {
        my $func = $_;

        my $define = "NLNFS_$func";
        $define =~ tr<a-z><A-Z>;

        {
            label => $func,
            c => [
                '#include <nfsc/libnfs.h>',
                'int main() {',
                "   (void)($func);",
                '   return 0;',
                '}',
            ],
            define => $define,
        };
    } (
        'nfs_set_auto_traverse_mounts',
        'nfs_set_nfsport',
        'nfs_set_mountport',
        'nfs_set_readdir_max_buffer_size',
    ) ),
);

if ($use_dynamic) {
    print "I found a suitable shared libnfs, so I’ll use it:\n";
    print "    libs: $pc_ldflags\n";
    print "    cflags: $cflags\n";

    push @link_args, ( LIBS => $pc_ldflags );

    if ($^O !~ /^(MSWin32|darwin|solaris)$/ && ($Config{ld} =~ /gcc|g\+\+/ ||     $Config{gccversion})) {
       push @link_args, (LDDLFLAGS => "$Config{lddlflags} -Wl,--exclude-libs,ALL");
    }

    my $ccpath = $ENV{'CC'} || $Config::Config{'cc'};
    print "Your C compiler appears to be: $ccpath\n";

    for my $check (@checks) {
        my $tdir = File::Temp::tempdir( CLEANUP => 1 );
        my $cpath = File::Spec->catdir( $tdir, 'check.c' );
        my $progpath = File::Spec->catdir( $tdir, 'check' );

        {
            open my $wfh, '>', $cpath;
            print {$wfh} "$_$/" for @{ $check->{'c'} };
        }

        my $cmd = "$ccpath $Config{'ccflags'} $cflags $cpath -o $progpath $Config{ccdlflags} $pc_ldflags";
        system($cmd);

        print "$check->{'define'}: ";
        if (-s $progpath) {
            print "yes";
            push @defines, $check->{'define'};
        }
        else {
            print "no";
        }

        print $/;
    }
}
else {
    print "I found no usable shared libnfs, so I’ll try to make a static one.\n";

    # We’ll build our own libnfs, which is recent enough to have all
    # the latest bells & whistles.
    #
    push @defines, map { $_->{'define'} } @checks;

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

    DEFINE => join(
        q< >,
        map { "-D$_" } @defines,
    ),

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
\t'$cmake_path' @cmake_opts -B $build_path -S libnfs
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
