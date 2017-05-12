use ExtUtils::MakeMaker;
use ExtUtils::Constant "WriteConstants";

WriteMakefile(
    NAME              => 'Ouroboros',
    VERSION_FROM      => 'lib/Ouroboros.pm',
    ABSTRACT_FROM     => 'lib/Ouroboros.pm',
    AUTHOR            => 'Vickenty Fesunov <cpan-ouroboros@setattr.net>',
    LICENSE           => 'freebsd',
    MIN_PERL_VERSION  => "5.18.0", # SvREFCNT_dec_NN
    PREREQ_PM         => {
        "File::ShareDir" => 0,
    },
    TEST_REQUIRES     => {
        "FFI::Raw" => 0,
        "FFI::Platypus" => 0,
    },
    OBJECT            => "Ouroboros.o libouroboros.o",
    LIBS              => [],
    DEFINE            => '',
    INC               => '-I.',
    depend            => { "Ouroboros.xs" => "const-c.inc const-xs.inc" },
    realclean         => { FILES => "const-c.inc const-xs.inc" },
    META_MERGE        => {
        "meta-spec" => { version => 2 },
        no_index => {
            directory => [ qw/tools/ ],
        },
        resources => {
            repository => {
                type => "git",
                url => "https://github.com/vickenty/ouroboros",
                web => "https://github.com/vickenty/ouroboros",
            },
            bugtracker => {
                web => "https://github.com/vickenty/ouroboros/issues",
            },
        },
    },
);

my @consts = (
    { name => 'SVt_NULL', type => 'IV', macro => 1 },
    { name => 'SVt_IV', type => 'IV', macro => 1 },
    { name => 'SVt_NV', type => 'IV', macro => 1 },
    { name => 'SVt_PV', type => 'IV', macro => 1 },
    { name => 'SVt_PVIV', type => 'IV', macro => 1 },
    { name => 'SVt_PVNV', type => 'IV', macro => 1 },
    { name => 'SVt_PVMG', type => 'IV', macro => 1 },
    { name => 'SVt_REGEXP', type => 'IV', macro => 1 },
    { name => 'SVt_PVGV', type => 'IV', macro => 1 },
    { name => 'SVt_PVLV', type => 'IV', macro => 1 },
    { name => 'SVt_PVAV', type => 'IV', macro => 1 },
    { name => 'SVt_PVHV', type => 'IV', macro => 1 },
    { name => 'SVt_PVCV', type => 'IV', macro => 1 },
    { name => 'SVt_PVFM', type => 'IV', macro => 1 },
    { name => 'SVt_PVIO', type => 'IV', macro => 1 },
    { name => 'SVt_LAST', type => 'IV', macro => 1 },
    { name => 'SV_CATBYTES', type => 'UV' },
    { name => 'SV_CATUTF8', type => 'UV' },
    { name => 'SV_COW_DROP_PV', type => 'UV' },
    { name => 'SV_COW_OTHER_PVS', type => 'UV' },
    { name => 'SV_COW_SHARED_HASH_KEYS', type => 'UV' },
    { name => 'SV_FORCE_UTF8_UPGRADE', type => 'UV' },
    { name => 'SV_GMAGIC', type => 'UV' },
    { name => 'SV_HAS_TRAILING_NUL', type => 'UV' },
    { name => 'SV_IMMEDIATE_UNREF', type => 'UV' },
    { name => 'SV_MUTABLE_RETURN', type => 'UV' },
    { name => 'SV_NOSTEAL', type => 'UV' },
    { name => 'SV_SKIP_OVERLOAD', type => 'UV' },
    { name => 'SV_SMAGIC', type => 'UV' },
    { name => 'SV_UNDEF_RETURNS_NULL', type => 'UV' },
    { name => 'SV_UTF8_NO_ENCODING', type => 'UV' },
);

WriteConstants(
    NAME => "Ouroboros",
    NAMES => \@consts,
    PROXYSUBS => { push => "CONSTS" },
);

package MY;
use File::Spec::Functions qw/catfile/;

sub MY::postamble {
    my $self = shift;
    my $dest = catfile(qw#$(INST_LIB) auto share dist $(DISTNAME)#);
    my $make = "config::\n";
    my @files = qw/libouroboros.h libouroboros.c/;

    join "", map "$_\n",
        "config::",
        "\t\$(NOECHO) \$(MKPATH) '$dest'\n",
        map "\t\$(NOECHO) \$(CP) '$_->[0]' '$_->[1]'",
        map [ $_, catfile($dest, $_) ],
        @files;
}
