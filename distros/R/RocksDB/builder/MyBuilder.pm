package builder::MyBuilder;
use 5.008_001;
use strict;
use warnings;
use parent 'Module::Build';

our $ROCKSDB_DIR = 'vendor/rocksdb';

sub new {
    my ($class, %args) = @_;
    %args = (get_options => { 'with-included-rocksdb' => { type => '!' } }, %args);
    my $self = $class->SUPER::new(%args);
    $self->check_compiler or die 'C++11 compiler required';
    my $make_config = $self->parse_make_config();
    my @extra_compiler_flags = (
        qw(-x c++ -std=gnu++11 -I.),
        qw(
            -Wall
            -Wno-reserved-user-defined-literal
            -Wno-duplicate-decl-specifier
            -Wno-parentheses
            -Wno-unused
            -Wno-literal-suffix
            -Wno-unknown-warning-option
        ),
        split(/\s+/, $make_config->{PLATFORM_CXXFLAGS}),
    );
    my @extra_linker_flags = (
        qw(-lstdc++ -lrocksdb),
        split(/\s+/, $make_config->{PLATFORM_LDFLAGS}),
    );
    if ($self->args('with-included-rocksdb') || !$self->have_rocksdb($make_config)) {
        push @extra_compiler_flags, "-I$ROCKSDB_DIR/include";
        push @extra_linker_flags, "-L$ROCKSDB_DIR";
    }
    my $ld = $self->config('ld');
    if ($ld =~ s/^\s*env MACOSX_DEPLOYMENT_TARGET=[^\s]+ //) {
        $self->config(ld => $ld);
    }
    if ($self->is_debug) {
        $self->config(optimize => '-g -O0');
    }
    $self->extra_compiler_flags(@extra_compiler_flags);
    $self->extra_linker_flags(@extra_linker_flags);
    $self;
}

sub check_compiler {
    my $self = shift;
    require File::Temp;
    print 'checking for C++11 support... ';
    my ($fh, $filename) = File::Temp::tempfile(SUFFIX => '.cc', UNLINK => 1);
    print $fh <<'END_SRC';
#if __cplusplus < 201103L
#error C++11 Required
#endif
END_SRC
    my $cc = $self->config('cc');
    my $failed = system "$cc -x c++ -std=gnu++11 $filename -c -o /dev/null >/dev/null 2>&1";
    print $failed ? "no\n" : "yes\n";
    !$failed;
}

sub parse_make_config {
    my $self = shift;
    my $file = File::Spec->catfile($ROCKSDB_DIR, 'make_config.mk');
    -f $file or $self->gen_make_config();
    open my $fh, '<', $file or die $!;
    my %config;
    while (defined(my $line = <$fh>)) {
        chomp $line;
        my ($key, $val) = split '=', $line, 2;
        $val =~ s/^\s+//;
        $val =~ s/\s+$//;
        $config{$key} = $val;
    }
    close $fh;
    \%config;
}

sub gen_make_config {
    my $self = shift;
    require Cwd;
    my $script = File::Spec->catfile('build_tools', 'build_detect_platform');
    -e File::Spec->catfile($ROCKSDB_DIR, $script) or $self->fetch_rocksdb();
    my $cwd = Cwd::getcwd;
    chdir $ROCKSDB_DIR or die $!;
    local $ENV{ROCKSDB_ROOT} = Cwd::getcwd;
    system $script, 'make_config.mk' and die $!;
    chdir $cwd or die $!;
}

sub have_rocksdb {
    my ($self, $config) = @_;
    require File::Temp;
    print 'checking for rocksdb/db.h... ';
    my ($fh, $filename) = File::Temp::tempfile(SUFFIX => '.cc', UNLINK => 1);
    print $fh <<'END_SRC';
#include <rocksdb/db.h>
int main() {
    rocksdb::DB *db;
    return 0;
}
END_SRC
    my $cc = $self->config('cc');
    my $options = "-x c++ -std=gnu++11 -lstdc++ $config->{PLATFORM_CXXFLAGS} $config->{PLATFORM_LDFLAGS}";
    my $failed = system "$cc $options $filename -o /dev/null >/dev/null 2>&1";
    print $failed ? "no\n" : "yes\n";
    !$failed;
}

sub fetch_rocksdb {
    my $self = shift;
    system qw(git submodule update --init) and die $!;
}

sub compile_xs {
    my ($self, $file, %args) = @_;
    require ExtUtils::ParseXS;
    $self->log_verbose("$file -> $args{outfile}\n");
    ExtUtils::ParseXS::process_file(
        filename   => $file,
        prototypes => 0,
        output     => $args{outfile},
        'C++'      => 1,
        hiertype   => 1,
    );
}

sub is_debug {
    -d '.git';
}

sub ACTION_ppport_h {
    require Devel::PPPort;
    Devel::PPPort::WriteFile('ppport.h');
}

sub ACTION_typemap {
    require ExtUtils::Typemaps;
    require ExtUtils::Typemaps::Default;
    my $typemaps = ExtUtils::Typemaps->new;
    $typemaps->merge(typemap => ExtUtils::Typemaps::Default->new);
    $typemaps->write(file => 'typemap');
}

sub ACTION_build {
    my $self = shift;
    $self->do_system('make' => '-C', $ROCKSDB_DIR, 'static_lib', 'OPT=-fPIC', 'USE_RTTI=1');
    $self->SUPER::ACTION_build();
}

sub ACTION_clean {
    my $self = shift;
    $self->do_system('make' => '-C', $ROCKSDB_DIR, 'clean');
    $self->SUPER::ACTION_clean();
}

1;
__END__
