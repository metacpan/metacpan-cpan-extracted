use strict;
use warnings;
use Module::Build;


# Module::Build does not validate linker and compiler flags, so we have
# to prepare them in advance

my $compiler_flags = `pkg-config librrd --cflags`;
$compiler_flags =~ s/\s+$//m;
if( defined($ENV{RRDTWEAK_CFLAGS}) ) {
    $compiler_flags .= ' ' . $ENV{RRDTWEAK_CFLAGS};
}
$compiler_flags = length($compiler_flags) ?
    [split(/\s+/,$compiler_flags)]:undef;

my $linker_flags = `pkg-config librrd --libs`;
$linker_flags =~ s/\s+$//m;
if( defined($ENV{RRDTWEAK_LDFLAGS}) ) {
    $linker_flags .= ' ' . $ENV{RRDTWEAK_LDFLAGS};
}
$linker_flags = length($linker_flags) ?
    [split(/\s+/,$linker_flags)]:undef;


my $builder = Module::Build->new(
    module_name         => 'RRD::Tweak',
    license             => 'gpl',
    dist_author         => q{Stanislav Sinyagin <ssinyagin@k-open.com>},
    dist_version_from   => 'lib/RRD/Tweak.pm',
    build_requires => {
        'Test::More' => 0,
        'Data::Compare' => 0,
        'Data::Dumper' => 0,
        'ExtUtils::CBuilder' => 0,
        'RRDs' => 0,
    },
    requires => {
        perl => '5.8.8',
    },
    extra_compiler_flags => $compiler_flags,
    extra_linker_flags   => $linker_flags,
    add_to_cleanup      => [ 'RRD-Tweak-*' ],
    create_makefile_pl => 'small',
);

$builder->create_build_script();
