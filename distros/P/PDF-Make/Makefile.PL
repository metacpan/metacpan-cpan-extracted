use 5.010001;
use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use Config;
use File::Find;

mkdir 'Install';

# ── Platform-specific linker flags ────────────────────────
# Export C symbols so downstream XS modules (Chandra) can link against us.

my %platform_args;
if ($^O eq 'linux' || $^O eq 'freebsd' || $^O eq 'openbsd' || $^O eq 'netbsd' ||
    $^O eq 'dragonfly') {
    $platform_args{LDDLFLAGS} = $Config{lddlflags} . ' -Wl,--export-dynamic';
}
elsif ($^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'msys') {
    $platform_args{LDDLFLAGS} = ($Config{lddlflags} || '') . ' -Wl,--export-all-symbols';
}

# ── ExtUtils::Depends (export headers for downstream XS) ─

my $pkg = ExtUtils::Depends->new('PDF::Make');
$pkg->set_inc('-Iinclude');
$pkg->install(sort glob('include/pdfmake*.h'));
$pkg->save_config('Install/Files.pm');

my %dep_vars = $pkg->get_makefile_vars;

# ── Auto-discover PM files ────────────────────────────────

find(sub {
    return unless /\.pm$/;
    my $path = $File::Find::name;
    $path =~ s{^\./}{};
    (my $inst = $path) =~ s{^lib/}{\$(INST_LIB)/};
    $dep_vars{PM}{$path} = $inst;
}, 'lib');

# ── Auto-discover C/H/OBJECT from src/ and include/ ──────

my @c_src  = ('Make.c', sort glob('src/pdfmake*.c'));
my @h_files = sort glob('include/pdfmake*.h');
my @obj     = map { (my $o = $_) =~ s/\.c$/\$(OBJ_EXT)/; $o } @c_src;

# ── Read exported symbol list ─────────────────────────────

sub _read_funclist {
    open my $fh, '<', 'funclist.txt' or return ();
    my @funcs = grep { /\S/ && !/^#/ } map { chomp; $_ } <$fh>;
    return @funcs;
}

# ── WriteMakefile ─────────────────────────────────────────

my %WriteMakefileArgs = (
    NAME             => 'PDF::Make',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/PDF/Make.pm',
    ABSTRACT_FROM    => 'lib/PDF/Make.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010001',
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    OBJECT           => join(' ', @obj),
    C                => \@c_src,
    H                => \@h_files,
    XS               => { 'Make.xs' => 'Make.c' },
    INC              => '-Iinclude',
    CCFLAGS          => "$Config{ccflags} -std=gnu99",

    FUNCLIST         => [_read_funclist()],
    DL_FUNCS         => { 'PDF::Make' => [] },

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0',
    },
    TEST_REQUIRES => {
        'Test::More'                => '0',
        'Test::LeakTrace'           => '0',
        'Test2::Bundle::Numerical'  => '0.03',
    },
    PREREQ_PM => {
        'Object::Proto' => '0.16',
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'PDF-Make-* Make.c Make.bs Install/' },

    %platform_args,
    %dep_vars,
);

# Compatibility with older ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}
unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}
delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);

# ── Postamble: per-file compile rules for src/*.c ────────

package MY;

sub postamble {
    my @rules;

    # MakeMaker's default .c.o rule compiles into ./ not src/,
    # so we generate explicit rules with -o src/foo$(OBJ_EXT).
    for my $c (sort glob('src/pdfmake*.c')) {
        (my $o = $c) =~ s/\.c$/\$(OBJ_EXT)/;
        push @rules, <<"RULE";
$o: $c
\t\$(CC) -c \$(INC) \$(CCFLAGS) \$(OPTIMIZE) \$(CCCDLFLAGS) \\
\t    -DVERSION=\\"\$(VERSION)\\" -DXS_VERSION=\\"\$(XS_VERSION)\\" \\
\t    "-I\$(PERL_INC)" \\
\t    -o $o $c
RULE
    }

    return join("\n", @rules);
}
