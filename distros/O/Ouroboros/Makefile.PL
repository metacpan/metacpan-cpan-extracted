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
    { name => 'SV_CONST_RETURN', type => 'UV' },
    { name => 'SV_COW_DROP_PV', type => 'UV' },
    { name => 'SV_FORCE_UTF8_UPGRADE', type => 'UV' },
    { name => 'SV_GMAGIC', type => 'UV' },
    { name => 'SV_HAS_TRAILING_NUL', type => 'UV' },
    { name => 'SV_IMMEDIATE_UNREF', type => 'UV' },
    { name => 'SV_NOSTEAL', type => 'UV' },
    { name => 'SV_SMAGIC', type => 'UV' },
    { name => 'GV_ADD', type => 'UV' },
    { name => 'GV_ADDMG', type => 'UV' },
    { name => 'GV_ADDMULTI', type => 'UV' },
    { name => 'GV_NOADD_NOINIT', type => 'UV' },
    { name => 'GV_NOEXPAND', type => 'UV' },
    { name => 'GV_NOINIT', type => 'UV' },
    { name => 'GV_SUPER', type => 'UV' },
    { name => 'PERL_MAGIC_arylen', type => 'UV' },
    { name => 'PERL_MAGIC_arylen_p', type => 'UV' },
    { name => 'PERL_MAGIC_backref', type => 'UV' },
    { name => 'PERL_MAGIC_bm', type => 'UV' },
    { name => 'PERL_MAGIC_checkcall', type => 'UV' },
    { name => 'PERL_MAGIC_collxfrm', type => 'UV' },
    { name => 'PERL_MAGIC_dbfile', type => 'UV' },
    { name => 'PERL_MAGIC_dbline', type => 'UV' },
    { name => 'PERL_MAGIC_debugvar', type => 'UV' },
    { name => 'PERL_MAGIC_defelem', type => 'UV' },
    { name => 'PERL_MAGIC_env', type => 'UV' },
    { name => 'PERL_MAGIC_envelem', type => 'UV' },
    { name => 'PERL_MAGIC_ext', type => 'UV' },
    { name => 'PERL_MAGIC_fm', type => 'UV' },
    { name => 'PERL_MAGIC_foo', type => 'UV' },
    { name => 'PERL_MAGIC_hints', type => 'UV' },
    { name => 'PERL_MAGIC_hintselem', type => 'UV' },
    { name => 'PERL_MAGIC_isa', type => 'UV' },
    { name => 'PERL_MAGIC_isaelem', type => 'UV' },
    { name => 'PERL_MAGIC_lvref', type => 'UV' },
    { name => 'PERL_MAGIC_nkeys', type => 'UV' },
    { name => 'PERL_MAGIC_overload_table', type => 'UV' },
    { name => 'PERL_MAGIC_pos', type => 'UV' },
    { name => 'PERL_MAGIC_qr', type => 'UV' },
    { name => 'PERL_MAGIC_regdata', type => 'UV' },
    { name => 'PERL_MAGIC_regdatum', type => 'UV' },
    { name => 'PERL_MAGIC_regex_global', type => 'UV' },
    { name => 'PERL_MAGIC_rhash', type => 'UV' },
    { name => 'PERL_MAGIC_shared', type => 'UV' },
    { name => 'PERL_MAGIC_shared_scalar', type => 'UV' },
    { name => 'PERL_MAGIC_sig', type => 'UV' },
    { name => 'PERL_MAGIC_sigelem', type => 'UV' },
    { name => 'PERL_MAGIC_substr', type => 'UV' },
    { name => 'PERL_MAGIC_sv', type => 'UV' },
    { name => 'PERL_MAGIC_symtab', type => 'UV' },
    { name => 'PERL_MAGIC_taint', type => 'UV' },
    { name => 'PERL_MAGIC_tied', type => 'UV' },
    { name => 'PERL_MAGIC_tiedelem', type => 'UV' },
    { name => 'PERL_MAGIC_tiedscalar', type => 'UV' },
    { name => 'PERL_MAGIC_utf8', type => 'UV' },
    { name => 'PERL_MAGIC_uvar', type => 'UV' },
    { name => 'PERL_MAGIC_uvar_elem', type => 'UV' },
    { name => 'PERL_MAGIC_vec', type => 'UV' },
    { name => 'PERL_MAGIC_vstring', type => 'UV' },
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
