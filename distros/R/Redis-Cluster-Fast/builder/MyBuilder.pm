package builder::MyBuilder;
use strict;
use warnings FATAL => 'all';
use 5.008005;
use base 'Module::Build::XSUtil';
use Config;
use Devel::CheckBin qw(check_bin);
use File::Spec;
use File::Which qw(which);
use File::chdir;

sub is_debug {
    -d '.git';
}

sub _build_dependencies {
    my $self = shift;

    my $abs = File::Spec->rel2abs('./deps');
    # Skip if already built
    return if -e "$abs/build";

    check_bin('patch');
    # libevent
    check_bin('autoconf');
    check_bin('automake');
    check_bin('libtoolize');
    check_bin('pkg-config');

    my $make;
    if ($^O =~ m/(bsd|dragonfly)$/ && $^O !~ m/gnukfreebsd$/) {
        my $gmake = which('gmake');
        unless (defined $gmake) {
            print "'gmake' is necessary for BSD platform.\n";
            exit 0;
        }
        $make = $gmake;
    } else {
        $make = $Config{make};
    }
    if (is_debug) {
        $self->do_system('git', 'submodule', 'update', '--init');
    }
    $self->do_system('patch -N -p1 < deps/async_context_always_use_resp3.patch');

    # libevent
    {
        local $CWD = "deps/libevent";
        $self->do_system('./autogen.sh');
        $self->do_system('./configure',
            '--disable-openssl',
            '--disable-samples',
            '--disable-shared',
            '--with-pic',
            '--prefix',
            "$abs/build/usr/local",
        );
        $self->do_system($make);
        $self->do_system($make, 'install');
    }

    # hiredis
    $self->do_system($make, '-C', 'deps/hiredis', "USE_SSL=0", "DESTDIR=$abs/build", 'all', 'install');

    # hiredis-cluster
    $self->do_system($make, '-C', 'deps/hiredis-cluster',
        "CFLAGS=-I$abs/build/usr/local/include -D_XOPEN_SOURCE=600",
        "LDFLAGS=-L$abs/build/usr/local/lib",
        "USE_SSL=0",
        "DESTDIR=$abs/build",
        'clean',
        'install',
    );
}

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(
        %args,
        generate_ppport_h => 'src/ppport.h',
        c_source => 'src',
        xs_files => { './src/Fast.xs' => './lib/Redis/Cluster/Fast.xs', },
        include_dirs => [
            'src',
            'deps/build/usr/local/include',
        ],
        extra_linker_flags => [
            "deps/build/usr/local/lib/libevent$Config{lib_ext}",
            "deps/build/usr/local/lib/libhiredis$Config{lib_ext}",
            "deps/build/usr/local/lib/libhiredis_cluster$Config{lib_ext}",
        ],
    );

    $self->_build_dependencies;

    $self->config(optimize => '-g3 O0 -fsanitize=undefined,leak -fno-sanitize-recover=all -Wall')
        if is_debug;

    return $self;
}

1;
