use 5.016000;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;

# QR::Code encodes QR symbols in C. It links nothing and requires nothing
# at runtime: the encoder is arithmetic over its own tables, so there is
# no probe cascade here and no way for this to be unbuildable on a
# platform with a C compiler.
#
# It is a provider only - qr_abi.h lets a C consumer reach the encoder
# without going back through Perl.

my $INC = '-Iinclude';

my $pkg = ExtUtils::Depends->new('QR::Code');
$pkg->install('include/qr_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');

my %dep = $pkg->get_makefile_vars;
$INC = join ' ', grep { defined && length } $INC, delete $dep{INC};
# EU::Depends returns an empty LIBS and an LDFROM copy; both would
# clobber MakeMaker's defaults if passed through.
delete $dep{LIBS};
delete $dep{LDFROM};

# EU::Depends' PM map (qr_abi.h + Files.pm) replaces MakeMaker's
# auto-detected PM, so re-add the module's own .pm files.
require File::Find;
File::Find::find(sub {
    return unless /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

# MakeMaker tracks neither include/*.h nor xs/*.xs pulled in by INCLUDE:,
# so edits there do not rebuild without this (house gotcha).
my $deps = join ' ', glob('include/qr/*.h include/qr_abi.h'), glob('xs/*.xs');

WriteMakefile(
    NAME             => 'QR::Code',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/QR/Code.pm',
    ABSTRACT_FROM    => 'lib/QR/Code.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.016000',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.98',
    },
    PREREQ_PM => {
        'ExtUtils::Depends' => '0.404',
        'XSLoader'          => '0',
    },
    INC    => $INC,
    XS     => { 'Code.xs' => 'Code.c' },
    OBJECT => 'Code$(OBJ_EXT)',
    depend => {
        'Code.c'         => $deps,
        'Code$(OBJ_EXT)' => $deps,
    },
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'QR-Code-* Code.c Code.o Code.bs Install/Files.pm' },
    %dep,
);
